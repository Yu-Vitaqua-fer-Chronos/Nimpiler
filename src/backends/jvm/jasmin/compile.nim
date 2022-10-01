## A heavily thinned down version of the ``compiler/vm/vmbackend`` module
## with some tweaks plus the skeleton of a recursive code-generator that
## only traverses alive code and *procedures* (the special handling required
## for ``method``s is not present).
##
## The ``collectPass`` needs to be registered before calling
## ``compileProject``. After ``compileProject`` finished, ``generateCode``
## needs to be called.

import
  std/[
    sets, os, osproc, strutils, unicode, options, sequtils
  ],
  compiler/ast/[
    ast,
    ast_types
  ],
  compiler/sem/[
    passes,
    transf
  ],
  compiler/modules/[
    modulegraphs
  ],
  compiler/front/[
    msgs
  ]

import ../../../typedefinitions as gendefs
import ../../../utils

import ./typedefinitions as jasdefs
import ./construction

import ./instructions

import jnim # Only used for finding the JVM

template addAll[T](sequence: seq[T], values: varargs[T]) =
  for val in values:
    sequence.add val

var files:seq[string] = @["output/source/HelloWorld.j"]

proc gen(ctx: var JasminCtx, n: PNode)

proc genProc(ctx: var JasminCtx, s: PSym) =
  ctx.depth += 1
  assert s.kind in routineKinds
  # only generate code for the procedure once
  if not ctx.seensProcs.containsOrIncl(s.itemId):
    let body = transformBody(ctx.graph, ctx.idgen, s, cache = true)
    gen(ctx, body)
  ctx.depth -= 1

proc genMagic(ctx: var JasminCtx, m: TMagic, callExpr: PNode): bool =
  ## Returns 'false' if no special handling is used and a default function
  ## call is to be emitted instead
  # implement special handling for calls to magics here...
  result = true

  case m
  of mAddI:
    echo "Addition magic!"
  of mEcho:
    ctx.cmthd.getstatic("java/lang/System/out", "Ljava/io/PrintStream;")

    for son in callExpr.sons.items:
      gen(ctx, son) # To unwrap the node
    ctx.cmthd.invokevirtual("java/io/PrintStream/println(Ljava/lang/String;)V")
  else:
    echo "magic not implemented: ", m
    result = false

proc genCall(ctx: var JasminCtx, n: PNode) =
  # generate code for the call:
  # ...
  echo n.kind

proc gen(ctx: var JasminCtx, n: PNode) =
  ## Generate code for the expression or statement `n`
  case n.kind
  of nkSym:
    let s = n.sym

    case s.kind
    of skProc, skFunc, skIterator, skConverter:
      genProc(ctx, s)

    of skVar:
      echo s.name.s
      echo s.magic

    else:
      # handling of other symbol kinds here...
      echo "Implementation missing for: ", s.kind

  of nkCallKinds:
    if n[0].kind == nkSym:
      let s = n[0].sym

      let useNormal = 
        if s.magic != mNone:
          # if ``genMagic`` returns 'false', the procedure is treated as a
          # non-builtin and uses the same code-generator logic as all other
          # procedures 
          not genMagic(ctx, s.magic, n)
        else:
          true

      if useNormal:
        genCall(ctx, n)

    else:
      # indirect call
      genCall(ctx, n)

  of routineDefs, nkTypeSection, nkTypeOfExpr, nkCommentStmt, nkIncludeStmt,
      nkImportStmt, nkImportExceptStmt, nkExportStmt, nkExportExceptStmt,
      nkFromStmt, nkStaticStmt:
    # ignore declarative nodes, e.g. routine definitions, import statments, etc.
    discard

  of nkLiterals:
    case n.kind
    of nkStrLit..nkTripleStrLit:
      ctx.cmthd.ldc(n.strVal)

    of nkIntLit..nkUInt64Lit:
      ctx.cmthd.sipush(n.intVal)
      ctx.cmthd.stackCounter += 1

    else:
      echo "Implementation missing for: ", n.kind

  of nkStmtList: # Go through child nodes
    for i in 0..<n.len:
      gen(ctx, n[i])

  of nkIdentDefs:
    discard # Do work on this

  of nkEmpty: # Empty nodes can be safely discarded
    discard

  else:
    # each node kind needs it's own visitor logic, but to help with
    # prototyping, nodes for which none is implemented yet simply visit their
    # children (if any)
    # ``safeLen`` is used because the node might be a leaf node
    echo "Unimplemented node: ", n.kind
    for i in 0..<n.safeLen:
      gen(ctx, n[i])

proc generateTopLevelStmts(ctx: var JasminCtx, m: Module) =
  let
    # for simplicity, merge all statments into a single one
    stmts = newTree(nkStmtList, m.stmts)
    # transform the statement
    transformed = transformStmt(ctx.graph, ctx.idgen, m.sym, stmts)

  # note: ``injectdestructors`` is not run, so destructors and lifetime-hooks
  #       won't work

  # Define current method
  ctx.queueMthd Method(accessModifiers: @["public", "static"], name: "main",
    arguments: @["[Ljava/lang/String;"]) # IDE ]

  gen(ctx, stmts)

  ctx.cmthd.jreturn
  ctx.delMthd()


proc generateCode*(g: ModuleGraph) =
  ## The backend's entry point
  let
    mlist = g.backend.ModuleListRef
    conf = g.config

  # Our own Context, inherited from GenCtx so it can be used to store other need info
  var ctx = JasminCtx(graph: g)

  # TODO: Make class generation automatic
  ctx.ccls = Class(
    accessModifiers: @["public"],
    name: "HelloWorld",
    super: "java/lang/Object",
    implements: newSeq[string](0)
  )

  # TODO: Make it so we can create init methods and others, easier (as well as making it so Nim code can still
  # TODO: follow Nim semantics)
  var init = Method(
    accessModifiers: @["public"],
    name: "<init>"
  )

  init.aload_0()
  init.invokespecial("java/lang/Object/<init>()V")
  init.jreturn

  # TODO: Possibly directly modify the method in the sequence instead of adding manually?
  ctx.ccls.methods.add init
  # Finish up initial class setup

  for m in mlist.modules.items:
    if m.sym == nil:
      # ``include``d modules don't reach ``myOpen`` and so don't have
      # a valid list entry -> skip them
      continue

    if m.sym.owner != nil and m.sym.owner.kind == skPackage and m.sym.owner.name.s == "stdlib":
      # skip modules that are part of the stdlib (this includes ``system``!)
      # only here for development purposes really, ideally this should work with most things!
      continue

    var fn = toFilename(g.config, m.sym.position.FileIndex)

    if fn.endsWith(".nim"):
      fn = fn.substr(0, fn.len - 5)

    fn = fn.replace("_", " ").title.replace(" ", "")

    ctx.idgen = m.idgen # use the IdGenerator of the module

    "output/source".createDir
    "output/compiled".createDir

    generateTopLevelStmts(ctx, m)

    writeFile("output/source/HelloWorld.j", $ctx.ccls)

    let path = findJVM()
    if path.isSome:
      let bin = path.get().root / "bin" / "java"

      let jasminPath = getAppDir() / "src" / "backends" / "jvm" / "jasmin" / "compile.jar"

      var arguments = @["-jar", jasminPath, "-d", "output"/"compiled"]

      for file in files:
        arguments.add file

      discard execProcess(bin, options={poStdErrToStdOut}, args=arguments)
    else:
      echo "The Jasmin source code couldn't be compiled! Is your java installation on the PATH?"