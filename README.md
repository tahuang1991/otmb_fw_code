## OTMB_VIRTEX6
 
 Original author: Jonathan Kubik (UCLA)
 
 Current developers: Yuriy Pakhotin (Texas A&M), Jason Gilmore (Texas A&M)
 
======================================================================

Official firmware for the Optical Trigger MotherBoard (OTMB) for
the ME1/1 station of the CMS muon endcap detector.

This repository contains the source code and default ISE project file:

- otmb_virtex6.xise: Production, ISE 14.5

The difference between "Production" and "Pre-Production" versions is
in the file ./source/otmb_pinout.ucf, where different values for the
parameters "dmb_tx<39>" and "dmb_tx<40>" might be set:

- NET "dmb_tx<40>"	LOC = "W32"; # Production:     I/O_440
- NET "dmb_tx<39>"	LOC = "C9";  # Production:     I/O_441

- NET "dmb_tx<40>"	LOC = "C9";  # Pre-production: I/O_440
- NET "dmb_tx<39>"	LOC = "W32"; # Pre-production: I/O_441

Default version is "Production".

The difference between the ISE 14.5 and 12.4 versions is in the file
./source/cfeb/gtx_rx_buf_bypass.v, where different values for the
parameter "GTX_POWER_SAVE" might be set:

- .GTX_POWER_SAVE (10'b0000010000)  // For ISE 12.4: do not bypass the RX Delay Aligner
- .GTX_POWER_SAVE (10'b0000110000)  // For ISE 14.5: bypass the RX Delay Aligner
 
Default version is ISE 14.5 which allows to bypass the RX Delay Aligner,
thus saving some power consumption.

### Version control
master branch code is used for Run2 operation and the compiled date is 2016-03-16


Starting fro 2016, Yuriy, Jason, Andrew and Tao worked on improving OTMB fw performance and several key new features were added:
 - localized dead time zone in cathode pretriggering 
 - CLCT reuse in ALCT-CLCT matching
 
 
the branch of this version firmware is renamed to 2018OTMBfw on Tao's github.  This version was tested in the 2018, late of Run2. and significant efficinecy improvement is observed in  PU~40 

The ISE used for compiling is 14.7

2019 July 1st: On top of 2018OTMBfw, we compiled one new version, called 2018OTMBfw_clockchange, by changing the main logic clock from tmb_clock0 into clk40

### Simulation
The folder source/simulation contains a test bench, as well as a
file handler and VME emulator, for the OTMB firmware simulation.
