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

wire [3:0] fg_r = 4'b1111;
wire [3:0] fg_g = 4'b0000;
wire [3:0] fg_b = 4'b0000;

wire [3:0] bg_r = 4'b0000;
wire [3:0] bg_g = 4'b1111;
wire [3:0] bg_b = 4'b0000;

wire [2:0] alpha = 3'b011;

wire [3:0] new_r;
wire [3:0] new_g;
wire [3:0] new_b;

component_blender blend_r (
	.i_bg_color(bg_r),
	.i_fg_color(fg_r),
	.i_fg_alpha(alpha),
	.o_color(new_r)
);

component_blender blend_g (
	.i_bg_color(bg_g),
	.i_fg_color(fg_g),
	.i_fg_alpha(alpha),
	.o_color(new_g)
);

component_blender blend_b (
	.i_bg_color(bg_b),
	.i_fg_color(fg_b),
	.i_fg_alpha(alpha),
	.o_color(new_b)
);

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

assign o_led = 8'b0;
assign o_clk = 1'b0;//clk_i;
assign o_rst = 1'b0;//rstn_i;
assign o_r = de_s ? new_r : 1'b0;
assign o_g = de_s ? new_g : 1'b0;
assign o_b = de_s ? new_b : 1'b0;

endmodule
