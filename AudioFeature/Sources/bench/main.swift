import Foundation
import CoreFoundation
import AudioFeature

public func benchmarkTime(f: ()->()) -> Double {
  f() // warmup
  let start = CFAbsoluteTimeGetCurrent()
  for _ in 0..<1 {f()}
  return (CFAbsoluteTimeGetCurrent()-start)
}

public func benchmark(title:String, f:()->()) {
  let time = benchmarkTime(f:f)
  print("\(title): \(time) s")
}

let filename = "./Tests/data/sa1.wav"
let (wavInput, _) = loadSound(filename)
let mfcc = Mfcc<Float>()

benchmark(title: "mfcc") {
  var _ = mfcc.apply(on: wavInput)
}

let mfsc = Mfsc<Float>()
benchmark(title: "mfsc") {
  var _ = mfsc.apply(on: wavInput)
}