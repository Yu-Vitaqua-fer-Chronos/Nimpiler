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

import ../../typedefinitions
import ../../utils

import jnim

type Method* = object
  accessModifiers*: string[seq] # public, private, protected, static, final, synchronized, native, abstract
  name*: string                 # constructors are `<init>`
  arguments*: seq[string]       # Types, such as `[Ljava/lang/String;` for a string array ## ]
  stackCounter: int             # Counts how many items should be on the stack, this is just an internal counter
  body*: seq[string]            # The same as `statements`, `return`s aren't implicit in Jasmin
  variables*: seq[string]       # Kept here so we can turn mangled names into integers for accessing variables

type Field* = object
  accessModifiers*: string[seq] # public, private, protected, static, final, volatile, transient
  name*: string                 # Name of the field
  typ*: string                  # Descriptor is the same as type
  value*: Option[string]        # Value, value is optional

type Class* = object
  accessModifiers*: string[seq] # public, final, super, interface, abstract
  name*: string                 # The name of the class
  super*: string                # The base class, by default this should be `java/lang/Object`
  implements*: seq[string]      # Unless we're interacting with JVM code, this should be empty
  methods*: seq[Method]         # All methods in the class body
  fields*: seq[Field]           # All fields in the class body


proc construct(c: Class): string =
  result &= ".class " & c.accessModifiers.join(" ") & " " & c.name & "\n"
  result &= ".super " & c.super & "\n"

  for i in c.implements:
    result &= ".implements " & i & "\n"

  for field in c.fields:
    result &= ".field " & field.accessModifiers.join(" ") & " " & field.name & " " & field.typ
    if field.value.isSome():
      result &= " = " & field.value.get()

  for method in c.methods:
    result &= ""



var files:seq[string] = @["output/source/HelloWorld.j"]

# Just a test
var code = """.class public HelloWorld
.super java/lang/Object

.method public <init>()V
    aload_0
    invokenonvirtual java/lang/Object/<init>()V
    return
.end method

.method public static main([Ljava/lang/String;)V
"""

proc gen(ctx: var GenCtx, n: PNode)

proc genProc(ctx: var GenCtx, s: PSym) =
  assert s.kind in routineKinds
  # only generate code for the procedure once
  if not ctx.seensProcs.containsOrIncl(s.itemId):
    let body = transformBody(ctx.graph, ctx.idgen, s, cache = true)
    gen(ctx, body)

proc genMagic(ctx: var GenCtx, m: TMagic, callExpr: PNode): bool =
  ## Returns 'false' if no special handling is used and a default function
  ## call is to be emitted instead
  # implement special handling for calls to magics here...
  result = true

  case m
  of mAddI:
    echo "Addition magic!"
  of mEcho:
    code &= ".limit stack 2\n" &
      "getstatic java/lang/System/out Ljava/io/PrintStream;\n"

    for son in callExpr.sons.items:
      gen(ctx, son) # To unwrap the node

    code &= "invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n"
  else:
    echo "magic not implemented: ", m
    result = false

proc genCall(ctx: var GenCtx, n: PNode) =
  # generate code for the callee:
  gen(ctx, n[0])

  # generate code for the call:
  # ...
  echo n.kind

proc gen(ctx: var GenCtx, n: PNode) =
  ## Generate code for the expression or statement `n`
  case n.kind
  of nkSym:
    let s = n.sym

    case s.kind
    of skProc, skFunc, skIterator, skConverter:
      genProc(ctx, s)
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
      code &= "ldc " & n.strVal.escape() & "\n"
    of nkIntLit..nkUInt64Lit:
      code &= "ldc " & $n.intVal & "\n"
    else:
      echo "Implementation missing for: ", n.kind

  else:
    # each node kind needs it's own visitor logic, but to help with
    # prototyping, nodes for which none is implemented yet simply visit their
    # children (if any)
    # ``safeLen`` is used because the node might be a leaf node
    echo "Unimplemented node: ", n.kind
    for i in 0..<n.safeLen:
      gen(ctx, n[i])

proc generateTopLevelStmts(ctx: var GenCtx, m: Module) =
  let
    # for simplicity, merge all statments into a single one
    stmts = newTree(nkStmtList, m.stmts)
    # transform the statement
    transformed = transformStmt(ctx.graph, ctx.idgen, m.sym, stmts)

  # note: ``injectdestructors`` is not run, so destructors and lifetime-hooks
  #       won't work

  gen(ctx, stmts)

proc generateCode*(g: ModuleGraph) =
  ## The backend's entry point
  let
    mlist = g.backend.ModuleListRef
    conf = g.config

  var ctx = GenCtx(graph: g)

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

    code &= "return\n.end method"

    writeFile("output/source/HelloWorld.j", code)

    let path = findJVM()
    if path.isSome:
      let bin = path.get().root / "bin" / "java"

      let jasminPath = getAppDir() / "src" / "backends" / "jvm" / "jasmin.jar"

      var arguments = @["-jar", jasminPath, "-d", "output"/"compiled"]

      for file in files:
        arguments.add file

      discard execProcess(bin, options={poStdErrToStdOut}, args=arguments)
    else:
      echo "The Jasmin source code couldn't be compiled! Is your java installation on the PATH?"