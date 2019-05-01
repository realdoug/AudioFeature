import SwiftyMKL
import BaseMath

public class Mfsc<DType : SupportsMKL> : PowerSpectrum<DType> {
  var triFilterbank: TriFilterbank<DType>
  var derivatives: Derivatives<DType>

  public override init(params: FeatureParams = FeatureParams()) {
    // validateMfscParams()
    self.triFilterbank = TriFilterbank<DType>(
      numFilters: params.numFilterbankChans,
      filterLength: params.filterFreqResponseLen(),
      sampleFrequency: params.samplingFreq,
      lowFrequency: DType(params.lowFreqFilterbank),
      highFrequency: DType(params.highFreqFilterbank)
    )
    self.derivatives = Derivatives<DType>(
      deltaWindow: params.deltaWindow,
      accWindow: params.accWindow
    )
    super.init(params: params)
  }

  public override func apply(on input: [DType]) -> [DType] {
    var frames = frameSignal(input: input, params: featureParams)
    if frames.count < 1 {
      return []
    }

    let nSamples = featureParams.numFrameSizeSamples()
    let nFrames = frames.count / nSamples

    var energy = [DType](repeating: 0.0, count: nFrames)
    if featureParams.useEnergy && featureParams.rawEnergy {
      for f in 0..<nFrames {
        let beginPtr = frames.p + f * nSamples
        let framesView = UnsafeMutableBufferPointer(start: beginPtr, count: nSamples)
        energy[f] = max(
            framesView.summul(framesView),
            DType.leastNormalMagnitude
        ).log()
      }
    }

    var mfscFeatures = mfscImpl(frames: &frames)
    var numFeatures = featureParams.numFilterbankChans
    if featureParams.useEnergy {
      if !featureParams.rawEnergy {
        for f in 0..<nFrames {
          let beginPtr = frames.p + f * nSamples
          let framesView = UnsafeMutableBufferPointer(start: beginPtr, count: nSamples)
          energy[f] = max(
              framesView.summul(framesView),
              DType.leastNormalMagnitude
          ).log()
        }
      }

      var newMfscFeat = [DType](repeating: 0.0, count: mfscFeatures.count + nFrames)
      for f in 0..<nFrames {
        let start = f * numFeatures
        newMfscFeat[start + f] = energy[f]
        
        for k in 0..<numFeatures {
          newMfscFeat[start + f + 1 + k] = mfscFeatures[start + k]
        }
      }
      for i in 0..<mfscFeatures.count {
        swap(&mfscFeatures[i], &newMfscFeat[i])
      }
      numFeatures += 1
    }

    return derivatives.apply(on: mfscFeatures, numFeatures: numFeatures)
  }

  public func outputSize(inputSz: Int) -> Int {
    return featureParams.mfscFeatSz() * featureParams.numFrames(inSize: inputSz)
  }

  func mfscImpl(frames: inout [DType]) -> [DType] {
    var powSpectrum = powSpectrumImpl(&frames)
    if featureParams.usePower {
      powSpectrum.mul_(powSpectrum)
    }

    var triflt = triFilterbank.apply(powSpectrum, melFloor: DType(featureParams.melFloor))
    triflt.log_()

    return triflt
  }

// template <typename T>
// void Mfsc<T>::validateMfscParams() const {
//   this->validatePowSpecParams();
//   LOG_IF(FATAL, this->featParams_.numFilterbankChans <= 0)
//       << "numfilterbankchans' has to be positive.";
//   LOG_IF(FATAL, this->featParams_.melFloor <= 0.0)
//       << "'melfloor' has to be positive.";
// }
}