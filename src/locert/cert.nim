import std/[os, osproc, strutils]

var opensslBin = "openssl"

when defined windows:
  opensslBin = "openssl.exe"

proc genExt(domain: string) = 
    var extText = "authorityKeyIdentifier = keyid,issuer\nbasicConstraints = CA:FALSE\nkeyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\nsubjectAltName = @alt_names\n[alt_names]\nDNS.1 = *.$#\nDNS.2 = $#" % [domain, domain]
    writeFile(joinPath("locert-tmp", "locert.ext"), extText)

proc genCA*() =
    var genCAcmd = "$# req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout $# -out $# -subj \"/C=LO/ST=Dev/L=Local/O=Dev/OU=Local/CN=locert\"" % [opensslBin, joinPath("locert-tmp", "locertCA.key"), joinPath("locert-tmp", "locertCA.pem")]
    var result = execCmdEx(genCAcmd)
    if result.exitCode != 0:
        echo genCAcmd & " failed with code " & $result.exitCode & " and message " & result.output
        quit()

proc genCSR*(domain: string) =
    var genCSRcmd = "$# req -sha256 -nodes -newkey rsa:2048 -keyout locert.key -out $# -subj \"/C=LO/ST=Dev/L=Local/O=Dev/OU=Local/CN=$#\"" % [opensslBin, joinPath("locert-tmp", "locert.csr"), domain]
    var result = execCmdEx(genCSRcmd)
    if result.exitCode != 0:
        echo genCSRcmd & " failed with code " & $result.exitCode & " and message " & result.output
        quit()

proc genCRT*(domain: string) =
    genExt(domain)
    var genCRTcmd = "$# x509 -req -in $# -CA $# -CAkey $# -CAcreateserial -out locert.crt -days 825 -sha256 -extfile $#" % [opensslBin, joinPath("locert-tmp", "locert.csr"), joinPath("locert-tmp", "locertCA.pem"), joinPath("locert-tmp", "locertCA.key"), joinPath("locert-tmp", "locert.ext")]
    var result = execCmdEx(genCRTcmd)
    if result.exitCode != 0:
        echo genCRTcmd & " failed with code: " & $result.exitCode & " and message: " & result.output
        quit()
