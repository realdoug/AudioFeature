import BaseMath

public enum WindowType {
  case hamming, hanning
};

public enum FrequencyScale {
  case mel, linear, log10
}

public struct FeatureParams {
  // frequency (Hz) of speech signal recording
  public var samplingFreq: Int = 16000

  // frame size in milliseconds
  public var frameSizeMs: Int = 25

  // frame step size in milliseconds
  public var frameStrideMs: Int = 10

  // number of filterbank channels
  // Kaldi recommends using 23 for 16KHz and 15 for 8KHz sampled data
  public var numFilterbankChans: Int = 23

  // lower cutoff frequency (HZ) for the filterbank
  public var lowFreqFilterbank: Int = 0

  // upper cutoff frequency (HZ) for the filterbank
  public var highFreqFilterbank: Int = -1

  // number of cepstral coefficients
  public var numCepstralCoeffs: Int = 13

  // liftering parameter
  public var lifterParam: Double = 22.0

  //  number of delta (first order regression) coefficients
  public var deltaWindow: Int = 2

  //  number of acceleration (second order regression) coefficients
  public var accWindow: Int = 2

  // analysis window function handle for framing (hamming by default)
  public var windowType: WindowType = WindowType.hamming

  // preemphasis filtering coefficient (0.7 default)
  public var preemCoef: Float = 0.97

  // option controlling the size of the mel floor (1.0 default)
  public var melFloor: Float = 1.0

  // dithering constant (0.0 default ==> no dithering)
  public var ditherVal: Float = 0.0

  // use power instead of magnitude for filterbank energies
  public var usePower: Bool = true

  // If true, append log energy term as a feature to MFSC
  // For MFCC, C0 is replaced with energy term
  public var useEnergy: Bool = true

  // If true, use energy before PreEmphasis and Windowing
  public var rawEnergy: Bool = true

  // If true, remove DC offset from the signal frames
  public var zeroMeanFrame: Bool = true

  public init() {}

  // frame size (no of samples)
  // the last frame is discarded, if less than the frame size
  public func numFrameSizeSamples() -> Int {
    var num = (1e-3 * Double(frameSizeMs) * Double(samplingFreq))
    num.round()
    return Int(num)
  }

  public func numFrameStrideSamples() -> Int {
    var num = (1e-3 * Double(frameStrideMs) * Double(samplingFreq))
    num.round()
    return Int(num)
  }

  public func nFft() -> Int {
    let nsamples = numFrameSizeSamples();
    let shift = Double(nsamples).log2().rounded(.up)
    return (nsamples > 0) ? 1 << Int(shift) : 0;
  }

  public func filterFreqResponseLen() -> Int {
    return (nFft() >> 1) + 1;
  }

  public func powSpecFeatSz() -> Int {
    return filterFreqResponseLen();
  }

  public func mfscFeatSz() -> Int {
    let devMultiplier: Int = 
          1 + (deltaWindow > 0 ? 1 : 0) + (accWindow > 0 ? 1 : 0)
    return (numFilterbankChans + (useEnergy ? 1 : 0)) * (devMultiplier)
  }

  public func mfccFeatSz() -> Int {
    let devMultiplier: Int =
        1 + (deltaWindow > 0 ? 1 : 0) + (accWindow > 0 ? 1 : 0)
    return numCepstralCoeffs * devMultiplier;
  }

  public func numFrames(inSize: Int) -> Int {
    let frameSize = numFrameSizeSamples();
    let frameStride = numFrameStrideSamples();
    if frameStride <= 0 || inSize < frameSize {
      return 0;
    }
    let rounded = Double((inSize - frameSize) * 1 / frameStride).rounded(.down)
    return 1 + Int(rounded);
  }
}
