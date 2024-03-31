# Olimex GateMateA1-EVB Graphics Engine (OGEGE)

This repository contains Verilog code to drive the VGA output of the Olimex GateMateA1-EVB
board. The GM1A-EVB board combines an RP2040 microcontroller with a GateMate1 FPGA (a.k.a., the Cologne Chip or "CC"), and other components, such as PSRAM.

As experimental development progresses, the hope is to support such functions as the following:

* 640x480 and 320x240 pixel resolutions
* 12-bit color (4 bits each for R, G, & B)
* Color palette indexing
* Transparency (multiple levels)
* Horizontal and vertical scrolling
* Sprites and collision detection
* Bit-block transfers (blitting)
* Communication between RP2040 and GM FPGA

This repository uses some code and/or concepts from these repositories:

https://github.com/goran-mahovlic/GateMate_demos

https://github.com/trabucayre/GateMate_demos

https://github.com/goran-mahovlic/apple-one/tree/master/boards/olimex_gatemate

The board description and other information may be found here:

https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware

Information about the FPGA may be found here:

https://www.colognechip.com/programmable-logic/gatemate/

Information about the RP2040 may be found here:

https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf

