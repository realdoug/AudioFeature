import BaseMath
import SwiftyMKL
import CIPL

func frameSignal<DType : SupportsBasicMath>(
  input: [DType],
  params: FeatureParams) -> [DType] {

  let frameSize = params.numFrameSizeSamples()
  let frameStride = params.numFrameStrideSamples()
  let numFrames: Int = params.numFrames(inSize: input.count)

  // HTK: Values coming out of rasta treat samples as integers,
  // not range -1..1, hence scale up here to match (approx)
  let scale: DType = 32768.0
  var frames: [DType] = Array(repeating: 0, count: numFrames * frameSize)
  let p = UnsafeMutableBufferPointer(start: frames.p, count: frames.count)
  let inputP = UnsafeBufferPointer(start: input.p, count: input.count)
  for f in 0..<numFrames {
    for i in 0..<frameSize {
      p[f * frameSize + i] = scale.mul(inputP[f * frameStride + i]); 
    }
  }
  return frames;
} 

func mklGemm<DType : SupportsMKL>(_ matA: [DType], _ matB: [DType], _ n: Int, _ k: Int) -> [DType] {
  // LOG_IF(
  //   FATAL,
  //   n <= 0 || k <= 0 || matA.empty() || (matA.size() % k != 0) ||
  //       (matB.size() != n * k))
  //   << "Invalid args";

  let m: Int = matA.count / k;
  var matC = [DType](repeating: 0.0, count: m * n)

  DType.gemm(
    CblasRowMajor,
    CblasNoTrans,
    CblasNoTrans,
    m,
    n,
    k,
    1.0, // alpha
    UnsafePointer(matA),
    k,
    UnsafePointer(matB),
    n,
    0.0, // beta
    UnsafeMutablePointer(&matC[0]),
    n)

  return matC
}
