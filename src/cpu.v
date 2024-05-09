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
    ABS,    // Absolute a
    AII,    // Absolute Indexed Indirect (a,x)
    AIX,    // Absolute Indexed with X a,x
    AIY,    // Absolute Indexed with Y a,y
    AIA,    // Absolute Indirect (a)
    ACC,    // Accumulator A
    IMM,    // Immediate Addressing #
    IMP,    // Implied i
    PCR,    // Program Counter Relative r
    STK,    // Stack s
    ZPG,    // Zero Page zp
    ZII,    // Zero Page Indexed Indirect (zp,x)
    ZIX,    // Zero Page Indexed with X zp,x
    ZIY,    // Zero Page Indexed with Y zp,y
    ZPI,    // Zero Page Indirect (zp)
    ZIIY    // Zero Page Indirect Indexed with Y (zp),y
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
    WAI
} Operation;

// 6502 Instructions

// Processing registers

typedef struct packed {
    Operation       operation;
    AddressMode     address_mode;
} DecodedInstruction;

reg [2:0] reg_stage;
wire DecodedInstruction tmp_instr;
wire DataWidth tmp_data_width;
wire [2:0] tmp_src_bank;
wire [3:0] tmp_src_index;
wire [2:0] tmp_dst_bank;
wire [3:0] tmp_dst_index;
wire [2:0] tmp_which;

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
                    tmp_data_width = DATA_WIDTH_8;
                    tmp_src_bank = 0;
                    tmp_src_index = 0;
                    tmp_dst_bank = 0;
                    tmp_dst_index = 0;
                    tmp_which = 0;

                    // Determine operation
                    case (IR0)
                        8'h61: tmp_inst = `{ ADC, ZII };
                        8'h65: tmp_inst = `{ ADC, ZPG };
                        8'h69: tmp_inst = `{ ADC, IMM };
                        8'h6D: tmp_inst = `{ ADC, ABS };
                        8'h71: tmp_inst = `{ ADC, ZIIY };
                        8'h72: tmp_inst = `{ ADC, ZPI };
                        8'h75: tmp_inst = `{ ADC, ZIX };
                        8'h79: tmp_inst = `{ ADC, AIY };
                        8'h7D: tmp_inst = `{ ADC, AIX };

                        8'h22: tmp_inst = `{ AND, ZII };
                        8'h25: tmp_inst = `{ AND, ZPG };
                        8'h29: tmp_inst = `{ AND, IMM };
                        8'h2D: tmp_inst = `{ AND, ABS };
                        8'h32: tmp_inst = `{ AND, ZIIY };
                        8'h33: tmp_inst = `{ AND, ZPI };
                        8'h35: tmp_inst = `{ AND, ZIX };
                        8'h39: tmp_inst = `{ AND, AIY };
                        8'h3D: tmp_inst = `{ AND, AIX };

                        8'h06: tmp_inst = `{ ASL, ZPG };
                        8'h0A: tmp_inst = `{ ASL, ACC };
                        8'h0E: tmp_inst = `{ ASL, ABS };
                        8'h16: tmp_inst = `{ ASL, ZIX };

                        8'hF0: tmp_inst = `{ BEQ, IMM };

                        8'h24: tmp_inst = `{ BIT, ZPG };
                        8'h2C: tmp_inst = `{ BIT, ABS };
                        8'h34: tmp_inst = `{ BIT, ZIX };
                        8'h3C: tmp_inst = `{ BIT, AIX };

                        8'h0F, 8'h1F, 8'h2F, 8'h3F,
                        8'h4F, 8'h5F, 8'h6F, 8'h7F:
                            begin
                                tmp_inst = `{ BBR, PCR };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h8F, 8'h8F, 8'hAF, 8'hBF,
                        8'hCF, 8'hDF, 8'hEF, 8'hFF:
                            begin
                                tmp_inst = `{ BBS, PCR };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h90: tmp_inst = `{ BCC, PCR };
                        8'hB0: tmp_inst = `{ BCS, PCR };
                        8'h30: tmp_inst = `{ BMI, PCR };
                        8'hD0: tmp_inst = `{ BNE, PCR };
                        8'h10: tmp_inst = `{ BPL, PCR };
                        8'h80: tmp_inst = `{ BRA, PCR };
                        8'h00: tmp_inst = `{ BRK, STK };
                        8'h50: tmp_inst = `{ BVC, PCR };
                        8'h70: tmp_inst = `{ BVS, PCR };
                        8'h18: tmp_inst = `{ CLC, IMP };
                        8'hD8: tmp_inst = `{ CLD, IMP };
                        8'h58: tmp_inst = `{ CLI, IMP };
                        8'hB8: tmp_inst = `{ CLV, IMP };

                        8'hC1: tmp_inst = `{ CMP, ZIX };
                        8'hC5: tmp_inst = `{ CMP, ZPG };
                        8'hC9: tmp_inst = `{ CMP, IMM };
                        8'hCD: tmp_inst = `{ CMP, ABS };
                        8'hD1: tmp_inst = `{ CMP, ZIIY };
                        8'hD2: tmp_inst = `{ CMP, ZPI };
                        8'hD5: tmp_inst = `{ CMP, ZIX };
                        8'hD9: tmp_inst = `{ CMP, AIY };
                        8'hDD: tmp_inst = `{ CMP, AIX };

                        8'hE0: tmp_inst = `{ CPX, IMM };
                        8'hE4: tmp_inst = `{ CPX, ZPG };
                        8'hEC: tmp_inst = `{ CPX, ABS };

                        8'hC0: tmp_inst = `{ CPY, IMM };
                        8'hC4: tmp_inst = `{ CPY, ZPG };
                        8'hCC: tmp_inst = `{ CPY, ABS };

                        8'h3A: tmp_inst = `{ DEC, ACC };
                        8'hCA: tmp_inst = `{ DEX, IMP };
                        8'h88: tmp_inst = `{ DEY, IMP };

                        8'h41: tmp_inst = `{ EOR, ZII };
                        8'h45: tmp_inst = `{ EOR, ZPG };
                        8'h49: tmp_inst = `{ EOR, IMM };
                        8'h4D: tmp_inst = `{ EOR, ABS };
                        8'h51: tmp_inst = `{ EOR, ZIIY };
                        8'h52: tmp_inst = `{ EOR, ZPI };
                        8'h55: tmp_inst = `{ EOR, ZIX };
                        8'h59: tmp_inst = `{ EOR, AIY };
                        8'h5D: tmp_inst = `{ EOR, AIX };

                        8'1Ah: tmp_inst = `{ INC, ACC };
                        8'hE8: tmp_inst = `{ INX, IMP };
                        8'hC8: tmp_inst = `{ INY, IMP };

                        8'h: tmp_inst = `{ JMP, };
                        8'h20: tmp_inst = `{ JSR, ABS };

                        8'hA1: tmp_inst = `{ LDA, ZII };
                        8'hA5: tmp_inst = `{ LDA, ZPG };
                        8'hA9: tmp_inst = `{ LDA, IMM };
                        8'hAD: tmp_inst = `{ LDA, ABS };
                        8'hB1: tmp_inst = `{ LDA, ZIIY };
                        8'hB2: tmp_inst = `{ LDA, ZPI };
                        8'hB5: tmp_inst = `{ LDA, ZIX };
                        8'hB9: tmp_inst = `{ LDA, AIY };
                        8'hBD: tmp_inst = `{ LDA, AIX };

                        8'hA2: tmp_inst = `{ LDX, IMM };
                        8'hA6: tmp_inst = `{ LDX, ZPG };
                        8'hAE: tmp_inst = `{ LDX, ABS };
                        8'hB6: tmp_inst = `{ LDX, ZIY };
                        8'hBE: tmp_inst = `{ LDX, AIY };

                        8'hA0: tmp_inst = `{ LDY, IMM };
                        8'hA4: tmp_inst = `{ LDY, ZPG };
                        8'hAC: tmp_inst = `{ LDY, ABS };
                        8'hB4: tmp_inst = `{ LDY, ZIX };
                        8'hBC: tmp_inst = `{ LDY, AIX };

                        8'h46: tmp_inst = `{ LSR, ZPG };
                        8'h4A: tmp_inst = `{ LSR, ACC };
                        8'h4E: tmp_inst = `{ LSR, ABS };
                        8'h56: tmp_inst = `{ LSR, ZIX };
                        8'h5E: tmp_inst = `{ LSR, AIX };

                        8'hEA: tmp_inst = `{ NOP, IMP };

                        8'h01: tmp_inst = `{ ORA, ZIX };
                        8'h05: tmp_inst = `{ ORA, ZPG };
                        8'h09: tmp_inst = `{ ORA, IMM };
                        8'h0D: tmp_inst = `{ ORA, ABS };
                        8'h11: tmp_inst = `{ ORA, ZIIY };
                        8'h12: tmp_inst = `{ ORA, ZPI };
                        8'h15: tmp_inst = `{ ORA, ZIX };
                        8'h19: tmp_inst = `{ ORA, AIY };
                        8'h1D: tmp_inst = `{ ORA, AIX };

                        8'h48: tmp_inst = `{ PHA, STK };
                        8'h08: tmp_inst = `{ PHP, STK };
                        8'hDA: tmp_inst = `{ PHX, STK };
                        8'h5A: tmp_inst = `{ PHY, STK };
                        8'h68: tmp_inst = `{ PLA, STK };
                        8'h28: tmp_inst = `{ PLP, STK };
                        8'hFA: tmp_inst = `{ PLX, STK };
                        8'h7A: tmp_inst = `{ PLY, STK };

                        8'h07, 8'h17, 8'h27, 8'h37,
                        8'h47, 8'h57, 8'h67, 8'h77:
                            begin
                                tmp_inst = `{ RMB, ZPG };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h26: tmp_inst = `{ ROL, ZPG };
                        8'h2A: tmp_inst = `{ ROL, ACC };
                        8'h2E: tmp_inst = `{ ROL, ABS };
                        8'h36: tmp_inst = `{ ROL, ZIX };
                        8'h3E: tmp_inst = `{ ROL, AIX };

                        8'h66: tmp_inst = `{ ROR, ZPG };
                        8'h6A: tmp_inst = `{ ROR, ACC };
                        8'h6E: tmp_inst = `{ ROR, ABS };
                        8'h76: tmp_inst = `{ ROR, ZIX };
                        8'h7E: tmp_inst = `{ ROR, AIXs };

                        8'h40: tmp_inst = `{ RTI, STK };
                        8'h60: tmp_inst = `{ RTS, STK };

                        8'hE1: tmp_inst = `{ SBC, ZII };
                        8'hE5: tmp_inst = `{ SBC, ZPG };
                        8'hE9: tmp_inst = `{ SBC, IMM };
                        8'hED: tmp_inst = `{ SBC, ABS };
                        8'hF1: tmp_inst = `{ SBC, ZIIY };
                        8'hF2: tmp_inst = `{ SBC, ZPI };
                        8'hF5: tmp_inst = `{ SBC, ZIX };
                        8'hF9: tmp_inst = `{ SBC, AIY };
                        8'hFD: tmp_inst = `{ SBC, AIX };

                        8'h38: tmp_inst = `{ SEC, IMP };
                        8'hF8: tmp_inst = `{ SED, IMP };
                        8'h78: tmp_inst = `{ SEI, IMP };

                        8'h87, 8'h97, 8'hA7, 8'hB7,
                        8'hC7, 8'hD7, 8'hE7, 8'hF7:
                            begin
                                tmp_inst = `{ SMB, ZPG };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h81: tmp_inst = `{ STA, ZII };
                        8'h85: tmp_inst = `{ STA, ZPG };
                        8'h8D: tmp_inst = `{ STA, ABS };
                        8'h91: tmp_inst = `{ STA, ZIIY };
                        8'h92: tmp_inst = `{ STA, ZPI };
                        8'h95: tmp_inst = `{ STA, ZIX };
                        8'h99: tmp_inst = `{ STA, AIY };
                        8'h9D: tmp_inst = `{ STA, AIX };

                        8'hDB: tmp_inst = `{ STP, IMP };

                        8'h86: tmp_inst = `{ STX, ZPG };
                        8'h8E: tmp_inst = `{ STX, ABS };
                        8'h96: tmp_inst = `{ STX, ZIY };

                        8'h84: tmp_inst = `{ STY, ZPG };
                        8'h8C: tmp_inst = `{ STY, ABS };
                        8'h94: tmp_inst = `{ STY, ZIX };

                        8'h64: tmp_inst = `{ STZ, ZPG };
                        8'h74: tmp_inst = `{ STZ, ZIX };
                        8'h9C: tmp_inst = `{ STZ, ABS };
                        8'h9E: tmp_inst = `{ STZ, AIX };

                        8'hAA: tmp_inst = `{ TAX, IMP };
                        8'hA8: tmp_inst = `{ TAY, IMP };
                        8'h14: tmp_inst = `{ TRB, ZPG };

                        8'h04: tmp_inst = `{ TSB, ZPG };
                        8'h0C: tmp_inst = `{ TSB, ABS };

                        8'hBA: tmp_inst = `{ TSX, IMP };
                        8'h8A: tmp_inst = `{ TXA, IMP };
                        8'h9A: tmp_inst = `{ TXS, IMP };
                        8'h98: tmp_inst = `{ TYA, IMP };
                        8'hCB: tmp_inst = `{ WAI, IMP }; 
                    endcase
                end
        endcase
    end
end

endmodule
