import std/[
  strutils,
  options
]

import ./typedefinitions
import ./instructions

# TODO: Add class verification (in terms of access modifier checking and such)
proc `$`*(c: Class): string =
  result &= ".class " & c.accessModifiers.join(" ") & " " & c.name & "\n"
  result &= ".super " & c.super & "\n"

  for i in c.implements:
    result &= ".implements " & i & "\n"

  for field in c.fields:
    result &= ".field " & field.accessModifiers.join(" ") & " " & field.name & " " & field.typ
    if field.value.isSome():
      result &= " = " & field.value.get()
    result &= "\n"

  for mthd in c.methods:
    var indentCounter = 1
    template indent() = result &= repeat("  ", indentCounter)
    result &= ".method " & mthd.accessModifiers.join(" ") & " " & mthd.name & "(" & mthd.arguments.join(" ")
    result &= ")V\n"

    indent()
    result &= ".limit stack " & $mthd.stackCounter & "\n\n"

    if mthd.throws.len != 0:
      for exception in mthd.throws:
        indent()
        result &= ".throws " & exception & "\n"

      result &= "\n"

    for snippet in mthd.body:
      indentCounter += snippet.indent
      indent()
      result &= snippet.code & "\n"

    result &= ".end method\n\n"

template construct*(c: Class): string = $c