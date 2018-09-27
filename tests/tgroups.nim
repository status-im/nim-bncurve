import unittest
import ../bncurve/groups

proc randomAdd*(G: typedesc): bool =
  for i in 0..<10:
    let r1 = G.random()
    let r2 = G.random()
    let r3 = G.random()

    if ((r1 + r2) + r3) != (r1 + (r2 + r3)):
      return false
    let rc = (r1 + r2 + r3) - r2 - r3 - r1
    if not rc.isZero():
      return false
  return true

proc randomMul*(G: typedesc): bool =
  for i in 0..<10:
    let r1 = G.random()
    let r2 = G.random()
    let ti = FR.fromString("2").inverse().get()

    if (r1 + r2) + r1 != (r1.double() + r2):
      return false
    if r1 != r1.double() * ti:
      return false
  return true

proc zeroTest*(G: typedesc): bool =
  if not G.zero().isZero():
    return false
  if not (G.zero() - G.zero()).isZero():
    return false
  if not (G.one() - G.one()).isZero():
    return false
  if (G.one() + G.one()) != (G.one() * FR.fromString("2")):
    return false
  if not G.zero().double().isZero():
    return false
  if not ((G.one() * (-FR.one())) + G.one()).isZero():
    return false
  return true

proc randomDH*(G: typedesc): bool =
  for i in 0..<10:
    let alice_sk = FR.random()
    let bob_sk = FR.random()
    let alice_pk = G.one() * alice_sk
    let bob_pk = G.one() * bob_sk
    let alice_shared = bob_pk * alice_sk
    let bob_shared = alice_pk * bob_sk
    if alice_shared != bob_shared:
      return false
  result = true

proc randomEquality*(G: typedesc): bool =
  let ti = FR.fromString("2").inverse().get()
  for i in 0..<10:
    let begin = G.random()
    var acc = begin

    let a = FR.random()
    let b = G.random()
    let c = FR.random()
    let d = G.random()

    for k in 0..<10:
      acc = acc * a
      acc = -acc
      acc = acc + b
      acc = acc * c
      acc = -acc
      acc = acc - d
      acc = acc.double()

    let ai = a.inverse().get()
    let ci = c.inverse().get()

    for k in 0..<10:
      acc = acc * ti
      acc = acc + d
      acc = -acc
      acc = acc * ci
      acc = acc - b
      acc = -acc
      acc = acc * ai

    if begin != acc:
      return false
  result = true

proc affineJacobianConversion(G: typedesc): bool =
  if not G.zero().toAffine().isNone():
    return false
  if not G.zero().toAffine().isNone():
    return false
  for i in 0..<100:
    var a = G.one() * FR.random()
    let b = a.toAffine().get()
    let c = b.toJacobian()
    if a != c:
      return false
  return true

when isMainModule:
  suite "Group elements test suite:":
    test "[G1] Zero/One test":
      check G1.zeroTest() == true
    test "[G1] Random addition test":
      check G1.randomAdd() == true
    test "[G1] Random doubling test":
      check G1.randomMul() == true
    test "[G1] Random Diffie-Hellman test":
      check G1.randomDH() == true
    test "[G1] Random equality test":
      check G1.randomEquality() == true
    test "[G1] Random Affine to Jacobian conversion test":
      check G1.affineJacobianConversion() == true
    test "[G1] Y at point at Infinity test":
      check:
        (G1.zero()).y == FQ.one()
        (-G1.zero()).y == FQ.one()
    test "[G2] Zero/One test":
      check G2.zeroTest() == true
    test "[G2] Random addition test":
      check G1.randomAdd() == true
    test "[G2] Random doubling test":
      check G2.randomMul() == true
    test "[G2] Random Diffie-Hellman test":
      check G2.randomDH() == true
    test "[G2] Random equality test":
      check G2.randomEquality() == true
    test "[G2] Random Affine to Jacobian conversion test":
      check G2.affineJacobianConversion() == true
    test "[G2] Y at point at Infinity test":
      check:
        (G2.zero()).y == FQ2.one()
        (-G2.zero()).y == FQ2.one()
