## BNCurve
[![Build Status](https://travis-ci.org/status-im/nim-bncurve.svg?branch=master)](https://travis-ci.org/status-im/nim-bncurve)
[![Build status](https://ci.appveyor.com/api/projects/status/hvv14l9v31mksam6/branch/master?svg=true)](https://ci.appveyor.com/project/nimbus/nim-bncurve/branch/master)
[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

## Introduction
This pure Nim implementation of Barreto-Naehrig pairing-friendly elliptic curve.

This is a [pairing cryptography](https://en.wikipedia.org/wiki/Pairing-based_cryptography) library written in pure Nim. It makes use of the Barreto-Naehrig (BN) curve construction from [[BCTV2015]](https://eprint.iacr.org/2013/879.pdf) to provide two cyclic groups **G<sub>1</sub>** and **G<sub>2</sub>**, with an efficient bilinear pairing:

*e: G<sub>1</sub> × G<sub>2</sub> → G<sub>T</sub>*

This code is adaptation of [bn](https://github.com/zcash-hackworks/bn) library.

## Security warnings

This library, like other pairing cryptography libraries implementing this construction, is not resistant to side-channel attacks.

## Installation

Add to your `.nimble` file:
```
requires "https://github.com/status-im/nim-bncurve"
```

or install it via
```
nimble install https://github.com/status-im/nim-bncurve
```

## Build and test

```
nimble install https://github.com/status-im/nim-bncurve
nimble test
```

## License

Licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT
* Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. This file may not be copied, modified, or distributed except according to those terms.
