/*
 * ogege.v
 *
 * This is the top-level module for the graphics generator. It holds all of the
 * registers needed to generate the entire display, and supports reading and
 * writing those registers from an external application standpoint.
 *
 * Copyright (C) 2024-2026 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

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

wire clock_locked;
wire sys_rst_n;
wire main_clk;
wire rst_s;

reg [11:0] reg_fg_color = 12'b111111111111;
reg [11:0] reg_bg_color = 12'b000000000000;
wire [11:0] new_color;
wire [9:0] h_count_s;
wire [8:0] v_count_s;

wire active_s;
wire blank_s;

reg [3:0] glyph_row_count;
wire [2:0] cell_col_count;
reg [4:0] text_row_count;
wire hbstart;
wire vbstart;

clock_gen_50_25 pll_inst(
    .clk_osc(clk_i), // 10 MHz (Olimex)
    .clk_50_25(main_clk), // 50.250 MHz
    .pll_lock(clock_locked),
    .sys_rst_n(sys_rst_n)
);

vga_core #(
	.HSZ(10),
	.VSZ(9)
) vga_inst (.clk_i(main_clk),
    .rst_i(rst_s),
	.hcount_o(h_count_s),
	.vcount_o(v_count_s),
	.de_o(active_s),
	.vsync_o(o_vsync),
	.hsync_o(o_hsync),
	.hbstart_o(hbstart),
	.vbstart_o(vbstart)
);

assign cell_col_count = h_count_s[2:0];

always @(posedge main_clk) begin
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

// Connection to PSRAM peripheral
reg periph_psram_cs;
reg periph_psram_stb;
reg periph_psram_we;
reg [23:0] periph_psram_addr;
reg `VHW periph_psram_i_data;
wire `VHW periph_psram_o_data;
wire periph_psram_o_data_ready;
wire periph_psram_busy;
wire [5:0] periph_psram_state;
wire [34:0] states_hit;

// Connection to text area peripheral
reg periph_text_cs;
reg periph_text_stb;
reg periph_text_we;
reg [6:0] periph_text_addr;
reg `VB periph_text_i_data;
wire `VB periph_text_o_data;
wire periph_text_o_data_ready;

// Text area peripheral
text_area8x8 text_area8x8_inst (
	.i_rst(rst_s),
    .i_cs(periph_text_cs),
	.i_pix_clk(main_clk),
	.i_blank(blank_s),
    .i_cpu_clk(main_clk),
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

    .i_test_ad(periph_psram_addr),
    .i_test_wr(periph_psram_i_data),
    .i_test_rd(periph_psram_o_data),
	.i_test_busy(periph_psram_busy)
);

psram psram_inst (
	.i_rst(rst_s),
    .i_cs(periph_psram_cs),
	.i_clk(main_clk), // not main_clk ?
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

reg [2:0] test_state;
reg finished;
reg success;
reg `VHW counter;

always @(posedge rst_s or posedge main_clk) begin
	if (rst_s) begin
		periph_psram_cs <= 0;
		periph_psram_stb <= 0;
		periph_psram_we <= 0;
		periph_psram_addr <= 0;
		periph_psram_i_data <= 0;
		test_state <= 3'd6;
		finished <= 0;
		success <= 0;
		counter <= 0;
	end else begin
		case (test_state)
			3'd0: begin
					// Wait for PSRAM startup
					if (~periph_psram_busy)
						test_state <= 3'd1;
				end
			3'd1: begin
					// Write a 16-bit value
					periph_psram_cs <= 1;
					periph_psram_we <= 1;
					periph_psram_stb <= 1;
					test_state <= 3'd2;
				end
			3'd2: begin
					// Wait for the value to be written
					if (periph_psram_busy) begin
						periph_psram_stb <= 0;
						periph_psram_we <= 0;
						test_state <= 3'd3;
					end
				end
			3'd3: begin
					// Read the value back again
					if (~periph_psram_busy) begin
						periph_psram_stb <= 1;
						test_state <= 3'd4;
					end
				end
			3'd4: begin
					// Wait for the value to be read
					if (periph_psram_busy) begin
						periph_psram_stb <= 0;
						test_state <= 3'd5;
					end
				end
			3'd5: begin
					// Indicate completion
					if (~periph_psram_busy) begin
						if (periph_psram_o_data == periph_psram_i_data) begin
							if (periph_psram_addr == 24'hFFFFFF) begin
								if (periph_psram_i_data == 16'hFFFF) begin
									finished <= 1;
									success <= 1;
									test_state <= 3'd7;
								end else begin
									periph_psram_addr <= 0;
									periph_psram_i_data <= periph_psram_i_data + 1;
									test_state <= 3'd1;
								end
							end else begin
								periph_psram_addr <= periph_psram_addr + 1;
								test_state <= 3'd1;
							end
						end else begin
							finished <= 1;
							success <= 0;
							test_state <= 3'd7;
						end
					end
				end
			3'd6: begin
					if (counter == 16'hFFFF) begin
						test_state = 3'd0;
					end else begin
						counter <= counter + 1;
					end
				end
		endcase;
	end;
end

assign periph_text_cs = 0;
assign periph_text_stb = 0;
assign periph_text_we = 0;
assign periph_text_addr = 0;
assign periph_text_i_data = 0;

assign rst_s = (~rstn_i) || (~sys_rst_n);
assign o_led = 1'd0;
assign o_clk = clk_i;
assign o_rst = rst_s;
assign blank_s = ~active_s;
assign o_r = active_s ? new_color[11:8] : 4'd0;
assign o_g = active_s ? new_color[7:4] : 4'd0;
assign o_b = active_s ? new_color[3:0] : 4'd0;

endmodule
