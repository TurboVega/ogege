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

wire [HSZ-1:0] hcount_s;
wire [VSZ-1:0] v_count_s;
wire de_s;

vga_core #(
	.HSZ(HSZ), .VSZ(VSZ)
) vga_inst (.clk_i(clk_pix), .rst_i(~clk_locked),
	.hcount_o(hcount_s), .vcount_o(v_count_s),
	.de_o(de_s),
	.vsync_o(o_vsync), .hsync_o(o_hsync)
);

color_bar #(
    .H_RES(80), .PIX_SZ(4)
) col_inst (
	.i_clk(clk_pix), .i_rst(~clk_locked),
	.i_blank(~de_s),
	.o_r(o_r), .o_g(o_g), .o_b(o_b)
);

assign o_led = 8'b0;

endmodule
