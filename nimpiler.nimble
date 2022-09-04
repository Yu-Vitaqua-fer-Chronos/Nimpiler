# Package

version       = "0.1.0"
author        = "Mythical Forest Collective"
description   = "Nimpiler is a project made to convert Nim code/syntax to other programming languages such as Java!"
license       = "MIT"
srcDir        = "src"
bin           = @["nimpiler"]


# Dependencies

requires "nim >= 1.6.6"
requires "codegenlib >= 1.1.9"