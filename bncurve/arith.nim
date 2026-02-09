# Nim Barreto-Naehrig pairing-friendly elliptic curve implementation
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises: [], gcsafe, inline.}

import std/options, stew/[staticfor, endians2], nimcrypto/utils, intops/ops/[add, sub, muladd]

# random numbers are not supported on bare metal
when not defined(`any`) and not defined(standalone):
  import nimcrypto/sysrand

export options

type
  BNU256* = array[4, uint64]
  BNU512* = array[8, uint64]

# random numbers are not supported on bare metal
when not defined(`any`) and not defined(standalone):

  proc setRandom*(a: var BNU512) =
    ## Set value of integer ``a`` to random value.
    let ret = randomBytes(a)
    doAssert(ret == 8)

  proc random*(t: typedesc[BNU512]): BNU512 {.noinit.} =
    ## Return random 512bit integer.
    setRandom(result)

func setZero*(a: var BNU256) =
  ## Set value of integer ``a`` to zero.
  a[0] = 0'u64
  a[1] = 0'u64
  a[2] = 0'u64
  a[3] = 0'u64

func setOne*(a: var BNU256) =
  ## Set value of integer ``a`` to one.
  a[0] = 1'u64
  a[1] = 0'u64
  a[2] = 0'u64
  a[3] = 0'u64

func zero*(t: typedesc[BNU256]): BNU256 =
  ## Return zero 256bit integer.
  discard

func one*(t: typedesc[BNU256]): BNU256 {.noinit.} =
  ## Return one 256bit integer.
  setOne(result)

func isZero*(a: BNU256): bool =
  ## Check if integer ``a`` is zero.
  (a[0] == 0'u64) and (a[1] == 0'u64) and (a[2] == 0'u64) and (a[3] == 0'u64)

func setBit*[N: static int](a: var array[N, uint64], n: int, to: bool): bool =
  ## Set bit of integer ``a`` at position ``n`` to value ``to``.
  if n >= 256:
    false
  else:
    let part = n shr 6
    let index = n and 63
    let value = uint64(to)
    a[part] = a[part] and not (1'u64 shl index) or (value shl index)
    true

func getBit*[N: static int](a: array[N, uint64], n: int): bool =
  ## Get value of bit at position ``n`` in integer ``a``.
  let part = n shr 6
  let bit = n - (part shl 6)
  ((a[part] and (1'u64 shl bit)) != 0)

func div2(a: var BNU256) =
  ## Divide integer ``a`` in place by ``2``.
  a[0] = a[0] shr 1 or a[1] shl 63
  a[1] = a[1] shr 1 or a[2] shl 63
  a[2] = a[2] shr 1 or a[3] shl 63
  a[3] = a[3] shr 1

func mul2(a: var BNU256) =
  ## Multiply integer ``a`` in place by ``2``.
  var carry: bool
  staticFor i, 0 ..< 4:
    (a[i], carry) = carryingAdd(a[i], a[i], carry)

func addNoCarry(a: var BNU256, b: BNU256) =
  ## Calculate integer addition ``a = a + b``.
  var carry: bool
  staticFor i, 0 ..< 4:
    (a[i], carry) = carryingAdd(a[i], b[i], carry)

func subNoBorrow(a: var BNU256, b: BNU256) =
  ## Calculate integer substraction ``a = a - b``.
  var borrow: bool
  staticFor i, 0 ..< 4:
    (a[i], borrow) = borrowingSub(a[i], b[i], borrow)

func macDigit(acc: var array[8, uint64], pos: static int, b: BNU256, c: uint64) =
  if c == 0'u64:
    return

  var carry = 0'u64

  staticFor i, pos ..< acc.len:
    when (i - pos) < len(b):
      (carry, acc[i]) = wideningMulAdd(b[i - pos], c, acc[i], carry)
    else:
      (carry, acc[i]) = wideningMulAdd(0'u64, c, acc[i], carry)

func macDigit(acc: var array[8, uint64], pos: static int, b: static BNU256, c: uint64) =
  if c == 0'u64:
    return

  var carry = 0'u64

  staticFor i, pos ..< acc.len:
    when (i - pos) < len(b):
      (carry, acc[i]) = wideningMulAdd(b[i - pos], c, acc[i], carry)
    else:
      (carry, acc[i]) = wideningMulAdd(0'u64, c, acc[i], carry)

func mulReduce(a: var BNU256, by: BNU256, modulo: static BNU256, inv: static uint64) =
  var res {.align: 32.}: array[8, uint64]
  staticFor i, 0 ..< 4:
    macDigit(res, i, by, a[i])

  staticFor i, 0 ..< 4:
    let k = inv * res[i]
    macDigit(res, i, modulo, k)

  staticFor i, 0 ..< 4:
    a[i] = res[i + 4]

func compare*(a: BNU256, b: BNU256): int =
  ## Compare integers ``a`` and ``b``.
  ## Returns ``-1`` if ``a < b``, ``1`` if ``a > b``, ``0`` if ``a == b``.
  staticFor j, 0 ..< 4:
    const i = 3 - j
    if a[i] < b[i]:
      return -1
    elif a[i] > b[i]:
      return 1
  return 0

func `<`*(a: BNU256, b: BNU256): bool =
  ## Return true if `a < b`.
  staticFor j, 0 ..< 4:
    const i = 3 - j
    if a[i] < b[i]:
      return true
    elif a[i] > b[i]:
      return false
  return false

func `<=`*(a: BNU256, b: BNU256): bool =
  ## Return true if `a <= b`.
  staticFor j, 0 ..< 4:
    const i = 3 - j
    if a[i] < b[i]:
      return true
    elif a[i] > b[i]:
      return false
  return true

func `==`*(a, b: BNU256): bool =
  ## Return true if `a == b`.
  var res = 0'u64
  staticFor i, 0 ..< 4:
    res = res or (a[i] xor b[i])
  res == 0

func mul*(a: var BNU256, b: BNU256, modulo: static BNU256, inv: static uint64) =
  ## Multiply integer ``a`` by ``b`` (mod ``modulo``) via the Montgomery
  ## multiplication method.
  mulReduce(a, b, modulo, inv)
  if a >= modulo:
    subNoBorrow(a, modulo)

func mul2*(a: var BNU256, modulo: static BNU256) =
  ## Compute `a * 2 mod modulo`
  mul2(a)
  if a >= modulo:
    subNoBorrow(a, modulo)

func add*(a: var BNU256, b: BNU256, modulo: static BNU256) =
  ## Add integer ``b`` from integer ``a`` (mod ``modulo``).
  addNoCarry(a, b)
  if a >= modulo:
    subNoBorrow(a, modulo)

func sub*(a: var BNU256, b: BNU256, modulo: static BNU256) =
  ## Subtract integer ``b`` from integer ``a`` (mod ``modulo``).
  if a < b:
    addNoCarry(a, modulo)
  subNoBorrow(a, b)

func neg*(a: var BNU256, modulo: static BNU256) =
  ## Turn integer ``a`` into its additive inverse (mod ``modulo``).
  if a > BNU256.zero():
    var tmp = modulo
    subNoBorrow(tmp, a)
    a = tmp

func isEven*(a: BNU256): bool =
  ## Check if ``a`` is even.
  ((a[0] and 1'u64) == 0'u64)

func divrem*(
    a: BNU512, modulo: static BNU256, reminder: var BNU256
): Option[BNU256] {.noinit.} =
  ## Divides integer ``a`` by ``modulo``, set ``remainder`` to reminder and, if
  ## possible, return quotient smaller than the modulus.
  var q {.align: 32.} = BNU256.zero()
  reminder.setZero()
  var ok = true
  for i in countdown(511, 0):
    mul2(reminder)
    let ret = reminder.setBit(0, a.getBit(i))
    doAssert ret
    if reminder >= modulo:
      subNoBorrow(reminder, modulo)
      if ok and not q.setBit(i, true):
        ok = false

  if not ok or q >= modulo:
    none[BNU256]()
  else:
    some(q)

func into*(t: typedesc[BNU512], c1: BNU256, c0: BNU256, modulo: BNU256): BNU512 =
  ## Return 512bit integer of value ``c1 * modulo + c0``.

  staticFor i, 0 ..< 4:
    macDigit(result, i, modulo, c1[i])

  var carry: bool
  staticFor i, 0 ..< len(result):
    when len(c0) > i:
      (result[i], carry) = carryingAdd(result[i], c0[i], carry)
    else:
      (result[i], carry) = carryingAdd(result[i], 0'u64, carry)

  doAssert(not carry)

func fromBytesBE*(dst: var (BNU256 | BNU512), src: openArray[byte]): bool =
  ## Create 256bit integer from big-endian bytes representation ``src``.
  ## Returns ``true`` if ``dst`` was successfully initialized, ``false``
  ## otherwise.
  if len(src) < 32:
    return false

  staticFor i, 0 ..< dst.len:
    const pos = (dst.len - i - 1) * sizeof(uint64)
    dst[i] = uint64.fromBytesBE(src.toOpenArray(pos, pos + sizeof(uint64) - 1))

  true

func fromBytes*(
    dst: var (BNU256 | BNU512), src: openArray[byte]
): bool {.deprecated: "fromBytesBE".} =
  fromBytesBE(dst, src)

func fromHexString*(dst: var BNU256, src: string): bool =
  ## Create 256bit integer from big-endian hexadecimal string
  ## representation ``src``.
  ## Returns ``true`` if ``dst`` was successfully initialized, ``false``
  ## otherwise.
  dst.fromBytesBE(fromHex(src))

template copyBytes(tgt, src, tstart, sstart, n: untyped) =
  when nimvm:
    for i in 0 ..< n:
      tgt[tstart + i] = src[sstart + i]
  else:
    moveMem(addr tgt[tstart], unsafeAddr src[sstart], n)

func toBytesBE*(src: BNU256 | BNU512, dst: var openArray[byte]): bool =
  ## Convert 256bit integer ``src`` to big-endian bytes representation.
  ## Return ``true`` if ``dst`` was successfully set, ``false`` otherwise.
  if len(dst) < src.len * sizeof(uint64):
    return false

  staticFor i, 0 ..< src.len:
    const pos = (src.len - i - 1) * sizeof(uint64)
    let limb = src[i].toBytesBE()
    copyBytes(dst, limb, pos, 0, sizeof(uint64))

  true

func toBytesBE*(src: BNU256): array[32, byte] {.noinit.} =
  ## Convert 256bit integer ``src`` to big-endian bytes representation.
  ## Return ``true`` if ``dst`` was successfully set, ``false`` otherwise.

  discard toBytesBE(src, result)

func toBytesBE*(src: BNU512): array[64, byte] {.noinit.} =
  ## Convert 256bit integer ``src`` to big-endian bytes representation.
  ## Return ``true`` if ``dst`` was successfully set, ``false`` otherwise.

  discard toBytesBE(src, result)

func toBytes*(
    src: BNU256 | BNU512, dst: var openArray[byte]
): bool {.deprecated: "toBytesBE".} =
  toBytesBE(src, dst)

func toString*(src: BNU256, lowercase = true): string =
  ## Convert 256bit integer ``src`` to big-endian hexadecimal representation.
  var a: array[32, byte]
  discard src.toBytesBE(a)
  a.toHex(lowercase)

func toString*(src: BNU512, lowercase = true): string =
  ## Convert 256bit integer ``src`` to big-endian hexadecimal representation.
  var a: array[64, byte]
  discard src.toBytesBE(a)
  a.toHex(lowercase)

func `$`*(src: BNU256 | BNU512): string =
  ## Return hexadecimal string representation of integer ``src``.
  toString(src, false)

# random numbers are not supported on bare metal
when not defined(`any`) and not defined(standalone):

  proc setRandom*(a: var BNU256, modulo: static BNU256) =
    ## Set value of integer ``a`` to random value (mod ``modulo``).
    var r = BNU512.random()
    discard divrem(r, modulo, a)

  proc random*(t: typedesc[BNU256], modulo: static BNU256): BNU256 {.noinit.} =
    ## Return random 256bit integer (mod ``modulo``).
    result.setRandom(modulo)

func invert*(a: var BNU256, modulo: static BNU256) =
  ## Turn integer ``a`` into its multiplicative inverse (mod ``modulo``).
  var u {.align: 32.} = a
  var v {.align: 32.} = modulo
  var b {.align: 32.} = BNU256.one()
  var c {.align: 32.} = BNU256.zero()

  while u != BNU256.one() and v != BNU256.one():
    while u.isEven():
      u.div2()
      if not b.isEven():
        b.addNoCarry(modulo)
      b.div2()
    while v.isEven():
      v.div2()
      if not c.isEven():
        c.addNoCarry(modulo)
      c.div2()
    if u >= v:
      u.subNoBorrow(v)
      b.sub(c, modulo)
    else:
      v.subNoBorrow(u)
      c.sub(b, modulo)

  if u == BNU256.one():
    a = b
  else:
    a = c

iterator bits*(a: BNU256): bool =
  ## Iterate over bits of integer ``a``.
  for i in countdown(255, 0):
    yield a.getBit(i)

iterator pairs*(a: BNU256): tuple[key: int, value: bool] =
  ## Iterate over index and bit value of integer ``a``.
  var k = 0
  for i in countdown(255, 0):
    yield (k, a.getBit(i))
    inc(k)
