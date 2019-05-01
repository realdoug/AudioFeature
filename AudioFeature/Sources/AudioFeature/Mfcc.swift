import SwiftyMKL
import BaseMath

public class Mfcc<DType : SupportsMKL> : Mfsc<DType> {
  var dct: Dct<DType>
  var ceplifter: Ceplifter<DType>

  public override init(params: FeatureParams = FeatureParams()) {
    self.dct = Dct<DType>(numFilters: params.numFilterbankChans, numCeps: params.numCepstralCoeffs)
    self.ceplifter = Ceplifter<DType>(numFilters: params.numCepstralCoeffs, lifterParam: params.lifterParam)
    super.init(params: params)
    //  validateMfccParams();
  }

  public override func outputSize(inputSz: Int) -> Int {
    return featureParams.mfccFeatSz() * featureParams.numFrames(inSize: inputSz)
  }

  public override func apply(on input: [DType]) -> [DType] {
    var frames = frameSignal(input: input, params: featureParams)
    if frames.count == 0 { return [] }

    let nSamples = featureParams.numFrameSizeSamples()
    let nFrames = frames.count / nSamples

    var energy = [DType](repeating: 0.0, count: nFrames)
    
    if featureParams.useEnergy && featureParams.rawEnergy {
      for f in 0..<nFrames {
        let beginPtr = frames.p + f * nSamples
        let framesView = UnsafeMutableBufferPointer(start: beginPtr, count: nSamples)

        energy[f] = framesView.summul(framesView).log()
      }
    }

    let mfscFeatures = mfscImpl(frames: &frames)
    var cep = dct.apply(on: mfscFeatures)
    ceplifter.apply(inPlace: &cep)

    let nFeat = featureParams.numCepstralCoeffs

    if featureParams.useEnergy {
      if !featureParams.rawEnergy {
        for f in 0..<nFrames {
          let beginPtr = frames.p + f * nSamples
          let framesView = UnsafeMutableBufferPointer(start: beginPtr, count: nSamples)
          energy[f] = framesView.summul(framesView).log()
        }
      }
      for f in 0..<nFrames {
        cep[f * nFeat] = energy[f]
      }
    }

    return derivatives.apply(on: cep, numFeatures: nFeat)
  }

  // template <typename T>
  // void Mfcc<T>::validateMfccParams() const {
  //   this->validatePowSpecParams();
  //   this->validateMfscParams();
  //   LOG_IF(FATAL, this->featParams_.lifterParam < 0)
  //       << "'lifterparam' has to be >=0.";
  // }
}