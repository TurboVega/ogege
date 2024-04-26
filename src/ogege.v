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

wire clk_125mhz, pix_clk, clk_locked;
reg [11:0] reg_fg_color = 12'b111111111111;
reg [11:0] reg_bg_color = 12'b000000000000;
wire [11:0] new_color;
wire [HSZ-1:0] h_count_s;
wire [VSZ-1:0] v_count_s;
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

/* 10 MHz to 125 MHz */
pll pll_inst (
	.clock_in(clk_i), // 10 MHz
	.rst_in(~rstn_i),
	.clock_out(clk_125mhz), // 125 MHz
	.locked(clk_locked)
);

reg [2:0] cnt_5_ph_0 = 0;
reg [2:0] cnt_5_ph_1 = 0;
assign pix_clk = (cnt_5_ph_0 < 3) && (cnt_5_ph_1 != 2);

always @(posedge clk_125mhz or negedge rstn_i)
begin
	if (~rstn_i)
		cnt_5_ph_0 <= 0;
	else if (cnt_5_ph_0 == 4)
		cnt_5_ph_0 <= 0;
	else
		cnt_5_ph_0 <= cnt_5_ph_0 + 1;
end

always @(negedge clk_125mhz or posedge rstn_i)
begin
	if (rstn_i)
		cnt_5_ph_1 <= 0;
	else if (cnt_5_ph_1 == 4)
		cnt_5_ph_1 <= 0;
	else
		cnt_5_ph_1 <= cnt_5_ph_1 + 1;
end

localparam
	HRES = 640,
	HSZ  = $clog2(HRES),
	VRES = 480,
	VSZ  = $clog2(VRES);

vga_core #(
	.HSZ(HSZ),
	.VSZ(VSZ)
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
/*
text_area8x8 text_area8x8_inst (
	.i_rst(rst_s),
	.i_pix_clk(pix_clk),
	.i_blank(blank_s),
    .i_cmd_clk(reg_cmd_clk),
    .i_cmd_data(reg_cmd_data),
	.i_scan_row(v_count_s),
	.i_scan_column(h_count_s),
	.i_bg_color(reg_bg_color),
	.o_color(new_color)
);
*/

reg canvas_wea = 1'b0;
reg canvas_web = 1'b0;
wire canvas_clka;
reg canvas_clkb = 1'b0;
reg [7:0] canvas_dia;
reg [7:0] canvas_dib;
wire [8:0] canvas_cola;
wire [7:0] canvas_rowa;
reg [8:0] canvas_colb;
reg [7:0] canvas_rowb;
wire [7:0] canvas_doa;
reg [7:0] canvas_dob;

assign canvas_clka = pix_clk;
assign canvas_cola = h_count_s;
assign canvas_rowa = v_count_s;

canvas my_canvas (
        .wea(canvas_wea),
        .web(canvas_web),
        .clka(canvas_clka),
        .clkb(canvas_clkb),
        .dia(canvas_dia),
        .dib(canvas_dib),
        .cola(canvas_cola),
        .rowa(canvas_rowa),
        .colb(canvas_colb),
        .rowb(canvas_rowb),
        .doa(canvas_doa),
        .dob(canvas_dob)
    );

assign new_color = {canvas_doa,canvas_doa[3:0]};

assign rst_s = ~rstn_i;
assign o_led = 8'b0;
assign o_clk = clk_i;
assign o_rst = rstn_i;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 4'd0;
assign o_g = active_s ? new_color[7:4] : 4'd0;
assign o_b = active_s ? new_color[3:0] : 4'd0;

endmodule
