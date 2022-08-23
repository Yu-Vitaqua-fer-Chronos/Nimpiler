import compiler/modulegraphs
import compiler/ast

import json

type Module = ref object
  identifier:string  # This is the name of the module identifier, so if your file is named `aaaaa.nim`, the module is named `aaaaa`

type JsonOutput = object
  modules:seq[Module]

proc serialiseModule(m:PSym): Module =
  result = Module(
    identifier:m.name.s
  )


proc jsonifyProject*(graph: ModuleGraph) =
  var jOutput = JsonOutput(modules:newSeq[Module]())

  for iface in graph.ifaces:
    if iface.module == nil:
      continue

    jOutput.modules.add serialiseModule(iface.module)

  echo ""

  # echo "\n" & (%jOutput).pretty 2