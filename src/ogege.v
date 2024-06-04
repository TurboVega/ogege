/*
 * ogege.v
 *
 * This is the top-level module for the graphics generator. It holds all of the
 * registers needed to generate the entire display, and supports reading and
 * writing those registers from an external application standpoint.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module ogege (
	input  wire       clk_i, 
	input  wire       rstn_i,
	output wire [3:0] o_r,
	output wire [3:0] o_g,
	output wire [3:0] o_b,
	output wire       o_vsync,
	output wire       o_hsync,
	output wire       o_clk,
	output wire       o_rst,
	output wire [7:0] o_led/*,
	output wire       o_psram_csn,
	output wire       o_psram_sclk,
	inout  wire       io_psram_data0,
	inout  wire       io_psram_data1,
	inout  wire       io_psram_data2,
	inout  wire       io_psram_data3,
	inout  wire       io_psram_data4,
	inout  wire       io_psram_data5,
	inout  wire       io_psram_data6,
	inout  wire       io_psram_data7*/
);

wire clk_100mhz, pix_clk, clk_locked;
reg [11:0] reg_fg_color = 12'b111111111111;
reg [11:0] reg_bg_color = 12'b000000000000;
wire [11:0] new_color;
wire [9:0] h_count_s;
wire [8:0] v_count_s;
wire rst_s;
wire active_s;
wire blank_s;
reg [3:0] glyph_row_count;
wire [2:0] cell_col_count;
reg [4:0] text_row_count;

reg reg_cmd_clk = 1'b0;
reg [31:0] reg_cmd_data = 32'd0;
reg [5:0] reg_frame_count = 6'd0;
reg [9:0] reg_scroll_x_offset = 10'd0;
reg [8:0] reg_scroll_y_offset = 9'd0;

/* 10 MHz to 100 MHz */
pll pll_inst (
	.clock_in(clk_i), // 10 MHz
	.rst_in(~rstn_i),
	.clock_out(clk_100mhz), // 100 MHz
	.locked(clk_locked)
);

reg [2:0] cnt_4_ph_0 = 0;
reg [2:0] cnt_4_ph_1 = 0;
assign pix_clk = (cnt_4_ph_0 < 2) && (cnt_4_ph_1 != 2);

always @(posedge clk_100mhz or negedge rstn_i)
begin
	if (~rstn_i)
		cnt_4_ph_0 <= 0;
	else if (cnt_4_ph_0 == 3)
		cnt_4_ph_0 <= 0;
	else
		cnt_4_ph_0 <= cnt_4_ph_0 + 1;
end

always @(negedge clk_100mhz or posedge rstn_i)
begin
	if (rstn_i)
		cnt_4_ph_1 <= 0;
	else if (cnt_4_ph_1 == 3)
		cnt_4_ph_1 <= 0;
	else
		cnt_4_ph_1 <= cnt_4_ph_1 + 1;
end

vga_core #(
	.HSZ(10),
	.VSZ(9)
) vga_inst (.clk_i(pix_clk),
    .rst_i(~clk_locked),
	.hcount_o(h_count_s),
	.vcount_o(v_count_s),
	.de_o(active_s),
	.vsync_o(o_vsync),
	.hsync_o(o_hsync)
);

assign cell_col_count = h_count_s[2:0];

always @(posedge pix_clk) begin
	reg_cmd_clk = 0;
	if (h_count_s == 639) begin
		if (v_count_s == 479) begin
			glyph_row_count <= 0;
			text_row_count <= 0;
		end else if (glyph_row_count == 11) begin
			glyph_row_count <= 0;
			text_row_count <= text_row_count + 1;
		end else
			glyph_row_count <= glyph_row_count + 1;
	end
end

reg reg_text_rd;
reg reg_text_wr;
reg [6:0] reg_text_addr;
reg [7:0] reg_text_i_data;
reg [7:0] reg_text_o_data;

text_area8x8 text_area8x8_inst (
	.i_rst(rst_s),
	.i_pix_clk(pix_clk),
	.i_blank(blank_s),
    .i_rd(reg_text_rd),
    .i_wr(reg_text_wr),
    .i_addr(reg_text_addr),
    .i_data(reg_text_i_data),
	.i_scan_row(v_count_s),
	.i_scan_column(h_count_s),
	.i_bg_color(reg_bg_color),
    .o_data(reg_text_o_data),
	.o_color(new_color)
);

/*
canvas canvas_inst (
	.i_rst(rst_s),
	.i_pix_clk(pix_clk),
	.i_blank(blank_s),
    .i_cmd_clk(reg_cmd_clk),
    .i_cmd_data(reg_cmd_data),
	.i_scan_row({1'b0, v_count_s[8:1]}),
	.i_scan_column({1'b0, h_count_s[9:1]}),
	.o_color(new_color)
);
*/

reg [2:0] test_state;

always @(posedge rst_s or posedge o_vsync) begin
	if (rst_s) begin
		test_state <= 0;
        reg_text_rd <= 0;
        reg_text_wr <= 0;
        reg_text_addr <= 0;
        reg_text_i_data <= 0;
        reg_text_o_data <= 0;
	end else begin
		case (test_state)
			3'd0: begin
					reg_text_addr <= 7'h46; // Character
				    reg_text_i_data <= 8'h62;
                    reg_text_wr <= 1;
					test_state <= 3'd1;
				end
			3'd1: begin
                    reg_text_wr <= 0;
					test_state <= 3'd2;
				end
			3'd2: begin
					reg_text_addr <= 7'h47; // FG
				    reg_text_i_data <= 8'h03;
                    reg_text_wr <= 1;
					test_state <= 3'd3;
				end
			3'd3: begin
                    reg_text_wr <= 0;
					test_state <= 3'd4;
				end
			3'd4: begin
					reg_text_addr <= 7'h48; // BG
				    reg_text_i_data <= 8'h07;
                    reg_text_wr <= 1;
					test_state <= 3'd5;
				end
			3'd5: begin
                    reg_text_wr <= 0;
					test_state <= 3'd0;
				end
		endcase;
	end;
end

cpu cpu_inst (
	.i_clk(clk_100mhz)
);

assign rst_s = ~rstn_i;
assign o_led = 8'b0;
assign o_clk = clk_i;
assign o_rst = rstn_i;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 4'd0;
assign o_g = active_s ? new_color[7:4] : 4'd0;
assign o_b = active_s ? new_color[3:0] : 4'd0;

endmodule
