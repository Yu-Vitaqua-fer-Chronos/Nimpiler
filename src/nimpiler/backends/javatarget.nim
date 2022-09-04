import ../typedefinitions

import codegenlib/java

import compiler/[ast, modulegraphs, idents, lineinfos, ropes, options, pathutils, msgs]
import std/os


proc toJava*(graph:ModuleGraph, mlist:ModuleList) =
  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)

    for n in m.nodes.items:
      if n == nil:
        continue

  #[
  if graph:
    gr
  else:
    createDir "output"
  ]#