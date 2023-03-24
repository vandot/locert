when defined linux:
  import std/[os, osproc]
else:
  import std/[os, osproc]
  import std/strutils

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
  var ca = joinPath(dir, "locertCA.pem")
  when defined linux:
    echo "installing CA and generating certificate, please provide sudo password when asked"
    var addTrustedCert = "sudo update-ca-certificates"
    if dirExists("/etc/pki/ca-trust/source/anchors"):
      copyFile(ca, "/etc/pki/ca-trust/source/anchors/locertCA.pem")
      addTrustedCert = "sudo update-ca-trust extract"
    elif dirExists("/usr/local/share/ca-certificates"):
      copyFile(ca, "/usr/local/share/ca-certificates/locertCA.crt")
    elif dirExists("/etc/ca-certificates/trust-source/anchors"):
      copyFile(ca, "/etc/ca-certificates/trust-source/anchors/locertCA.crt")
      addTrustedCert = "sudo trust extract-compat"
    elif dirExists("/usr/share/pki/trust/anchors"):
      copyFile(ca, "/usr/share/pki/trust/anchors/locertCA.pem")
  when defined macosx:
    echo "installing CA and generating certificate, please provide sudo password and login to keychain when asked"
    var addTrustedCert = "sudo security add-trusted-cert -d -k /Library/Keychains/System.keychain \"$#\"" % [ca]
  when defined windows:
    echo "installing CA and generating certificate"
    var addTrustedCert = "Import-Certificate -FilePath \"$#\" -CertStoreLocation Cert:\\LocalMachine\\Root" % [ca]
  removeDir("locert-tmp")
  var result = execCmdEx(addTrustedCert)
  if result.exitCode != 0:
    echo addTrustedCert & " failed with code " & $result.exitCode & " and message " & result.output
    quit()
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
      removeFile("/etc/pki/ca-trust/source/anchors/locertCA.pem")
      removeTrustedCert = "sudo update-ca-trust extract"
    elif dirExists("/usr/local/share/ca-certificates"):
      removeFile("/usr/local/share/ca-certificates/locertCA.crt")
    elif dirExists("/etc/ca-certificates/trust-source/anchors"):
      removeFile("/etc/ca-certificates/trust-source/anchors/locertCA.crt")
      removeTrustedCert = "sudo trust extract-compat"
    elif dirExists("/usr/share/pki/trust/anchors"):
      removeFile("/usr/share/pki/trust/anchors/locertCA.pem")
  when defined macosx:
    echo "uninstalling and removing CA, please provide sudo password and login to keychain when asked"
    var removeTrustedCert = "sudo security delete-certificate -t -c locert"
  when defined windows:
    echo "uninstalling and removing CA"
    var removeTrustedCert = "Get-ChildItem Cert:\\LocalMachine\\Root | Where-Object {$_.Subject -match \"locert\"} | Remove-Item"
  var result = execCmdEx(removeTrustedCert)
  if result.exitCode != 0:
    echo removeTrustedCert & " failed with code " & $result.exitCode & " and message " & result.output
    quit()
  removeFile(certs[0])
  removeFile(certs[1])
  echo "locert.crt and locert.key deleted"
  removeDir(dir)
  echo "CA removed from trusted roots and locertCA.pem deleted"
