import ./typedefinitions

# Instructions that manipulate local variables
# TODO: Label these so there's an easy to understand reference
proc aload*(varNum: int): Snippet = Snippet(code: "aload " & $varNum, indent: 0)

proc astore*(varNum: int): Snippet = Snippet(code: "astore " & $varNum, indent: 0)

proc dload*(varNum: int): Snippet = Snippet(code: "dload " & $varNum, indent: 0)

proc dstore*(varNum: int): Snippet = Snippet(code: "dstore " & $varNum, indent: 0)

proc fload*(varNum: int): Snippet = Snippet(code: "fload " & $varNum, indent: 0)

proc fstore*(varNum: int): Snippet = Snippet(code: "fstore " & $varNum, indent: 0)

proc iload*(varNum: int): Snippet = Snippet(code: "iload " & $varNum, indent: 0)

proc istore*(varNum: int): Snippet = Snippet(code: "istore " & $varNum, indent: 0)

proc lload*(varNum: int): Snippet = Snippet(code: "lload " & $varNum, indent: 0)

proc lstore*(varNum: int): Snippet = Snippet(code: "lstore " & $varNum, indent: 0)