# AudioFeature
This is a Swift port of the [featurization portion of FAIR's wav2letter++](https://github.com/facebookresearch/wav2letter/tree/master/src/feature).  It includes implementations & tests for PowerSpectrum, Mfsc & Mfcc.

# Notes
This uses the excellent [BaseMath](https://github.com/jph00/BaseMath/) and [SwiftyMKL](https://github.com/jph00/SwiftyMKL/).  Adding the following flags to your SwiftPM command will yield the best performance.  (See BaseMath documenation for details)

```-Xswiftc -Ounchecked -Xcc -ffast-math -Xcc -O3 -Xcc -march=native```

It also relies on libfftw, libsndfile and MKL, so you will need to have those three libraries installed and discoverable within your system.  The very easiest way to install MKL is to clone & build [SwiftyMKL](https://github.com/jph00/SwiftyMKL/), which will download and uzip the appropriate Intel libraries into a subdirectory.  You can add ```-Xcc -I``` and ```-Xlinker -L``` flags to your build command and set ```LD_LIBRARY_PATH``` so the files can be included & linked by SwiftPM.

# Benchmarks
To run benchmark for MFCC and MFSC: 

```$ swift run -Xswiftc -Ounchecked -Xcc -ffast-math -Xcc -O3 -Xcc -march=native -c release```
