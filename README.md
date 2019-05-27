# AudioFeature
This is a Swift port of the [featurization portion of FAIR's wav2letter++](https://github.com/facebookresearch/wav2letter/tree/master/src/feature).

# Notes
Wav2letter uses libfftw, libsndfile and MKL, so you will need to have these three libraries installed and discoverable within your system.  The very easiest way to install MKL is to clone & build [SwiftyMKL](https://github.com/jph00/SwiftyMKL/), which will download and uzip the appropriate Intel libraries into a subdirectory.  You can add ```-Xcc -I``` and ```-Xlinker -L``` flags to your build command and set ```LD_LIBRARY_PATH``` so the files can be included & linked by SwiftPM.

# Status
This project has accurate implementations & tests for PowerSpectrum, Mfsc & Mfcc.  

To run benchmark for MFCC and MFSC: 
```swift run -Xswiftc -Ounchecked -Xcc -ffast-math -Xcc -O3 -Xcc -march=native -c release```
