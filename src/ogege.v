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
	output wire [7:0] o_led
);

wire clk_pix, clk_locked;
reg [11:0] reg_fg_color = 12'b111111111111;
reg [11:0] reg_bg_color = 12'b000000000000;
wire [11:0] new_color;
wire [HSZ-1:0] h_count_s;
wire [VSZ-1:0] v_count_s;
wire active_s;
wire blank_s;
reg [3:0] cell_row_count;
wire [2:0] cell_col_count;
reg [4:0] text_row_count;

pll pll_inst (
    .clock_in(clk_i), // 10 MHz
	.rst_in(~rstn_i),
    .clock_out(clk_pix), // 25 MHz, 0 deg
    .locked(clk_locked)
);

localparam
	HRES = 640,
	HSZ  = $clog2(HRES),
	VRES = 480,
	VSZ  = $clog2(VRES);

vga_core #(
	.HSZ(HSZ),
	.VSZ(VSZ)
) vga_inst (.clk_i(clk_pix),
    .rst_i(~clk_locked),
	.hcount_o(h_count_s),
	.vcount_o(v_count_s),
	.de_o(active_s),
	.vsync_o(o_vsync),
	.hsync_o(o_hsync)
);

assign cell_col_count = h_count_s[2:0];

always @(posedge clk_pix) begin
	if (h_count_s == 639) begin
		if (v_count_s == 479) begin
			cell_row_count = 0;
			text_row_count = 0;
		end else if (cell_row_count == 11) begin
			cell_row_count = 0;
			text_row_count = text_row_count + 1;
		end else
			cell_row_count = cell_row_count + 1;
	end
end

text_area8x8 text_area8x8_inst (
	.i_scan_row(v_count_s),
	.i_scan_column(h_count_s),
	.i_bg_color(reg_bg_color),
	.o_color(new_color)
);

assign o_led = 8'b0;
assign o_clk = clk_i;
assign o_rst = rstn_i;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 1'b0;
assign o_g = active_s ? new_color[7:4] : 1'b0;
assign o_b = active_s ? new_color[3:0] : 1'b0;

endmodule
