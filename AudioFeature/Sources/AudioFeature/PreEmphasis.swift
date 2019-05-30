import BaseMath

public struct PreEmphasis<DType : SupportsBasicMath> {
  var preemCoef: DType
  var windowLength: Int

  public init(preemCoef: DType, windowLength: Int) {
    self.preemCoef = preemCoef
    self.windowLength = windowLength
  }

  public func apply(_ input: [DType]) -> [DType] {
    var out = input.copy()
    apply(inPlace: out)
    return out
  }

  public func apply(inPlace input: [DType]) {
    // LOG_IF(FATAL, (input.size() % windowLength_) != 0);
    let nFrames = input.count / windowLength
    for n in stride(from: nFrames, to: 0, by: -1) {
      let end = n * windowLength - 1
      let start = (n - 1) * windowLength
      for i in stride(from: end, to: start, by: -1) {
        // let j = input[i] - (preemCoef * input[i - 1])
        // input.p[i] = 1.0
      }
    //   input.p[start] = input[start] * (1 - preemCoef)
    }
  }
}