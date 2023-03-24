import std/[os, parseopt]
# Internal imports
import ./locertpkg/actions

const domain = "dev.lo"

proc writeVersion() =
  const NimblePkgVersion {.strdefine.} = "dev"
  echo getAppFilename().extractFilename(), "-", NimblePkgVersion

proc writeHelp() =
  writeVersion()
  echo """
  Generate SSL cert with dev.lo TLD for
  local development.

  install       : generate and install cert to system
  uninstall     : remove and uninstall cert from system
  -h, --help    : show help
  -v, --version : show version
  """
  quit()

proc main() =
  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      case key
      of "install":
        installCA(domain, false)
      of "uninstall":
        uninstallCA(false)
      else:
        echo "unknown argument: ", key
        writeHelp()
    of cmdLongOption, cmdShortOption:
      case key
      of "v", "version":
        writeVersion()
      of "h", "help":
        writeHelp()
      else:
        echo "unknown option: ", key
        writeHelp()
    of cmdEnd:
      discard

when isMainModule:
  main()
