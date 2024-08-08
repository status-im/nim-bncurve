# Nim Barreto-Naehrig pairing-friendly elliptic curve implementation
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.
import options, endians
import nimcrypto/[utils, sysrand]
export options

# TODO replace private stint operations with an integer primitive library
when sizeof(int) == 4:
  import stint/private/primitives/compiletime_fallback

  # TODO a future intops library should expose this on 32-bit platforms too!
  func addC*(cOut: var Carry, sum: var uint64, a, b: uint64, cIn: Carry) {.inline.} =
    addC_nim(cOut, sum, a, b, cIn)
  func subB*(bOut: var Borrow, diff: var uint64, a, b: uint64, bIn: Borrow) {.inline.} =
    subB_nim(bOuit, diff, a, b, bIn)
  proc muladd2(hi, lo: var uint64, a, b, c1, c2: uint64) =
    muladd2_nim(hi, lo, a, b, c1, c2)

else:
  import stint/private/primitives/[addcarry_subborrow, extended_precision]

import stint/private/datatypes

type
  BNU256* = array[4, uint64]
  BNU512* = array[8, uint64]

proc setRandom*(a: var BNU512) {.inline.} =
  ## Set value of integer ``a`` to random value.
  let ret = randomBytes(a)
  doAssert(ret == 8)

proc random*(t: typedesc[BNU512]): BNU512 {.inline, noinit.} =
  ## Return random 512bit integer.
  setRandom(result)

proc setZero*(a: var BNU256) {.inline.} =
  ## Set value of integer ``a`` to zero.
  a[0] = 0'u64
  a[1] = 0'u64
  a[2] = 0'u64
  a[3] = 0'u64

proc setOne*(a: var BNU256) {.inline.} =
  ## Set value of integer ``a`` to one.
  a[0] = 1'u64
  a[1] = 0'u64
  a[2] = 0'u64
  a[3] = 0'u64

proc zero*(t: typedesc[BNU256]): BNU256 {.inline.} =
  ## Return zero 256bit integer.
  discard

proc one*(t: typedesc[BNU256]): BNU256 {.inline, noinit.} =
  ## Return one 256bit integer.
  setOne(result)

proc isZero*(a: BNU256): bool {.inline, noinit.} =
  ## Check if integer ``a`` is zero.
  (a[0] == 0'u64) and (a[1] == 0'u64) and (a[2] == 0'u64) and (a[3] == 0'u64)

proc setBit*(a: var openArray[uint64], n: int,
             to: bool): bool {.inline, noinit.} =
  ## Set bit of integer ``a`` at position ``n`` to value ``to``.
  if n >= 256:
    return
  let part = n shr 6
  let index = n and 63
  let value = uint64(to)
  a[part] = a[part] and not(1'u64 shl index) or (value shl index)
  result = true

proc getBit*(a: openArray[uint64], n: int): bool {.inline, noinit.} =
  ## Get value of bit at position ``n`` in integer ``a``.
  let part = n shr 6
  let bit = n - (part shl 6)
  result = ((a[part] and (1'u64 shl bit)) != 0)

proc div2(a: var BNU256) {.inline.} =
  ## Divide integer ``a`` in place by ``2``.
  var t = a[3] shl 63
  a[3] = a[3] shr 1
  let b = a[2] shl 63
  a[2] = a[2] shr 1
  a[2] = a[2] or t
  t = a[1] shl 63
  a[1] = a[1] shr 1
  a[1] = a[1] or b
  a[0] = a[0] shr 1
  a[0] = a[0] or t

proc mul2(a: var BNU256) {.inline.} =
  ## Multiply integer ``a`` in place by ``2``.
  var last = 0'u64
  for i in a.mitems():
    let tmp = i shr 63
    i = i shl 1
    i = i or last
    last = tmp

proc addNoCarry(a: var BNU256, b: BNU256) {.inline.} =
  ## Calculate integer addition ``a = a + b``.
  var carry: Carry
  staticFor i, 0, 4:
    addC(carry, a[i], a[i], b[i], carry)

proc subNoBorrow(a: var BNU256, b: BNU256) {.inline.} =
  ## Calculate integer substraction ``a = a - b``.
  var borrow: Borrow
  staticFor i, 0, 4:
    subB(borrow, a[i], a[i], b[i], borrow)

proc macDigit[N, N2: static int](
    acc: var array[N, uint64], pos: static int, b: array[N2, uint64], c: uint64) =
  if c == 0'u64:
    return

  var carry = 0'u64

  staticFor i, pos, N:
    when (i - pos) < len(b):
      muladd2(carry, acc[i], b[i-pos], c, acc[i], carry)
    else:
      muladd2(carry, acc[i], 0, c, acc[i], carry)

proc mulReduce(a: var BNU256, by: BNU256, modulus: BNU256, inv: uint64) =
  var res: array[4 * 2, uint64]
  staticFor i, 0, 4:
    macDigit(res, i, by, a[i])

  staticFor i, 0, 4:
    let k = inv * res[i]
    macDigit(res, i, modulus, k)

  staticFor i, 0, 4:
    a[i] = res[i + 4]

proc compare*(a: BNU256, b: BNU256): int {.noinit, inline.}=
  ## Compare integers ``a`` and ``b``.
  ## Returns ``-1`` if ``a < b``, ``1`` if ``a > b``, ``0`` if ``a == b``.
  for i in countdown(3, 0):
    if a[i] < b[i]:
      return -1
    elif a[i] > b[i]:
      return 1
  return 0

proc `<`*(a: BNU256, b: BNU256): bool {.noinit, inline.} =
  ## Return true if `a < b`.
  result = (compare(a, b) == -1)

proc `<=`*(a: BNU256, b: BNU256): bool {.noinit, inline.} =
  ## Return true if `a <= b`.
  result = (compare(a, b) <= 0)

proc `==`*(a: BNU256, b: BNU256): bool {.noinit, inline.} =
  ## Return true if `a == b`.
  result = (compare(a, b) == 0)

proc mul*(a: var BNU256, b: BNU256, modulo: BNU256,
          inv: uint64) {.inline.} =
  ## Multiply integer ``a`` by ``b`` (mod ``modulo``) via the Montgomery
  ## multiplication method.
  mulReduce(a, b, modulo, inv)
  if a >= modulo:
    subNoBorrow(a, modulo)

proc add*(a: var BNU256, b: BNU256, modulo: BNU256) {.inline.} =
  ## Add integer ``b`` from integer ``a`` (mod ``modulo``).
  addNoCarry(a, b)
  if a >= modulo:
    subNoBorrow(a, modulo)

proc sub*(a: var BNU256, b: BNU256, modulo: BNU256) {.inline.} =
  ## Subtract integer ``b`` from integer ``a`` (mod ``modulo``).
  if a < b:
    addNoCarry(a, modulo)
  subNoBorrow(a, b)

proc neg*(a: var BNU256, modulo: BNU256) {.inline.} =
  ## Turn integer ``a`` into its additive inverse (mod ``modulo``).
  if a > BNU256.zero():
    var tmp = modulo
    subNoBorrow(tmp, a)
    a = tmp

proc isEven*(a: BNU256): bool {.inline, noinit.} =
  ## Check if ``a`` is even.
  ((a[0] and 1'u64) == 0'u64)

proc divrem*(a: BNU512, modulo: BNU256, reminder: var BNU256): Option[BNU256] =
  ## Divides integer ``a`` by ``modulo``, set ``remainder`` to reminder and, if
  ## possible, return quotient smaller than the modulus.
  var q = BNU256.zero()
  reminder.setZero()
  result = some[BNU256](q)
  for i in countdown(511, 0):
    mul2(reminder)
    let ret = reminder.setBit(0, a.getBit(i))
    doAssert ret
    if reminder >= modulo:
      subNoBorrow(reminder, modulo)
      if result.isSome():
        if not q.setBit(i, true):
          result = none[BNU256]()
        else:
          result = some[BNU256](q)

  if result.isSome() and result.get() >= modulo:
    result = none[BNU256]()

proc into*(t: typedesc[BNU512], c1: BNU256,
           c0: BNU256, modulo: BNU256): BNU512 =
  ## Return 512bit integer of value ``c1 * modulo + c0``.
  macDigit(result, 0, modulo, c1[0])
  macDigit(result, 1, modulo, c1[1])
  macDigit(result, 2, modulo, c1[2])
  macDigit(result, 3, modulo, c1[3])
  var carry: Carry
  staticFor i, 0, len(result):
    when len(c0) > i:
      addC(carry, result[i], result[i], c0[i], carry)
    else:
      addC(carry, result[i], result[i], 0'u64, carry)

  doAssert(carry == 0)

proc fromBytes*(dst: var BNU256, src: openArray[byte]): bool =
  ## Create 256bit integer from big-endian bytes representation ``src``.
  ## Returns ``true`` if ``dst`` was successfully initialized, ``false``
  ## otherwise.
  var buffer: array[32, byte]
  if len(src) == 0:
    return false
  let length = if len(src) > 32: 32 else: len(src)
  copyMem(addr buffer[0], unsafeAddr src[0], length)
  bigEndian64(addr dst[0], addr buffer[3 * sizeof(uint64)])
  bigEndian64(addr dst[1], addr buffer[2 * sizeof(uint64)])
  bigEndian64(addr dst[2], addr buffer[1 * sizeof(uint64)])
  bigEndian64(addr dst[3], addr buffer[0 * sizeof(uint64)])
  result = true

proc fromBytes*(dst: var BNU512, src: openArray[byte]): bool =
  ## Create 512bit integer form big-endian bytes representation ``src``.
  ## Returns ``true`` if ``dst`` was successfully initialized, ``false``
  ## otherwise.
  var buffer: array[64, byte]
  if len(src) == 0:
    return false
  let length = if len(src) > 64: 64 else: len(src)
  copyMem(addr buffer[0], unsafeAddr src[0], length)
  bigEndian64(addr dst[0], addr buffer[7 * sizeof(uint64)])
  bigEndian64(addr dst[1], addr buffer[6 * sizeof(uint64)])
  bigEndian64(addr dst[2], addr buffer[5 * sizeof(uint64)])
  bigEndian64(addr dst[3], addr buffer[4 * sizeof(uint64)])
  bigEndian64(addr dst[4], addr buffer[3 * sizeof(uint64)])
  bigEndian64(addr dst[5], addr buffer[2 * sizeof(uint64)])
  bigEndian64(addr dst[6], addr buffer[1 * sizeof(uint64)])
  bigEndian64(addr dst[7], addr buffer[0 * sizeof(uint64)])
  result = true

proc fromHexString*(dst: var BNU256, src: string): bool {.inline, noinit.} =
  ## Create 256bit integer from big-endian hexadecimal string
  ## representation ``src``.
  ## Returns ``true`` if ``dst`` was successfully initialized, ``false``
  ## otherwise.
  result = dst.fromBytes(fromHex(src))

proc toBytes*(src: BNU256, dst: var openArray[byte]): bool {.noinit.} =
  ## Convert 256bit integer ``src`` to big-endian bytes representation.
  ## Return ``true`` if ``dst`` was successfully set, ``false`` otherwise.
  if len(dst) < 4 * sizeof(uint64):
    return false
  bigEndian64(addr dst[0 * sizeof(uint64)], unsafeAddr src[3])
  bigEndian64(addr dst[1 * sizeof(uint64)], unsafeAddr src[2])
  bigEndian64(addr dst[2 * sizeof(uint64)], unsafeAddr src[1])
  bigEndian64(addr dst[3 * sizeof(uint64)], unsafeAddr src[0])
  result = true

proc toBytes*(src: BNU512, dst: var openArray[byte]): bool {.noinit.} =
  ## Convert 512bit integer ``src`` to big-endian bytes representation.
  ## Return ``true`` if ``dst`` was successfully set, ``false`` otherwise.
  if len(dst) < 8 * sizeof(uint64):
    return false
  bigEndian64(addr dst[0 * sizeof(uint64)], unsafeAddr src[7])
  bigEndian64(addr dst[1 * sizeof(uint64)], unsafeAddr src[6])
  bigEndian64(addr dst[2 * sizeof(uint64)], unsafeAddr src[5])
  bigEndian64(addr dst[3 * sizeof(uint64)], unsafeAddr src[4])
  bigEndian64(addr dst[4 * sizeof(uint64)], unsafeAddr src[3])
  bigEndian64(addr dst[5 * sizeof(uint64)], unsafeAddr src[2])
  bigEndian64(addr dst[6 * sizeof(uint64)], unsafeAddr src[1])
  bigEndian64(addr dst[7 * sizeof(uint64)], unsafeAddr src[0])
  result = true

proc toString*(src: BNU256, lowercase = true): string =
  ## Convert 256bit integer ``src`` to big-endian hexadecimal representation.
  var a: array[4 * sizeof(uint64), byte]
  discard src.toBytes(a)
  result = a.toHex(lowercase)

proc toString*(src: BNU512, lowercase = true): string =
  ## Convert 512bit integer ``src`` to big-endian hexadecimal representation.
  var a: array[8 * sizeof(uint64), byte]
  discard src.toBytes(a)
  result = a.toHex(lowercase)

proc `$`*(src: BNU256): string =
  ## Return hexadecimal string representation of integer ``src``.
  result = toString(src, false)

proc `$`*(src: BNU512): string =
  ## Return hexadecimal string representation of integer ``src``.
  result = toString(src, false)

proc setRandom*(a: var BNU256, modulo: BNU256) {.noinit, inline.} =
  ## Set value of integer ``a`` to random value (mod ``modulo``).
  var r = BNU512.random()
  discard divrem(r, modulo, a)

proc random*(t: typedesc[BNU256], modulo: BNU256): BNU256 {.noinit, inline.} =
  ## Return random 256bit integer (mod ``modulo``).
  result.setRandom(modulo)

proc invert*(a: var BNU256, modulo: BNU256) =
  ## Turn integer ``a`` into its multiplicative inverse (mod ``modulo``).
  var u = a
  var v = modulo
  var b = BNU256.one()
  var c = BNU256.zero()

  while u != BNU256.one() and v != BNU256.one():
    while u.isEven():
      u.div2()
      if b.isEven():
        b.div2()
      else:
        b.addNoCarry(modulo)
        b.div2()
    while v.isEven():
      v.div2()
      if c.isEven():
        c.div2()
      else:
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
