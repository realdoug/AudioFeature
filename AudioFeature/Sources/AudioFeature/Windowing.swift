import BaseMath

public struct Windowing<Coef : SupportsBasicMath> {
  var windowLength: Int
  public var windowType: WindowType
  var coefs: [Coef]

  public init(N: Int, window: WindowType) {
    windowLength = N
    windowType = window
    //LOG_IF(FATAL, N <= 1) << "Windowlength has to be > 1";
    coefs = [Coef](repeating: 0, count: N)
    switch windowType {
      /* breaking into sub-functions helps the compiler out */
      case WindowType.hamming:
        for c in 0..<N {
          let nMinusOne: Coef = Coef(N) - 1.0
          let b: Coef = (2.0 * Coef.pi * Coef(c) / nMinusOne).cos()
          coefs[c] = 0.54 - 0.46 * b
        }
      case WindowType.hanning:
        for c in 0..<N {
          let nMinusOne: Coef = Coef(N) - 1.0
          let b: Coef = (2 * Coef.pi * Coef(c) / nMinusOne).cos()
          coefs[c] = 0.5 * (1.0 - b)
        }
    }   
  }

  func apply(_ input: [Coef]) -> [Coef] {
    var out = input.copy()
    apply(inPlace: &out)
    return out
  }

  func apply(inPlace input: inout [Coef]) {
    // LOG_IF(FATAL, (input.size() % windowLength_) != 0);
    var n: Int = 0
    for i in 0..<input.count {
      input[i] = input[i] * coefs[n]
      n += 1
      if n == windowLength {
        n = 0
      }
    }
  }
}
