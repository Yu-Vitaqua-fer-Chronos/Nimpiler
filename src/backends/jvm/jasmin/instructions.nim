import std/[
  strformat # Using this so it's neater in general
]

import ../../../utils

import ./typedefinitions

# TODO: Rename methods (or make aliases) with better names

type InvalidJVMTypeDefect* = object of Defect

#[ Templates for repetitive use ]#
template increaseLocalsCounter(mthd: var Method, varNum: int) =
  if mthd.localsCounter < varNum:
    mthd.localsCounter = varNum

template singleByteLoadStoreInstruction(mthd: var Method, instr: string, varNum: int) =
  if varNum < 4:
    mthd.body.add Snippet(code: instr & "_" & $varNum)
  else:
    mthd.body.add Snippet(code: instr & " " & $varNum)


#[ Non-instructions, these are 'shortcuts' to groups of instructions or ]#
#[ are convinience methods ]#
proc storeVar*(mthd: var Method, name: string, descriptor: string) =
  mthd.localsCounter += 1
  var varNum = mthd.variables.len
  mthd.variables.add name
  mthd.body.add Snippet(code: fmt".var {varNum} is {name} {descriptor}", indent: 0) # from <label1> to <label2>

# We shouldn't be using this tbh
proc indent(mthd: var Method, increaseIndentBy: int=1) =
  mthd.body.add Snippet(code: "", indent: increaseIndentBy)


#[ Instructions to load constants ]#
# 8 bit integers
proc bipush*(mthd: var Method, integer: BiggestInt) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"bipush {integer}", indent: 0)
# 16 bit integers
proc sipush*(mthd: var Method, integer: BiggestInt) =
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

  mthd.singleByteLoadStoreInstruction("aload", varNum)

  mthd.increaseLocalsCounter(varNum)

proc astore*(mthd: var Method, varNum: int) =
  mthd.singleByteLoadStoreInstruction("astore", varNum)

  mthd.increaseLocalsCounter(varNum)

proc dload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 2

  mthd.singleByteLoadStoreInstruction("dload", varNum)

  mthd.increaseLocalsCounter(varNum)

proc dstore*(mthd: var Method, varNum: int) =
  mthd.singleByteLoadStoreInstruction("dstore", varNum)

  mthd.increaseLocalsCounter(varNum)

proc fload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 1

  mthd.singleByteLoadStoreInstruction("fload", varNum)

  mthd.increaseLocalsCounter(varNum)

proc fstore*(mthd: var Method, varNum: int) =
  mthd.singleByteLoadStoreInstruction("fstore", varNum)

  mthd.increaseLocalsCounter(varNum)

proc iload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 1

  mthd.singleByteLoadStoreInstruction("iload", varNum)

  mthd.increaseLocalsCounter(varNum)

proc istore*(mthd: var Method, varNum: int) =
  mthd.singleByteLoadStoreInstruction("istore", varNum)

  mthd.increaseLocalsCounter(varNum)

proc lload*(mthd: var Method, varNum: int) =
  mthd.stackCounter += 2

  mthd.singleByteLoadStoreInstruction("lload", varNum)

  mthd.increaseLocalsCounter(varNum)

proc lstore*(mthd: var Method, varNum: int) =
  mthd.singleByteLoadStoreInstruction("lstore", varNum)

  mthd.increaseLocalsCounter(varNum)

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
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"anewarray {className}", indent: 0)

proc checkcast*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"checkcast {className}", indent: 0)

# In Nim this is equivalent to `myObject of MyObjectType`
proc instanceof*(mthd: var Method, className: string) =
  mthd.body.add Snippet(code: fmt"instanceof {className}", indent: 0)

proc new*(mthd: var Method, className: string) =
  mthd.stackCounter += 1
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
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"getfield {fieldSpec} {descriptor}", indent: 0)

proc getstatic*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"getstatic {fieldSpec} {descriptor}", indent: 0)

proc putfield*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"putfield {fieldSpec} {descriptor}", indent: 0)

proc putstatic*(mthd: var Method, fieldSpec, descriptor: string) =
  mthd.body.add Snippet(code: fmt"putstatic {fieldSpec} {descriptor}", indent: 0)



#[ Array-related instructions ]#

proc newarray*(mthd: var Method,
  typ: typedesc[int] | typedesc[int8] | typedesc[int16] | typedesc[int32] | typedesc[int64] |
  typedesc[float] | typedesc[float32] | typedesc[float64]) =
  mthd.stackCounter += 1

  var arrayType = ""

  # Note that shorts don't exist on a JVM level
  # Note that we'll have to handle uint math ourselves... Not fun
  if (typ is typedesc[int]) or (typ is typedesc[int8]) or
    (typ is typedesc[int16]):
    arrayType = "short"
  elif typ is typedesc[int32]:
    arrayType = "int"
  elif typ is typedesc[int64]:
    arrayType = "double"
  elif (typ is typedesc[float]) or (typ is typedesc[float32]):
    arrayType = "float"
  elif typ is typedesc[float64]:
    arrayType = "long"
  else:
    raise newException(InvalidJVMTypeDefect, fmt"{typ} isn't a valid JVM type!")

  mthd.body.add Snippet(code: fmt"newarray {arrayType}", indent: 0)

proc multianewarray*(mthd: var Method, arrayDescriptor: string, dimensions: int) =
  mthd.stackCounter += 1
  mthd.body.add Snippet(code: fmt"multianewarray {arrayDescriptor} {dimensions}", indent: 0)


#[ Load constants ]#
proc ldc*(mthd: var Method, constant: int | int8 | int16 | int32 | int64 |
  float | float32 | float64 | string) =
  mthd.stackCounter += 1

  when constant is string:
    mthd.body.add Snippet(code: fmt"ldc {constant.quoted()}")
  else:
    mthd.body.add Snippet(code: fmt"ldc {constant}")

proc ldc_w*(mthd: var Method, constant: int | int8 | int16 | int32 | int64 |
  float | float32 | float64 | string) =
  mthd.stackCounter += 1

  when constant is string:
    mthd.body.add Snippet(code: fmt"ldc_w {constant.quoted()}")
  else:
    mthd.body.add Snippet(code: fmt"ldc_w {constant}")



#[ Unlabelled instructions that don't take any arguments ]#
# TODO: Reorder, label and clean these up
# TODO: Go through these and make sure methods that add to the stack *actually* increase the stack counter
proc aaload*(mthd: var Method) =
  mthd.body.add Snippet(code: "aaload", indent: 0)

proc aastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "aastore", indent: 0)

proc aconst_null*(mthd: var Method) =
  mthd.body.add Snippet(code: "aconst_null", indent: 0)

proc areturn*(mthd: var Method) =
  mthd.body.add Snippet(code: "areturn", indent: 0)

proc arraylength*(mthd: var Method) =
  mthd.body.add Snippet(code: "arraylength", indent: 0)

proc athrow*(mthd: var Method) =
  mthd.body.add Snippet(code: "athrow", indent: 0)

proc baload*(mthd: var Method) =
  mthd.body.add Snippet(code: "baload", indent: 0)

proc bastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "bastore", indent: 0)

proc breakpoint*(mthd: var Method) =
  mthd.body.add Snippet(code: "breakpoint", indent: 0)

proc caload*(mthd: var Method) =
  mthd.body.add Snippet(code: "caload", indent: 0)

proc castore*(mthd: var Method) =
  mthd.body.add Snippet(code: "castore", indent: 0)

proc d2f*(mthd: var Method) =
  mthd.body.add Snippet(code: "d2f", indent: 0)

proc d2i*(mthd: var Method) =
  mthd.body.add Snippet(code: "d2i", indent: 0)

proc d2l*(mthd: var Method) =
  mthd.body.add Snippet(code: "d2l", indent: 0)

proc dadd*(mthd: var Method) =
  mthd.body.add Snippet(code: "dadd", indent: 0)

proc daload*(mthd: var Method) =
  mthd.body.add Snippet(code: "daload", indent: 0)

proc dastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "dastore", indent: 0)

proc dcmpg*(mthd: var Method) =
  mthd.body.add Snippet(code: "dcmpg", indent: 0)

proc dcmpl*(mthd: var Method) =
  mthd.body.add Snippet(code: "dcmpl", indent: 0)

proc dconst_0*(mthd: var Method) =
  mthd.body.add Snippet(code: "dconst_0", indent: 0)

proc dconst_1*(mthd: var Method) =
  mthd.body.add Snippet(code: "dconst_1", indent: 0)

proc ddiv*(mthd: var Method) =
  mthd.body.add Snippet(code: "ddiv", indent: 0)

proc dmul*(mthd: var Method) =
  mthd.body.add Snippet(code: "dmul", indent: 0)

proc dneg*(mthd: var Method) =
  mthd.body.add Snippet(code: "dneg", indent: 0)

proc drem*(mthd: var Method) =
  mthd.body.add Snippet(code: "drem", indent: 0)

proc dreturn*(mthd: var Method) =
  mthd.body.add Snippet(code: "dreturn", indent: 0)

proc dsub*(mthd: var Method) =
  mthd.body.add Snippet(code: "dsub", indent: 0)

proc dup*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup", indent: 0)

proc dup2*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup2", indent: 0)

proc dup2_x1*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup2_x1", indent: 0)

proc dup2_x2*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup2_x2", indent: 0)

proc dup_x1*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup_x1", indent: 0)

proc dup_x2*(mthd: var Method) =
  mthd.body.add Snippet(code: "dup_x2", indent: 0)

proc f2d*(mthd: var Method) =
  mthd.body.add Snippet(code: "f2d", indent: 0)

proc f2i*(mthd: var Method) =
  mthd.body.add Snippet(code: "f2i", indent: 0)

proc f2l*(mthd: var Method) =
  mthd.body.add Snippet(code: "f2l", indent: 0)

proc fadd*(mthd: var Method) =
  mthd.body.add Snippet(code: "fadd", indent: 0)

proc faload*(mthd: var Method) =
  mthd.body.add Snippet(code: "faload", indent: 0)

proc fastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "fastore", indent: 0)

proc fcmpg*(mthd: var Method) =
  mthd.body.add Snippet(code: "fcmpg", indent: 0)

proc fcmpl*(mthd: var Method) =
  mthd.body.add Snippet(code: "fcmpl", indent: 0)

proc fconst_0*(mthd: var Method) =
  mthd.body.add Snippet(code: "fconst_0", indent: 0)

proc fconst_1*(mthd: var Method) =
  mthd.body.add Snippet(code: "fconst_1", indent: 0)

proc fconst_2*(mthd: var Method) =
  mthd.body.add Snippet(code: "fconst_2", indent: 0)

proc fdiv*(mthd: var Method) =
  mthd.body.add Snippet(code: "fdiv", indent: 0)

proc fmul*(mthd: var Method) =
  mthd.body.add Snippet(code: "fmul", indent: 0)

proc fneg*(mthd: var Method) =
  mthd.body.add Snippet(code: "fneg", indent: 0)

proc frem*(mthd: var Method) =
  mthd.body.add Snippet(code: "frem", indent: 0)

proc freturn*(mthd: var Method) =
  mthd.body.add Snippet(code: "freturn", indent: 0)

proc fsub*(mthd: var Method) =
  mthd.body.add Snippet(code: "fsub", indent: 0)

proc i2d*(mthd: var Method) =
  mthd.body.add Snippet(code: "i2d", indent: 0)

proc i2f*(mthd: var Method) =
  mthd.body.add Snippet(code: "i2f", indent: 0)

proc i2l*(mthd: var Method) =
  mthd.body.add Snippet(code: "i2l", indent: 0)

proc iadd*(mthd: var Method) =
  mthd.body.add Snippet(code: "iadd", indent: 0)

proc iaload*(mthd: var Method) =
  mthd.body.add Snippet(code: "iaload", indent: 0)

proc iand*(mthd: var Method) =
  mthd.body.add Snippet(code: "iand", indent: 0)

proc iastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "iastore", indent: 0)

proc iconst_0*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_0", indent: 0)

proc iconst_1*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_1", indent: 0)

proc iconst_2*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_2", indent: 0)

proc iconst_3*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_3", indent: 0)

proc iconst_4*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_4", indent: 0)

proc iconst_5*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_5", indent: 0)

proc iconst_m1*(mthd: var Method) =
  mthd.body.add Snippet(code: "iconst_m1", indent: 0)

proc idiv*(mthd: var Method) =
  mthd.body.add Snippet(code: "idiv", indent: 0)

proc imul*(mthd: var Method) =
  mthd.body.add Snippet(code: "imul", indent: 0)

proc ineg*(mthd: var Method) =
  mthd.body.add Snippet(code: "ineg", indent: 0)

proc int2byte*(mthd: var Method) =
  mthd.body.add Snippet(code: "int2byte", indent: 0)

proc int2char*(mthd: var Method) =
  mthd.body.add Snippet(code: "int2char", indent: 0)

proc int2short*(mthd: var Method) =
  mthd.body.add Snippet(code: "int2short", indent: 0)

proc ior*(mthd: var Method) =
  mthd.body.add Snippet(code: "ior", indent: 0)

proc irem*(mthd: var Method) =
  mthd.body.add Snippet(code: "irem", indent: 0)

proc ireturn*(mthd: var Method) =
  mthd.body.add Snippet(code: "ireturn", indent: 0)

proc ishl*(mthd: var Method) =
  mthd.body.add Snippet(code: "ishl", indent: 0)

proc ishr*(mthd: var Method) =
  mthd.body.add Snippet(code: "ishr", indent: 0)

proc isub*(mthd: var Method) =
  mthd.body.add Snippet(code: "isub", indent: 0)

proc iushr*(mthd: var Method) =
  mthd.body.add Snippet(code: "iushr", indent: 0)

proc ixor*(mthd: var Method) =
  mthd.body.add Snippet(code: "ixor", indent: 0)

proc l2d*(mthd: var Method) =
  mthd.body.add Snippet(code: "l2d", indent: 0)

proc l2f*(mthd: var Method) =
  mthd.body.add Snippet(code: "l2f", indent: 0)

proc l2i*(mthd: var Method) =
  mthd.body.add Snippet(code: "l2i", indent: 0)

proc ladd*(mthd: var Method) =
  mthd.body.add Snippet(code: "ladd", indent: 0)

proc laload*(mthd: var Method) =
  mthd.body.add Snippet(code: "laload", indent: 0)

proc land*(mthd: var Method) =
  mthd.body.add Snippet(code: "land", indent: 0)

proc lastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "lastore", indent: 0)

proc lcmp*(mthd: var Method) =
  mthd.body.add Snippet(code: "lcmp", indent: 0)

proc lconst_0*(mthd: var Method) =
  mthd.body.add Snippet(code: "lconst_0", indent: 0)

proc lconst_1*(mthd: var Method) =
  mthd.body.add Snippet(code: "lconst_1", indent: 0)

proc ldiv*(mthd: var Method) =
  mthd.body.add Snippet(code: "ldiv", indent: 0)

proc lmul*(mthd: var Method) =
  mthd.body.add Snippet(code: "lmul", indent: 0)

proc lneg*(mthd: var Method) =
  mthd.body.add Snippet(code: "lneg", indent: 0)

proc lor*(mthd: var Method) =
  mthd.body.add Snippet(code: "lor", indent: 0)

proc lrem*(mthd: var Method) =
  mthd.body.add Snippet(code: "lrem", indent: 0)

proc lreturn*(mthd: var Method) =
  mthd.body.add Snippet(code: "lreturn", indent: 0)

proc lshl*(mthd: var Method) =
  mthd.body.add Snippet(code: "lshl", indent: 0)

proc lshr*(mthd: var Method) =
  mthd.body.add Snippet(code: "lshr", indent: 0)

proc lsub*(mthd: var Method) =
  mthd.body.add Snippet(code: "lsub", indent: 0)

proc lushr*(mthd: var Method) =
  mthd.body.add Snippet(code: "lushr", indent: 0)

proc lxor*(mthd: var Method) =
  mthd.body.add Snippet(code: "lxor", indent: 0)

proc monitorenter*(mthd: var Method) =
  mthd.body.add Snippet(code: "monitorenter", indent: 0)

proc monitorexit*(mthd: var Method) =
  mthd.body.add Snippet(code: "monitorexit", indent: 0)

proc nop*(mthd: var Method) =
  mthd.body.add Snippet(code: "nop", indent: 0)

proc pop*(mthd: var Method) =
  mthd.body.add Snippet(code: "pop", indent: 0)

proc pop2*(mthd: var Method) =
  mthd.body.add Snippet(code: "pop2", indent: 0)

proc jreturn*(mthd: var Method) = # Prefixed with `j` due to naming conflict
  mthd.body.add Snippet(code: "return", indent: 0)

proc saload*(mthd: var Method) =
  mthd.body.add Snippet(code: "saload", indent: 0)

proc sastore*(mthd: var Method) =
  mthd.body.add Snippet(code: "sastore", indent: 0)

proc swap*(mthd: var Method) =
  mthd.body.add Snippet(code: "swap", indent: 0)