import
  compiler/ast/[
    reports
  ],
  compiler/modules/[
    modulegraphs
  ]

import std/[intsets]

type
  Module* = ref object of TPassContext
    sym*: PSym
    nodes*: seq[PNode]

  ModuleList* = ref object of RootObj
    modules*: seq[Module]

  Collected*[T] = object
    marker*: IntSet
    data*: seq[T]

  Data* = object
    syms*:  Collected[PSym]
    types*: Collected[PType]