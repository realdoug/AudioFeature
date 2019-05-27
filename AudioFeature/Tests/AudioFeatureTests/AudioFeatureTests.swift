import XCTest
import AudioFeature
import SwiftyMKL

final class AudioFeatureTests: XCTestCase {
    let filename = "./Tests/data/sa1.wav"

    // wav2letter uses 5, but I ran into some float issues at that precision
    func roundedTo4(_ input: [Float]) -> [Float] {
      return input.map({ Float(($0 * 10000).rounded() / 10000) })
    }

    func transposeVec(_ inp: [Float], _ inRow: Int, _ inCol: Int) -> [Float] {
      let sz = inRow * inCol
      var out: [Float] = [Float](repeating: 0.0, count: sz)
      for r in 0..<inRow {
        for c in 0..<inCol {
          out[c * inRow + r] = inp[r * inCol + c];
        }
      }
      return out;
    }

    func testLoadSound() throws {
        let (_, fileinfo) = loadSound(filename)
        XCTAssertEqual(fileinfo.frames, 52122)
    }
        
    func testPowerSpectrum() throws {
        let (samples, _) = loadSound(filename)
        let samplesOrig = samples.copy()
        let p = PowerSpectrum<Float>()
        for _ in 0...9 {
          let _ = p.apply(on: samples)
          assert(samples == samplesOrig)
        }
    }

    func testPreEmphasis() throws {
      let N: Int = 8
      let preemph1d = PreEmphasis<Float>(preemCoef: 0.95, windowLength: N)
      let input: [Float] = [
        0.098589,
        0.715877,
        0.750572,
        0.787636,
        0.116829,
        0.242914,
        0.327526,
        0.410389
      ]

      // copied from https://github.com/facebookresearch/wav2letter/blob/master/src/feature/test/PreEmphasisTest.cpp#L30
      let matlaboutput1d: [Float] = [
        0.004929,
        0.622218,
        0.070489,
        0.074592,
        -0.631425,
        0.131927,
        0.096757,
        0.099240
      ]

      let output1d = preemph1d.apply(input)
      XCTAssertEqual(roundedTo4(output1d), roundedTo4(matlaboutput1d))

      let preemph2d = PreEmphasis<Float>(preemCoef: 0.95, windowLength: N / 2)
      // copied from https://github.com/facebookresearch/wav2letter/blob/master/src/feature/test/PreEmphasisTest.cpp#L44
      let matlaboutput2d: [Float] = [
        0.004929,
        0.622218,
        0.070489,
        0.074592,
        0.005841,
        0.131927,
        0.096757,
        0.099240
      ]
      let output2d = preemph2d.apply(input)
      XCTAssertEqual(roundedTo4(output2d), roundedTo4(matlaboutput2d))
    }

    func testTriFilterbank() throws {
      let trifilt1 = TriFilterbank<Float>(
        numFilters: 10,
        filterLength: 9,
        sampleFrequency: 20000,
        lowFrequency: 0.0,
        highFrequency: 10000.0,
        frequencyScale: FrequencyScale.mel)
      
      let matlabfb1: [Float] = [
        0, 0, 0,        0,        0,        0, 0, 0, 0, 0, 0,
        0, 0, 0.881121, 0.118879, 0,        0, 0, 0, 0, 0, 0,
        0, 0, 0,        0.882891, 0.117109, 0, 0, 0, 0, 0, 0,
        0, 0, 0,        0.569722, 0.430278, 0, 0, 0, 0, 0, 0,
        0, 0, 0,        0.571075, 0.428925, 0, 0, 0, 0, 0, 0,
        0, 0, 0,        0.763933, 0.236067, 0, 0, 0, 0, 0, 0,
        0, 0, 0.082177, 0.917823, 0,        0, 0, 0, 0, 0, 0,
        0, 0, 0.532067, 0,        0,        0, 0, 0, 0, 0, 0,
        0, 0
      ]

      XCTAssertEqual(roundedTo4(trifilt1.filterbank), roundedTo4(matlabfb1))

      let trifilt2 = TriFilterbank<Float>(
        numFilters: 23,
        filterLength: 33,
        sampleFrequency: 8000,
        lowFrequency: 300.0,
        highFrequency: 3700.0,
        frequencyScale: FrequencyScale.mel)

      let input2: [Float] = [
        0.0461713, 0.0971317, 0.823457, 0.694828, 0.317099, 0.950222, 0.0344460,
        0.438744,  0.381558,  0.765516, 0.795199, 0.186872, 0.489764, 0.445586,
        0.646313,  0.709364,  0.754686, 0.276025, 0.679702, 0.655098, 0.162611,
        0.118997,  0.498364,  0.959743, 0.340385, 0.585267, 0.223811, 0.751267,
        0.255095, 0.505957, 0.699076, 0.890903, 0.959291]
      
      // copied from https://github.com/facebookresearch/wav2letter/blob/master/src/feature/test/TriFilterbankTest.cpp#L47
      let matlabout2: [Float] = [
        0.578693, 0.131362, 0.301871, 0.426760, 0.523461, 0.0338169,
        0.285265, 0.311304, 0.424245, 0.714087, 0.680402, 0.267582,
        0.526783, 0.612373, 0.814208, 0.962699, 0.620225, 0.907083,
        0.326320, 0.879130, 1.07004, 0.844134, 0.957356]
      
      let output2 = trifilt2.apply(input2)
      XCTAssertEqual(roundedTo4(output2), roundedTo4(matlabout2))
    }

    func testDerivatives() throws {
      let der1 = Derivatives<Float>(deltaWindow: 4, accWindow: 4)
      let input1: [Float] = (0..<12).map({Float($0)})
      let matlabout1: [Float] = [
        0.0000,     1.0000,     2.0000,     3.0000,     4.0000,     5.0000,
        6.0000,     7.0000,     8.0000,     9.0000,     10.0000,    11.0000,
        0.5000000,  0.6666667,  0.8166667,  0.9333333,  1.0000000,  1.0000000,
        1.0000000,  1.0000000,  0.9333333,  0.8166667,  0.6666667,  0.5000000,
        0.0683333,  0.0780556,  0.0794444,  0.0725000,  0.0527778,  0.0180556,
        -0.0180556, -0.0527778, -0.0725000, -0.0794444, -0.0780556, -0.0683333
      ]
      let output1 = der1.apply(on: input1, numFeatures: 1)
      XCTAssertEqual(roundedTo4(output1), roundedTo4(transposeVec(matlabout1, 3, 12)))


       // Test Case: 2
      //   Derivatives<float> dev2(9, 7);
      //   std::vector<float> input2{
      //       3.827583, 3.975999, 0.9343630, 2.448821, 2.227931,  3.231565,  3.546824,
      //       3.773433, 1.380125, 3.398513,  3.275490, 0.8130586, 0.5949884, 2.491820,
      //       4.798719, 1.701928, 2.926338,  1.119059, 3.756335,  1.275475,  2.529785,
      //       3.495383, 4.454516, 4.796457,  2.736077, 0.6931222, 0.7464700, 1.287541,
      //       4.203586, 1.271410, 4.071424,  1.217624, 4.646318,  1.749918,  0.9829762,
      //       1.255419, 3.080223, 2.366444,  1.758297, 4.154143};
      //   std::vector<float> matlaboutput2{
      //       3.827583,   3.975999,   0.9343630,  2.448821,   2.227931,   3.231565,
      //       3.546824,   3.773433,   1.380125,   3.398513,   3.275490,   0.8130586,
      //       0.5949884,  2.491820,   4.798719,   1.701928,   2.926338,   1.119059,
      //       3.756335,   1.275475,   2.529785,   3.495383,   4.454516,   4.796457,
      //       2.736077,   0.6931222,  0.7464700,  1.287541,   4.203586,   1.271410,
      //       4.071424,   1.217624,   4.646318,   1.749918,   0.9829762,  1.255419,
      //       3.080223,   2.366444,   1.758297,   4.154143,   -0.0783472, -0.0703440,
      //       -0.1002527, -0.1283159, -0.1207580, -0.0744319, -0.0787063, -0.0599186,
      //       -0.0680858, -0.0298600, -0.0306807, -0.0046153, -0.0141285, 0.0135790,
      //       0.0392915,  0.0455732,  0.0259977,  0.0162468,  -0.0216384, 0.0220920,
      //       0.0159542,  0.0143425,  -0.0418714, -0.0117627, 0.0093056,  -0.0307167,
      //       -0.0436951, -0.0566360, -0.0380197, -0.0700912, -0.0431751, -0.0021685,
      //       0.0545093,  0.1177130,  0.1458966,  0.1357510,  0.1204694,  0.1087019,
      //       0.1430639,  0.1260710,  -0.0007462, -0.0001886, 0.0012880,  0.0025709,
      //       0.0043352,  0.0055983,  0.0073248,  0.0093658,  0.0111437,  0.0122183,
      //       0.0118505,  0.0093177,  0.0077131,  0.0067685,  0.0053387,  0.0027080,
      //       0.0005322,  -0.0002259, -0.0021479, -0.0036494, -0.0056067, -0.0061552,
      //       -0.0065865, -0.0057748, -0.0041803, -0.0013468, 0.0018477,  0.0064985,
      //       0.0102782,  0.0132019,  0.0138463,  0.0156723,  0.0171224,  0.0170120,
      //       0.0159708,  0.0139536,  0.0118158,  0.0081756,  0.0046038,  0.0015992};
      //   auto output2 = dev2.apply(input2, 1);
      //   // Implementation should match with matlab for Test case 2.
      //   ASSERT_TRUE(compareVec<float>(output2, transposeVec(matlaboutput2, 3, 40)));
      // }

      // TEST(DerivativesTest, batchingTest) {
      //   int numFeat = 60, frameSz = 20;
      //   auto input = randVec<double>(numFeat * frameSz);
      //   Derivatives<double> dev(6, 7);
      //   auto output = dev.apply(input, numFeat);
      //   ASSERT_EQ(output.size(), input.size() * 3);
      //   for (int i = 0; i < numFeat; ++i) {
      //     std::vector<double> curInput(frameSz), expOutput(frameSz * 3);
      //     for (int j = 0; j < frameSz; ++j) {
      //       curInput[j] = input[j * numFeat + i];
      //       expOutput[j * 3] = output[j * numFeat * 3 + i];
      //       expOutput[j * 3 + 1] = output[j * numFeat * 3 + numFeat + i];
      //       expOutput[j * 3 + 2] = output[j * numFeat * 3 + 2 * numFeat + i];
      //     }
      //     auto curOutput = dev.apply(curInput, 1);
      //     ASSERT_TRUE(compareVec<double>(curOutput, expOutput, 1E-4));
      //   }
      // }
    }

    func testDct() throws {
      let dct1 = Dct<Float>(numFilters: 9, numCeps: 6)
      let input1 = [Float](repeating: 1.0, count: 9)
      let matlabout1: [Float] = [4.24264, 0.0, 0.0, 0.0, 0.0, 0.0]
      let output1 = dct1.apply(on: input1)
      XCTAssertEqual(roundedTo4(output1), roundedTo4(matlabout1))

      let dct2 = Dct<Float>(numFilters: 40, numCeps: 23)
      let input2: [Float] = [
        3.827583, 3.975999, 0.9343630, 2.448821, 2.227931,  3.231565,  3.546824,
        3.773433, 1.380125, 3.398513,  3.275490, 0.8130586, 0.5949884, 2.491820,
        4.798719, 1.701928, 2.926338,  1.119059, 3.756335,  1.275475,  2.529785,
        3.495383, 4.454516, 4.796457,  2.736077, 0.6931222, 0.7464700, 1.287541,
        4.203586, 1.271410, 4.071424,  1.217624, 4.646318,  1.749918,  0.9829762,
        1.255419, 3.080223, 2.366444, 1.758297, 4.154143
      ]

      let matlabout2: [Float] = [
        23.03049,    0.7171224,  0.09039740, 0.5560513, 1.210070,  -0.6701894,
        -0.7615307,  0.1116579,  1.157483,   -2.012746, 2.964205,  2.444191,
        -0.4926429,  -0.1332636, 1.275104,   0.2767147, 0.2781188, 2.661390,
        -0.03644234, -2.326455, -0.1963445, -1.229159, 2.124846
      ]

      let out2 = dct2.apply(on: input2)
      XCTAssertEqual(roundedTo4(out2), roundedTo4(matlabout2))

      // TODO: batching test
      // TEST(DctTest, batchingTest) {
      //   int F = 16, C = 10, B = 15;
      //   auto input = randVec<double>(F * B);
      //   auto dct = Dct<double>(F, C);
      //   auto output = dct.apply(input);
      //   ASSERT_EQ(output.size(), C * B);
      //   for (int i = 0; i < B; ++i) {
      //     std::vector<double> curInput(F), expOutput(C);
      //     std::copy(
      //         input.data() + i * F, input.data() + (i + 1) * F, curInput.data());
      //     std::copy(
      //         output.data() + i * C, output.data() + (i + 1) * C, expOutput.data());
      //     auto curOutput = dct.apply(curInput);
      //     ASSERT_TRUE(compareVec<double>(curOutput, expOutput, 1E-10));
      // }
    }

    func testCeplifter() throws {
      let cep1 = Ceplifter<Float>(numFilters: 25, lifterParam: 22.0)
      let input1 = [Float](repeating: 1.0, count: 25)
      let matlabout1: [Float] = [
        1,        2.565463, 4.099058,   5.569565,  6.947048, 8.203468, 9.313245,
        10.25378, 11.00595, 11.55442,   11.88803,  12,       11.88803, 11.55442,
        11.00595, 10.25378, 9.313245,   8.203468,  6.947048, 5.569565, 4.099058,
        2.565463, 1.000000, -0.5654632, -2.0990581
      ]

      let output1 = cep1.apply(on: input1)
      XCTAssertEqual(roundedTo4(output1), roundedTo4(matlabout1))

      let cep2 = Ceplifter<Float>(numFilters: 40, lifterParam: 13)
      let input2: [Float] = [
        3.827583, 3.975999, 0.9343630, 2.448821, 2.227931,  3.231565,  3.546824,
        3.773433, 1.380125, 3.398513,  3.275490, 0.8130586, 0.5949884, 2.491820,
        4.798719, 1.701928, 2.926338,  1.119059, 3.756335,  1.275475,  2.529785,
        3.495383, 4.454516, 4.796457,  2.736077, 0.6931222, 0.7464700, 1.287541,
        4.203586, 1.271410, 4.071424,  1.217624, 4.646318,  1.749918,  0.9829762,
        1.255419, 3.080223, 2.366444, 1.758297, 4.154143
      ]
      let matlabout2: [Float] = [
        3.82758300,   10.1608714,  3.75679389,  13.0039674,  14.1460142,
        22.8717424,   26.4330877,  28.1219157,  9.76798039,  21.5785018,
        17.3938256,   3.26906521,  1.52052368,  2.49182000,  -2.66593706,
        -3.43908696,  -9.68704871, -4.86722976, -19.0731875, -6.95466478,
        -13.7939251,  -17.7481762, -19.3744501, -15.8776985, -5.52879248,
        -0.385065298, 0.746470000, 3.29037774,  16.9013608,  6.75156506,
        25.8510797,   8.61786241,  34.6271852,  13.0414523,  6.95711783,
        7.97115128, 16.3568998, 9.51476285, 4.49341909, 4.15414300
      ]

      let out2 = cep2.apply(on: input2)
      XCTAssertEqual(roundedTo4(out2), roundedTo4(matlabout2))

      // TODO: batching test
    }

    func testMfcc() throws {
      let (wavInput, _) = loadSound(filename)

      var htkFeatures: [Float] = []
      let htkFile = try! String(contentsOfFile: "./Tests/data/sa1-mfcc.htk")
      for entry in htkFile.components(separatedBy: ["\n", "\t"]) {
        if let f = Float(entry) {
          htkFeatures.append(f)
        }
      }
      XCTAssert(htkFeatures.count > 0)

      var params = FeatureParams()
      params.samplingFreq = 16000;
      params.lowFreqFilterbank = 0;
      params.highFreqFilterbank = 8000;
      params.zeroMeanFrame = true;
      params.numFilterbankChans = 20;
      params.numCepstralCoeffs = 13;
      params.useEnergy = false;
      params.rawEnergy = false;
      params.zeroMeanFrame = false;
      params.usePower = false;
      let mfcc = Mfcc<Float>(params: params)
      var feat = mfcc.apply(on: wavInput)
    
      XCTAssertEqual(feat.count, htkFeatures.count);
      XCTAssert(feat.count % 39 == 0)

      let numFrames = feat.count / 39

      // HTK keeps C0 at last position. adjust accordingly.
      let featCopy = feat.copy()
      for f in 0..<numFrames {
        for i in 1..<39 {
          let newVal = feat[f * 39 + i]
          feat[f * 39 + i - 1] = newVal
        }
        feat[f * 39 + 12] = featCopy[f * 39 + 0];
        feat[f * 39 + 25] = featCopy[f * 39 + 13];
        feat[f * 39 + 38] = featCopy[f * 39 + 26];
      }
      var sum: Double = 0.0
      var max: Double = 0.0
      for i in 0..<feat.count {
        let curDiff = Double((feat[i] - htkFeatures[i]).abs())
        sum = sum + curDiff
        if max < curDiff {
          max = curDiff
        }
      }

      let avg = sum / Double(feat.count)
      print("Max diff across all dimensions: \(max)") // 0.325853
      print("Avg diff across all dimensions: \(avg)") // 0.00252719
    }

    static var allTests = [
        ("testLoadSound", testLoadSound),
        ("testPowerSpectrum", testPowerSpectrum),
        ("testPreEmphasis", testPreEmphasis),
        ("testTriFilterbank", testTriFilterbank),
        ("testDerivatives", testDerivatives),
        ("testDct", testDct),
        ("testCeplifter", testCeplifter),
        ("testMfcc", testMfcc)
    ]
}