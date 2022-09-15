# Yoinked straight from Zerbina's backend skeleton, thanks again!
# It's from the vmgen pass but stripped of the meat and stuff-

import
  std/[
    sets
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

import ../typedefinitions
import ../utils

proc myOpen(graph: ModuleGraph, module: PSym, idgen: IdGenerator): PPassContext =
  if graph.backend == nil:
    graph.backend = ModuleListRef()

  let
    mlist = ModuleListRef(graph.backend)
    id = module.itemId.module

  assert id >= 0 and id == module.position # sanity check

  # resize the table
  mlist.modules.setLen(id + 1)
  mlist.modules[id] = Module(sym: module, idgen: idgen)

  # Debugging stuff
  if getPackage(module).name.s != "stdlib":
    echo toFullPath(graph.config, module.position.FileIndex)

  result = ModuleRef(list: mlist, index: id)


proc myProcess(b: PPassContext, n: PNode): PNode =
  result = n
  let m = ModuleRef(b)

  if n.kind == nkStmtList:
    m.list.modules[m.index].stmts.add(n)


proc myClose(graph: ModuleGraph; b: PPassContext, n: PNode): PNode =
  result = myProcess(b, n)

  let m = ModuleRef(b)
  m.list.modulesClosed.add(m.index)


const collectPass* = makePass(myOpen, myProcess, myClose)