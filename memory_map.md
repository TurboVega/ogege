# Graphics Engine Memory Map

This document details the memory map (layout) of the GateMate BRAM,
as used by the graphics engine. The GateMate has a total of 160 KB of BRAM.

<i>All of this information is under design and is subject to change!</i>

## Overall Memory Allocation

In general, memory is allocated into these main sections (numbers may be approximate, depending on how physical arrangement must be done):

|Purpose|Size (bytes)|Usage|
|-------|----:|-----|
|Frame Buffer|76800|640x480 or 320x240 pixels|
|Text FG Color Palette|24|16 colors at 12 bits each|
|Text BG Color Palette|24|16 colors at 12 bits each|
|Main Color Palette|384|256 colors at 12 bits each|
|Small Text Array|9600|80x60 or 40x30 characters, at 16 bits each|
|Large Text Array|2250|40x30 or 20x15 characters, at 15 bits each|
|Small Font|6144|256 characters of 8x8x3 bit alpha levels|
|Large Font|6144|128 characters of 16x8x3 bit alpha levels|
|Sprite Control|640|Control settings for sprites|
|Sprite Data|62470|Pixel data for sprites|
|Total|163840|Total size of used BRAM|

## Frame Buffer

The frame buffer is considered to be the background
image; therefore, there is no transparency. The
entire background must be 100% opaque. The frame
buffer and sprites share the same color palette.

### 640x480 mode
Each frame buffer byte holds two pixels.
Pixel format (as bits) is AAAABBBB where AAAA is the palette index of the first pixel and BBBB is the palette index of the second pixel. The first pixel has an even X coordinate, and the second pixel has an odd X coordinate.

### 320x240 mode
Each byte holds one pixel, which is the palette index.

## Text FG Color Palette
There are 16 text foreground palette entries, each with 4 bits per color component (red, green, and blue). Each palette color is one of 4096 possible colors.

## Text BG Color Palette
There are 16 text background palette entries, each with 4 bits per color component (red, green, and blue). Each palette color is one of 4096 possible colors.

## Main Color Palette
There are 64 main palette entries, each with 4 bits per color component (red, green, and blue). Each palette color is one of 4096 possible colors.
The background image and sprites both use the main
color palette

## Small Text Array
Each character is composed of a 4 bit palette index and an 8 bit font array index. Characters can be shown in 16 foreground colors, distinct from the 16 background colors, according to the current palette.

## Large Text Array
Each character is composed of a 4 bit palette index and a 7 bit font array index. Characters can be shown in 16 foreground colors, distinct from the 16 background colors, according to the current palette.

## Small Font
Each pixel in the 8x8 pixel character is defined as a 3-bit alpha value. This allows characters to be shown with some amount of anti-aliasing. Each of the
256 characters in the font may be redefined by the
application at runtime, to define new characters.

## Large Font
Each pixel in the 16x8 pixel character is defined as a 3-bit alpha value. This allows characters to be shown with some amount of anti-aliasing. Each of the
128 characters in the font may be redefined by the
application at runtime, to define new characters.

## Sprite Control
There may be up to 128 sprites on the screen at one time. Each one is controlled by a sprite control table entry (element) with the following fields:

|Field|Size (bits)|Description|
|---|---|--|
|Active|1|Whether the sprite is active|
|Visible|1|Whether the sprite is drawn|
|Sprite Group|4|Index of group to which sprite belongs|
|Height|2|Code selecting height of sprite|
|Width|2|Code selecting width of sprite|
|X Position|11|Signed X coordinate of sprite
|Y Position|10|Signed Y coordinate of sprite
|Flip Horizontal|1|Whether to flip the pixels horizontally|
|Flip Vertical|1|Whether to flip the pixels vertically|
|Pixel Data|16|Index of pixel data for sprite|
|Reserved|1|Future use|
|Total|40|5 bytes|

Active: a sprite that is active may be involved in collisions, even if it is not visible, to allow for hidden dangers.

Visible: a sprite that is visible is drawn; however, if all of its pixels are 0% opaque (100% transparent), it will not be seen.

Sprit Group: sprites may be arranged into 16 groups, for global overrides to the Active and Visible flags, and for collision detection purposes.

Height and Width: Sprite size is determined by the following set of 2-bit codes:

* 00B (0H) - 8 pixels
* 01B (1H) - 16 pixels
* 10B (2H) - 32 pixels
* 11B (3H) - 64 pixels

X Position: the X position of a sprite ranges from -1024 to +1023, with the visible range (of any pixel) being either 0..639 or 0..319.

Y Position: the Y position of a sprite ranges from -512 to +511, with the visible range (of any pixel) being either 0..479 or 0.239.

Flip Horizontal: the pixels in a sprite may flipped in a left-to-right manner, so that the left-most stored pixel is displayed as the right-most pixel, and
the right-most stored pixel is displayed as the left-most pixel.

Flip Vertical: the pixels in a sprite may flipped in a top-to-bottom manner, so that the top-most stored pixel is displayed as the bottom-most pixel, and
the bottom-most stored pixel is displayed as the top-most pixel.

Data Index: pixel data for sprites is stored in an array, accessed using the pixel data index value.

## Sprite Data
Pixel data for sprites is stored in an array, accessed using the pixel data index value.
Each data element is 10 bits long. There are 3 bits for an alpha level, and 8 bits for a palette color index.

In terms of storage sprites of various sizes consume the following numbers of sprite array bytes (sizes can be thought of as WxH or HxW):

|Size|Pixels|Total Bits|Total Bytes|
|---:|---:|---:|---:|
|8 x 8|64|704|88|
|8 x 16|128|1408|176|
|8 x 32|256|2816|352|
|8 x 64|512|5632|704|
|16 x 16|256|2816|352|
|16 x 32|512|5632|704|
|16 x 64|1024|11264|1408|
|32 x 32|1024|11264|1408|
|32 x 64|2048|22528|2816|
|64 x 64|4096|45056|5632|

## Alpha (opaqueness) Levels

In font characters and in sprite data there a are 3 bits designating the opaqueness (and
corresponding transparency) of each pixel, according
to the following set of codes.

* 000B (0H) - 0% opaque (100% transparent)
* 001B (1H) - 25% opaque (75% transparent)
* 010B (2H) - 33% opaque (67% transparent)
* 011B (3H) - 50% opaque (50% transparent)
* 100B (4H) - 67% opaque (33% transparent)
* 101B (5H) - 75% opaque (25% transparent)
* 110B (6H) - 100% opaque (0% transparent)
* 111B (7H) - reserved

## Graphics Engine Registers

TBD

[Home](README.md)
