import
  compiler/ast/[
    reports,
    ast,
    ast_types
  ],
  compiler/modules/[
    modulegraphs
  ]

import std/[intsets, sets]

type
  Module* = object
    stmts*: seq[PNode] ## top level statements in the order they were seen
    sym*: PSym ## module symbol
    idgen*: IdGenerator

  ModuleList* = object of RootObj
    modules*: seq[Module]
    modulesClosed*: seq[int] ## indices into `modules` in the order the modules
                            ## were closed. The first closed module comes
                            ## first, then the next, etc

  ModuleListRef* = ref ModuleList

  ModuleRef* = ref object of TPassContext
    ## The pass context for the VM backend. Represents a reference to a
    ## module in the module list
    list*: ModuleListRef
    index*: int

  GenCtx* = object of RootObj # Inheritable as some backends may need to store other stuff here
    seensProcs*: HashSet[ItemId]

    graph*: ModuleGraph
    idgen*: IdGenerator

  Collected*[T] = object
    marker*: IntSet
    data*: seq[T]

  Data* = object
    syms*:  Collected[PSym]
    types*: Collected[PType]