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

// Various data widths
typedef enum {
    DATA_WIDTH_8 = 0,
    DATA_WIDTH_16 = 1,
    DATA_WIDTH_32 = 2,
    DATA_WIDTH_64 = 3,
    DATA_WIDTH_128 = 4
} DataWidth;

// CPU registers

reg [127:0] reg_bank [2:0]; // Data registers for ALU
reg [31:0] reg_pc;          // Program counter
reg [7:0] reg_status;       // Processor status
reg [31:0] reg_sp;          // Stack pointer
reg [31:0] reg_ir;          // Instruction

/*
  Examples:
        `RB(0,0) <= 0;
        `RH(1,1) <= 0;
        `RW(2,1) <= 0;
        `RD(3,0) <= 0;
        `RQ(0) <= 0;
*/
`define RB(bank,index) reg_bank[bank][index*8+7:index*8]    // each bank has 16 bytes
`define RH(bank,index) reg_bank[bank][index*16+15:index*16] // each bank has 8 half-words
`define RW(bank,index) reg_bank[bank][index*32+31:index*32] // each bank has 4 words
`define RD(bank,index) reg_bank[bank][index*64+63:index*64] // each bank has 2 double-words
`define RQ(bank) reg_bank[bank]                             // each bank has 1 quad-word

`define IR0 reg_ir[7:0]     // Instruction register part 0
`define IR1 reg_ir[15:8]    // Instruction register part 1
`define IR2 reg_ir[23:16]   // Instruction register part 2
`define IR3 reg_ir[31:24]   // Instruction register part 3

// 6502 Registers

`define A   `RB(0,0)        // Accumulator
`define X   `RB(1,0)        // Index X
`define Y   `RB(2,0)        // Index Y
`define S   reg_sp[7:0]     // Stack pointer
`define PC  reg_pc[15:0]    // Program counter
`define PCH reg_pc[15:8]    // Program counter high
`define PCL reg_pc[7:0]     // Program counter low

`define P   reg_status      // Processor status
`define N   reg_status[7]   // Negative
`define V   reg_status[6]   // Overflow
`define U   reg_status[5]   // User status/mode
`define B   reg_status[4]   // IRQB disable
`define D   reg_status[3]   // Decimal
`define I   reg_status[2]   // IRQB disable
`define Z   reg_status[1]   // Zero
`define C   reg_status[0]   // Carry

// 6502 Address modes

typedef enum {
    ABS,            // Absolute a
    ABS_INX_IND,    // Absolute Indexed Indirect (a,x)
    ABS_INX_X,      // Absolute Indexed with X a,x
    ABS_INX_Y,      // Absolute Indexed with Y a, y
    ABS_IND,        // Absolute Indirect (a)
    ACC,            // Accumulator A
    IMM,            // Immediate Addressing #
    IMP,            // Implied i
    PCR,            // Program Counter Relative r
    STK,            // Stack s
    ZPG,            // Zero Page zp
    ZPG_INX_IND,    // Zero Page Indexed Indirect (zp,x)
    ZPG_INX_X,      // Zero Page Indexed with X zp,x
    ZPG_INX_Y,      // Zero Page Indexed with Y zp, y
    ZPG_IND,        // Zero Page Indirect (zp)
    ZPG_IND_INX_Y   // Zero Page Indirect Indexed with Y (zp), y
} AddressMode;

typedef enum {
    ADC,
    AND,
    ASL,
    BEQ,
    BIT,
    BBR,
    BBS,
    BCC,
    BCS,
    BMI,
    BNE,
    BPL,
    BRA,
    BRK,
    BVC,
    BVS,
    CLC,
    CLD,
    CLI,
    CLV,
    CMP,
    CPX,
    CPY,
    DEC,
    DEX,
    DEY,
    EOR,
    INC,
    INX,
    INY,
    JMP,
    JSR,
    LDA,
    LDX,
    LDY,
    LSR,
    NOP,
    ORA,
    PHA,
    PHP,
    PHX,
    PHY,
    PLA,
    PLP,
    PLX,
    PLY,
    RMB,
    ROL,
    ROR,
    RTI,
    RTS,
    SBC,
    SEC,
    SED,
    SEI,
    SMB,
    STA,
    STP,
    STX,
    STY,
    STZ,
    TAX,
    TAY,
    TRB,
    TSB,
    TSX,
    TXA,
    TXS,
    TYA,
    WAI,
} Operation;

// 6502 Instructions

// Processing registers

typedef struct {
    AddressMode     address_mode;
    logic [2:0]     data_reg_bank;
    logic [3:0]     data_reg_index;
} DecodedInstruction;

reg [2:0] reg_stage;
reg DataWidth reg_data_width;
reg DecodedInstruction reg_instr;

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        reg_bank[0] <= 0;
        reg_bank[1] <= 0;
        reg_bank[2] <= 0;
        reg_bank[3] <= 0;
        reg_pc <= 8'h0000FFFC;
        reg_sp <= 8'h00000100;
        reg_status <= 8'b00110100;
        reg_data_width <= DATA_WIDTH_8;
        reg_ir <= 0;
        reg_stage <= 0;
    end else begin
        case (reg_stage)
            0: begin
                    // Decode instruction
                    case (IR0)
                        8'h00: 
                    endcase
                end
        endcase
    end
end

endmodule
