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

// Text area peripheral addresses range 10000000..10XXXX7F
`define TEXT_PERIPH_BASE    			32'h10000000

// Text area peripheral addresses range 10000000..10XXXX7F
`define TEXT_PERIPH_BASE_HIGH_PART		8'h10 // highest 8 bits of address

// PSRAM peripheral addresses range 40000000..407FFFFF
`define PSRAM_PERIPH_BASE_HIGH_PART 	8'h40 // highest 8 bits of address

`define VB  [7:0]
`define VHW [15:0]
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
	//output wire `VB   o_led,
	output wire       o_led,
	output wire       o_psram_csn,
	output wire       o_psram_sclk,
	inout  wire       io_psram_data0,
	inout  wire       io_psram_data1,
	inout  wire       io_psram_data2,
	inout  wire       io_psram_data3,
	inout  wire       io_psram_data4,
	inout  wire       io_psram_data5,
	inout  wire       io_psram_data6,
	inout  wire       io_psram_data7
);

wire clk_100mhz, clk_50mhz, pix_clk, clk_locked;
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
assign clk_50mhz = cnt_4_ph_0[1];

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
		end else begin
			glyph_row_count <= glyph_row_count + 1;
		end
	end
end

// Memory/peripheral bus (32-bit)
wire bus_clk;
wire bus_we;
//wire `VW bus_addr;
//wire `VW bus_wr_data;
//wire `VW bus_rd_data;
wire bus_rd_ready;

reg `VW bus_addr = 0;
reg `VW bus_wr_data = 0;
reg `VW bus_rd_data = 0;

// Peripheral chip selects
wire periph_psram_cs;
wire periph_text_cs;

// Connection to PSRAM peripheral
assign periph_psram_cs = (bus_addr[31:24] == `PSRAM_PERIPH_BASE_HIGH_PART);
wire periph_psram_stb; assign periph_psram_stb = bus_clk;
wire periph_psram_we; assign periph_psram_we = bus_we;
wire [23:0] periph_psram_addr; assign periph_psram_addr = bus_addr[23:0];
wire `VHW periph_psram_i_data; assign periph_psram_i_data = bus_wr_data`VHW;
wire `VHW periph_psram_o_data;
wire periph_psram_o_data_ready;

// Connection to text area peripheral
assign periph_text_cs = (bus_addr[31:24] == `TEXT_PERIPH_BASE_HIGH_PART);
wire periph_text_stb; assign periph_text_stb = bus_clk;
wire periph_text_we; assign periph_text_we = bus_we;
wire [6:0] periph_text_addr; assign periph_text_addr = bus_addr[6:0];
wire `VB periph_text_i_data; assign periph_text_i_data = bus_wr_data`VB;
wire `VB periph_text_o_data;
wire periph_text_o_data_ready;
wire periph_psram_busy;
wire [5:0] periph_psram_state;
wire [34:0] states_hit;

// Returned (read) values from peripherals

reg `VW zero = 0;

assign bus_rd_data =
//    periph_psram_cs ? {zero[31:16], periph_psram_o_data} :
    periph_text_cs ? {zero[31:8], periph_text_o_data} :
    32'd0;

assign bus_rd_ready =
    //periph_psram_cs ? periph_psram_o_data_ready :
    periph_text_cs ? periph_text_o_data_ready :
    1'b0;

/*wire [3:0] cur_cycle;
wire `VHW cur_pc;
wire `VHW cur_sp;
wire `VW cur_ad;
wire `VB cur_cb;
wire `VB cur_db;
wire `VB cur_a;
wire `VB cur_x;
wire `VB cur_y;
wire `VB cur_ps;*/

reg [3:0] cur_cycle = 0;
reg `VHW cur_pc = 0;
reg `VHW cur_sp = 0;
reg `VW cur_ad = 0;
reg `VB cur_cb = 0;
reg `VB cur_db = 0;
reg `VB cur_a = 0;
reg `VB cur_x = 0;
reg `VB cur_y = 0;
reg `VB cur_ps = 0;

// Text area peripheral
text_area8x8 text_area8x8_inst (
	.i_rst(rst_s),
    .i_cs(periph_text_cs),
	.i_pix_clk(pix_clk),
	.i_blank(blank_s),
    .i_cpu_clk(clk_50mhz),
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
	.i_sp(cur_sp),
    .i_ad(cur_ad),
    .i_cb(cur_cb),
    .i_db(cur_db),
    .i_a(cur_a),
    .i_x(cur_x),
    .i_y(cur_y),
	.i_ps(cur_ps)
);

psram psram_inst (
	.i_rst(rst_s),
    .i_cs(periph_psram_cs),
	.i_clk(pix_clk),
	.i_stb(periph_psram_stb),
	.i_we(periph_psram_we),
	.i_addr(periph_psram_addr),
	.i_din(periph_psram_i_data),
	.o_busy(periph_psram_busy),
	.o_done(periph_psram_o_data_ready),
	.o_dout(periph_psram_o_data),
    .o_state(periph_psram_state),
	.o_psram_csn(o_psram_csn),
	.o_psram_sclk(o_psram_sclk),
	.io_psram_data0(io_psram_data0),
	.io_psram_data1(io_psram_data1),
	.io_psram_data2(io_psram_data2),
	.io_psram_data3(io_psram_data3),
	.io_psram_data4(io_psram_data4),
	.io_psram_data5(io_psram_data5),
	.io_psram_data6(io_psram_data6),
	.io_psram_data7(io_psram_data7),
	.states_hit(states_hit)
);

// The CPUs!
/*cpu cpu_inst (
    .i_rst(rst_s),
	.i_cpu_clk(clk_50mhz),
	.i_bram_clk(clk_100mhz),
    .o_bus_clk(bus_clk),
    .o_bus_we(bus_we),
    .o_bus_addr(bus_addr),
    .o_bus_data(bus_wr_data),
    .i_bus_data(bus_rd_data),
    .i_bus_data_ready(bus_rd_ready),
    .o_cycle(cur_cycle),
    .o_pc(cur_pc),
	.o_sp(cur_sp),
    .o_ad(cur_ad),
    .o_cb(cur_cb),
    .o_db(cur_db),
    .o_a(cur_a),
    .o_x(cur_x),
    .o_y(cur_y),
	.o_ps(cur_ps)
);*/

assign rst_s = ~rstn_i;
assign o_led = 8'b0;
assign o_clk = clk_i;
assign o_rst = rstn_i;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 4'd0;
assign o_g = active_s ? new_color[7:4] : 4'd0;
assign o_b = active_s ? new_color[3:0] : 4'd0;

endmodule
