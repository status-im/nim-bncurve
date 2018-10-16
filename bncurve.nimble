packageName   = "bncurve"
version       = "1.0.1"
author        = "Status Research & Development GmbH"
description   = "Barreto-Naehrig pairing-friendly elliptic curve implementation"
license       = "Apache License 2.0 or MIT"
skipDirs      = @["tests", "Nim", "nim"]

### Dependencies

requires "nim > 0.18.0"
requires "https://github.com/cheatfate/nimcrypto"

task test, "Run all tests":
  exec "nim c -f -r -d:release tests/tarith"
  exec "nim c -f -r -d:release tests/tfields"
  exec "nim c -f -r -d:release tests/tgroups"
  exec "nim c -f -r -d:release tests/tpairing"
  exec "nim c -f -r -d:release tests/tether"
  exec "nim c -f -r -d:release tests/tvectors"
