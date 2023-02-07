import std/[os, parseopt]
# Internal imports
import ./locert/actions

const domain = "dev.lo"

proc writeVersion() =
  const NimblePkgVersion {.strdefine.} = "dev"
  echo getAppFilename().extractFilename(), "-", NimblePkgVersion

proc writeHelp() =
  writeVersion()
  echo """
  Generate SSL cert with lo TLD for
  local development.

  install       : generate and install cert to system
  uninstall     : remove and uninstall cert from system
  -h, --help    : show help
  -v, --version : show version
  """
  quit()

proc main() =
  var install, uninstall = false

  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      case key
      of "install":
        install = true
      of "uninstall":
        uninstall = true
      else:
        echo "unknown argument: ", key
    of cmdLongOption, cmdShortOption:
      case key
      of "v", "version":
        writeVersion()
        quit()
      of "h", "help":
        writeHelp()
      else:
        echo "unknown option: ", key
    of cmdEnd:
      discard

  if install:
    echo "Install"
    installCA(domain)
    quit()
  if uninstall:
    echo "Uninstall"
    uninstallCA()
  else:
    writeHelp()

when isMainModule:
  main()
