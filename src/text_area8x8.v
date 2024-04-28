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
    input  wire i_rst,
    input  wire i_pix_clk,
    input  wire i_blank,
    input  wire i_cmd_clk,
    input  wire [31:0] i_cmd_data,
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
    reg [11:0] reg_fg_palette_color[0:15];
    reg [11:0] reg_bg_palette_color[0:15];

    // The scroll offsets default to zero, which means that the upper-left
    // visible pixel is the upper-left pixel in the text cell for text row 0
    // and text column 0.
    //
    reg [9:0] reg_scroll_x_offset;
    reg [8:0] reg_scroll_y_offset;

    // The text area alpha determines how the entire text area is
    // blended onto the given background.
    //
    reg [2:0] reg_text_area_alpha = 3'b110; // 100%

    // The items in this array are arranged as if it were a 2D array:
    // With 8x8 pixel cells on a 640x480 screen, there is enough room
    // to show 80x60 characters (60 rows of 80 columns). In order to
    // support smooth scrolling of the text area, there are 84x64 cells
    // in this array. This allows the application to fill invisible cells
    // while visible cells are being scrolled.
    //
    // cells[text column][text row]
    //          0..83       0..63
    //
    // Total number of text cells is 84*64 = 5376.
    //
    // The format of each cell is:
    //
    // FG palette index: 4 bits
    // BG palette index: 4 bits
    // Character code: 8 bits
    //

    reg reg_cmd_in_progress;
    reg reg_wea;
    reg reg_web;
    reg reg_clka;
    wire wire_clkb;
    reg [15:0] reg_dia;
    reg [15:0] reg_dib;
    reg [12:0] reg_addra;
    wire [12:0] wire_addrb;
    reg [15:0] reg_doa;
    reg [15:0] reg_dob;

    text_array8x8 text_array8x8_inst (
        .wea(reg_wea),
        .web(reg_web),
        .clka(reg_clka),
        .clkb(wire_clkb),
        .dia(reg_dia),
        .dib(reg_dib),
        .addra(reg_addra),
        .addrb(wire_addrb),
        .doa(reg_doa),
        .dob(reg_dob)
    );

    initial begin
        $readmemh("../font/default_palette.bits", reg_fg_palette_color, 0, 15);
        $readmemh("../font/default_palette.bits", reg_bg_palette_color, 0, 15);
    end

    reg [5:0] reg_cursor_row;
    reg [6:0] reg_cursor_column;

    wire [9:0] adjusted_scan_row;
    wire [10:0] adjusted_scan_column;
    wire [9:0] wrapped_scan_row;
    wire [10:0] wrapped_scan_column;

    wire [5:0] text_cell_row;
    wire [6:0] text_cell_column;
    wire [2:0] cell_scan_row;
    wire [2:0] cell_scan_column;
    wire [15:0] cell_value;
    wire [3:0] cell_fg_color_index;
    wire [3:0] cell_bg_color_index;
    wire [7:0] cell_char_code;
    wire [11:0] char_fg_color;
    wire [11:0] char_bg_color;
    wire [11:0] intermediate_color;

    assign adjusted_scan_row ={1'b0,i_scan_row} + {1'b0,reg_scroll_y_offset};
    assign wrapped_scan_row = adjusted_scan_row >= 672 ?
        adjusted_scan_row - 672 : adjusted_scan_row;

    assign adjusted_scan_column = {1'b0,i_scan_column} + {1'b0,reg_scroll_x_offset};
    assign wrapped_scan_column = adjusted_scan_column >= 512 ?
        adjusted_scan_column - 512 : adjusted_scan_column;

    assign text_cell_row = wrapped_scan_row[8:3];
    assign text_cell_column = wrapped_scan_column[9:3];
    assign cell_scan_row = wrapped_scan_row[2:0];
    assign cell_scan_column = wrapped_scan_column[2:0];

    assign cell_value = reg_dob;
    assign cell_fg_color_index = cell_value[15:12];
    assign cell_bg_color_index = cell_value[11:8];
    assign cell_char_code = cell_value[7:0];
    assign char_fg_color = reg_fg_palette_color[cell_fg_color_index];
    assign char_bg_color = reg_bg_palette_color[cell_bg_color_index];

    assign wire_addrb = {text_cell_column, text_cell_row};
    //assign reg_web = 0;
    assign wire_clkb = i_pix_clk;

    char_blender8x8 char_blender_inst (
        .i_clk(i_pix_clk),
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

/*
    Text Area commands:

    33222222222211111111110000000000
    10987654321098765432109876543210
    --------------------------------
    0001xxxxxxxxxxxxxxxxxxXXXXXXXXXX    Set horizontal scroll position (X offset)
    0010xxxxxxxxxxxxxxxxxxxYYYYYYYYY    Set vertical scroll position (Y offset)
    0011xxxYYYYYYYYYxxxxxxXXXXXXXXXX    Set horizontal and vertical scroll positions (X and Y offsets)
    0100xxxxxxxxxxxxIIIIRRRRGGGGBBBB    Set foreground palette color for index (RGB)
    0101xxxxxxxxxxxxIIIIRRRRGGGGBBBB    Set background palette color for index (RGB)
    0110xxxxxxxxxxxxxxxxxxxxxxxxxAAA    Set text area alpha value
    0111xxxxxxxxxxxxxCCCCCCCxxRRRRRR    Set cursor position (row and column)
    1000xxxxxxxxxxxxFFFFBBBBCCCCCCCC    Set cell attributes (FG index, BG index, Character code)
    1001xxxxxxxxxxxxxxxxxxxxxxxxFFFF    Set cell foreground (FG index)
    1010xxxxxxxxxxxxxxxxxxxxxxxxBBBB    Set cell background (BG index)
    1011xxxxxxxxxxxxxxxxxxxxCCCCCCCC    Set cell character code
*/

    always @(posedge i_rst or posedge i_cmd_clk) begin
        if (i_rst) begin
            reg_scroll_x_offset <= 0;
            reg_scroll_y_offset <= 0;
            reg_cmd_in_progress <= 0;
            reg_wea <= 0;
            reg_web <= 0;
            reg_clka <= 0;
            //wire_clkb <= 0;
            reg_dia <= 0;
            reg_dib <= 0;
            reg_addra <= 0;
            //reg_addrb <= 0;
        end else if (reg_cmd_in_progress) begin
            reg_cmd_in_progress <= 0;
        end else begin
            reg_cmd_in_progress <= 1;
            case (i_cmd_data[31:28])
                4'b0001: reg_scroll_x_offset <= i_cmd_data[9:0];
                4'b0010: reg_scroll_y_offset <= i_cmd_data[8:0];
                4'b0011: begin
                            reg_scroll_x_offset <= i_cmd_data[9:0];
                            reg_scroll_y_offset <= i_cmd_data[24:16];
                         end
                4'b0100: reg_fg_palette_color[i_cmd_data[15:12]] <= i_cmd_data[11:0];
                4'b0101: reg_bg_palette_color[i_cmd_data[15:12]] <= i_cmd_data[11:0];
                4'b0110: reg_text_area_alpha <= i_cmd_data[2:0];
                4'b0111: begin
                            reg_cursor_row <= i_cmd_data[24:16];
                            reg_cursor_column <= i_cmd_data[9:0];
                         end
                4'b1000: begin
                            reg_addra = {reg_cursor_column, reg_cursor_row};
                            reg_dia <= i_cmd_data[15:0];
                            reg_wea <= 1;
                            reg_clka <= 1;
                         end
                4'b1001: begin
                            reg_addra = {reg_cursor_column, reg_cursor_row};
                            //reg_cells[{reg_cursor_column, reg_cursor_row}][15:12] <= i_cmd_data[3:0];
                         end
                4'b1010: begin
                            reg_addra = {reg_cursor_column, reg_cursor_row};
                            //reg_cells[{reg_cursor_column, reg_cursor_row}][11:8] <= i_cmd_data[3:0];
                         end
                4'b1011: begin
                            reg_addra = {reg_cursor_column, reg_cursor_row};
                            //reg_cells[{reg_cursor_column, reg_cursor_row}][7:0] <= i_cmd_data[7:0];
                         end
            endcase
        end
    end

endmodule
