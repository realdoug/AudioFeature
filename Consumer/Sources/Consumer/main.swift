import AudioFeature

let filename = "../5d4e3bb8_nohash_0.wav"
let (samples, fileinfo) = loadSound(filename)
print(fileinfo)

let samplesOrig = samples.copy() // assure we arent modifying the original

let params = FeatureParams()
let p = PowerSpectrum<Float>()
for _ in 0...9 {
  let result = p.apply(on: samples)
  print(result.count)
  assert(samples == samplesOrig)
}

let pe = PreEmphasis<Double>(
  preemCoef: 1.0,
  windowLength: 2
)
var a = [1.0, 2.0, 3.0, 4.0]
pe.apply(inPlace: &a)
assert(a == [0.0, 1.0, 0.0, 1.0])
