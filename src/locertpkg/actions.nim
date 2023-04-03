when defined windows:
  import std/osproc
else:
  import pkg/sudo
import std/[os,strutils]
# Internal imports
import cert

proc getCertPath(): (string) =
  var dir = getEnv("HOME")
  if dir == "":
    return ""
  dir = joinPath(dir, ".local", "share")
  when defined macosx:
    dir = getHomeDir()
    dir = joinPath(dir, "Library", "Application Support")
  when defined windows:
    dir = getEnv("LocalAppData")
  if getEnv("XDG_DATA_HOME") != "":
    dir = getEnv("XDG_DATA_HOME")
  return joinPath(dir, "locert")

proc getCert*(moveCert: bool): (string, string) =
  if moveCert:
    var dir = getCertPath()
    if dirExists(dir):
      return (joinPath(dir, "locert.crt"), joinPath(dir, "locert.key"))
  return ("locert.crt", "locert.key")

proc moveCA(dir: string) =
  if not dirExists(dir):
    createDir(dir)
  moveFile(joinPath("locert-tmp", "locertCA.pem"), joinPath(dir,
          "locertCA.pem"))

proc moveCert(dir: string) =
  if not dirExists(dir):
    createDir(dir)
  moveFile("locert.crt", joinPath(dir, "locert.crt"))
  moveFile("locert.key", joinPath(dir, "locert.key"))

proc installCA*(domain: string, moveCert: bool) =
  var dir = getCertPath()
  createDir("locert-tmp")
  genCA()
  genCSR(domain)
  genCRT(domain)
  if moveCert:
    moveCert(dir)
  moveCA(dir)
  removeDir("locert-tmp")
  var ca = joinPath(dir, "locertCA.pem")
  when defined linux:
    echo "installing CA and generating certificate, please provide sudo password when asked"
    var addTrustedCert = "update-ca-certificates"
    if dirExists("/etc/pki/ca-trust/source/anchors"):
      var result = sudoCmdEx("cp " & ca & " /etc/pki/ca-trust/source/anchors/locertCA.pem")
      if result.exitCode != 0:
        echo "copying CA to /etc/pki/ca-trust/source/anchors failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
      addTrustedCert = "update-ca-trust extract"
    elif dirExists("/usr/local/share/ca-certificates"):
      var result = sudoCmdEx("cp " & ca & " /usr/local/share/ca-certificates/locertCA.crt")
      if result.exitCode != 0:
        echo "copying CA to /usr/local/share/ca-certificates failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
    elif dirExists("/etc/ca-certificates/trust-source/anchors"):
      var result = sudoCmdEx("cp " & ca & " /etc/ca-certificates/trust-source/anchors/locertCA.crt")
      if result.exitCode != 0:
        echo "copying CA to /etc/ca-certificates/trust-source/anchors failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
      addTrustedCert = "trust extract-compat"
    elif dirExists("/usr/share/pki/trust/anchors"):
      var result = sudoCmdEx("cp " & ca & " /usr/share/pki/trust/anchors/locertCA.pem")
      if result.exitCode != 0:
        echo "copying CA to /etc/ca-certificates/trust/anchors failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
  when defined macosx:
    echo "installing CA and generating certificate, please provide sudo password and login to keychain when asked"
    var addTrustedCert = "security add-trusted-cert -d -k /Library/Keychains/System.keychain \"$#\"" % [ca]
  when defined windows:
    echo "installing CA and generating certificate"
    var addTrustedCert = "Import-Certificate -FilePath \"$#\" -CertStoreLocation Cert:\\LocalMachine\\Root" % [ca]
    var result = execCmdEx(addTrustedCert)
  else:
    var result = sudoCmdEx(addTrustedCert)
  if result.exitCode != 0:
    echo addTrustedCert & " failed with code " & $result.exitCode &
        " and message " & result.output
    quit(1)
  echo "CA added as trusted root and certificate generated"
  echo "certificate is located at " & getCert(moveCert)[0]
  echo "key is located at " & getCert(moveCert)[1]

proc uninstallCA*(moveCert: bool) =
  var dir = getCertPath()
  var certs = getCert(moveCert)
  when defined linux:
    echo "uninstalling and removing CA, please provide sudo password when asked"
    var removeTrustedCert = "sudo update-ca-certificates"
    if dirExists("/etc/pki/ca-trust/source/anchors"):
      var result = sudoCmdEx("rm -f /etc/pki/ca-trust/source/anchors/locertCA.pem")
      if result.exitCode != 0:
        echo "removing CA /etc/pki/ca-trust/source/anchors/locertCA.pem failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
      removeTrustedCert = "sudo update-ca-trust extract"
    elif dirExists("/usr/local/share/ca-certificates"):
      var result = sudoCmdEx("rm -f /usr/local/share/ca-certificates/locertCA.crt")
      if result.exitCode != 0:
        echo "removing CA /usr/local/share/ca-certificates/locertCA.crt failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
    elif dirExists("/etc/ca-certificates/trust-source/anchors"):
      var result = sudoCmdEx("rm -f /etc/ca-certificates/trust-source/anchors/locertCA.crt")
      if result.exitCode != 0:
        echo "removing CA /etc/ca-certificates/trust-source/anchors/locertCA.crt failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
      removeTrustedCert = "sudo trust extract-compat"
    elif dirExists("/usr/share/pki/trust/anchors"):
      var result = sudoCmdEx("rm -f /usr/share/pki/trust/anchors/locertCA.pem")
      if result.exitCode != 0:
        echo "removing CA /etc/ca-certificates/trust/anchors/locertCA.pem failed with code " &
            $result.exitCode & " and message " & result.output
        quit(1)
  when defined macosx:
    echo "uninstalling and removing CA, please provide sudo password and login to keychain when asked"
    var removeTrustedCert = "security delete-certificate -t -c locert"
  when defined windows:
    echo "uninstalling and removing CA"
    var removeTrustedCert = "Get-ChildItem Cert:\\LocalMachine\\Root | Where-Object {$_.Subject -match \"locert\"} | Remove-Item"
    var result = execCmdEx(removeTrustedCert)
  else:
    var result = sudoCmdEx(removeTrustedCert)
  if result.exitCode != 0:
    echo removeTrustedCert & " failed with code " & $result.exitCode &
        " and message " & result.output
    quit(1)
  removeFile(certs[0])
  removeFile(certs[1])
  echo "locert.crt and locert.key deleted"
  removeDir(dir)
  echo "CA removed from trusted roots and locertCA.pem deleted"
