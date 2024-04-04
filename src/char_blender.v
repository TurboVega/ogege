/*
 * char_blender.v
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module char_blender (
	input  wire i_clk,
	input  wire	i_rst,
	input  wire i_blank,
	input  wire [7:0] i_char,
	input  wire [2:0] i_column,
	input  wire [2:0] i_row,
    input  wire [11:0] i_bg_color,
	output wire [11:0] o_color
);

    wire [2:0] char_alpha;
    wire [11:0] char_color;

    char_gen char_gen_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_blank(i_blank),
        .i_char(i_char),
        .i_column(i_column),
        .i_row(i_row),
        .o_alpha(char_alpha),
        .o_color(char_color)
    );

    color_blender blend_r (
        .i_bg_color(i_bg_color),
        .i_fg_color(char_color),
        .i_fg_alpha(char_alpha),
        .o_color(o_color)
    );

endmodule
