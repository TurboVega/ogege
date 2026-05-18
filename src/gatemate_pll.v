module clock_gen_25_125 (
    input wire clk_osc, // 10 MHz (Olimex)
    output wire clk_25_125, // 25.125 MHz
    output wire pll_lock,
    output wire sys_rst_n
);

    wire clk270, clk180, clk90, clk0, usr_ref_out;
    wire usr_pll_lock_stdy;
    wire pll_clk_nobuf, clk_fb;

    CC_PLL #(
        .REF_CLK("10.0"),    // reference input in MHz
        .OUT_CLK("25.125"),  // pll output frequency in MHz
        .LOCK_REQ(1),        // require lock before output
        .PERF_MD("SPEED"),   // LOWPOWER, ECONOMY, SPEED
        .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
        .CI_FILTER_CONST(2), // optional CI filter constant
        .CP_FILTER_CONST(4)  // optional CP filter constant
    ) pll25_125 (
        .CLK_REF(clk_osc), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
        .USR_LOCKED_STDY_RST(1'b0),
        .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(pll_lock),
        .CLK270(clk270), .CLK180(clk180),
        .CLK90(clk90), .CLK0(pll_clk_nobuf),
        .CLK_REF_OUT(usr_ref_out)
    );

    CC_BUFG pll_bufg (.I(pll_clk_nobuf), .O(clk_25_125));

    assign clk_fb = clk_25_125;

    wire sys_rst_n;
    reg [3:0] rst_sync;

    // Create a reset that releases only AFTER the PLL is locked
    // and stays synchronous to the fast clock
    always @(posedge clk_25_125 or negedge pll_lock) begin
        if (!pll_lock)
            rst_sync <= 4'b0000;
        else
            rst_sync <= {rst_sync[2:0], 1'b1};
    end

    assign sys_rst_n = rst_sync[3];

endmodule
