when not defined(nimcore):
  {.error: "`nimcore` must be defined as we use Nim compiler libraries!".}

when defined(isCyo) or defined(isNimskull):
  import
    compiler/ast/[
      ast_idgen, reports, idents
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
      json, os
    ]
else:
  import
    compiler/[
      ast, idents, lineinfos, modulepaths
    ],
    compiler/[
      msgs, cmdlinehelper, options, commands
    ],
    compiler/[
      modulegraphs, modules
    ],
    compiler/[
      passes, passaux, sem
    ],
    compiler/[
      pathutils
    ],
    std/[
      json, os, parseopt
    ]

type
  Module = ref object of TPassContext
    sym: PSym
    nodes: seq[PNode]

  ModuleList = ref object of RootObj
    modules: seq[Module]

proc myOpen(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  ## Called when a new module starts parsing/processing. Note that multiple
  ## modules can start processing before one of them is closed. `s` is the
  ## symbol of the module.

  # create a context object for the module. Each further processing of the
  # module in question will get this object passed to it
  result = Module(sym: s)

  # register the module in the list
  ModuleList(graph.backend).modules.add Module(result)

proc myProcess(b: PPassContext, n: PNode): PNode =
  ## Called when a top-level statement or declaration is parsed. `n` is the
  ## input node. Each pass' input is the output of the previous pass.
  ## In case of the first pass (usually semantic ananlysis) this input is the
  ## parser output.

  # we're the last processing step and we're also only collecting - just
  # return the input
  result = n

  # append the node to the module
  Module(b).nodes.add(n)

proc myClose(graph: ModuleGraph; b: PPassContext, n: PNode): PNode =
  ## Called when a module has finished parsing and processing

  # process the final node
  result = myProcess(b, n)

# wrap the procedures into a ``TPass`` object that we can then register
const collectPass = makePass(myOpen, myProcess, myClose)

proc mainCommand(graph: ModuleGraph) =
  # the order in which the passes are registered dictates in which order
  # they're invoked.

  # register the semantic passes:
  registerPass graph, verbosePass # <- not strictly necessary - only used for logging
  registerPass graph, semPass

  registerPass graph, collectPass # register the collection pass

  # setup the object in which all processed modules are collected:
  let mlist = ModuleList()
  graph.backend = mlist

  # run the compilation. The pass callbacks are invoked from there:
  compileProject(graph)

  let conf = graph.config

  # we now have access to each semantically analysed statement and declaration
  # for each processed module. Do note that the AST is in the raw semantically
  # analysed form - it is not transformed (see ``transf``) nor was it
  # processed by ``injectdestructors`` (so no ARC/ORC)
  for m in mlist.modules.items:
    # create a file for writing the JSON data to. The file is located in the nimcache directory
    let nimfile = AbsoluteFile toFullPath(conf, m.sym.position.FileIndex)

    when defined(isCyo) or defined(isNimskull):
      let modulePath = withPackageName(conf, nimfile)
    else:
      let modulePath = mangleModuleName(conf, nimfile).AbsoluteFile

    let f = open(changeFileExt(completeGeneratedFilePath(conf, modulePath, true), "json").string, fmWrite)

    echo ""
    for n in m.nodes.items: # AST serialisation stuff!
      if n == nil:
        continue

      echo "A"

    f.close()


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
    processCmdLine: processCmdLine # <- the callback used for processing the command line
  )
  # unconditionally enable some ``define``s:
  self.initDefinesProg(conf, "nim2json")

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

when defined(isCyo) or defined(isNimskull):
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
else:
  var conf = newConfigRef()

handleCmdLine(newIdentCache(), conf)

msgQuit(int8(conf.errorCounter > 0))