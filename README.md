# locert
locert is a simple cert generator for local development.

It's a heavilly opiniated certificate generator.

It is designed to generate and install CA and certificate for `dev.lo` and `*.dev.lo`.

It relies on `openssl` to be installed on the system and exposed in the PATH.

In combination with [lodns](https://github.com/vandot/lodns) provides easy setup for testing application with https enabled.

*Note: current implementaion doesn't work with Firefox and Java, implementation planned in the future.*

## Installation
Download correct binary from the latest [release](https://github.com/vandot/locert/releases) and place it somewhere in the PATH.

Or `nimble install https://github.com/vandot/locert`

## Configuration
locert comes preconfigured for all supported platforms.

## Install
On MacOS and Linux it will ask for `sudo` password
```
locert install
```
On Windows inside elevated Powershell
```
locert.exe install
```
And restart browser.

Certificate and key will be generated inside current directory.

## Uninstallation
On MacOS and Linux run 
```
locert uninstall
```
On Windows run inside elevated command prompt or Powershell
```
lodns.exe uninstall
```
and remove the binary.

## License

BSD 3-Clause License
