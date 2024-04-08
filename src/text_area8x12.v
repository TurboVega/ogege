/*
 * text_area8x12.v
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

module text_area8x12 (
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
	reg [11:0] fg_palette_color[0:15];
	reg [11:0] bg_palette_color[0:15];

    // The scroll offsets default to zero, which means that the upper-left
	// visible pixel is the upper-left pixel in the text cell for text row 0
	// and text column 0.
	//
	reg [4:0] reg_scroll_x_offset = 4'd0;
	reg [4:0] reg_scroll_y_offset = 4'd0;

	// The text area alpha determines how the entire text area is
	// blended onto the given background.
	//
	reg [2:0] reg_text_area_alpha = 3'b110; // 100%

	// The items in this array are arranged as if it were a 2D array:
	// With 8x12 pixel cells on a 640x480 screen, there is enough room
	// to show 80x40 characters (40 rows of 80 columns). In order to
	// support smooth scrolling of the text area, there are 84x44 cells
	// in this array. This allows the application to fill invisible cells
	// while visible cells are being scrolled.
	//
	// cells[text column][text row]
	//         0..83        0..43
	//
	// Total number of text cells is 84*44 = 3696.
	//
	// The format of each cell is:
	//
	// FG palette index: 4 bits
	// BG palette index: 4 bits
	// Character code: 8 bits
	//
    // Because neither the number of text rows nor the number of text
    // columns is an even power of 2, the array is split into 3 pieces,
    // to make indexing it easier, and to prevent waste.
    //
	// cells[text column][text row]
	//         0..83        0..31       2688 cells
	//         0..83       32..39        672 cells
	//         0..83       40..43        336 cells
    //

    reg [15:0] cells_0_31[0:2687];
    reg [15:0] cells_32_39[0:7];
    reg [15:0] cells_40_43[0:4];

    initial begin
        $readmemh("../font/default_palette.bits", fg_palette_color, 0, 15);
        $readmemh("../font/default_palette.bits", bg_palette_color, 0, 15);
        $readmemh("../font/sample_text8x12_0_31.bits", cells_0_31, 0, 2687);
        $readmemh("../font/sample_text8x12_32_39.bits", cells_32_39, 0, 7);
        $readmemh("../font/sample_text8x12_40_43.bits", cells_40_43, 0, 4);
	end

	wire [8:0] adjusted_scan_row;
	wire [9:0] adjusted_scan_column;
	wire [5:0] text_cell_row_a;
	wire [5:0] text_cell_row_b;
	wire [5:0] text_cell_row_c;
	wire [6:0] text_cell_column;
	wire [3:0] cell_scan_row;
	wire [2:0] cell_scan_column;
	wire [15:0] cell_value;
	wire [3:0] cell_fg_color_index;
	wire [3:0] cell_bg_color_index;
	wire [7:0] cell_char_code;
	wire [11:0] char_fg_color;
	wire [11:0] char_bg_color;
	wire [11:0] intermediate_color;

	assign adjusted_scan_row = i_scan_row + {5'b00000, reg_scroll_y_offset};
	assign adjusted_scan_column = i_scan_column + {6'b000000, reg_scroll_x_offset};
	assign text_cell_row_a = adjusted_scan_row[8:4];
	assign text_cell_row_b = text_cell_row_a - 32;
	assign text_cell_row_c = text_cell_row_b - 8;
	assign text_cell_column = adjusted_scan_column[9:3];
	assign cell_scan_row = adjusted_scan_row[3:0];
	assign cell_scan_column = adjusted_scan_column[2:0];

	assign cell_value = text_cell_row_a < 32 ? cells_0_31[{text_cell_column, text_cell_row_a}] :
                        text_cell_row_a < 40 ? cells_32_39[{text_cell_column, text_cell_row_b[2:0]}] :
                        cells_40_43[{text_cell_column, text_cell_row_c[1:0]}];

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
