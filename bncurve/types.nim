type
  BNU256* = array[4, uint64]
  BNU512* = array[8, uint64]

  FR* = distinct BNU256
  FQ* = distinct BNU256

type
  FQ2* = object
    c0*: FQ
    c1*: FQ

type
  FQ6* = object
    c0*: FQ2
    c1*: FQ2
    c2*: FQ2

type
  FQ12* = object
    c0*: FQ6
    c1*: FQ6

type
  G1* = object
  G2* = object

  Point*[T: G1|G2] = object
    when T is G1:
      x*, y*, z*: FQ
    else:
      x*, y*, z*: FQ2

  AffinePoint*[T: G1|G2] = object
    when T is G1:
      x*, y*: FQ
    else:
      x*, y*: FQ2

  EllCoeffs* = object
    ell_0*: FQ2
    ell_vw*: FQ2
    ell_vv*: FQ2

  G2Precomp* = object
    q*: AffinePoint[G2]
    coeffs*: seq[EllCoeffs]
