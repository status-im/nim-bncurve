packageName   = "bncurve"
version       = "1.0.0"
author        = "Status Research & Development GmbH"
description   = "Barreto-Naehrig pairing-friendly elliptic curve implementation"
license       = "Apache License 2.0 or MIT"
skipDirs      = @["tests", "Nim", "nim"]

### Dependencies

requires "nim > 0.18.0"

task test, "Run all tests":
  exec "nim c -r tests/tarith"
  exec "nim c -r -d:release tests/tarith"

  exec "nim c -r tests/tfields"
  exec "nim c -r -d:release tests/tfields"

  exec "nim c -r tests/tgroups"
  exec "nim c -r -d:release tests/tgroups"

  exec "nim c -r tests/tpairing"
  exec "nim c -r -d:release tests/tpairing"

  exec "nim c -r tests/tvectors"
  exec "nim c -r -d:release tests/tvectors"
