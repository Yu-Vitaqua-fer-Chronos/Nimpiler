import std/[
  strutils,
  strformat,
  options
]

import ./typedefinitions
import ./instructions

const SPACE = " "

# TODO: Add class verification (in terms of access modifier checking and such)
proc `$`*(c: Class): string =
  result &= ".class {c.accessModifiers.join(SPACE)} {c.name}\n".fmt
  result &= ".super {c.super}\n".fmt

  for i in c.implements:
    result &= ".implements {i}\n".fmt

  for field in c.fields:
    result &= ".field {field.accessModifiers.join(SPACE)} {field.name} {field.typ}".fmt
    if field.value.isSome():
      result &= " = {field.value.get()}".fmt
    result &= "\n"

  for mthd in c.methods:
    var indentCounter = 1
    template indent() = result &= repeat("  ", indentCounter)
    result &= ".method {mthd.accessModifiers.join(SPACE)} {mthd.name}({mthd.arguments.join(SPACE)})V\n".fmt

    indent()
    result &= ".limit stack {mthd.stackCounter}\n".fmt

    indent()
    result &= ".limit locals {mthd.localsCounter}\n\n".fmt

    if mthd.throws.len != 0:
      for exception in mthd.throws:
        indent()
        result &= ".throws {exception}\n".fmt

      result &= "\n"

    for snippet in mthd.body:
      indentCounter += snippet.indent
      indent()
      result &= snippet.code.replace("!!CurrentJavaClass!!", fmt"L{c.name};") & "\n"

    result &= ".end method\n\n"

template construct*(c: Class): string = $c