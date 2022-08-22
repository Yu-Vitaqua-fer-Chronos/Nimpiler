import compiler/modulegraphs

import json

proc jsonifyProject*(graph: ModuleGraph) =
  var jsonNode = JsonNode()

  for iface in graph.ifaces:
    echo "A"