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

// BRAM peripheral addresses range 00000000..0FFFF, except I/O area
`define BRAM_PERIPH_BASE_HIGH_PART  16'h0000 // highest 16 bits of address

// Text area peripheral addresses range 0000FF00..0000FF7F
`define TEXT_PERIPH_BASE_HIGH_PART  25'h00001FE // highest 25 bits of address

// PSRAM peripheral addresses range 40000000..407FFFFF
`define PSRAM_PERIPH_BASE_HIGH_PART  8'h40 // highest 8 bits of address

`define VB  'VB
`define VHW 'VHW
`define VW  [31:0]

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
	output wire 'VB o_led/*,
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
	if (h_count_s == 639) begin
		if (v_count_s == 479) begin
			glyph_row_count <= 0;
			text_row_count <= 0;
		end else if (glyph_row_count == 7) begin
			glyph_row_count <= 0;
			text_row_count <= text_row_count + 1;
		end else
			glyph_row_count <= glyph_row_count + 1;
	end
end

// Memory/peripheral bus (32-bit)
logic bus_clk;
logic bus_we;
logic `VW bus_addr;
logic `VW bus_wr_data;
logic `VW bus_rd_data;
logic bus_rd_ready;

// Peripheral chip selects
logic periph_psram_cs;
logic periph_bram_cs;
logic periph_text_cs;

// Connection to PSRAM peripheral
assign periph_psram_cs = (bus_addr[31:23] == `PSRAM_PERIPH_BASE_HIGH_PART);
logic periph_psram_stb; assign periph_psram_stb = bus_clk;
logic periph_psram_we; assign periph_psram_we = bus_we;
logic [23:0] periph_psram_addr; assign periph_psram_addr = bus_addr[23:0];
logic 'VB periph_psram_i_data; assign periph_psram_i_data = bus_wr_data`VB;
logic 'VB periph_psram_o_data;
logic periph_psram_o_data_ready;

// Connection to BRAM peripheral
assign periph_bram_cs = (bus_addr[31:16] == `BRAM_PERIPH_BASE_HIGH_PART) & (~periph_text_cs);
logic periph_bram_stb; assign periph_bram_stb = bus_clk;
logic periph_bram_we; assign periph_bram_we = bus_we;
logic 'VHW periph_bram_addr; assign periph_bram_addr = bus_addr`VHW;
logic 'VB periph_bram_i_data; assign periph_bram_i_data = bus_wr_data`VB;
logic 'VB periph_bram_o_data;
logic periph_bram_o_data_ready;

// Connection to text area peripheral
assign periph_text_cs = (bus_addr[31:7] == `TEXT_PERIPH_BASE_HIGH_PART);
logic periph_text_stb; assign periph_text_stb = bus_clk;
logic periph_text_we; assign periph_text_we = bus_we;
logic [6:0] periph_text_addr; assign periph_text_addr = bus_addr[6:0];
logic 'VB periph_text_i_data; assign periph_text_i_data = bus_wr_data'VB;
logic 'VB periph_text_o_data;
logic periph_text_o_data_ready;

// Returned (read) values from peripherals

assign bus_rd_data =
    periph_bram_cs ?  periph_bram_o_data :
    periph_psram_cs ? periph_psram_o_data :
    periph_text_cs ? periph_text_o_data :
    `ZERO_8;

assign bus_rd_ready =
    periph_bram_cs ?  periph_bram_o_data_ready :
    periph_psram_cs ? periph_psram_o_data_ready :
    periph_text_cs ? periph_text_o_data_ready :
    1'b0;

logic [3:0] cur_cycle;
logic 'VHW cur_pc;
logic 'VHW cur_ad;
logic 'VB cur_cb;
logic 'VB cur_rb;
logic 'VB cur_a;
logic 'VB cur_x;
logic 'VB cur_y;

// Text area peripheral
text_area8x8 text_area8x8_inst (
	.i_rst(rst_s),
    .i_cs(periph_text_cs),
	.i_pix_clk(pix_clk),
	.i_blank(blank_s),
    .i_cpu_clk(pix_clk),
    .i_stb(periph_text_stb),
    .i_we(periph_text_we),
    .i_addr(periph_text_addr),
    .i_data(periph_text_i_data),
	.i_scan_row(v_count_s),
	.i_scan_column(h_count_s),
	.i_bg_color(reg_bg_color),
    .o_data(periph_text_o_data),
    .o_data_ready(periph_text_o_data_ready),
	.o_color(new_color),
    .i_cycle(cur_cycle),
    .i_pc(cur_pc),
    .i_ad(cur_ad),
    .i_cb(cur_cb),
    .i_rb(cur_rb),
    .i_a(cur_a),
    .i_x(cur_x),
    .i_y(cur_y)
);

reg bram_web;
reg bram_clkb;
reg `VB bram_dib;
reg `VHW bram_addrb;
reg `VB bram_dob;
reg dram_drb;

bram_64kb bram_64kb_inst (
        .wea(periph_bram_we),
        .web(bram_web),
        .clka(periph_bram_stb),
        .clkb(bram_clkb),
        .dia(periph_bram_i_data),
        .dib(bram_dib),
        .addra(periph_bram_addr),
        .addrb(bram_addrb),
        .doa(periph_bram_o_data),
        .dob(bram_dob),
        .dra(periph_bram_o_data_ready),
        .drb(dram_drb)
    );

// The CPUs!
cpu cpu_inst (
    .i_rst(rst_s),
	.i_clk(pix_clk),
    .o_bus_clk(bus_clk),
    .o_bus_we(bus_we),
    .o_bus_addr(bus_addr),
    .o_bus_data(bus_wr_data),
    .i_bus_data(bus_rd_data),
    .i_bus_data_ready(bus_rd_ready),
    .o_cycle(cur_cycle),
    .o_pc(cur_pc),
    .o_ad(cur_ad),
    .o_cb(cur_cb),
    .o_rb(cur_rb),
    .o_a(cur_a),
    .o_x(cur_x),
    .o_y(cur_y)
);

always @(posedge rst_s) begin
    bram_web <= 0;
    bram_clkb <= 0;
    bram_dib <= 0;
    bram_addrb <= 0;
end

assign rst_s = ~rstn_i;
assign o_led = 8'b0;
assign o_clk = clk_i;
assign o_rst = rstn_i;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 4'd0;
assign o_g = active_s ? new_color[7:4] : 4'd0;
assign o_b = active_s ? new_color[3:0] : 4'd0;

endmodule
