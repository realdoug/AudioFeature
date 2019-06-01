# AudioFeature
This is a Swift port of the [featurization portion of FAIR's wav2letter++](https://github.com/facebookresearch/wav2letter/tree/master/src/feature), including implementations & tests for PowerSpectrum, Mfsc & Mfcc.  These functions are part of a larger system described in [their 2018 paper](https://arxiv.org/abs/1812.07625).

# Background
I could not find a good spectrogram implementation in Swift, so I decided to port the /feature section of W2l.  This will likely never be as fast as the C++ version, but I'm hoping to get as close as I can to performance parity.

# Usage/Notes
This uses the awesome [BaseMath](https://github.com/jph00/BaseMath/) and [SwiftyMKL](https://github.com/jph00/SwiftyMKL/).  Adding the following flags to your SwiftPM command will yield the best performance.  (See BaseMath documenation for details).

```-Xswiftc -Ounchecked -Xcc -ffast-math -Xcc -O2 -Xcc -march=native```

You will also need to have [fftw](http://fftw.org/), [libsndfile](http://www.mega-nerd.com/libsndfile/) and [MKL](https://software.intel.com/en-us/mkl) installed and visible to the compiler & linker.  [The SwiftyMKL Makefile](https://github.com/jph00/SwiftyMKL/blob/master/Makefile) has a target that will download and uzip the appropriate Intel libraries for convenience.

```Mfsc``` and ```Mfcc``` support Double and Float.  For example:

```swift
let mfsc = Mfsc<Float>()
mfsc.apply(on: input)

let mfcc Mfcc<Double>()
mfcc.apply(on: input)
```

# Benchmarks
To run the benchmark for MFCC: 

```$ swift run -Xswiftc -Ounchecked -Xcc -ffast-math -Xcc -O3 -Xcc -march=native -c release```
