# Nim2IR
This tool converts Nim to an easy to parse format! Currently the goal is MessagePack but if someone adds a way to generate more formats in a simple to intergrate way, I am *more* than happy to include it! Reason why we didn't use JSON as we wanted to, is because the file size that would be generated for some files were *big*, from tests Zerbina did with their own local implementation of Nim2JSON, (Nim2IR's original purpose) which went up to around 780 MB on disk.

## Why?
Because fuck you, kind stranger!

Okay for real, this was made with the goal to make Nim truely portable to many other programming languages, especially Java due to us thinking that the JVM has a severe lack of easy to use languages! sure, Kotlin and Haxe exist, but in our opinion, they don't compare to the beauty we see in Nim!

## Goals
### Language Targets
Current languages we are planning on creating targets for:

 * Lua 5.1
   * 5.1 specifically because ComputerCraft (A minecraft mod) and a few other games use Lua 5.1 for scripting!

 * Python
   * This would be more of a low-priority goal to see how flexible it is

 * Java
   * Now this, THIS is the real beast, the goal of this would be to attempt to make a Java backend for Nim that intergrates decently with other Java libraries, and for using Nim to make a Java library itself.
     * This will definitely be harder than the others, but would be amazing to pull off!
     * This is also likely to be the first/main target to be focused on, as in our opinion, it shouldn't be too hard in some ways? Such as Java having pre-existing function overloading.

Once a target is in a semi-usable state we will cross off the language name!

### QoL Improvements
 * I think providing a way to keep module names included, as well as the version of the compiler/library should be added, as it'd allow backends to implement their own stdlib implementation for it, though ideally anything pure Nim *should* work!
 * "You first traverse all the top-level statements/declaration and collect the symbols and types referenced by them. Then you traverse all types and symbols and collect the symbols and types referenced by them." relating to handling getting all references and stuff

## Notes
This is currently a W.I.P, code is uploaded as a backup for now tbh.

## Acknowledgements
Thanks to Zerbina for providing the stuff we needed to get started! It was more like 98% of the code aha-