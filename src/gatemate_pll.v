module clock_gen_50_25 (
    input wire clk_osc, // 10 MHz (Olimex)
    output wire clk_50_25, // 50.250 MHz
    output wire clk_25_12, // 25.125 MHz
    output wire pll_lock,
    output wire sys_rst_n
);

    wire clk_fb;

    // CC_PLL Primitive
    // Ratio: 10 * (201 / 40) = 50.250 MHz
    CC_PLL #(
        .REF_CLK("10.0"),
        .P_DIV(40), // N = 40
        .M_MULT(201), // M = 201
        .S_DIV(0) // S = 0 (2^0 = 1)
    ) pll_inst (
        .CLK_REF(clk_osc),
        .CLK_FEEDBACK(clk_fb),
        .CLK_OUT(clk_50_25),
        .CLK_LOCK(pll_lock)
    );

    assign clk_fb = clk_50_25;

    // Synchronous clock divider for 25.125 MHz
    reg r_clk_25;
    always @(posedge clk_50_25 or negedge pll_lock) begin
        if (!pll_lock) 
            r_clk_25 <= 0;
        else           
            r_clk_25 <= ~r_clk_25;
    end
    
    // Global Buffer for the divided clock
    CC_BUFG bufg_25 (
        .I(r_clk_25),
        .Y(clk_25_12)
    );

wire sys_rst_n;
reg [3:0] rst_sync;

// Create a reset that releases only AFTER the PLL is locked
// and stays synchronous to the fast clock
always @(posedge clk_50_25 or negedge pll_lock) begin
    if (!pll_lock)
        rst_sync <= 4'b0000;
    else
        rst_sync <= {rst_sync[2:0], 1'b1};
end

assign sys_rst_n = rst_sync[3];

endmodule
