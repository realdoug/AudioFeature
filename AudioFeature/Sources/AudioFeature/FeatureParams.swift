enum WindowType {
  case hamming, hanning
};

enum FrequencyScale {
  case mel, linear, log10
}

struct FeatureParams {
// frequency (Hz) of speech signal recording
  var samplingFreq: Int

  // frame size in milliseconds
  var frameSizeMs: Int

  // frame step size in milliseconds
  var frameStrideMs: Int

  // number of filterbank channels
  // Kaldi recommends using 23 for 16KHz and 15 for 8KHz sampled data
  var numFilterbankChans: Int

  // lower cutoff frequency (HZ) for the filterbank
  var lowFreqFilterbank: Int

  // upper cutoff frequency (HZ) for the filterbank
  var highFreqFilterbank: Int

  // number of cepstral coefficients
  var numCepstralCoeffs: Int

  // liftering parameter
  var lifterParam: Int

  //  number of delta (first order regression) coefficients
  var deltaWindow: Int

  //  number of acceleration (second order regression) coefficients
  var accWindow: Int

  // analysis window function handle for framing (hamming by default)
  var windowType: Int

  // preemphasis filtering coefficient (0.7 default)
  var preemCoef: Int

  // option controlling the size of the mel floor (1.0 default)
  var melFloor: Int

  // dithering constant (0.0 default ==> no dithering)
  var ditherVal: Int

  // use power instead of magnitude for filterbank energies
  var usePower: Bool

  // If true, append log energy term as a feature to MFSC
  // For MFCC, C0 is replaced with energy term
  var useEnergy: Bool

  // If true, use energy before PreEmphasis and Windowing
  var rawEnergy: Bool

  // If true, remove DC offset from the signal frames
  var zeroMeanFrame: Bool

  // TODO default initializer
  init(
  )
}