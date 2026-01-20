packageName   = "bncurve"
version       = "1.0.1"
author        = "Status Research & Development GmbH"
description   = "Barreto-Naehrig pairing-friendly elliptic curve implementation"
license       = "Apache License 2.0 or MIT"
skipDirs      = @["tests", "Nim", "nim"]

### Dependencies

requires "nim >= 1.6.0",
         "nimcrypto",
         "stew >= 0.2.0",
         "intops >= 1.0.6",
         "unittest2 >= 0.2.3"

task bench, "Run benchmark":
  exec "nim c -f -r -d:release --styleCheck:error --styleCheck:usages --threads:on benchmarks/bench"

task test, "Run all tests":
  exec "nim c -f -r -d:release --styleCheck:error --styleCheck:usages --threads:on tests/all_tests"
