# Nimpiler
Nimpiler is a project made to convert Nim code/syntax (unsure if this will have the goal of making anything pure Nim code to another language, especially since concepts between languages change) to another language! Additionally we should eventually have a working serialisation backend!

## Why?
This was made with the goal to make Nim truely portable to many other programming languages, especially Java due to us thinking that the JVM has a severe lack of easy to use languages! sure, Kotlin and Haxe exist, but in our opinion, they don't compare to the beauty we see in Nim!

## Goals
### Language Targets
Current languages we are planning on creating targets for:

 * Lua
   * Lua 5.1 specifically because ComputerCraft (A minecraft mod) and a few other games use Lua 5.1 for scripting (since they don't have gotos)!

 * Python
   * This would be more of a low-priority goal to see how flexible it is

 * JVM
   * Welp we scrapped the Java backend. We're now gonna make a general JVM backend by using `Jasmin`, a 'Java Assembler Interface', which will allow us to make a JVM backend without selling our soul (In theory)!
   * During my time learning stuff, I've also realised that converting Nim semantics to the JVM will be hell... So fun!

Once a target is in a semi-usable state we will cross off the backend name!

### To-Do
Focusing on the JVM backend currently, we NEED to make it so the API for creating instructions and such are *way* better than they are currently.
Right now they're... Usable, but clunky and make us do most of the work. Ideally we wouldn't need to even worry about this.

### QoL Improvements
 * I think providing a way to keep module names included, as well as the version of the compiler/library should be added, as it'd allow backends to implement their own stdlib implementation for it, though ideally anything pure Nim *should* work!
 * "You first traverse all the top-level statements/declaration and collect the symbols and types referenced by them. Then you traverse all types and symbols and collect the symbols and types referenced by them." relating to handling getting all references and stuff

## Notes
WE ARE NOT ENDORSED OR PROMOTED BY JASMIN, THE LICENSE CAN BE FOUND AT `LICENSES/JASMIN.txt`!

This is currently a heavy W.I.P, code is uploaded as a backup for now tbh.

## Acknowledgements
Thanks to Zerbina for providing the stuff we needed to get started! It was more like 98% of the code aha-