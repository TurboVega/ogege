module pll (
	input  wire clock_in,
	input  wire rst_in,
	output wire clock_out_psram,
	output reg  locked_psram,
	output wire clock_out_vga,
	output reg  locked_vga,
);

wire clk270, clk180, clk90, clk0, usr_ref_out;
wire usr_pll_lock_stdy, usr_pll_lock;

wire pll_clk_nobuf;
CC_PLL #(
    .REF_CLK("10.0"),    // reference input in MHz
    .OUT_CLK("40.0"),   // pll output frequency in MHz
    .LOCK_REQ(1),        // require lock before output
    .PERF_MD("SPEED"),   // LOWPOWER, ECONOMY, SPEED
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll75 (
    .CLK_REF(clock_in), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
	.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(pll_clk_nobuf), .CLK_REF_OUT(usr_ref_out)
);
CC_BUFG pll_bufg (.I(pll_clk_nobuf), .O(clock_out_psram));

// reset is synced the clock
reg locked_s1;
always @(posedge clock_out_psram) begin
	locked_s1 <= usr_pll_lock;//_stdy;
	locked_psram <= locked_s1;
end

wire clk270_b, clk180_b, clk90_b, clk0_b, usr_ref_out_b;
wire usr_pll_lock_stdy_b, usr_pll_lock_b;

wire pll_clk_nobuf_b;
CC_PLL #(
    .REF_CLK("10.0"),    // reference input in MHz
    .OUT_CLK("25.175"),   // pll output frequency in MHz
    .LOCK_REQ(1),        // require lock before output
    .PERF_MD("SPEED"),   // LOWPOWER, ECONOMY, SPEED
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll25 (
    .CLK_REF(clock_in), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_b), .USR_PLL_LOCKED(usr_pll_lock_b),
	.CLK270(clk270_b), .CLK180(clk180_b), .CLK90(clk90_b), .CLK0(pll_clk_nobuf_b), .CLK_REF_OUT(usr_ref_out_b)
);
CC_BUFG pll_bufg_b (.I(pll_clk_nobuf_b), .O(clock_out_vga));

// reset is synced the clock
reg locked_s1_b;
always @(posedge clock_out_vga) begin
	locked_s1_b <= usr_pll_lock_b;//_stdy_b;
	locked_vga <= locked_s1_b;
end

endmodule
