/*
 * char_gen.v
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module char_gen (
	input  wire i_clk,
	input  wire	i_rst,
	input  wire i_blank,
	input  wire [7:0] i_char,
	input  wire [2:0] i_column,
	input  wire [2:0] i_row,
	output wire [2:0] o_alpha,
	output wire [11:0] o_color
);

	assign o_alpha = i_column;
	assign o_color = (i_blank) ? 12'b0 :
		i_row == 0 || i_column == 0 ? 12'b0 :
		{i_char, i_row, i_column};

endmodule
