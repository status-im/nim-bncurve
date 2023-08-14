import arith, group_operations, types
import nimcrypto/sysrand

proc setRandom*(a: var BNU512) {.inline.} =
  ## Set value of integer ``a`` to random value.
  let ret = randomBytes(a)
  doAssert(ret == 8)
proc random*(t: typedesc[BNU512]): BNU512 {.inline, noinit.} =
  ## Return random 512bit integer.
  setRandom(result)
proc setRandom*(a: var BNU256, modulo: BNU256) {.noinit, inline.} =
  ## Set value of integer ``a`` to random value (mod ``modulo``).
  var r = BNU512.random()
  discard divrem(r, modulo, a)
proc random*(t: typedesc[BNU256], modulo: BNU256): BNU256 {.noinit, inline.} =
  ## Return random 256bit integer (mod ``modulo``).
  result.setRandom(modulo)

var fimodulusFQ = [0x3c208c16d87cfd47'u64, 0x97816a916871ca8d'u64, 0xb85045b68181585d'u64, 0x30644e72e131a029'u64]
proc setRandom*(dst: var FQ) {.noinit, inline.} =
  ## Set ``dst`` to random value
  var a = BNU256.random(fimodulusFQ)
  dst = FQ(a)
var fimodulusFR = [0x43e1f593f0000001'u64, 0x2833e84879b97091'u64, 0xb85045b68181585d'u64, 0x30644e72e131a029'u64]
proc setRandom*(dst: var FR) {.noinit, inline.} =
  ## Set ``dst`` to random value
  var a = BNU256.random(fimodulusFR)
  dst = FR(a)
proc random*(t: typedesc[FQ]): FQ {.noinit, inline.} =
  ## Return random ``Fp``.
  result.setRandom()
proc random*(t: typedesc[FR]): FR {.noinit, inline.} =
  ## Return random ``Fp``.
  result.setRandom()

proc random*(t: typedesc[FQ2]): FQ2 {.inline, noinit.} =
  result.c0 = FQ.random()
  result.c1 = FQ.random()

proc random*(t: typedesc[FQ6]): FQ6 {.inline, noinit.} =
  result.c0 = FQ2.random()
  result.c1 = FQ2.random()
  result.c2 = FQ2.random()

proc random*(t: typedesc[FQ12]): FQ12 {.inline, noinit.} =
  result.c0 = FQ6.random()
  result.c1 = FQ6.random()

proc random*[T: G1|G2](t: typedesc[T]): Point[T] {.inline, noinit.} =
  result = t.one() * FR.random()
