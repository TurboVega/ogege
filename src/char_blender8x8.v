/*
 * char_blender8x8.v
 *
 * This module blends a single pixel of a character with the background color
 * and outputs the resulting color. The character pixel is based on the given
 * row and column within the character cell.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module char_blender8x8 (
	input  wire [7:0] i_char,
	input  wire [2:0] i_row,
	input  wire [2:0] i_column,
    input  wire [11:0] i_bg_color,
    input  wire [11:0] i_fg_color,
	output wire [11:0] o_color
);

    wire [2:0] char_alpha;

    char_gen8x8 char_gen_inst (
        .i_char(i_char),
        .i_row(i_row),
        .i_column(i_column),
        .o_alpha(char_alpha)
    );

    color_blender blender (
        .i_bg_color(i_bg_color),
        .i_fg_color(i_fg_color),
        .i_fg_alpha(char_alpha),
        .o_color(o_color)
    );

endmodule
