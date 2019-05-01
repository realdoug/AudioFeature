import BaseMath

public struct Ceplifter<DType : SupportsBasicMath> {
  var numFilters: Int
  var lifterParam: Double
  var coefs: [DType]

  public init(numFilters: Int, lifterParam: Double) {
    self.numFilters = numFilters
    self.lifterParam = lifterParam
    self.coefs = [DType](repeating: 0.0, count: numFilters)

    for i in 0..<coefs.count {
      let pi_c_div_lifter = Double.pi * Double(i) / lifterParam
      coefs[i] = DType(1.0 + 0.5 * lifterParam * pi_c_div_lifter.sin())
    }
  }

  public func apply(on input: [DType]) -> [DType]{
    var output = input.copy()
    apply(inPlace: &output)
    return output
  }

  public func apply(inPlace input: inout [DType]) {
    // LOG_IF(FATAL, (input.size() % numFilters_) != 0);
    var n: Int = 0
    for i in 0..<input.count {
      input[i] = input[i] * coefs[n]
      n += 1
      if n == numFilters {
        n = 0
      }
    }
  }
}