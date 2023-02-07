import std/[os, osproc, strutils]
# Internal imports
import cert

proc getCAPath(): (string) =
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

proc moveCA(ca: string) =
    if not dirExists(ca):
      createDir(ca)
    moveFile(joinPath("locert-tmp", "locertCA.pem"), joinPath(ca, "locertCA.pem"))

proc installCA*(domain: string) =
    var ca = getCAPath()
    createDir("locert-tmp")
    genCA()
    genCSR(domain)
    genCRT(domain)
    moveCA(ca)
    when defined linux:
        if dirExists("/etc/pki/ca-trust/source/anchors"):
            copyFile(joinPath(ca, "locertCA.pem"), "/etc/pki/ca-trust/source/anchors/locertCA.pem")
            var addTrustedCert = "sudo update-ca-trust extract"
        elseif dirExists("/usr/local/share/ca-certificates"):
            copyFile(joinPath(ca, "locertCA.pem"), "/usr/local/share/ca-certificates/locertCA.crt")
            var addTrustedCert = "sudo update-ca-certificates"
        elseif pathExists("/etc/ca-certificates/trust-source/anchors"):
            copyFile(joinPath(ca, "locertCA.pem"), "/etc/ca-certificates/trust-source/anchors/locertCA.crt")
            var addTrustedCert = "sudo trust extract-compat"
        elseif pathExists("/usr/share/pki/trust/anchors"):
            copyFile(joinPath(ca, "locertCA.pem"), "/usr/share/pki/trust/anchors/locertCA.pem")
            var addTrustedCert = "sudo update-ca-certificates"
    when defined macosx:
        var addTrustedCert = "sudo security add-trusted-cert -d -k /Library/Keychains/System.keychain \"$#\"" % [joinPath(ca, "locertCA.pem")]
    when defined windows:
        var addTrustedCert = "Import-Certificate -FilePath \"$#\" -CertStoreLocation Cert:\\LocalMachine\\Root" % [joinPath(ca, "locertCA.pem")]
    removeDir("locert-tmp")
    var result = execCmdEx(addTrustedCert)
    if result.exitCode != 0:
        echo addTrustedCert & " failed with code " & $result.exitCode & " and message " & result.output
        quit()

proc uninstallCA*() =
    var ca = getCAPath()
    ca = joinPath(ca, "locertCA.pem")
    when defined linux:
        if dirExists("/etc/pki/ca-trust/source/anchors"):
            removeFile("/etc/pki/ca-trust/source/anchors/locertCA.pem")
            var addTrustedCert = "sudo update-ca-trust extract"
        elseif dirExists("/usr/local/share/ca-certificates"):
            removeFile("/usr/local/share/ca-certificates/locertCA.crt")
            var addTrustedCert = "sudo update-ca-certificates"
        elseif pathExists("/etc/ca-certificates/trust-source/anchors"):
            removeFile("/etc/ca-certificates/trust-source/anchors/locertCA.crt")
            var addTrustedCert = "sudo trust extract-compat"
        elseif pathExists("/usr/share/pki/trust/anchors"):
            removeFile("/usr/share/pki/trust/anchors/locertCA.pem")
            var addTrustedCert = "sudo update-ca-certificates"
    when defined macosx:
        var removeTrustedCert = "sudo security delete-certificate -t -c locert"
    when defined windows:
        var removeTrustedCert = "Get-ChildItem Cert:\\LocalMachine\\Root | Where-Object {$_.Subject -match \"locert\"} | Remove-Item"
    var result = execCmdEx(removeTrustedCert)
    if result.exitCode != 0:
        echo removeTrustedCert & " failed with code " & $result.exitCode & " and message " & result.output
        quit()
    removeFile(ca)
