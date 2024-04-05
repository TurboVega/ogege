/*
 * char_gen8x12.v
 *
 * This module looks up a character in the font table, and outputs a single pixel
 * for that character, in terms of its alpha code and color, based on the given
 * row and column within the character cell.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module char_gen8x12 (
	input  wire [7:0] i_char,
	input  wire [3:0] i_row,
	input  wire [2:0] i_column,
	output wire [2:0] o_alpha
);

	// The items in this array are arranged as if it were a 3D array:
	// glyphs[character scan row][character code][character scan column]
	//               0..11            0..255              0..7
	//
	// Total number of alpha values is 12*256*8 = 24576.
	//
    reg [2:0] glyphs[0:24575];

    initial
        $readmemb("../font/font8x12.bits", glyphs, 0, 24575);

	assign o_alpha = glyphs[{i_row, i_char, i_column}];

endmodule
