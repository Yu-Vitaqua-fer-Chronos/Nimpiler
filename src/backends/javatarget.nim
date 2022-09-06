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
  var javafile = newJavaFile(namespace="com.foc.nim.codegen")
  var javaclass = newJavaClass("Main", true)
  javafile.addJavaClass(javaclass)

  var mainMethod = newJavaMethodDeclaration("main", "void", true, true)
  javaclass.addClassMethod(mainMethod)

  mainMethod.addMethodArgument("String[]", "args")

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)

    for n in m.nodes.items:
      if n == nil:
        continue

      n.scan(data)

      var jc = ""

      if nimfile.string.endsWith("quit.nim"):
        if n.kind == TNodeKind.nkCall:
          echo "Call statement found!"
          for son in n.sons.items:
            case son.kind
            of nkSym:
              if son.sym.name.s == "quit":
                jc &= "System.exit"
            of nkIntLit:
              jc &= "(" & $son.intVal & ");"
            else:
              echo "Kind: ", n.kind

        mainMethod.addSnippetToMethodBody jc.javacode

  echo $javafile