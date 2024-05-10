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
	input   logic i_rst,
	input   logic i_clk
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
DecodedInstruction tmp_instr;
DataWidth tmp_data_width;
logic [2:0] tmp_src_bank;
logic [3:0] tmp_src_index;
logic [2:0] tmp_dst_bank;
logic [3:0] tmp_dst_index;
logic [2:0] tmp_which;

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        reg_bank[0] <= 0;
        reg_bank[1] <= 0;
        reg_bank[2] <= 0;
        reg_bank[3] <= 0;
        reg_pc <= 32'h0000FFFC;
        reg_sp <= 32'h00000100;
        reg_status <= 8'b00110100;
        tmp_data_width <= DATA_WIDTH_8;
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
                        8'h61: tmp_instr = '{ ADC, ZII };
                        8'h65: tmp_instr = '{ ADC, ZPG };
                        8'h69: tmp_instr = '{ ADC, IMM };
                        8'h6D: tmp_instr = '{ ADC, ABS };
                        8'h71: tmp_instr = '{ ADC, ZIIY };
                        8'h72: tmp_instr = '{ ADC, ZPI };
                        8'h75: tmp_instr = '{ ADC, ZIX };
                        8'h79: tmp_instr = '{ ADC, AIY };
                        8'h7D: tmp_instr = '{ ADC, AIX };

                        8'h22: tmp_instr = '{ AND, ZII };
                        8'h25: tmp_instr = '{ AND, ZPG };
                        8'h29: tmp_instr = '{ AND, IMM };
                        8'h2D: tmp_instr = '{ AND, ABS };
                        8'h32: tmp_instr = '{ AND, ZIIY };
                        8'h33: tmp_instr = '{ AND, ZPI };
                        8'h35: tmp_instr = '{ AND, ZIX };
                        8'h39: tmp_instr = '{ AND, AIY };
                        8'h3D: tmp_instr = '{ AND, AIX };

                        8'h06: tmp_instr = '{ ASL, ZPG };
                        8'h0A: tmp_instr = '{ ASL, ACC };
                        8'h0E: tmp_instr = '{ ASL, ABS };
                        8'h16: tmp_instr = '{ ASL, ZIX };

                        8'hF0: tmp_instr = '{ BEQ, IMM };

                        8'h24: tmp_instr = '{ BIT, ZPG };
                        8'h2C: tmp_instr = '{ BIT, ABS };
                        8'h34: tmp_instr = '{ BIT, ZIX };
                        8'h3C: tmp_instr = '{ BIT, AIX };
                        8'h89: tmp_instr = '{ BIT, IMM };

                        8'h0F, 8'h1F, 8'h2F, 8'h3F,
                        8'h4F, 8'h5F, 8'h6F, 8'h7F:
                            begin
                                tmp_instr = '{ BBR, PCR };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h8F, 8'h8F, 8'hAF, 8'hBF,
                        8'hCF, 8'hDF, 8'hEF, 8'hFF:
                            begin
                                tmp_instr = '{ BBS, PCR };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h90: tmp_instr = '{ BCC, PCR };
                        8'hB0: tmp_instr = '{ BCS, PCR };
                        8'h30: tmp_instr = '{ BMI, PCR };
                        8'hD0: tmp_instr = '{ BNE, PCR };
                        8'h10: tmp_instr = '{ BPL, PCR };
                        8'h80: tmp_instr = '{ BRA, PCR };
                        8'h00: tmp_instr = '{ BRK, STK };
                        8'h50: tmp_instr = '{ BVC, PCR };
                        8'h70: tmp_instr = '{ BVS, PCR };
                        8'h18: tmp_instr = '{ CLC, IMP };
                        8'hD8: tmp_instr = '{ CLD, IMP };
                        8'h58: tmp_instr = '{ CLI, IMP };
                        8'hB8: tmp_instr = '{ CLV, IMP };

                        8'hC1: tmp_instr = '{ CMP, ZIX };
                        8'hC5: tmp_instr = '{ CMP, ZPG };
                        8'hC9: tmp_instr = '{ CMP, IMM };
                        8'hCD: tmp_instr = '{ CMP, ABS };
                        8'hD1: tmp_instr = '{ CMP, ZIIY };
                        8'hD2: tmp_instr = '{ CMP, ZPI };
                        8'hD5: tmp_instr = '{ CMP, ZIX };
                        8'hD9: tmp_instr = '{ CMP, AIY };
                        8'hDD: tmp_instr = '{ CMP, AIX };

                        8'hE0: tmp_instr = '{ CPX, IMM };
                        8'hE4: tmp_instr = '{ CPX, ZPG };
                        8'hEC: tmp_instr = '{ CPX, ABS };

                        8'hC0: tmp_instr = '{ CPY, IMM };
                        8'hC4: tmp_instr = '{ CPY, ZPG };
                        8'hCC: tmp_instr = '{ CPY, ABS };

                        8'h3A: tmp_instr = '{ DEC, ACC };
                        8'hC6: tmp_instr = '{ DEC, ZPG };
                        8'hCE: tmp_instr = '{ DEC, ABS };
                        8'hD6: tmp_instr = '{ DEC, ZIX };
                        8'hDE: tmp_instr = '{ DEC, AIX };

                        8'hCA: tmp_instr = '{ DEX, IMP };
                        8'h88: tmp_instr = '{ DEY, IMP };

                        8'h41: tmp_instr = '{ EOR, ZII };
                        8'h45: tmp_instr = '{ EOR, ZPG };
                        8'h49: tmp_instr = '{ EOR, IMM };
                        8'h4D: tmp_instr = '{ EOR, ABS };
                        8'h51: tmp_instr = '{ EOR, ZIIY };
                        8'h52: tmp_instr = '{ EOR, ZPI };
                        8'h55: tmp_instr = '{ EOR, ZIX };
                        8'h59: tmp_instr = '{ EOR, AIY };
                        8'h5D: tmp_instr = '{ EOR, AIX };

                        8'h1A: tmp_instr = '{ INC, ACC };
                        8'hE6: tmp_instr = '{ INC, ZPG };
                        8'hEE: tmp_instr = '{ INC, ABS };
                        8'hF6: tmp_instr = '{ INC, ZIX };
                        8'hFE: tmp_instr = '{ INC, AIX };

                        8'hE8: tmp_instr = '{ INX, IMP };
                        8'hC8: tmp_instr = '{ INY, IMP };

                        8'h4C: tmp_instr = '{ JMP, ABS };
                        8'h6C: tmp_instr = '{ JMP, AIA };
                        8'h7C: tmp_instr = '{ JMP, AII };

                        8'h20: tmp_instr = '{ JSR, ABS };

                        8'hA1: tmp_instr = '{ LDA, ZII };
                        8'hA5: tmp_instr = '{ LDA, ZPG };
                        8'hA9: tmp_instr = '{ LDA, IMM };
                        8'hAD: tmp_instr = '{ LDA, ABS };
                        8'hB1: tmp_instr = '{ LDA, ZIIY };
                        8'hB2: tmp_instr = '{ LDA, ZPI };
                        8'hB5: tmp_instr = '{ LDA, ZIX };
                        8'hB9: tmp_instr = '{ LDA, AIY };
                        8'hBD: tmp_instr = '{ LDA, AIX };

                        8'hA2: tmp_instr = '{ LDX, IMM };
                        8'hA6: tmp_instr = '{ LDX, ZPG };
                        8'hAE: tmp_instr = '{ LDX, ABS };
                        8'hB6: tmp_instr = '{ LDX, ZIY };
                        8'hBE: tmp_instr = '{ LDX, AIY };

                        8'hA0: tmp_instr = '{ LDY, IMM };
                        8'hA4: tmp_instr = '{ LDY, ZPG };
                        8'hAC: tmp_instr = '{ LDY, ABS };
                        8'hB4: tmp_instr = '{ LDY, ZIX };
                        8'hBC: tmp_instr = '{ LDY, AIX };

                        8'h46: tmp_instr = '{ LSR, ZPG };
                        8'h4A: tmp_instr = '{ LSR, ACC };
                        8'h4E: tmp_instr = '{ LSR, ABS };
                        8'h56: tmp_instr = '{ LSR, ZIX };
                        8'h5E: tmp_instr = '{ LSR, AIX };

                        8'hEA: tmp_instr = '{ NOP, IMP };

                        8'h01: tmp_instr = '{ ORA, ZIX };
                        8'h05: tmp_instr = '{ ORA, ZPG };
                        8'h09: tmp_instr = '{ ORA, IMM };
                        8'h0D: tmp_instr = '{ ORA, ABS };
                        8'h11: tmp_instr = '{ ORA, ZIIY };
                        8'h12: tmp_instr = '{ ORA, ZPI };
                        8'h15: tmp_instr = '{ ORA, ZIX };
                        8'h19: tmp_instr = '{ ORA, AIY };
                        8'h1D: tmp_instr = '{ ORA, AIX };

                        8'h48: tmp_instr = '{ PHA, STK };
                        8'h08: tmp_instr = '{ PHP, STK };
                        8'hDA: tmp_instr = '{ PHX, STK };
                        8'h5A: tmp_instr = '{ PHY, STK };
                        8'h68: tmp_instr = '{ PLA, STK };
                        8'h28: tmp_instr = '{ PLP, STK };
                        8'hFA: tmp_instr = '{ PLX, STK };
                        8'h7A: tmp_instr = '{ PLY, STK };

                        8'h07, 8'h17, 8'h27, 8'h37,
                        8'h47, 8'h57, 8'h67, 8'h77:
                            begin
                                tmp_instr = '{ RMB, ZPG };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h26: tmp_instr = '{ ROL, ZPG };
                        8'h2A: tmp_instr = '{ ROL, ACC };
                        8'h2E: tmp_instr = '{ ROL, ABS };
                        8'h36: tmp_instr = '{ ROL, ZIX };
                        8'h3E: tmp_instr = '{ ROL, AIX };

                        8'h66: tmp_instr = '{ ROR, ZPG };
                        8'h6A: tmp_instr = '{ ROR, ACC };
                        8'h6E: tmp_instr = '{ ROR, ABS };
                        8'h76: tmp_instr = '{ ROR, ZIX };
                        8'h7E: tmp_instr = '{ ROR, AIXs };

                        8'h40: tmp_instr = '{ RTI, STK };
                        8'h60: tmp_instr = '{ RTS, STK };

                        8'hE1: tmp_instr = '{ SBC, ZII };
                        8'hE5: tmp_instr = '{ SBC, ZPG };
                        8'hE9: tmp_instr = '{ SBC, IMM };
                        8'hED: tmp_instr = '{ SBC, ABS };
                        8'hF1: tmp_instr = '{ SBC, ZIIY };
                        8'hF2: tmp_instr = '{ SBC, ZPI };
                        8'hF5: tmp_instr = '{ SBC, ZIX };
                        8'hF9: tmp_instr = '{ SBC, AIY };
                        8'hFD: tmp_instr = '{ SBC, AIX };

                        8'h38: tmp_instr = '{ SEC, IMP };
                        8'hF8: tmp_instr = '{ SED, IMP };
                        8'h78: tmp_instr = '{ SEI, IMP };

                        8'h87, 8'h97, 8'hA7, 8'hB7,
                        8'hC7, 8'hD7, 8'hE7, 8'hF7:
                            begin
                                tmp_instr = '{ SMB, ZPG };
                                tmp_which = reg_ir[6:4];
                            end

                        8'h81: tmp_instr = '{ STA, ZII };
                        8'h85: tmp_instr = '{ STA, ZPG };
                        8'h8D: tmp_instr = '{ STA, ABS };
                        8'h91: tmp_instr = '{ STA, ZIIY };
                        8'h92: tmp_instr = '{ STA, ZPI };
                        8'h95: tmp_instr = '{ STA, ZIX };
                        8'h99: tmp_instr = '{ STA, AIY };
                        8'h9D: tmp_instr = '{ STA, AIX };

                        8'hDB: tmp_instr = '{ STP, IMP };

                        8'h86: tmp_instr = '{ STX, ZPG };
                        8'h8E: tmp_instr = '{ STX, ABS };
                        8'h96: tmp_instr = '{ STX, ZIY };

                        8'h84: tmp_instr = '{ STY, ZPG };
                        8'h8C: tmp_instr = '{ STY, ABS };
                        8'h94: tmp_instr = '{ STY, ZIX };

                        8'h64: tmp_instr = '{ STZ, ZPG };
                        8'h74: tmp_instr = '{ STZ, ZIX };
                        8'h9C: tmp_instr = '{ STZ, ABS };
                        8'h9E: tmp_instr = '{ STZ, AIX };

                        8'hAA: tmp_instr = '{ TAX, IMP };
                        8'hA8: tmp_instr = '{ TAY, IMP };

                        8'h14: tmp_instr = '{ TRB, ZPG };
                        8'h1B: tmp_instr = '{ TRB, ABS };

                        8'h04: tmp_instr = '{ TSB, ZPG };
                        8'h0C: tmp_instr = '{ TSB, ABS };

                        8'hBA: tmp_instr = '{ TSX, IMP };
                        8'h8A: tmp_instr = '{ TXA, IMP };
                        8'h9A: tmp_instr = '{ TXS, IMP };
                        8'h98: tmp_instr = '{ TYA, IMP };
                        8'hCB: tmp_instr = '{ WAI, IMP }; 
                    endcase
                end
        endcase
    end
end

endmodule
