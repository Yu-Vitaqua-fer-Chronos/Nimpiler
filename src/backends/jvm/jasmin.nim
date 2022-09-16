import
  std/[
    sets, os, strutils, unicode
  ],
  compiler/ast/[
    ast,
    ast_types
  ],
  compiler/sem/[
    passes,
    transf
  ],
  compiler/modules/[
    modulegraphs
  ],
  compiler/front/[
    msgs
  ]

import ../../typedefinitions
import ../../utils

import ./jvmtypes


proc gen(ctx: var GenCtx, n: PNode)  # Forward declaration


proc genProc(ctx: var GenCtx, s: PSym) =
  assert s.kind in routineKinds
  # only generate code for the procedure once
  if not ctx.seensProcs.containsOrIncl(s.itemId):
    let body = transformBody(ctx.graph, ctx.idgen, s, cache = true)
    gen(ctx, body)

proc genMagic(ctx: var GenCtx, m: TMagic, callExpr: PNode): bool =
  ## Returns 'false' if no special handling is used and a default function
  ## call is to be emitted instead
  # implement special handling for calls to magics here...
  case m
  of mAddI:
    discard
  of mEcho:
    echo callExpr.sym.name.s
  else:
    discard

proc genCall(ctx: var GenCtx, n: PNode) =
  # generate code for the callee:
  gen(ctx, n[0])

  # generate code for call:
  # ...

proc gen(ctx: var GenCtx, n: PNode) =
  ## Generate code for the expression or statement `n`
  case n.kind
  of nkSym:
    let s = n.sym

    case s.kind
    of skProc, skFunc, skIterator, skConverter:
      genProc(ctx, s)
    else:
      # handling of other symbol kinds here...
      discard

  of nkCall:
    if n[0].kind == nkSym:
      let s = n[0].sym

      let useNormal = 
        if s.magic != mNone:
          # if ``genMagic`` returns 'false', the procedure is treated as a
          # non-builtin and uses the same code-generator logic as all other
          # procedures 
          not genMagic(ctx, s.magic, n)
        else:
          true

      if useNormal:
        genCall(ctx, n)

    else:
      # indirect call
      genCall(ctx, n)

  else:
    # code-generator logic here...
    discard

proc generateTopLevelStmts(ctx: var GenCtx, m: Module) =
  let
    # for simplicity, merge all statments into a single one
    stmts = newTree(nkStmtList, m.stmts)
    # transform the statement
    transformed = transformStmt(ctx.graph, ctx.idgen, m.sym, stmts)

  # note: ``injectdestructors`` is not run, so destructors and lifetime-hooks
  #       won't work

  gen(ctx, stmts)

proc generateCode*(g: ModuleGraph) =
  ## The backend's entry point
  let
    mlist = g.backend.ModuleListRef
    conf = g.config

  var ctx = GenCtx(graph: g)

  for m in mlist.modules.items:
    if m.sym == nil:
      # ``include``d modules don't reach ``myOpen`` and so don't have
      # a valid list entry -> skip them
      continue

    #[
    if m.sym.owner != nil and m.sym.owner.kind == skPackage and m.sym.owner.name.s == "stdlib":
      # skip modules that are part of the stdlib (this includes ``system``!)
      # only here for development purposes really, ideally this should work with everything!
      continue
    ]#

    var fn = toFilename(g.config, m.sym.position.FileIndex)

    if fn.endsWith(".nim"):
      fn = fn.substr(0, fn.len - 5)

    fn = fn.replace("_", " ").title.replace(" ", "")

    ctx.idgen = m.idgen # use the IdGenerator of the module

    "output".createDir
    generateTopLevelStmts(ctx, m)