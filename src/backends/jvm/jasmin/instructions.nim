import std/[
  strformat # Using this so it's neater in general
]

import ./typedefinitions

# TODO: Rename methods (or make aliases) with better names

type InvalidJVMTypeDefect* = object of Defect

# Primitive types only, we can work on something for other types later
proc storeVar*(mthd: var Method, typ: typedesc[int] | typedesc[string] | typedesc[float]) = 



#[ Instructions to load constants ]#
# 8 bit integers
proc bipush*(mthd: var Method, integer: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"bipush {integer}", indent: 0)
# 16 bit integers
proc sipush*(mthd: var Method, integer: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"sipush {integer}", indent: 0)



#[ Instructions that manipulate local variables ]#
# `a` means `object`
# `d` means `double`
# `f` means `float`
# `i` means `int`
# `l` means `long`

# Doubles and longs take up two spaces on the stack so increment by two there

# Abstract these away, these are *internal* details
proc aload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"aload {varNum}", indent: 0)

proc astore*(mthd: var Method, varNum: int) =
  mthd.body.add Snippet(code: fmt"astore {varNum}", indent: 0)

proc dload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 2
  mthd.body.add Snippet(code: fmt"dload {varNum}", indent: 0)

proc dstore*(mthd: var Method, varNum: int) =
  mthd.body.add Snippet(code: fmt"dstore {varNum}", indent: 0)

proc fload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"fload {varNum}", indent: 0)

proc fstore*(mthd: var Method, varNum: int) =
  mthd.body.add Snippet(code: fmt"fstore {varNum}", indent: 0)

proc iload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"iload {varNum}", indent: 0)

proc istore*(mthd: var Method, varNum: int) =
  mthd.body.add Snippet(code: fmt"istore {varNum}", indent: 0)

proc lload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 2
  mthd.body.add Snippet(code: fmt"lload {varNum}", indent: 0)

proc lstore*(mthd: var Method, varNum: int) =
  mthd.body.add Snippet(code: fmt"lstore {varNum}", indent: 0)

# Note: This is only for constants
proc iinc*(mthd: var Method, varNum: int, amount: int) =
  mthd.body.add Snippet(code: fmt"iinc {varNum}")



#[ Instructions that use labels ]#
proc goto*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"goto {labelName}", indent: 0)

proc goto_w*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"goto_w {labelName}", indent: 0)

proc if_acmpeq*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_acmpeq {labelName}", indent: 0)

proc if_acmpne*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_acmpne {labelName}", indent: 0)

proc if_icmpeq*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmpeq {labelName}", indent: 0)

proc if_icmpge*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmpge {labelName}", indent: 0)

proc if_icmpgt*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmpgt {labelName}", indent: 0)

proc if_icmple*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmple {labelName}", indent: 0)

proc if_icmplt*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmplt {labelName}", indent: 0)

proc if_icmpne*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"if_icmpne {labelName}", indent: 0)

proc ifeq*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifeq {labelName}", indent: 0)

proc ifge*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifge {labelName}", indent: 0)

proc ifgt*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifgt {labelName}", indent: 0)

proc ifle*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifle {labelName}", indent: 0)

proc iflt*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"iflt {labelName}", indent: 0)

proc ifne*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifne {labelName}", indent: 0)

proc ifnonnull*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifnonnull {labelName}", indent: 0)

proc ifnull*(mthd: var Method, labelName: string) =
  mthd.body.add Snippet(code: fmt"ifnull {labelName}", indent: 0)



#[ Class and object manipulation ]#
# Creates a new array of objects
proc anewarray*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"anewarray {className}", indent: 0)

proc checkcast*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"checkcast {className}", indent: 0)

# In Nim this is equivalent to `myObject of MyObjectType`
proc instanceof*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"instanceof {className}", indent: 0)

proc new*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"new {className}", indent: 0)



#[ Method invokation instructions ]#
# In Jasmin, this is called `invokenonvirtual`, there's no difference but it's just an outdated term
# It's used for private methods, constructors and calling `super` methods
proc invokespecial*(mthd: var Method, methodSpec: string) =
  mthd.body.add Snippet(code: fmt"invokenonvirtual {methodSpec}", indent: 0)

proc invokestatic*(mthd: var Method, methodSpec: string) =
  mthd.body.add Snippet(code: fmt"invokestatic {methodSpec}", indent: 0)

proc invokevirtual*(mthd: var Method, methodSpec: string) =
  mthd.body.add Snippet(code: fmt"invokevirtual {methodSpec}", indent: 0)



#[ Field manipulation instructions ]#
proc getfield*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"getfield {fieldSpec} {descriptor}", indent: 0)

proc getstatic*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"getstatic {fieldSpec} {descriptor}", indent: 0)

proc putfield*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"putfield {fieldSpec} {descriptor}", indent: 0)

proc putstatic*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"putstatic {fieldSpec} {descriptor}", indent: 0)



#[ Array-related instructions ]#

proc newarray*(mthd: var Method,
  typ: typedesc[int] | typedesc[int8] | typedesc[int16] | typedesc[int32] | typedesc[int64] |
  typedesc[float] | typedesc[float32] | typedesc[float64]) =
  var arrayType = ""

  # Note that shorts don't exist on a JVM level
  if (typ is typedesc[int]) or (typ is typedesc[int8]) or
    (typ is typedesc[int16]):
    arrayType = "short"
  elif typ is typedesc[int32]:
    arrayType = "int"
  elif typ is typedesc[int64]:
    arrayType = "double"
  elif (typ is typedesc[float]) or (typ is typedesc[float32])
    arrayType = "float"
  elif typ is typedesc[float64]:
    arrayType = "long"
  else:
    raise newException(InvalidJVMTypeDefect, fmt"{typ} isn't a valid JVM type!")

  mthd.body.add Snippet(code: fmt"newarray {arrayType}", indent: 0)

proc multianewarray*()