import compiler/[ast, modulegraphs, idents, lineinfos, ropes, options]

import std/[streams, tables]

import msgpack4nim


type
  ReferenceKey = distinct int

  Module* = ref object of TPassContext
    sym*: PSym
    nodes*: seq[PNode]

  ModuleList* = ref object of RootObj
    modules*: seq[Module]

  NoRefTLib = object
    kind*: TLibKind
    generated*: bool
    isOverriden*: bool
    name*: Rope
    path*: ReferenceKey  # Should reference a PNode

  NoRefTType = object
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

  NoRefTNode = object
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
        sons*: seq[NoRefTNode]

  NoRefTSym = object
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
    typ*: PType
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

  ItemidToLibRef = Table[int,NoRefTLib]
  ItemIdToTypeRef = Table[int,NoRefTType]
  ItemIdToNodeRef = Table[int,NoRefTNode]
  ItemIdToSymRef = Table[int,NoRefTSym]

  OutputtedData = object
    refLibs*:seq[ItemIdToLibRef]
    refTypes*:seq[ItemIdToTypeRef]
    refNodes*:seq[ItemIdToNodeRef]
    refSyms*:seq[ItemIdToSymRef]


proc serialise*(s:Stream, graph:ModuleGraph, mlist:ModuleList) = discard