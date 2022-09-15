import compiler/ast/ast_types

proc getPackage*(s: PSym): PSym =
  result = s
  while result.kind != skPackage:
    result = result.owner