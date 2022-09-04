import
  compiler/ast/[
    reports
  ],
  compiler/modules/[
    modulegraphs
  ]

type
  Module* = ref object of TPassContext
    sym*: PSym
    nodes*: seq[PNode]

  ModuleList* = ref object of RootObj
    modules*: seq[Module]