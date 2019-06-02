import CAudioFeature

public protocol SupportedBySndFile {}
extension Double: SupportedBySndFile {}
extension Float: SupportedBySndFile {}
extension Int16: SupportedBySndFile {}

enum LoadSoundError: Error {
  case invalidReturnType
}

// TODO: support formats other than float
public func loadSound<DType : SupportedBySndFile>(_ filename: String, as dtype: DType.Type) throws -> ([DType], SF_INFO) {
  var info = SF_INFO()
  info.format = 0
  let file = sf_open(filename, Int32(SFM_READ), &info);

  let dataSize: Int = Int(info.channels) * Int(info.frames)
  if DType.self == Float.self {
    var data = [Float](repeating: 0, count: dataSize) as! [DType]
    sf_readf_float(file, UnsafeMutablePointer(&data), Int64(dataSize))
    sf_close(file)
    return (data, info)
  } else if DType.self == Double.self {
    var data = [Double](repeating: 0, count: dataSize) as! [DType]
    sf_readf_double(file, UnsafeMutablePointer(&data), Int64(dataSize))
    sf_close(file)
    return (data, info)
  } else if DType.self == Int16.self {
    var data = [Int16](repeating: 0, count: dataSize) as! [DType]
    sf_readf_int(file, UnsafeMutablePointer(&data), Int64(dataSize))
    sf_close(file)
    return (data, info)
  } else {
    throw LoadSoundError.invalidReturnType
  }
}
