import ../typedefinitions
import ../utils

import codegenlib/java

import
  compiler/ast/[
    ast_idgen, reports, idents
  ],
  compiler/front/[
    msgs, cmdlinehelper, options, commands, cli_reporter
  ],
  compiler/modules/[
    modulegraphs, modules
  ],
  compiler/sem/[
    passes, passaux, sem
  ],
  compiler/utils/[
    pathutils
  ],
  std/[
    os, tables, strutils
  ]

java.globalNamespace = "com.foc.nimskull"


proc nodehandler(n:PNode) =
  if n == nil:
    return

  case n.kind

  of nkCharLit:
    echo n.intVal

  of nkIntLit..nkUInt64Lit:
    echo n.intVal

  of nkFloatLit..nkFloat128Lit:
    echo n.floatVal

  of nkStrLit..nkTripleStrLit:
    echo n.strVal

  of nkSym:
    echo n.sym.name.s

  of nkIdent:
    echo n.ident.s

  of nkEmpty:
    return

  else:
    for son in n.sons:
      nodehandler(son)


proc myOpen(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  ## Called when a new module starts parsing/processing. Note that multiple
  ## modules can start processing before one of them is closed. `s` is the
  ## symbol of the module.

  # create a context object for the module. Each further processing of the
  # module in question will get this object passed to it
  result = Module(sym: s)

  # register the module in the list
  ModuleList(graph.backend).modules.add Module(result)

  let nimfile = AbsoluteFile toFullPath(graph.config, s.position.FileIndex)

  echo "Handling ", nimfile.string

proc myProcess(b: PPassContext, n: PNode): PNode =
  ## Called when a top-level statement or declaration is parsed. `n` is the
  ## input node. Each pass' input is the output of the previous pass.
  ## In case of the first pass (usually semantic ananlysis) this input is the
  ## parser output.

  # we're the last processing step and we're also only collecting - just
  # return the input
  result = n

  # append the node to the module
  Module(b).nodes.add(n)

proc myClose(graph: ModuleGraph; b: PPassContext, n: PNode): PNode =
  ## Called when a module has finished parsing and processing

  # process the final node
  result = myProcess(b, n)


# wrap the procedures into a ``TPass`` object that we can then register
const javaPass* = makePass(myOpen, myProcess, myClose)


#[
proc toJava*(graph:ModuleGraph, mlist:ModuleList) =
  var data = Data()
  var tbl:Table[string, string]

  tbl["<tl>"] = ""

  createDir("output") # Create an output directory for generated Java code

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)

    for n in m.nodes.items:
      if n == nil:
        continue

      n.scan(data)

      if nimfile.string.endsWith("addition.nim"):
        nodehandler(n)
]#