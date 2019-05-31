import BaseMath

public struct Windowing<DType : SupportsBasicMath> {
  var windowLength: Int
  public var windowType: WindowType
  var coefs: [DType]

  public init(N: Int, window: WindowType) {
    windowLength = N
    windowType = window
    //LOG_IF(FATAL, N <= 1) << "Windowlength has to be > 1";
    coefs = [DType](repeating: 0, count: N)
    switch windowType {
      /* breaking into sub-functions helps the compiler out */
      case WindowType.hamming:
        for c in 0..<N {
          let nMinusOne: DType = DType(N) - 1.0
          let b: DType = (2.0 * DType.pi * DType(c) / nMinusOne).cos()
          coefs[c] = 0.54 - 0.46 * b
        }
      case WindowType.hanning:
        for c in 0..<N {
          let nMinusOne: DType = DType(N) - 1.0
          let b: DType = (2 * DType.pi * DType(c) / nMinusOne).cos()
          coefs[c] = 0.5 * (1.0 - b)
        }
    }   
  }

  func apply(_ input: [DType]) -> [DType] {
    var out = input.map {$0}
    apply(inPlace: &out)
    return out
  }

  func apply(inPlace input: inout [DType]) {
    // LOG_IF(FATAL, (input.size() % windowLength_) != 0);
    var n: Int = 0
    var inputBuffer = UnsafeMutableBufferPointer(start: input.p, count: input.count)
    for i in 0..<input.count {
      inputBuffer[i] = inputBuffer[i] * coefs[n]
      n += 1
      if n == windowLength {
        n = 0
      }
    }
  }
}
