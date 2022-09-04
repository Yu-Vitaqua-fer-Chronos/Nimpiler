# !!!THIS IS A HUGE WORK IN PROGRESS, I AM NOW FOCUSING MY EFFORTS TOWARDS THE NIM JAVA BACKEND!!!

{.experimental: "codeReordering".}

import compiler/[ast, modulegraphs, idents, lineinfos, ropes, options, pathutils, msgs]

import std/[streams, tables, options]

import ../typedefinitions

import msgpack4nim

type
  ReferenceKey* = distinct int

  NoCyclicTIdent = object
    id*: int
    s*: string
    next*: PIdent  # Should reference a PIdent
    h*: Hash

  NoCyclicTLib* = object
    kind*: TLibKind
    generated*: bool
    isOverriden*: bool
    name*: string  # We eliminate ropes by just using the string value
    path*: ReferenceKey  # Should reference a PNode

  NoCyclicTType* = object
    kind*: TTypeKind
    callConv*: TCallingConvention
    flags*: TTypeFlags
    sons*: TTypeSeq
    node*: ReferenceKey  # Should reference a PNode, n -> node
    owner*: ReferenceKey  # Should reference a PSym
    sym*: ReferenceKey  # Should reference a PSym
    size*: BiggestInt
    align*: int16
    paddingAtEnd*: int16
    lockLevel*: TLockLevel
    loc*: TLoc
    typeRefId*: ReferenceKey  # Should reference a PType, typeInst -> typeRefId
    uniqueId*: ItemId
    itemId*: ItemId

  NoCyclicTNode* = object
    when defined(useNodeIds):
        id*: int

    typeRefId*: ReferenceKey  # Should reference a PType, typ -> typeRefId
    info*: TLineInfo
    flags*: TNodeFlags
    case kind*: TNodeKind
    of nkCharLit .. nkUInt64Lit:
        intVal*: BiggestInt

    of nkFloatLit .. nkFloat128Lit:
        floatVal*: BiggestFloat

    of nkStrLit .. nkTripleStrLit:
        strVal*: string

    of nkSym:
        sym*: ReferenceKey  # Should reference a PSym

    of nkIdent:
        ident*: PIdent

    else:
        sons*: seq[ReferenceKey]  # Should reference PNodes (as a sequence)

  NoCyclicTSym* = object
    case kind*: TSymKind
    of routineKinds: # Idk what this is used for but keeping it in *just* in case
        gcUnsafetyReason*: ReferenceKey  # Should reference a PSym
        transformedBody*: ReferenceKey  # Should reference a PNode

    of skLet, skVar, skField, skForVar:
        guard*: ReferenceKey  # Should reference a PSym
        bitsize*: int
        alignment*: int

    else:
      nil
    magic*: TMagic
    typ*: PType  # Should reference a PType
    name*: PIdent
    info*: TLineInfo
    owner*: PSym
    flags*: TSymFlags
    ast*: ReferenceKey  # Should reference a PNode
    options*: TOptions
    position*: int
    offset*: int
    loc*: TLoc
    annex*: ReferenceKey  # Should reference a PLib

    # Code doesn't work for some odd reason, maybe that should be expected though
    #[
    when hasFFI:
        cname*: string
    ]#

    constraint*: ReferenceKey  # Should reference a PNode
    when defined(nimsuggest):
        allUsages*: seq[TLineInfo]

    itemId*: ItemId

  ItemIDToIdentRef* = Table[ReferenceKey,NoCyclicTIdent]
  ItemIdToLibRef* = Table[ReferenceKey,NoCyclicTLib]
  ItemIdToTypeRef* = Table[ReferenceKey,NoCyclicTType]
  ItemIdToNodeRef* = Table[ReferenceKey,NoCyclicTNode]
  ItemIdToSymRef* = Table[ReferenceKey,NoCyclicTSym]

  OutputtedData* = object
    refIdents*:ItemIDToIdentRef
    refLibs*:ItemIdToLibRef
    refTypes*:ItemIdToTypeRef
    refNodes*:ItemIdToNodeRef
    refSyms*:ItemIdToSymRef


proc serialise(dat:var OutputtedData, l:PIdent) = discard

proc serialise(dat:var OutputtedData, l:PLib) = discard

proc serialise(dat:var OutputtedData, t:PType) = discard

proc serialise(dat:var OutputtedData, n:PNode) =
  if n.id in dat.refNodes:
    return

  dat.refNodes[ReferenceKey(n.id)] = NoCyclicTNode(
    id:n.id,
    typeRefId:n.typ.uniqueId.item,
    info:n.info,

  )

proc serialise(dat:var OutputtedData, s:PSym) = discard


proc serialise*(s:Stream, graph:ModuleGraph, mlist:ModuleList) =
  var outputtedData = OutputtedData(
    refIdents: initTable[ReferenceKey,NoCyclicTIdent](),
    refLibs: initTable[ReferenceKey,NoCyclicTLib](),
    refTypes: initTable[ReferenceKey,NoCyclicTType](),
    refNodes: initTable[ReferenceKey,NoCyclicTNode](),
    refSyms: initTable[ReferenceKey,NoCyclicTSym]()
  )

  for m in mlist.modules.items:
    if m == nil:
      continue

    let nimfile = AbsoluteFile toFullPath(graph.config, m.sym.position.FileIndex)
    echo "Serialising ", nimfile

    for n in m.nodes.items:
      if n == nil:
        continue

      serialise(outputtedData, n)