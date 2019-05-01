import Foundation
import BaseMath
import SwiftyMKL

public struct Dct<DType : SupportsMKL> {
  var numFilters: Int
  var numCeps: Int
  public var dctMatrix: [DType]

  public func apply(on input: [DType]) -> [DType] {
    return mklGemm(input, dctMatrix, numCeps, numFilters)
  }

  public init(numFilters: Int, numCeps: Int) {
    self.numFilters = numFilters
    self.numCeps = numCeps
    dctMatrix = [DType](repeating: 0.0, count: numFilters * numCeps)
    for f in 0..<numFilters {
      for c in 0..<numCeps {
        let a: DType = sqrt(DType(2) / DType(numFilters))
        let pi_c = Double.pi * Double(c)
        let f_plus_one_half = Double(f) + 0.5
        let b: DType = DType(pi_c * f_plus_one_half / Double(numFilters))
        dctMatrix[f * numCeps + c] = a * b.cos()
      }
    }
  }
}