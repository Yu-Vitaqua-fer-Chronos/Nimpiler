import compiler/ast/[ast_query, reports]
import ./typedefinitions

import std/[intsets, sets]


func collect*[T](c: var Collected[T], item: T): bool =
  ## Returns whether or not the `item` was already collected
  mixin id
  if c.marker.containsOrIncl(item.id):
    return true

  c.data.add item
  result = false

func scan*(n: PNode, data: var Data)
func scan*(t: PType, data: var Data)
func scan*(s: PSym, data: var Data)

func scan*(t: PType, data: var Data) =
  if collect(data.types, t):
    return

  if t.sym != nil:
    scan(t.sym, data)

  for it in t.sons:
    if it != nil:
      scan(it, data)

  if t.kind in {tyObject, tyTuple} and t.n != nil: 
    scan(t.n, data)

func scan*(s: PSym, data: var Data) =
  if collect(data.syms, s):
    return

  if s.typ != nil:
    scan(s.typ, data)

  case s.kind
  of skConst:
    # scan the constant's data
    scan(astdef(s), data)
  of routineKinds:
    # XXX: ``modulegraphs.getBody`` should be used instead, but a
    #      ``ModuleGraph`` is required here then
    if bodyPos < s.ast.len:
      scan(s.ast[bodyPos], data)

  else:
    discard

func scan*(n: PNode, data: var Data) =
  if n == nil:
    return

  if n.typ != nil:
    scan(n.typ, data)

  case n.kind
  of nkSym:
    scan(n.sym, data)
  elif n.safeLen > 0:
    for it in n:
      scan(it, data)