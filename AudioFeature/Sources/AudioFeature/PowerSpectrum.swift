import BaseMath
import CAudioFeature
import Darwin

public class PowerSpectrum<DType : SupportsBasicMath> {
  var featureParams: FeatureParams
  // TODO: dither
  let preEmphasis: PreEmphasis<DType>
  let windowing: Windowing<DType>
  var fftPlan: fftw_plan
  var inFftBuf: [Double]
  var outFftBuf: [Double]
  var fftMutex: pthread_mutex_t = pthread_mutex_t()

  public init(params: FeatureParams = FeatureParams()) {
    pthread_mutex_init(&self.fftMutex, nil)
    featureParams = params
    // dither
    preEmphasis = PreEmphasis<DType>(
      preemCoef: params.preemCoef as! DType,
      windowLength: params.numFrameSizeSamples()
    )
    windowing = Windowing<DType>(
      N: params.numFrameSizeSamples(),
      window: params.windowType
    )

    // validatePowerSpectrums()
    let nFft = featureParams.nFft()

    inFftBuf = [Double](repeating: 0.0, count: nFft)
    outFftBuf = [Double](repeating: 0.0, count: nFft * 2)
    fftPlan = fftw_plan_dft_r2c_1d(
      Int32(nFft),
      inFftBuf.p,
      UnsafeMutablePointer<fftw_complex>(outFftBuf.p),
      FFTW_MEASURE
    )
    precondition(outFftBuf.count == nFft * 2) 
  }

  public func apply(on input: [DType]) -> [DType] {
    var frames = frameSignal(input: input, params: featureParams)
    if frames.isEmpty {
      return []
    }

    // return powSpectrumImpl(&frames)
    return input
  }

  func powSpectrumImpl(_ frames: inout [DType]) -> [DType] {
    let nSamples = featureParams.numFrameSizeSamples();
    let nFrames = frames.count / nSamples;
    let nFft = featureParams.nFft();
    let K = featureParams.filterFreqResponseLen();

    // TODO: implement dither
    // if featureParams.ditherVal != 0.0 {
    //   frames = dither_.apply(frames);
    // }

    if featureParams.zeroMeanFrame {
      let framesBuf = UnsafeMutableBufferPointer(
        start: frames.p,
        count: frames.count
      )
      for f in 0..<nFrames {
        let begin = f * nSamples
        let end = begin + nSamples

        let mean = UnsafeMutableBufferPointer(
          rebasing: framesBuf[begin..<end]
        ).sum() / DType(nSamples)

        for i in begin..<end {
          framesBuf[i] = framesBuf[i] - mean
        }
      }
    }

    if featureParams.preemCoef != 0 {
      preEmphasis.apply(inPlace: &frames);
    }
    windowing.apply(inPlace: &frames);

    var dft: [DType] = Array(repeating: 0.0, count: K * nFrames)
    var dftBuf = UnsafeMutableBufferPointer(start: dft.p, count: dft.count)
    for f in 0..<nFrames {
      let begin = f * nSamples;

      pthread_mutex_lock(&self.fftMutex)

      // original: std::copy(begin, begin + nSamples, inFftBuf_.data());
      for i in 0..<nSamples {
        inFftBuf[i] = Double(frames[begin + i])
      }

      // original: std::fill(outFftBuf_.begin(), outFftBuf_.end(), 0.0);
      for i in 0..<outFftBuf.count {
        outFftBuf[i] = 0.0
      }

      fftw_execute(fftPlan);

      // Copy stuff to the redundant part
      for i in K..<nFft {
        let redundantA = outFftBuf[2 * nFft - 2 * i]
        let reduntantB = -outFftBuf[2 * nFft - 2 * i + 1]
        outFftBuf[2 * i] = redundantA
        outFftBuf[2 * i + 1] = reduntantB
      }

      for i in 0..<K {
        dftBuf[f * K + i] = DType(sqrt(
            outFftBuf[2 * i] * outFftBuf[2 * i] +
            outFftBuf[2 * i + 1] * outFftBuf[2 * i + 1]))
      }

      pthread_mutex_unlock(&self.fftMutex)
    }
    return dft
  }

  deinit {
    fftw_destroy_plan(fftPlan)
  }

  // void PowerSpectrum<T>::validatePowSpecParams() const {
  //   LOG_IF(FATAL, featureParams.samplingFreq <= 0)
  //       << "'samplingfreq' has to be positive.";
  //   LOG_IF(FATAL, featureParams.frameSizeMs <= 0)
  //       << "'framesizems' has to be positive.";
  //   LOG_IF(FATAL, featureParams.frameStrideMs <= 0)
  //       << "'framestridems' has to be positive.";
  //   LOG_IF(FATAL, featureParams.numFrameSizeSamples() <= 0)
  //       << "'framesizems' too low.";
  //   LOG_IF(FATAL, featureParams.numFrameStrideSamples() <= 0)
  //       << "'framestridems' too low.";
  // }
}
