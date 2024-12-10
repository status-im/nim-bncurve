{.used.}

import unittest2
import nimcrypto/utils
import ../bncurve/fields

proc randomSquaring*[T](): bool =
  for i in 0..100:
    var a = T.random()
    if a * a != a.squared():
      return false

  var cur = T.zero()
  for i in 0..100:
    if cur.squared() != cur * cur:
      return false
    cur = cur + T.one()

  return true

proc zeroTest*[T](): bool =
  if -T.zero() != T.zero():
    return false
  if (-T.one() + T.one()) != T.zero():
    return false
  if (T.zero() - T.zero()) != T.zero():
    return false
  return true

proc canInvert*[T](): bool =
  var a = T.one()
  for i in 0..100:
    if (a * a.inverse().get()) != T.one():
      return false
    a = a + T.one()
  a = -T.one()
  for i in 0..100:
    if (a * a.inverse().get()) != T.one():
      return false
    a = a - T.one()
  return true

proc randomElementInverse*[T](): bool =
  for i in 0..100:
    var a = T.random()
    if a.inverse().get() * a != T.one():
      return false
    var b = T.random()
    if a * b * a.inverse().get() != b:
      return false
  return true

proc randomElementMultiplication*[T](): bool =
  for i in 0..250:
    var a = T.random()
    var b = T.random()
    var c = T.random()
    result = ((a * b) * c == a * (b * c))

proc randomElementEval*[T](): bool =
  for i in 0..100:
    var a = T.random()
    var b = T.random()
    var c = T.random()
    var d = T.random()

    var lhs = (a + b) * (c + d)
    var rhs = (a * c) + (b * c) + (a * d) + (b * d)
    if lhs != rhs:
      return false
  return true

proc randomElementASN*[T](): bool =
  for i in 0..100:
    var a = T.random()
    if a + (-a) != T.zero():
      return false

  for i in 0..10:
    var a = T.random()
    var r = T.random()
    var b = a + r
    var c = T.random()
    var d = c + r

    for m in 0..10:
      let r0 = T.random()
      a += r0
      b += r0
      c = c + r0
      d = d + r0
      let r1 = T.random()
      a -= r1
      b -= r1
      c = c - r1
      d = d - r1
      let r2 = T.random()
      a += (-(-r2))
      b += (-(-r2))
      c = c + (-(-r2))
      d = d + (-(-r2))
      let r3 = T.random()
      a -= r3
      b += -r3
      c = c - r3
      d = d + (-r3)
      let r4 = T.random()
      a += -r4
      b -= r4
      c = c + (-r4)
      d = d - r4
    b -= r
    d = d - r

    if a != b or c != d:
      return false
  return true

proc testCyclotomicExp(): bool =
  var orig = FQ12(
    c0: FQ6(
      c0: FQ2(
        c0: FQ.fromString("2259924035228092997691937637688451143058635253053054071159756458902878894295"),
        c1: FQ.fromString("13145690032701362144460254305183927872683620413225364127064863863535255135244")
      ),
      c1: FQ2(
        c0: FQ.fromString("9910063591662383599552477067956819406417086889312288278252482503717089428441"),
        c1: FQ.fromString("537414042055419261990282459138081732565514913399498746664966841152381183961")
      ),
      c2: FQ2(
        c0: FQ.fromString("15311812409497308894370893420777496684951030254049554818293571309705780605004"),
        c1: FQ.fromString("13657107176064455789881282546557276003626320193974643644160350907227082365810")
      )
    ),
    c1: FQ6(
      c0: FQ2(
        c0: FQ.fromString("4913017949003742946864670837361832856526234260447029873580022776602534856819"),
        c1: FQ.fromString("7834351480852267338070670220119081676575418514182895774094743209915633114041")
      ),
      c1: FQ2(
        c0: FQ.fromString("12837298223308203788092748646758194441270207338661891973231184407371206766993"),
        c1: FQ.fromString("12756474445699147370503225379431475413909971718057034061593007812727141391799")
      ),
      c2: FQ2(
        c0: FQ.fromString("9473802207170192255373153510655867502408045964296373712891954747252332944018"),
        c1: FQ.fromString("4583089109360519374075173304035813179013579459429335467869926761027310749713")
      )
    )
  )

  var expected = FQ12(
    c0: FQ6(
      c0: FQ2(
        c0: FQ.fromString("14722956046055152398903846391223329501345567382234608299399030576415080188350"),
        c1: FQ.fromString("14280703280777926697010730619606819467080027543707671882210769811674790473417")
      ),
      c1: FQ2(
        c0: FQ.fromString("19969875076083990244184003223190771301761436396530543002586073549972410735411"),
        c1: FQ.fromString("10717335566913889643303549252432531178405520196706173198634734518494041323243")
      ),
      c2: FQ2(
        c0: FQ.fromString("6063612626166484870786832843320782567259894784043383626084549455432890717937"),
        c1: FQ.fromString("17089783040131779205038789608891431427943860868115199598200376195935079808729")
      )
    ),
    c1: FQ6(
      c0: FQ2(
        c0: FQ.fromString("10029863438921507421569931792104023129735006154272482043027653425575205672906"),
        c1: FQ.fromString("6406252222753462799887280578845937185621081001436094637606245493619821542775")
      ),
      c1: FQ2(
        c0: FQ.fromString("1048245462913506652602966692378792381004227332967846949234978073448561848050"),
        c1: FQ.fromString("1444281375189053827455518242624554285012408033699861764136810522738182087554")
      ),
      c2: FQ2(
        c0: FQ.fromString("8839610992666735109106629514135300820412539620261852250193684883379364789120"),
        c1: FQ.fromString("11347360242067273846784836674906058940820632082713814508736182487171407730718")
      )
    )
  )

  let e = orig.expByNegZ()
  result = (e == expected)

proc fq12TestVector(): bool =
  let start = FQ12(
    c0: FQ6(
      c0: FQ2(
        c0: FQ.fromString("19797905000333868150253315089095386158892526856493194078073564469188852136946"),
        c1: FQ.fromString("10509658143212501778222314067134547632307419253211327938344904628569123178733")
      ),
      c1: FQ2(
        c0: FQ.fromString("208316612133170645758860571704540129781090973693601051684061348604461399206"),
        c1: FQ.fromString("12617661120538088237397060591907161689901553895660355849494983891299803248390")
      ),
      c2: FQ2(
        c0: FQ.fromString("2897490589776053688661991433341220818937967872052418196321943489809183508515"),
        c1: FQ.fromString("2730506433347642574983433139433778984782882168213690554721050571242082865799")
      )
    ),
    c1: FQ6(
      c0: FQ2(
        c0: FQ.fromString("17870056122431653936196746815433147921488990391314067765563891966783088591110"),
        c1: FQ.fromString("14314041658607615069703576372547568077123863812415914883625850585470406221594")
      ),
      c1: FQ2(
        c0: FQ.fromString("10123533891707846623287020000407963680629966110211808794181173248765209982878"),
        c1: FQ.fromString("5062091880848845693514855272640141851746424235009114332841857306926659567101")
      ),
      c2: FQ2(
        c0: FQ.fromString("9839781502639936537333620974973645053542086898304697594692219798017709586567"),
        c1: FQ.fromString("1583892292110602864638265389721494775152090720173641072176370350017825640703")
      )
    )
  )
  let expect = FQ12(
    c0: FQ6(
      c0: FQ2(
        c0: FQ.fromString("18388750939593263065521177085001223024106699964957029146547831509155008229833"),
        c1: FQ.fromString("18370529854582635460997127698388761779167953912610241447912705473964014492243")
      ),
      c1: FQ2(
        c0: FQ.fromString("3691824277096717481466579496401243638295254271265821828017111951446539785268"),
        c1: FQ.fromString("20513494218085713799072115076991457239411567892860153903443302793553884247235")
      ),
      c2: FQ2(
        c0: FQ.fromString("12214155472433286415803224222551966441740960297013786627326456052558698216399"),
        c1: FQ.fromString("10987494248070743195602580056085773610850106455323751205990078881956262496575")
      )
    ),
    c1: FQ6(
      c0: FQ2(
        c0: FQ.fromString("5134522153456102954632718911439874984161223687865160221119284322136466794876"),
        c1: FQ.fromString("20119236909927036376726859192821071338930785378711977469360149362002019539920")
      ),
      c1: FQ2(
        c0: FQ.fromString("8839766648621210419302228913265679710586991805716981851373026244791934012854"),
        c1: FQ.fromString("9103032146464138788288547957401673544458789595252696070370942789051858719203")
      ),
      c2: FQ2(
        c0: FQ.fromString("10378379548636866240502412547812481928323945124508039853766409196375806029865"),
        c1: FQ.fromString("9021627154807648093720460686924074684389554332435186899318369174351765754041")
      )
    )
  )

  var next = start
  for i in 0..<100:
    next = next * start

  var cpy = next
  for i in 0..<10:
    next = next.squared()

  for i in 0..<10:
    next = next + start
    next = next - cpy
    next = -next

  next = next.squared()
  result = (expect == next)

proc fpSerializeTests[T](): bool =
  when (T is FQ) or (T is FR):
    var buffer: array[32, byte]
  elif (T is FQ2):
    var buffer: array[64, byte]
  else:
    {.fatal.}

  for i in 0..<1000:
    var e = T.random()
    zeroMem(addr buffer[0], sizeof(buffer))
    if not e.toBytes(buffer):
      return false
    var a: T
    if not a.fromBytes(buffer):
      return false
    if a != e:
      return false
  return true

proc fq2SerializeTestVectors(): bool =
  const vectors = [
    FQ2(
      c0: FQ([12685471316754074400'u64, 5151117139186389981'u64,
              1811926512010801501'u64, 2926027770199945729'u64]),
      c1: FQ([13288357145490715372'u64, 8465179270531902744'u64,
              2331932027798174928'u64, 1169568334929779847'u64])
    ),
    FQ2(
      c0: FQ([6571363706651148129'u64, 12259671536166748744'u64,
              13297153216522874336'u64, 3368736813872212066'u64]),
      c1: FQ([7356918428694088001'u64, 13325610168162790738'u64,
              11761401944674591087'u64, 2142266911265180485'u64])
    ),
    FQ2(
      c0: FQ([12770271250542491457'u64, 5841829129088508933'u64,
              5021659154182959822'u64, 765728708107386899'u64]),
      c1: FQ([9814770014224857768'u64, 169926129335489937'u64,
              4476430648250845846'u64, 575721800450622933'u64])
    ),
    FQ2(
      c0: FQ([10535443743532733005'u64, 18354663162560926093'u64,
              3005889269269496788'u64, 892863378917010121'u64]),
      c1: FQ([9912639056721134596'u64, 6115953886839683024'u64,
              4097812286267812943'u64, 1337629367136352970'u64])
    ),
    FQ2(
      c0: FQ([7658679475413450244'u64, 11440992707440007515'u64,
              16146061400040738154'u64, 991671862947387812'u64]),
      c1: FQ([2385857951922426638'u64, 6278331068203224119'u64,
              8247542493832618243'u64, 2945883060694238627'u64])
    )
  ]

  const expects = [
    "06b812bee59693d4f9f18dc46c55afe42fc5c18965669316117850ca22f55ffa44dda4f58baf6cdf629ecacae4a810098fc7d68a6bfcd200ca59322e37a4be3c",
    "00a41dd99c355e6984dedfc9c6752cd22b6d4d70283a128e4399734fbaa715724e0494d2d0cc7b0c71bda29d304a60cf6b3a69e366a3d50d80bfe441192d778d",
    "08f943db03ed61e8f2633740bdc071b76c27547891fe90d56776f9ef2a16de98dfd7d0a481fd5efb55374ea3762d879d226ac9bf7c0b347bae142e27f97d03ed",
    "068744cde0af982bff29d66a0e5799e78b350216ce53da6d828ca64d94bcd482af8816b7cad0dea041604d5b3ee5ddf2c5b65fc394e1752f6fa52133547a44bc",
    "09042d4acda2f2ff75073700783010461c5250f10724a0c27ecd295b2bda961245c9a740d3d8de3dbf6ed4fe142ee5480bd96a70d9a4442385718c4995b04b8b"
  ]

  var buffer: array[64, byte]
  for i in 0..<len(vectors):
    zeroMem(addr buffer[0], sizeof(buffer))
    if not vectors[i].toBytes(buffer):
      return false
    var expect = fromHex(expects[i])
    if not equalMem(addr expect[0], addr buffer[0], sizeof(buffer)):
      return false
    var c: FQ2
    if c.fromBytes(buffer) != true:
      return false
    if c != vectors[i]:
      return false
  return true

proc frSerializeTestVectors(): bool =
  const vectors = [
    FR([17421400499845239983'u64, 6997355861326767820'u64,
        8120099025258387513'u64, 3183707257070674626'u64]),
    FR([2146638237245267213'u64, 5090456461755122866'u64,
        6235019329087538353'u64, 387017393791451532'u64]),
    FR([6344330946110213979'u64, 4581536139297704744'u64,
        16303670869942326496'u64, 2666106878953846273'u64]),
    FR([8748641423870480081'u64, 5579982342510408473'u64,
        8096786847344710301'u64, 194588591521887053'u64]),
    FR([13962585249620634127'u64, 12179982421793366287'u64,
        16590787540748934681'u64, 1292188281347940190'u64])
  ]

  const expects = [
    "11177bed2bc11734f04d9c5ef4724e062835e514dc7142d7ea9c41758d16f8a0",
    "2619ea8400189f81213d2f1c29c4372ab5a91be78df5b1f2649827138a1d8401",
    "24f582ad30f718ecccbe241b94d826adb75f3aa9103deed3c7e183b06979bf1f",
    "22efbafeb86bd66aa38389b5ff513384bae6de53269fafd42a8a614b3d275e56",
    "03a880d889b5b4cf45376207b13d6c007c6efe0338f9490ab83938f20bd444b2"
  ]
  var buffer: array[32, byte]
  for i in 0..<len(vectors):
    zeroMem(addr buffer[0], sizeof(buffer))
    if not vectors[i].toBytes(buffer):
      return false
    var expect = fromHex(expects[i])
    if not equalMem(addr expect[0], addr buffer[0], sizeof(buffer)):
      return false
    var c: FR
    if c.fromBytes(buffer) != true:
      return false
    if c != vectors[i]:
      return false
  return true

proc fqSerializeTestVectors(): bool =
  const vectors = [
    FQ([12123287589963276695'u64, 17077283578393155025'u64,
        18124373372772101378'u64, 846421381194958693'u64]),
    FQ([17853748202411400943'u64, 2656002062984499858'u64,
        10048626202887305070'u64, 694231139270692630'u64]),
    FQ([14471564705950005567'u64, 18111991644968140513'u64,
        17814103556911721998'u64, 92110366780417983'u64]),
    FQ([2989648722487476748'u64, 6723225646291704123'u64,
        11622908385009293013'u64, 2374314218300473764'u64]),
    FQ([4494471629382615894'u64, 1770606299211341443'u64,
        11311559966274242210'u64, 3399355515865771034'u64])
  ]

  const expects = [
    "0b812cdf8aafd6cbe1d6959968066172ebf606339547f18d735cf8364ebb6008",
    "23094811623a66136c3a3f86dcf8ac67bf7a2654e1e880a42243cf0f2b652847",
    "25b9bf5f353b1d29c62b954257ac188330e1335d557a11c04fcd10fc6ef07834",
    "111341c47c8c55345493a0ee73fa91d5e9f853451a11c982ff6ae824d42d8017",
    "15e851e5eb9e990b33d9e2056749dbb8ca6f0726c750b6665052090ff6249a63"
  ]
  var buffer: array[32, byte]
  for i in 0..<len(vectors):
    zeroMem(addr buffer[0], sizeof(buffer))
    if not vectors[i].toBytes(buffer):
      return false
    var expect = fromHex(expects[i])
    if not equalMem(addr expect[0], addr buffer[0], sizeof(buffer)):
      return false
    var c: FQ
    if c.fromBytes(buffer) != true:
      return false
    if c != vectors[i]:
      return false
  return true


suite "Field elements test suite":
  test "[FR] rsquared() test":
    for i in 0..<1000:
      var a = FR.random()
      var b = BNU256.into(a)
      var c = FR.init(b)
      check a == c.get()

  test "[FR] String conversion test":
    var a = FR.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495616")
    check a == -FR.one()

  test "[FR] Random multiplication test":
    check randomElementMultiplication[FR]() == true

  test "[FR] Random addition/substraction/negation test":
    check randomElementASN[FR]() == true

  test "[FR] Inversion test":
    check canInvert[FR]() == true

  test "[FR] Zero test":
    check zeroTest[FR]() == true

  test "[FR] Random element squaring test":
    check randomSquaring[FR]() == true

  test "[FR] Random element inversion test":
    check randomElementInverse[FR]() == true

  test "[FR] Random element evaluation test":
    check randomElementEval[FR]() == true

  test "[FR] Serialize/Deserialize tests":
    check fpSerializeTests[FR]() == true

  test "[FR] Serialize test vectors":
    check frSerializeTestVectors() == true

  test "[FQ] rsquared() tests":
    for i in 0..1000:
      var a = FQ.random()
      var b = BNU256.into(a)
      var c = FQ.init(b)
      check a == c.get()

  test "[FQ] String conversion test":
    var b = FQ.fromString("21888242871839275222246405745257275088696311157297823662689037894645226208582")
    check b == -FQ.one()

  test "[FQ] Random multiplication test":
    check randomElementMultiplication[FQ]() == true

  test "[FQ] Random addition/substraction/negation test":
    check randomElementASN[FQ]() == true

  test "[FQ] Inversion test":
    check canInvert[FQ]() == true

  test "[FQ] Zero test":
    check zeroTest[FQ]() == true

  test "[FQ] Random element squaring test":
    check randomSquaring[FQ]() == true

  test "[FQ] Random element inversion test":
    check randomElementInverse[FQ]() == true

  test "[FQ] Random element evaluation test":
    check randomElementEval[FQ]() == true

  test "[FQ] Serialize/Deserialize tests":
    check fpSerializeTests[FQ]() == true

  test "[FQ] Serialize test vectors":
    check fqSerializeTestVectors() == true

  test "[FQ2] Random multiplication test":
    check randomElementMultiplication[FQ2]() == true

  test "[FQ2] Random addition/substraction/negation test":
    check randomElementASN[FQ2]() == true

  test "[FQ2] Inversion test":
    check canInvert[FQ2]() == true

  test "[FQ2] Zero test":
    check zeroTest[FQ2]() == true

  test "[FQ2] Random element squaring test":
    check randomSquaring[FQ2]() == true

  test "[FQ2] Random element inversion test":
    check randomElementInverse[FQ2]() == true

  test "[FQ2] Random element evaluation test":
    check randomElementEval[FQ2]() == true

  test "[FQ2] Serialize/Deserialize tests":
    check fpSerializeTests[FQ2]() == true

  test "[FQ2] Serialize test vectors":
    check fq2SerializeTestVectors() == true

  test "[FQ6] Random multiplication test":
    check randomElementMultiplication[FQ6]() == true

  test "[FQ6] Random addition/substraction/negation test":
    check randomElementASN[FQ6]() == true

  test "[FQ6] Inversion test":
    check canInvert[FQ6]() == true

  test "[FQ6] Zero test":
    check zeroTest[FQ6]() == true

  test "[FQ6] Random element squaring test":
    check randomSquaring[FQ6]() == true

  test "[FQ6] Random element inversion test":
    check randomElementInverse[FQ6]() == true

  test "[FQ6] Random element evaluation test":
    check randomElementEval[FQ6]() == true

  test "[FQ12] Random multiplication test":
    check randomElementMultiplication[FQ12]() == true

  test "[FQ12] Random addition/substraction/negation test":
    check randomElementASN[FQ12]() == true

  test "[FQ12] Inversion test":
    check canInvert[FQ12]() == true

  test "[FQ12] Zero test":
    check zeroTest[FQ12]() == true

  test "[FQ12] Random element squaring test":
    check randomSquaring[FQ12]() == true

  test "[FQ12] Random element inversion test":
    check randomElementInverse[FQ12]() == true

  test "[FQ12] Random element evaluation test":
    check randomElementEval[FQ12]() == true

  test "[FQ12] Cyclotomic exponent test":
    check testCyclotomicExp() == true

  test "[FQ12] Test vector test":
    check fq12TestVector() == true
