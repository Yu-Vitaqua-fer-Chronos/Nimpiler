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

template addAll[T](sequence: seq[T], values: varargs[T]) =
  for val in values:
    sequence.add val

type
  Snippet* = ref object
    code*: string  # The line of code as a string
    indent*: int   # The amount of times to indent the instruction

  Method* = object
    accessModifiers*: seq[string] # public, private, protected, static, final, synchronized, native, abstract
    name*: string                 # constructors are `<init>`
    arguments*: seq[string]       # Types, such as `[Ljava/lang/String;` for a string array ## ]
    throws*: seq[string]          # Not necessary but recommended for good Java interop
    body*: seq[Snippet]           # The same as `statements`, `return`s aren't implicit in Jasmin
    variables*: seq[string]       # Kept here so we can turn names into integers for accessing variables
    stackCounter: int             # Counts how many items should be on the stack, this is just an internal counter

  Field* = object
    accessModifiers*: seq[string] # public, private, protected, static, final, volatile, transient
    name*: string                 # Name of the field
    typ*: string                  # Descriptor is the same as type
    value*: Option[string]        # Value, value is optional

  Class* = object
    accessModifiers*: seq[string] # public, final, super, interface, abstract
    name*: string                 # The name of the class
    super*: string                # The base class, by default this should be `java/lang/Object`
    implements*: seq[string]      # Unless we're interacting with JVM code, this should be empty
    methods*: seq[Method]         # All methods in the class body
    fields*: seq[Field]           # All fields in the class body


proc getMethod(c: Class, name: string, args: seq[string]): ref Method =
  result = nil

  for mthd in c.methods:
    if mthd.name == name and mthd.arguments == args:
      result = ref mthd


proc `$`*(c: Class): string =
  result &= ".class " & c.accessModifiers.join(" ") & " " & c.name & "\n"
  result &= ".super " & c.super & "\n"

  for i in c.implements:
    result &= ".implements " & i & "\n"

  for field in c.fields:
    result &= ".field " & field.accessModifiers.join(" ") & " " & field.name & " " & field.typ
    if field.value.isSome():
      result &= " = " & field.value.get()
    result &= "\n"

  for mthd in c.methods:
    result &= ".method " & mthd.accessModifiers.join(" ") & " " & mthd.name & "(" & mthd.arguments.join(" ")
    result &= ")V\n"

    result &= ".limit stack " & mthd.stackCounter & "\n\n"

    if mthd.throws.len != 0:
      for exception in mthd.throws:
        result &= "  .throws " & exception & "\n"

      result &= "\n"

    for snippet in mthd.body:
      result &= repeat("  ", snippet.indent) & snippet.code & "\n"

    result &= ".end method\n\n"


template construct*(c: Class): string = $c

var files:seq[string] = @["output/source/HelloWorld.j"]

var HelloWorld = Class(
  accessModifiers: @["public"],
  name: "HelloWorld",
  super: "java/lang/Object",
  implements: newSeq[string](0)
)

var init = Method(
  accessModifiers: @["public"],
  name: "<init>",
  arguments: @["[Ljava/lang/String;"],
  stackCounter: 0
)

init.body.addAll
  Snippet(indent: 1, code: "aload_0"),
  Snippet(indent: 1, code: "invokenonvirtual java/lang/Object/<init>()V"),
  Snippet(indent: 1, code: "return")

HelloWorld.methods.add init

proc gen(ctx: var GenCtx, n: PNode)

proc genProc(ctx: var GenCtx, s: PSym) =
  ctx.depth += 1
  assert s.kind in routineKinds
  # only generate code for the procedure once
  if not ctx.seensProcs.containsOrIncl(s.itemId):
    let body = transformBody(ctx.graph, ctx.idgen, s, cache = true)
    gen(ctx, body)
  ctx.depth -= 1

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
      code &= "bipush " & $n.intVal & "\n"

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

  HelloWorld.getMethod()

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

    writeFile("output/source/HelloWorld.j", $HelloWorld)

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