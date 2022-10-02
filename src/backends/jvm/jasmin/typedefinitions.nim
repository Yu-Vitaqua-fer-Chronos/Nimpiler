import std/[
  options,
  strutils,
  strformat
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
    localsCounter*: int           # Keeps count of all the variables used within the code, possibly redundant?
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


proc newMethod*(accessModifiers: seq[string], name: string, arguments: seq[string]=newSeq[string](0)): Method =
  result = Method()
  result.accessModifiers = accessModifiers
  result.name = name
  result.arguments = arguments

  if "static" notin result.accessModifiers:
    result.localsCounter += 1
    result.variables.add name
    result.body.add Snippet(code: fmt".var 0 is JAVATHIS !!CurrentJavaClass!!", indent: 0)


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