/*
 * char_gen8x8.v
 *
 * This module looks up a character in the font table, and outputs a single pixel
 * for that character, in terms of its alpha code only, based on the given
 * row and column within the character cell.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module char_gen8x8 (
	input  wire i_clk,
	input  wire [7:0] i_char,
	input  wire [2:0] i_row,
	input  wire [2:0] i_column,
	output reg  [2:0] o_alpha
);

	// The items in this array are arranged as if it were a 3D array:
	//
	// glyphs[character code][character scan row][character scan column]
	//           0..255               0..7               0..7
	//
	// Total number of alpha values is 256*8*8 = 16384.
	//
    reg [2:0] glyphs[0:16383];

	wire [2:0] next_column;
	assign next_column = (i_column == 0 ? 7 : i_column - 1);

    initial
        $readmemb("../font/font8x8.bits", glyphs, 0, 16383);

	always @(posedge i_clk) begin
		o_alpha <= glyphs[{i_char, i_row, next_column}];
	end

endmodule
