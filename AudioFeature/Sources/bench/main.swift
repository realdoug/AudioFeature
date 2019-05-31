import Foundation
import CoreFoundation
import AudioFeature

var params = FeatureParams()
params.samplingFreq = 16000;
params.frameSizeMs = 25;
params.frameStrideMs = 10;
params.numFilterbankChans = 20;
params.lowFreqFilterbank = 0;
params.highFreqFilterbank = 8000;
params.numCepstralCoeffs = 13;
params.lifterParam = 22;
params.deltaWindow = 2;
params.accWindow = 2;
params.zeroMeanFrame = false;
params.useEnergy = false;
params.usePower = false;
params.windowType = WindowType.hanning

let mfcc = Mfcc<Float>(params: params)

let audioTimeSec = [1, 10, 15, 20, 25, 50, 100]
let nTimes = 1000

print("Benchmark MFCC")
for t in audioTimeSec {
  var totalTime = 0.0
  var input = [Float](repeating: 0.0, count: t * params.samplingFreq)
  for _ in 0..<nTimes {
    for i in 0..<input.count {
      input[i] = Float.random(in: 0..<1)
    }

    let start = CFAbsoluteTimeGetCurrent()
    let _ = mfcc.apply(on: input)
    let end = CFAbsoluteTimeGetCurrent()
    totalTime += (end - start) * 1000
  }
  print("| Input Size : \(t) sec , Av. time taken \(totalTime / Double(nTimes)) msec")
}