import ../bncurve, std/[monotimes, os, strutils, times]

template bench(desc: string, reps: int, body: untyped) =
  if paramCount() < 1 or desc.contains(paramStr(1)):
    let start = getMonoTime()
    for _ in 0..<reps:
      body
    let stop = getMonoTime()
    echo desc,": ", inNanoseconds(stop-start) div reps, " ns"

var g11 = G1.random()
var g12 = G1.random()

var fr = FR.random()

var g21 = G2.random()
var g22 = G2.random()

var a11 = g11.toAffine().get()
var a12 = g12.toAffine().get()
var a21 = g21.toAffine().get()
var a22 = g22.toAffine().get()

bench "G1 Jacobian add", 100000:
  g11 = g11 + g12

bench "G1 toAffine", 100000:
  a11 = g11.toAffine().get()

bench "G2 Jacobian add", 100000:
  g21 = g21 + g22

bench "G2 toAffine", 100000:
  a21 = g21.toAffine().get()

bench "G1 Jacobian mul", 10000:
  g11 = g11 * fr

bench "G2 Jacobian mul", 1000:
  g21 = g21 * fr

var acc: FQ12

bench "Pairing", 1000:
  acc = pairing(g11, g21)
