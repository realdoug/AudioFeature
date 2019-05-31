import BaseMath
import SwiftyMKL

public struct TriFilterbank<DType : SupportsMKL> {
  var numFilters: Int
  var filterLength: Int
  var sampleFrequency: Int
  var lowFrequency: DType
  var highFrequency: DType
  var frequencyScale: FrequencyScale
  var H: [DType] 
  public var filterbank: [DType] { get { return H } }

  public init(
    numFilters: Int,
    filterLength: Int,
    sampleFrequency: Int,
    lowFrequency: DType = 0.0,
    highFrequency: DType = -1.0,
    frequencyScale: FrequencyScale = FrequencyScale.mel
  ) {
    self.numFilters = numFilters
    self.filterLength = filterLength
    self.sampleFrequency = sampleFrequency
    self.lowFrequency = lowFrequency
    self.highFrequency = (highFrequency > 0) ? highFrequency : DType((sampleFrequency >> 1))
    self.frequencyScale = frequencyScale
    self.H = [DType](repeating: 0, count: filterLength * numFilters)

    let minWarpFreq = hertzToWarpedScale(hz: lowFrequency, scale: frequencyScale)
    let maxWarpFreq = hertzToWarpedScale(hz: highFrequency, scale: frequencyScale)
    let dwarp: DType = (maxWarpFreq - minWarpFreq) / DType(numFilters + 1)

    var f = [DType](repeating: 0.0, count: numFilters + 2)
    for i in 0..<(numFilters + 2) {
      f[i] = warpedToHertzScale(warped: DType(i) * dwarp + minWarpFreq, scale: frequencyScale) *
              DType(filterLength - 1) * 2.0 / DType(sampleFrequency)
    }

    let minH: DType = 0.0
    for i in 0..<filterLength {
      for j in 0..<numFilters {
        let hislope: DType = (DType(i) - f[j]) / (f[j + 1] - f[j])
        let loslope: DType = (f[j + 2] - DType(i)) / (f[j + 2] - f[j + 1])
        H[i * numFilters + j] = max(min(hislope, loslope), minH)
      }
    }
  }

  public func apply(_ input: [DType], melFloor: DType = 0.0) -> [DType] {
    var output: [DType] = mklGemm(input, H, numFilters, filterLength)
    var outputBuff = UnsafeMutableBufferPointer(start: output.p, count: output.count)
    for i in 0..<output.count {
      outputBuff[i] = max(outputBuff[i], melFloor)
    }
    return output
  }

  public func hertzToWarpedScale(hz: DType, scale frequencyScale: FrequencyScale) -> DType {
    switch frequencyScale {
    case .mel:
      return 2595.0 * ((1.0 + hz / 700.0).log10())
    case .log10:
      return hz.log10()
    case .linear:
      return hz
    }
  }

  public func warpedToHertzScale(warped: DType, scale frequencyScale: FrequencyScale) -> DType {
    switch frequencyScale {
    case .mel:
      return 700.0 * (DType(10).pow(warped / 2595.0) - 1)
    case .log10:
      return DType(10).pow(warped)
    case .linear:
      return warped
    }
  }
}