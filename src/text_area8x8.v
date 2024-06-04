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
    input  wire i_rd,
    input  wire i_wr,
    input  wire [6:0] i_addr,
    input  wire [7:0] i_data,
    input  wire [8:0] i_scan_row,
    input  wire [9:0] i_scan_column,
    input  wire [11:0] i_bg_color,
    output reg [7:0] o_data,
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
    reg [2:0] reg_text_area_alpha;

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

    reg reg_wea;
    reg reg_web;
    reg reg_clka;
    wire wire_clkb;
    reg [15:0] reg_put_cell;
    reg [15:0] reg_dib;
    reg [12:0] reg_addra;
    wire [12:0] wire_addrb;
    reg [15:0] reg_get_cell;
    reg [15:0] reg_scan_cell;

    text_array8x8 text_array8x8_inst (
        .wea(reg_wea),
        .web(reg_web),
        .clka(reg_clka),
        .clkb(wire_clkb),
        .dia(reg_put_cell),
        .dib(reg_dib),
        .addra(reg_addra),
        .addrb(wire_addrb),
        .doa(reg_get_cell),
        .dob(reg_scan_cell)
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
    assign wrapped_scan_row = adjusted_scan_row >= 512 ?
        adjusted_scan_row - 512 : adjusted_scan_row;

    assign adjusted_scan_column = {1'b0,i_scan_column} + {1'b0,reg_scroll_x_offset};
    assign wrapped_scan_column = adjusted_scan_column >= 672 ?
        adjusted_scan_column - 672 : adjusted_scan_column;

    assign text_cell_row = wrapped_scan_row[8:3];
    assign text_cell_column = wrapped_scan_column[9:3];
    assign cell_scan_row = wrapped_scan_row[2:0];
    assign cell_scan_column = wrapped_scan_column[2:0];

    assign cell_value = reg_scan_cell;
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
    Text Area control register addresses and data:
    (All hex addresses here are offsets from the text controller base address.)

    Addr R W   Value  Purpose
    ---- - - -------- ------------------------------------------------------
     00  r w GGGGBBBB Foreground palette color for index #0 (green & blue)
     01  r w xxxxRRRR Foreground palette color for index #0 (red)
     ..
     1E  r w GGGGBBBB Foreground palette color for index #15 (green & blue)
     1F  r w ----RRRR Foreground palette color for index #15 (red)
     20  r w GGGGBBBB Background palette color for index #0 (green & blue)
     21  r w xxxxRRRR Background palette color for index #0 (red)
     ..
     3E  r w GGGGBBBB Background palette color for index #15 (green & blue)
     3F  r w ----RRRR Background palette color for index #15 (red)
     40  r w XXXXXXXX Horizontal scroll position in pixels (lower 8 bits)
     41  r w ------XX Horizontal scroll position in pixels (upper 2 bits)
     42  r w YYYYYYYY Vertical scroll position in pixels (lower 8 bits)
     43  r w -------Y Vertical scroll position in pixels (upper 1 bit)
     44  r w --RRRRRR Text row index
     45  r w -CCCCCCC Text column index
     46  r w CCCCCCCC Character code index
     47  r w FFFFBBBB Character color palette indexes
     48  r w ----FFFF Character color foreground palette index
     49  r w ----BBBB Character color background palette index
     4A  r w -------- Read/write entire character cell to/from registers
     4B  r w -----AAA Text area alpha value
*/

    logic wr_or_rd; assign wr_or_rd = i_wr | i_rd;

    always @(posedge i_rst or posedge wr_or_rd) begin
        if (i_rst) begin
            reg_scroll_x_offset <= 0;
            reg_scroll_y_offset <= 0;
            reg_wea <= 0;
            reg_web <= 0;
            reg_clka <= 0;
            //wire_clkb <= 0;
            reg_put_cell <= 0;
            reg_dib <= 0;
            reg_addra <= 0;
            //reg_addrb <= 0;
            reg_text_area_alpha <= 3'b110; // 100%
            reg_cursor_row <= 0;
            reg_cursor_column <= 0;
        end else begin
            case (i_addr)
                7'h00: begin
                      if (i_wr) begin
                        reg_fg_palette_color[0][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[0][7:0];
                      end
                    end

                7'h01: begin
                      if (i_wr) begin
                        reg_fg_palette_color[0][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[0][11:8]};
                      end
                    end

                7'h02: begin
                      if (i_wr) begin
                        reg_fg_palette_color[1][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[1][7:0];
                      end
                    end
                7'h03: begin
                      if (i_wr) begin
                        reg_fg_palette_color[1][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[1][11:8]};
                      end
                    end

                7'h04: begin
                      if (i_wr) begin
                        reg_fg_palette_color[2][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[2][7:0];
                      end
                    end

                7'h05: begin
                      if (i_wr) begin
                        reg_fg_palette_color[2][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[2][11:8]};
                      end
                    end

                7'h06: begin
                      if (i_wr) begin
                        reg_fg_palette_color[3][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[3][7:0];
                      end
                    end

                7'h07: begin
                      if (i_wr) begin
                        reg_fg_palette_color[3][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[3][11:8]};
                      end
                    end

                7'h08: begin
                      if (i_wr) begin
                        reg_fg_palette_color[4][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[4][7:0];
                      end
                    end

                7'h09: begin
                      if (i_wr) begin
                        reg_fg_palette_color[4][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[4][11:8]};
                      end
                    end

                7'h0A: begin
                      if (i_wr) begin
                        reg_fg_palette_color[5][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[5][7:0];
                      end
                    end

                7'h0B: begin
                      if (i_wr) begin
                        reg_fg_palette_color[5][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[5][11:8]};
                      end
                    end

                7'h0C: begin
                      if (i_wr) begin
                        reg_fg_palette_color[6][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[6][7:0];
                      end
                    end

                7'h0D: begin
                      if (i_wr) begin
                        reg_fg_palette_color[6][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[6][11:8]};
                      end
                    end

                7'h0E: begin
                      if (i_wr) begin
                        reg_fg_palette_color[7][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[7][7:0];
                      end
                    end

                7'h0F: begin
                      if (i_wr) begin
                        reg_fg_palette_color[7][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[7][11:8]};
                      end
                    end

                7'h10: begin
                      if (i_wr) begin
                        reg_fg_palette_color[8][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[8][7:0];
                      end
                    end

                7'h11: begin
                      if (i_wr) begin
                        reg_fg_palette_color[8][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[8][11:8]};
                      end
                    end

                7'h12: begin
                      if (i_wr) begin
                        reg_fg_palette_color[9][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[9][7:0];
                      end
                    end

                7'h13: begin
                      if (i_wr) begin
                        reg_fg_palette_color[9][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[9][11:8]};
                      end
                    end

                7'h14: begin
                      if (i_wr) begin
                        reg_fg_palette_color[10][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[10][7:0];
                      end
                    end

                7'h15: begin
                      if (i_wr) begin
                        reg_fg_palette_color[10][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[10][11:8]};
                      end
                    end

                7'h16: begin
                      if (i_wr) begin
                        reg_fg_palette_color[11][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[11][7:0];
                      end
                    end

                7'h17: begin
                      if (i_wr) begin
                        reg_fg_palette_color[11][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[11][11:8]};
                      end
                    end

                7'h18: begin
                      if (i_wr) begin
                        reg_fg_palette_color[12][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[12][7:0];
                      end
                    end

                7'h19: begin
                      if (i_wr) begin
                        reg_fg_palette_color[12][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[12][11:8]};
                      end
                    end

                7'h1A: begin
                      if (i_wr) begin
                        reg_fg_palette_color[13][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[13][7:0];
                      end
                    end

                7'h1B: begin
                      if (i_wr) begin
                        reg_fg_palette_color[13][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[13][11:8]};
                      end
                    end

                7'h1C: begin
                      if (i_wr) begin
                        reg_fg_palette_color[14][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[14][7:0];
                      end
                    end

                7'h1D: begin
                      if (i_wr) begin
                        reg_fg_palette_color[14][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[14][11:8]};
                      end
                    end

                7'h1E: begin
                      if (i_wr) begin
                        reg_fg_palette_color[15][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_fg_palette_color[15][7:0];
                      end
                    end

                7'h1F: begin
                      if (i_wr) begin
                        reg_fg_palette_color[15][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_fg_palette_color[15][11:8]};
                      end
                    end

                7'h20: begin
                      if (i_wr) begin
                        reg_bg_palette_color[0][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[0][7:0];
                      end
                    end

                7'h21: begin
                      if (i_wr) begin
                        reg_bg_palette_color[0][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[0][11:8]};
                      end
                    end

                7'h22: begin
                      if (i_wr) begin
                        reg_bg_palette_color[1][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[1][7:0];
                      end
                    end
                7'h23: begin
                      if (i_wr) begin
                        reg_bg_palette_color[1][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[1][11:8]};
                      end
                    end

                7'h24: begin
                      if (i_wr) begin
                        reg_bg_palette_color[2][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[2][7:0];
                      end
                    end

                7'h25: begin
                      if (i_wr) begin
                        reg_bg_palette_color[2][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[2][11:8]};
                      end
                    end

                7'h26: begin
                      if (i_wr) begin
                        reg_bg_palette_color[3][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[3][7:0];
                      end
                    end

                7'h27: begin
                      if (i_wr) begin
                        reg_bg_palette_color[3][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[3][11:8]};
                      end
                    end

                7'h28: begin
                      if (i_wr) begin
                        reg_bg_palette_color[4][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[4][7:0];
                      end
                    end

                7'h29: begin
                      if (i_wr) begin
                        reg_bg_palette_color[4][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[4][11:8]};
                      end
                    end

                7'h2A: begin
                      if (i_wr) begin
                        reg_bg_palette_color[5][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[5][7:0];
                      end
                    end

                7'h2B: begin
                      if (i_wr) begin
                        reg_bg_palette_color[5][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[5][11:8]};
                      end
                    end

                7'h2C: begin
                      if (i_wr) begin
                        reg_bg_palette_color[6][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[6][7:0];
                      end
                    end

                7'h2D: begin
                      if (i_wr) begin
                        reg_bg_palette_color[6][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[6][11:8]};
                      end
                    end

                7'h2E: begin
                      if (i_wr) begin
                        reg_bg_palette_color[7][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[7][7:0];
                      end
                    end

                7'h2F: begin
                      if (i_wr) begin
                        reg_bg_palette_color[7][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[7][11:8]};
                      end
                    end

                7'h30: begin
                      if (i_wr) begin
                        reg_bg_palette_color[8][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[8][7:0];
                      end
                    end

                7'h31: begin
                      if (i_wr) begin
                        reg_bg_palette_color[8][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[8][11:8]};
                      end
                    end

                7'h32: begin
                      if (i_wr) begin
                        reg_bg_palette_color[9][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[9][7:0];
                      end
                    end

                7'h33: begin
                      if (i_wr) begin
                        reg_bg_palette_color[9][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[9][11:8]};
                      end
                    end

                7'h34: begin
                      if (i_wr) begin
                        reg_bg_palette_color[10][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[10][7:0];
                      end
                    end

                7'h35: begin
                      if (i_wr) begin
                        reg_bg_palette_color[10][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[10][11:8]};
                      end
                    end

                7'h36: begin
                      if (i_wr) begin
                        reg_bg_palette_color[11][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[11][7:0];
                      end
                    end

                7'h37: begin
                      if (i_wr) begin
                        reg_bg_palette_color[11][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[11][11:8]};
                      end
                    end

                7'h38: begin
                      if (i_wr) begin
                        reg_bg_palette_color[12][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[12][7:0];
                      end
                    end

                7'h39: begin
                      if (i_wr) begin
                        reg_bg_palette_color[12][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[12][11:8]};
                      end
                    end

                7'h3A: begin
                      if (i_wr) begin
                        reg_bg_palette_color[13][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[13][7:0];
                      end
                    end

                7'h3B: begin
                      if (i_wr) begin
                        reg_bg_palette_color[13][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[13][11:8]};
                      end
                    end

                7'h3C: begin
                      if (i_wr) begin
                        reg_bg_palette_color[14][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[14][7:0];
                      end
                    end

                7'h3D: begin
                      if (i_wr) begin
                        reg_bg_palette_color[14][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[14][11:8]};
                      end
                    end

                7'h3E: begin
                      if (i_wr) begin
                        reg_bg_palette_color[15][7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_bg_palette_color[15][7:0];
                      end
                    end

                7'h3F: begin
                      if (i_wr) begin
                        reg_bg_palette_color[15][11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_bg_palette_color[15][11:8]};
                      end
                    end

                7'h40: begin
                      if (i_wr) begin
                        reg_scroll_x_offset[7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_scroll_x_offset[7:0];
                      end
                    end

                7'h41: begin
                      if (i_wr) begin
                        reg_scroll_x_offset[9:8] <= i_data[1:0];
                      end else if (i_rd) begin
                        o_data <= {6'd0, reg_scroll_x_offset[9:8]};
                      end
                    end

                7'h42: begin
                      if (i_wr) begin
                        reg_scroll_y_offset[7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_scroll_y_offset[7:0];
                      end
                    end

                7'h43: begin
                      if (i_wr) begin
                        reg_scroll_y_offset[8] <= i_data[0];
                      end else if (i_rd) begin
                        o_data <= {7'd0, reg_scroll_y_offset[8]};
                      end
                    end

                7'h44: begin
                      if (i_wr) begin
                        reg_cursor_row[5:0] <= i_data[5:0];
                      end else if (i_rd) begin
                        o_data <= {2'd0, reg_cursor_row[5:0]};
                      end
                    end

                7'h45: begin
                      if (i_wr) begin
                        reg_cursor_column[6:0] <= i_data[6:0];
                      end else if (i_rd) begin
                        o_data <= {1'd0, reg_cursor_column[6:0]};
                      end
                    end

                7'h46: begin // set character code index
                      if (i_wr) begin
                        reg_put_cell[7:0] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_get_cell[7:0];
                      end
                    end

                7'h47: begin // set character color palette indexes
                      if (i_wr) begin
                        reg_put_cell[15:8] <= i_data;
                      end else if (i_rd) begin
                        o_data <= reg_get_cell[15:8];
                      end
                    end

                7'h48: begin // set character FG palette color index
                      if (i_wr) begin
                        reg_put_cell[15:12] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_get_cell[15:12]};
                      end
                    end

                7'h49: begin // set character BG palette color index
                      if (i_wr) begin
                        reg_put_cell[11:8] <= i_data[3:0];
                      end else if (i_rd) begin
                        o_data <= {4'd0, reg_get_cell[11:8]};
                      end
                    end

                7'h4A: begin // read/write entire character cell
                      if (i_wr) begin
                        reg_addra = {reg_cursor_column, reg_cursor_row};
                        reg_wea <= 1;
                        reg_clka <= 1;
                      end else if (i_rd) begin
                        reg_addra = {reg_cursor_column, reg_cursor_row};
                        reg_wea <= 0;
                        reg_clka <= 1;
                      end
                    end

                7'h4B: reg_text_area_alpha <= i_data[2:0];
            endcase
        end
    end
endmodule
