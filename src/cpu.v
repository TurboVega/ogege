/*
 * char_gen8x8.v
 *
 * This module defines a 6502-compatible CPU with enhancements for
 * larger registers and wider buses (address and data). It is compatible
 * in terms of instruction opcodes and register access, but not in
 * terms of bus or pin access, because the platform is entirely different.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module cpu (
	input   wire i_rst,
	input   wire i_clk
);

reg [127:0] reg_bank [3:0];

`define RB(bank,index) reg_bank[bank][index*8+7:index*8]
`define RH(bank,index) reg_bank[bank][index*16+15:index*16]
`define RW(bank,index) reg_bank[bank][index*32+31:index*32]
`define RD(bank,index) reg_bank[bank][index*64+63:index*64]
`define RQ(bank) reg_bank[bank]

`define A `RB(0,0)
`define X `RB(1,0)
`define Y `RB(2,0)

/*
  examples:
        `RB(0,0) <= 0;
        `RH(1,1) <= 0;
        `RW(2,2) <= 0;
        `RD(3,3) <= 0;
        `RQ(0) <= 0;
*/

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        reg_bank[0] <= 0;
        reg_bank[1] <= 0;
        reg_bank[2] <= 0;
        reg_bank[3] <= 0;
    end else begin
    end
end

endmodule
