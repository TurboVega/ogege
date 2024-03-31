# Graphics Engine Memory Map

This document details the memory map (layout) of the GateMate BRAM,
as used by the graphics engine. The GateMate has a total of 160 KB of BRAM.

# Overall Memory Allocation

In general, memory is allocated into these main sections:

|Purpose|Size (bytes)|Usage|
|-------|----:|-----|
|Frame Buffer|76800|640x480 or 320x240 pixels|
|Character Array|7200|80x60 or 40x30 characters, at 12 bits each|
|Small Font ROM|4096|256 characters of 8x8x2 bit transparency levels|
|Large Font ROM|8192|256 characters of 16x8x2 bit transparency levels|

# 640x480 Mode


# 320x240 Mode
