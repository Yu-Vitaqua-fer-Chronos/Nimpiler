import std/[
  options,
  strutils
]

import ../../../typedefinitions as gentypes

# TODO: Make access modifier enums

type
  # TODO: Add a way to automatically generate indentation
  # TODO: Predefine snippets for easy use and to aid with the above
  Snippet* = ref object
    code*: string  # The line of code as a string
    indent*: int   # The amount of times to indent the instruction

  Method* = object
    accessModifiers*: seq[string] # public, private, protected, static, final, synchronized, native, abstract
    name*: string                 # constructors are `<init>`
    arguments*: seq[string]       # Types, such as `[Ljava/lang/String;` for a string array ## ]
    throws*: seq[string]          # Not necessary but recommended for good Java interop
    body*: seq[Snippet]           # The same as `statements`, `return`s aren't implicit in Jasmin
    variables*: seq[string]       # Kept here so we can turn names into integers for accessing variables
    stackCounter*: int            # Counts how many items should be on the stack, this is just an internal counter

  Field* = object
    accessModifiers*: seq[string] # public, private, protected, static, final, volatile, transient
    name*: string                 # Name of the field
    typ*: string                  # Descriptor is the same as type
    value*: Option[string]        # Value, value is optional

  Class* = object
    accessModifiers*: seq[string] # public, final, super, interface, abstract
    name*: string                 # The name of the class
    super*: string                # The base class, by default this should be `java/lang/Object`
    implements*: seq[string]      # Unless we're interacting with JVM code, this should be empty
    methods*: seq[Method]         # All methods in the class body
    fields*: seq[Field]           # All fields in the class body


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
    result &= ".method " & mthd.accessModifiers.join(" ") & " " & mthd.name & "(" & mthd.arguments.join(" ")
    result &= ")V\n"

    result &= "  .limit stack " & $mthd.stackCounter & "\n\n"

    if mthd.throws.len != 0:
      for exception in mthd.throws:
        result &= "  .throws " & exception & "\n"

      result &= "\n"

    for snippet in mthd.body:
      result &= repeat("  ", snippet.indent) & snippet.code & "\n"

    result &= ".end method\n\n"

template construct*(c: Class): string = $c


type JasminCtx* = object of GenCtx
  ccls*: Class         # So we know the current class
  cmthds*: seq[Method] # Seq of all the methods in the sequence

  depth*: int # Only so we know if the code should be in the main method or not

# Allow easy access to the first value of the methods
template cmthd*(ctx: JasminCtx): Method = ctx.cmthds[0]
# Add the method to the queue
template queueMthd*(ctx: JasminCtx, mthd: Method) = ctx.cmthds.insert(mthd)

# Easy 'finalisation' of a method
template delMthd*(ctx: JasminCtx) =
  ctx.ccls.methods.add ctx.cmthds[0]
  ctx.cmthds.del(0)