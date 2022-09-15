when not defined(nimcore):
  {.error: "`nimcore` must be defined as we use Nim compiler libraries!".}

import
  compiler/ast/[
    idents
  ],
  compiler/front/[
    msgs, cmdlinehelper, options, commands, cli_reporter
  ],
  compiler/modules/[
    modulegraphs, modules
  ],
  compiler/sem/[
    passes, passaux, sem
  ],
  compiler/utils/[
    pathutils
  ],
  std/[
    os
  ]

import src/typedefinitions
import src/backends/collect
import src/backends/jvm/jasmin

proc mainCommand(graph: ModuleGraph) =
  # the order in which the passes are registered dictates in which order
  # they're invoked.

  # register the semantic passes:
  registerPass graph, verbosePass # <- not strictly necessary - only used for logging
  registerPass graph, semPass

  # register the collection pass, this will collect alive code only! Thank you Zerbina!
  registerPass graph, collectPass

  # setup the object in which all processed modules are collected:
  let mlist = ModuleListRef()
  graph.backend = mlist


  # run the compilation. The pass callbacks are invoked from there:
  compileProject(graph)

  let conf = graph.config

  generateCode(graph)



proc hardcodeJava(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  processCmdLine(pass, cmd, config)

  # Hardcode java backend for now
  if config.commandArgs.len == 0: config.commandArgs = @[config.command]
  config.command = "java"
  config.commandLine = config.command & config.commandLine
  config.projectName = config.commandArgs[0]
  config.projectFull = config.projectName.AbsoluteFile
  config.projectPath = AbsoluteDir getCurrentDir()


proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: hardcodeJava # <- the callback used for processing the command line
  )
  # Unconditionally enable some ``define``s:
  self.initDefinesProg(conf, "nimpiler")
  self.initDefinesProg(conf, "jvm")

  # Use the Nimskull path cloned locally
  conf.libpath = (getAppDir() / "modules" / "nimskull" / "lib").toAbsoluteDir

  # write out usage information and quit if no arguments are provided
  if paramCount() == 0:
    writeCommandLineUsage(conf)
    return

  # parse and process the given arguments into the `conf`
  self.processCmdLineAndProjectPath(conf)

  # create a new ``ModuleGraph``. A ``ModuleGraph`` is the root data structure
  # of the compiler - everything needed for the each compilation stage is
  # reachable/accessible from there
  var graph = newModuleGraph(cache, conf)

  # detect and process all relevant config files (including NimScript ones)
  # and reprocess the command line
  if not self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    return

  mainCommand(graph)


var conf = newConfigRef(cli_reporter.reportHook)
block:
  # setup the write hooks. These hooks are invoked when the compiler wants to
  # output something - error or warning messages for example
  conf.writeHook =
    proc(conf: ConfigRef, msg: string, flags: MsgFlags) =
      # write to stdout or stderr depending on configuration
      msgs.msgWrite(conf, msg, flags)

  conf.writelnHook =
    proc(conf: ConfigRef, msg: string, flags: MsgFlags) =
      conf.writeHook(conf, msg & "\n", flags)

handleCmdLine(newIdentCache(), conf)

msgQuit(int8(conf.errorCounter > 0))