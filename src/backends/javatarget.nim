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


proc toJava*(graph:ModuleGraph, mlist:ModuleList) =
  var data = Data()

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)
    collectedSyms[nimfile.string] = newSeq[PSym]()

    for n in m.nodes.items:
      if n == nil:
        continue

      n.scan(data)



  echo "Other collected symbols: ", data.syms.data.len