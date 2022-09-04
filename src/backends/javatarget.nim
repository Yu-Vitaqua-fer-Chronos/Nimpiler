import ../typedefinitions

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
    os, tables
  ]


proc nodehandler(node:PNode) =
  case node.kind
  of nkCharLit..nkUInt64Lit:
    discard
  of nkFloatLit..nkFloat128Lit:
    discard
  of nkStrLit..nkTripleStrLit:
    discard
  of nkSym:
    echo "Here be symbols!"
  of nkIdent:
    discard
  else:
    for son in node.sons.items:
      nodehandler(son)


proc toJava*(graph:ModuleGraph, mlist:ModuleList) =
  #var objectClasses = initTable[string, JavaClass]()

  #var basepkg = "base.package"

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)

    for n in m.nodes.items:
      if n == nil:
        continue

      case n.kind
      of nkSym:
        echo "Here be symbols! -" & nimfile.string

      else:
        discard