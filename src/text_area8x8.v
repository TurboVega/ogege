/*
 * text_area8x8.v
 *
 * This module uses a character from the text area, and outputs a single pixel
 * for that character, blending it over the given background, based on the given
 * screen position (scan row and column), and the text area scroll position. The
 * text cell character glyph, with its foreground color, is first blended over
 * the text cell background color, and then that intermediate color is blended
 * over the given background color. 
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module text_area8x8 (
	input  wire [8:0] i_scan_row,
	input  wire [9:0] i_scan_column,
	input  wire [11:0] i_bg_color,
	output wire [11:0] o_color
);

	// The color palettes each hold 16 colors at 12 bits each (4 bits per
	// color component), since 12 bits is all that the board supports.
	// The default palettes are both set to EGA colors, from this site:
	//   https://moddingwiki.shikadi.net/wiki/EGA_Palette
	//
	
	reg [11:0] fg_palette_color[0:15] =
	{
		12'h000, 12'h00A, 12'h0A0, 12'h0AA,
		12'hA00, 12'hA0A, 12'hA50, 12'hAAA,
		12'h555, 12'h55F, 12'h5F5, 12'h5FF,
		12'hF55, 12'hF5F, 12'hFF5, 12'hFFF
	};

	reg [11:0] bg_palette_color[0:15] =
	{
		12'h000, 12'h00A, 12'h0A0, 12'h0AA,
		12'hA00, 12'hA0A, 12'hA50, 12'hAAA,
		12'h555, 12'h55F, 12'h5F5, 12'h5FF,
		12'hF55, 12'hF5F, 12'hFF5, 12'hFFF
	};

    // The scroll offsets default to zero, which means that the upper-left
	// visible pixel is the upper-left pixel in the text cell for text row 0
	// and text column 0.
	reg [4:0] reg_scroll_x_offset = 4'd0;
	reg [4:0] reg_scroll_y_offset = 4'd0;

	// The text area alpha determines how the entire text area is
	// blended onto the given background.

	reg [2:0] reg_text_area_alpha = 3'b011; // 50%

	// The items in this array are arranged as if it were a 3D array:
	// With 8x8 pixel cells on a 640x480 screen, there is enough room
	// to show 80x60 characters (60 rows of 80 columns). In order to
	// support smooth scrolling of the text area, there are 84x64 cells
	// in this array. This allows the application to fill invisible cells
	// while visible cells are being scrolled.
	//
	// cells[text column][text row]
	//         0..83        0..63
	//
	// Total number of text cells is 84*64 = 5376.
	//
	// The format of each cell is:
	//
	// FG palette index: 4 bits
	// BG palette index: 4 bits
	// Character code: 8 bits
	//
    reg [15:0] cells[0:5375];

	wire [8:0] adjusted_scan_row;
	wire [9:0] adjusted_scan_column;
	wire [8:0] text_cell_row;
	wire [9:0] text_cell_column;
	wire [8:0] cell_scan_row;
	wire [9:0] cell_scan_column;
	wire [15:0] cell_value;
	wire [11:0] cell_fg_color_index;
	wire [11:0] cell_bg_color_index;
	wire [7:0] cell_char_code;
	wire [11:0] char_fg_color;
	wire [11:0] char_bg_color;
	wire [11:0] intermediate_color;

	assign adjusted_scan_row = i_scan_row + reg_scroll_y_offset;
	assign adjusted_scan_column = i_scan_column + reg_scroll_x_offset;
	assign text_cell_row = adjusted_scan_row[8:3];
	assign text_cell_column = adjusted_scan_column[9:3];
	assign cell_scan_row = text_cell_row[2:0];
	assign cell_scan_column = text_cell_column[2:0];

	assign cell_value = cells[{text_cell_column, text_cell_row}];
	assign cell_fg_color_index = cell_value[15:12];
	assign cell_bg_color_index = cell_value[11:8];
	assign cell_char_code = cell_value[7:0];
	assign char_fg_color = fg_palette_color[cell_fg_color_index];
	assign char_bg_color = bg_palette_color[cell_bg_color_index];

	char_blender8x12 char_blender_inst (
		.i_char(cell_char_code),
		.i_row(cell_scan_row),
		.i_column(cell_scan_column),
		.i_fg_color(char_fg_color),
		.i_bg_color(char_bg_color),
		.o_color(intermediate_color)
	);

    color_blender blender (
        .i_bg_color(i_bg_color),
        .i_fg_color(intermediate_color),
        .i_fg_alpha(reg_text_area_alpha),
        .o_color(o_color)
    );

endmodule
