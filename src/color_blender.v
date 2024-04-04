/*
 * color_blender.v
 *
 * This module blends the individual color components (red, green, and blue)
 * of a background color and a foreground color, using the given alpha code,
 * and outputs the resulting color.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module color_blender (
	input wire [11:0] i_bg_color,
	input wire [11:0] i_fg_color,
	input wire [2:0] i_fg_alpha,
	output logic [11:0] o_color
);

component_blender blend_r (
	.i_bg_color(i_bg_color[11:8]),
	.i_fg_color(i_fg_color[11:8]),
	.i_fg_alpha(i_fg_alpha),
	.o_color(o_color[11:8])
);

component_blender blend_g (
	.i_bg_color(i_bg_color[7:4]),
	.i_fg_color(i_fg_color[7:4]),
	.i_fg_alpha(i_fg_alpha),
	.o_color(o_color[7:4])
);

component_blender blend_b (
	.i_bg_color(i_bg_color[3:0]),
	.i_fg_color(i_fg_color[3:0]),
	.i_fg_alpha(i_fg_alpha),
	.o_color(o_color[3:0])
);

endmodule
