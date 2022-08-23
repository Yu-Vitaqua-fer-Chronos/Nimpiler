when not defined(nimcore):
  {.error: "Nim2JSON must be built with `-d:nimcore` because we use Nim's compiler libraries!".}

import jsoncompilerlogic

import parseopt, os

import
  compiler/[options, sem, idents, passes,
  passaux, modules, modulegraphs, msgs,
  commands, lineinfos, cmdlinehelper, pathutils]

proc semanticPasses(g: ModuleGraph) =
  registerPass g, verbosePass
  registerPass g, semPass

proc jsonBackend(graph: ModuleGraph) =
  let conf = graph.config
  conf.setErrorMaxHighMaybe
  semanticPasses(graph)  # use an empty backend to validate the Nim code
  compileProject(graph)

  jsonifyProject(graph)

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0

  config.commandLine.setLen 0
    # bugfix: otherwise, config.commandLine ends up duplicated

  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      config.commandLine.add " "
      config.commandLine.addCmdPrefix p.kind
      config.commandLine.add p.key.quoteShell # quoteShell to be future proof
      if p.val.len > 0:
        config.commandLine.add ':'
        config.commandLine.add p.val.quoteShell

      if p.key == "": # `-` was passed to indicate main project is stdin
        p.key = "-"
        if processArgument(pass, p, argsCount, config): break
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      config.commandLine.add " "
      config.commandLine.add p.key.quoteShell
      if processArgument(pass, p, argsCount, config): break
  if pass == passCmd2:
    if config.arguments.len > 0:
      rawMessage(config, errGenerated, errArgsNeedRunOption)

  if config.commandArgs.len == 0: config.commandArgs = @[config.command]
  config.command = "empty"
  config.commandLine = config.command & config.commandLine
  config.projectName = config.commandArgs[0]
  config.projectFull = config.projectName.AbsoluteFile
  config.projectPath = AbsoluteDir getCurrentDir()

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "nim_to_json")
  if paramCount() == 0:
    quit "You need to pass a file!", 1

  self.processCmdLineAndProjectPath(conf)
  var graph = newModuleGraph(cache, conf)
  if not self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    return

  jsonBackend(graph)


let conf = newConfigRef()
handleCmdLine(newIdentCache(), conf)
msgQuit(int8(conf.errorCounter > 0))