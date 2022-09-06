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


proc nodehandler(collectedSyms:var Table[string, seq[PSym]], file:AbsoluteFile, n:PNode) =
  case n.kind
  of nkCharLit:
    discard

  of nkIntLit..nkUInt64Lit:
    discard

  of nkFloatLit..nkFloat128Lit:
    discard

  of nkStrLit..nkTripleStrLit:
    discard

  of nkSym:
    if n.sym notin collectedSyms[file.string]:
      collectedSyms[file.string].add(n.sym)

  of nkIdent:
    discard

  of nkEmpty:
    discard

  else:
    for son in n.sons:
      nodehandler(collectedSyms, file, son)


proc toJava*(graph:ModuleGraph, mlist:ModuleList) =
  var data = Data()
  var collectedSyms:Table[string, seq[PSym]]

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)
    collectedSyms[nimfile.string] = newSeq[PSym]()

    for n in m.nodes.items:
      if n == nil:
        continue

      n.scan(data)

      nodehandler(collectedSyms, nimfile, n)

  var total = 0
  for key in collectedSyms.keys:
    echo "Collected symbols from `", key, "`: ", collectedSyms[key].len
    total += collectedSyms[key].len

  echo "My collected symbols: ", total
  echo "Other collected symbols: ", data.syms.data.len