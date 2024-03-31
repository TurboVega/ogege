# Graphics Engine Memory Map

This document details the memory map (layout) of the GateMate BRAM,
as used by the graphics engine. The GateMate has a total of 160 KB of BRAM.

## Overall Memory Allocation

In general, memory is allocated into these main sections:

|Purpose|Size (bytes)|Usage|
|-------|----:|-----|
|Frame Buffer|76800|640x480 or 320x240 pixels|
|Color Palette|768|64 colors at 12 bits each|
|Character Array|7200|80x60 or 40x30 characters, at 12 bits each|
|Small Font|4096|256 characters of 8x8x2 bit transparency levels|
|Large Font|8192|256 characters of 16x8x2 bit transparency levels|

## Frame Buffer
### 640x480 mode
Echo byte holds two pixels.
Pixel format is AAAABBBB where AAAA is the palette index of the first pixel and BBBB is the palette index of the second pixel. The first pixel has an even X coordinate, and the second pixel has an odd X coordinate.

### 320x240 mode
Each byte holds one pixel, which is the palette index.

## Color Palette
There are 64 palette entries, each with 4 bits per color component (red, green, and blue). Each palette color is one of 4096 possible colors.

## Character Array
Each character is composed of a 4 bit palette index and an 8 bit font ROM index. Characters can be shown in 16 colors, according to the current palette.

## Small Font
Each pixel in the 8x8 pixel character is defined as 64 2-bit transparency values. This allows characters to be shown with some amount of anti-aliasing.

## Large Font
Each pixel in the 16x8 pixel character is defined as 128 2-bit transparency values. This allows characters to be shown with some amount of anti-aliasing.

[Home](README.md)
