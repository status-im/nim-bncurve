import unittest
import ../bncurve/arith

when isMainModule:
  let modulo = [
    0x3c208c16d87cfd47'u64, 0x97816a916871ca8d'u64,
    0xb85045b68181585d'u64, 0x30644e72e131a029'u64
  ]

  suite "Modular arithmetic test suite":
    test "[256] Serialize/Deserialize tests":
      for i in 0..<100:
        var c0, c1, c2: BNU256
        var c0b: array[4 * sizeof(uint64), byte]
        c0 = BNU256.random(modulo)
        var c0s = c0.toString()
        check:
          c0.toBytes(c0b) == true
          c1.fromBytes(c0b) == true
          c2.fromHexString(c0s) == true
          c0 == c1
          c0 == c2

    test "[512] Serialize/Deserialize tests":
      for i in 0..<100:
        var cb: BNU512
        var cbs: array[8 * sizeof(uint64), byte]
        var e0 = BNU256.random(modulo)
        var e1 = BNU256.random(modulo)
        var bb12 = BNU512.into(e1, e0, modulo)
        check:
          bb12.toBytes(cbs) == true
          cb.fromBytes(cbs) == true
        var c0: BNU256
        var c1opt = cb.divrem(modulo, c0)
        check:
          isSome(c1opt) == true
          c1opt.get() == e1
          c0 == e0

    test "Setting bits":
      var moduloS = [
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64,
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64
      ]
      var a = BNU256.random(moduloS)
      var e = BNU256.zero()
      for i, b in a.pairs():
        let ret = e.setBit(255 - i, b)
        doAssert ret
      check e == a

    test "fromValue & divrem on random numbers":
      for i in 0..<100:
        var nc0: BNU256
        var nc1: Option[BNU256]
        var c0 = BNU256.random(modulo)
        var c1 = BNU256.random(modulo)
        var c1q = BNU512.into(c1, c0, modulo)
        nc1 = c1q.divrem(modulo, nc0)
        check:
          nc1.get() == c1
          nc0 == c0

    test "Modulus should become 1*q + 0":
      var a = [
        0x3c208c16d87cfd47'u64, 0x97816a916871ca8d'u64,
        0xb85045b68181585d'u64, 0x30644e72e131a029'u64,
        0'u64, 0'u64, 0'u64, 0'u64
      ]

      var c0, c2: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      c2 = c1.get()
      check:
        c2 == BNU256.one()
        c0 == BNU256.zero()
        c2 == BNU256.one()
        c0 == BNU256.zero()

    test "Modulus squared minus 1 should be (q-1) q + q-1":
      let a = [
        0x3b5458a2275d69b0'u64, 0xa602072d09eac101'u64,
        0x4a50189c6d96cadc'u64, 0x04689e957a1242c8'u64,
        0x26edfa5c34c6b38d'u64, 0xb00b855116375606'u64,
        0x599a6f7c0348d21c'u64, 0x0925c4b8763cbf9c'u64
      ]
      let expect = [
        0x3c208c16d87cfd46'u64, 0x97816a916871ca8d'u64,
        0xb85045b68181585d'u64, 0x30644e72e131a029'u64
      ]
      var c0, c2: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      c2 = c1.get()
      check:
        c0 == expect
        c2 == expect

    test "Modulus squared minus 2 should be (q-1) q + q-2":
      let a = [
        0x3b5458a2275d69af'u64, 0xa602072d09eac101'u64,
        0x4a50189c6d96cadc'u64, 0x04689e957a1242c8'u64,
        0x26edfa5c34c6b38d'u64, 0xb00b855116375606'u64,
        0x599a6f7c0348d21c'u64, 0x0925c4b8763cbf9c'u64
      ]
      let expectc1 = [
        0x3c208c16d87cfd46'u64, 0x97816a916871ca8d'u64,
        0xb85045b68181585d'u64, 0x30644e72e131a029'u64
      ]
      let expectc0 = [
        0x3c208c16d87cfd45'u64, 0x97816a916871ca8d'u64,
        0xb85045b68181585d'u64, 0x30644e72e131a029'u64
      ]
      var c0, c2: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      c2 = c1.get()
      check:
        c0 == expectc0
        c2 == expectc1

    test "Ridiculously large number should fail":
      let a = [
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64,
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64,
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64,
        0xfffffffffffffffff'u64, 0xfffffffffffffffff'u64
      ]
      let expectc0 = [
        0xf32cfc5b538afa88'u64, 0xb5e71911d44501fb'u64,
        0x47ab1eff0a417ff6'u64, 0x06d89f71cab8351f'u64
      ]
      var c0: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      check:
        c1.isNone() == true
        c0 == expectc0

    test "Modulus squared should fail":
      let a = [
        0x3b5458a2275d69b1'u64, 0xa602072d09eac101'u64,
        0x4a50189c6d96cadc'u64, 0x04689e957a1242c8'u64,
        0x26edfa5c34c6b38d'u64, 0xb00b855116375606'u64,
        0x599a6f7c0348d21c'u64, 0x0925c4b8763cbf9c'u64
      ]
      var c0: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      check:
        c1.isNone() == true
        c0.isZero() == true

    test "Modulus squared plus one should fail":
      let a = [
        0x3b5458a2275d69b2'u64, 0xa602072d09eac101'u64,
        0x4a50189c6d96cadc'u64, 0x04689e957a1242c8'u64,
        0x26edfa5c34c6b38d'u64, 0xb00b855116375606'u64,
        0x599a6f7c0348d21c'u64, 0x0925c4b8763cbf9c'u64
      ]
      var c0: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(modulo, c0)
      check:
        c1.isNone() == true
        c0 == BNU256.one()

    test "Fr modulus masked off is valid":
      let a = [
        0xffffffffffffffff'u64, 0xffffffffffffffff'u64,
        0xffffffffffffffff'u64, 0xffffffffffffffff'u64,
        0xffffffffffffffff'u64, 0xffffffffffffffff'u64,
        0xffffffffffffffff'u64, 0x07ffffffffffffff'u64
      ]
      let moduloFr = [
        0x43e1f593f0000001'u64, 0x2833e84879b97091'u64,
        0xb85045b68181585d'u64, 0x30644e72e131a029'u64
      ]
      var c0, c2: BNU256
      var c1: Option[BNU256]
      c1 = a.divrem(moduloFr, c0)
      check:
        c1.get() < moduloFr
        c0 < moduloFr
