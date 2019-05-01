import BaseMath

public struct Derivatives<DType : SupportsBasicMath> {
  private var deltaWindow: Int
  private var accWindow: Int

  public init(deltaWindow: Int, accWindow: Int) {
    self.deltaWindow = deltaWindow
    self.accWindow = accWindow
  }

  func computeDerivative(_ input: [DType], _ windowLen: Int, _ numFeatures: Int) -> [DType] {
    let numFrames = input.count / numFeatures
    var output = [DType](repeating: 0.0, count: input.count)
    let twoTimesWlPlusOne = 2 * windowLen + 1
    let denominator = DType(windowLen * (windowLen + 1) * twoTimesWlPlusOne) / 3.0

    for i in 0..<numFrames {
      for j in 0..<numFeatures {
        let curIx = i * numFeatures + j
        for d in 1...windowLen {
          let ix1 = curIx + min((numFrames - i - 1), d) * numFeatures
          let cmp = curIx - min(i, d) * numFeatures
          let dif = input[ix1] - input[cmp]
          output[curIx] = output[curIx] + DType(d) * dif
        }
        output[curIx] = output[curIx] / denominator
      }
    }
    return output
  }

  public func apply(on input: [DType], numFeatures: Int) -> [DType] {
    //  LOG_IF(FATAL, (input.size() % numfeat) != 0) << "Invalid args";
    if deltaWindow <= 0 {
      return input
    }

    let deltas = computeDerivative(input, deltaWindow, numFeatures)
    var szMul = 2
    var doubleDeltas = [DType](repeating: 0, count: deltas.count)
    if accWindow > 0 {
      szMul = 3
      doubleDeltas = computeDerivative(deltas, accWindow, numFeatures)
    }
    var output = [DType](repeating: 0.0, count: input.count * szMul)
    let numFrames = input.count / numFeatures
    for i in 0..<numFrames {
      let curInIx = i * numFeatures
      let curOutIx = curInIx * szMul

      output[curOutIx..<(curOutIx + numFeatures)] =
        input[curInIx..<(curInIx + numFeatures)]

      output[(curOutIx + numFeatures)..<(curOutIx + 2 * numFeatures)] =
        deltas[curInIx..<(curInIx + numFeatures)]

      if accWindow > 0 {
        output[(curOutIx + 2 * numFeatures)..<(curOutIx + 3 * numFeatures)] =
          doubleDeltas[curInIx..<(curInIx + numFeatures)]
      }
    }
    return output
  }
}