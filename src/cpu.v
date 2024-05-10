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

typedef enum bit [4:0] {
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

typedef enum bit [7:0] {
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

reg [2:0] reg_stage;
Operation tmp_operation;
AddressMode tmp_addr_mode;
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
                    case (`IR0)
                        8'h61: begin
								tmp_operation = ADC;
								tmp_addr_mode = ZII;
							end

                        8'h65: begin
								tmp_operation = ADC;
								tmp_addr_mode = ZPG;
							end

                        8'h69: begin
								tmp_operation = ADC;
								tmp_addr_mode = IMM;
							end

                        8'h6D: begin
								tmp_operation = ADC;
								tmp_addr_mode = ABS;
							end

                        8'h71: begin
								tmp_operation = ADC;
								tmp_addr_mode = ZIIY;
							end

                        8'h72: begin
								tmp_operation = ADC;
								tmp_addr_mode = ZIY;
							end

                        8'h75: begin
								tmp_operation = ADC;
								tmp_addr_mode = ZIX;
							end

                        8'h79: begin
								tmp_operation = ADC;
								tmp_addr_mode = AIY;
							end

                        8'h7D: begin
								tmp_operation = ADC;
								tmp_addr_mode = AIX;
							end

                        8'h22: begin
								tmp_operation = AND;
								tmp_addr_mode = ZII;
							end

                        8'h25: begin
								tmp_operation = AND;
								tmp_addr_mode = ZPG;
							end

                        8'h29: begin
								tmp_operation = AND;
								tmp_addr_mode = IMM;
							end

                        8'h2D: begin
								tmp_operation = AND;
								tmp_addr_mode = ABS;
							end

                        8'h32: begin
								tmp_operation = AND;
								tmp_addr_mode = ZIIY;
							end

                        8'h33: begin
								tmp_operation = AND;
								tmp_addr_mode = ZIY;
							end

                        8'h35: begin
								tmp_operation = AND;
								tmp_addr_mode = ZIX;
							end

                        8'h39: begin
								tmp_operation = AND;
								tmp_addr_mode = AIY;
							end

                        8'h3D: begin
								tmp_operation = AND;
								tmp_addr_mode = AIX;
							end

                        8'h06: begin
								tmp_operation = ASL;
								tmp_addr_mode = ZPG;
							end

                        8'h0A: begin
								tmp_operation = ASL;
								tmp_addr_mode = ACC;
							end

                        8'h0E: begin
								tmp_operation = ASL;
								tmp_addr_mode = ABS;
							end

                        8'h16: begin
								tmp_operation = ASL;
								tmp_addr_mode = ZIX;
							end

                        8'hF0: begin
								tmp_operation = BEQ;
								tmp_addr_mode = IMM;
							end

                        8'h24: begin
								tmp_operation = BIT;
								tmp_addr_mode = ZPG;
							end

                        8'h2C: begin
								tmp_operation = BIT;
								tmp_addr_mode = ABS;
							end

                        8'h34: begin
								tmp_operation = BIT;
								tmp_addr_mode = ZIX;
							end

                        8'h3C: begin
								tmp_operation = BIT;
								tmp_addr_mode = AIX;
							end

                        8'h89: begin
								tmp_operation = BIT;
								tmp_addr_mode = IMM;
							end

                        8'h0F, 8'h1F, 8'h2F, 8'h3F,
                        8'h4F, 8'h5F, 8'h6F, 8'h7F:
                            begin
								tmp_operation = BBR;
								tmp_addr_mode = PCR;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h8F, 8'h9F, 8'hAF, 8'hBF,
                        8'hCF, 8'hDF, 8'hEF, 8'hFF:
                            begin
								tmp_operation = BBS;
								tmp_addr_mode = PCR;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h90: begin
								tmp_operation = BCC;
								tmp_addr_mode = PCR;
							end

                        8'hB0: begin
								tmp_operation = BCS;
								tmp_addr_mode = PCR;
							end

                        8'h30: begin
								tmp_operation = BMI;
								tmp_addr_mode = PCR;
							end

                        8'hD0: begin
								tmp_operation = BNE;
								tmp_addr_mode = PCR;
							end

                        8'h10: begin
								tmp_operation = BPL;
								tmp_addr_mode = PCR;
							end

                        8'h80: begin
								tmp_operation = BRA;
								tmp_addr_mode = PCR;
							end

                        8'h00: begin
								tmp_operation = BRK;
								tmp_addr_mode = STK;
							end

                        8'h50: begin
								tmp_operation = BVC;
								tmp_addr_mode = PCR;
							end

                        8'h70: begin
								tmp_operation = BVS;
								tmp_addr_mode = PCR;
							end

                        8'h18: begin
								tmp_operation = CLC;
								tmp_addr_mode = IMP;
							end

                        8'hD8: begin
								tmp_operation = CLD;
								tmp_addr_mode = IMP;
							end

                        8'h58: begin
								tmp_operation = CLI;
								tmp_addr_mode = IMP;
							end

                        8'hB8: begin
								tmp_operation = CLV;
								tmp_addr_mode = IMP;
							end

                        8'hC1: begin
								tmp_operation = CMP;
								tmp_addr_mode = ZIX;
							end

                        8'hC5: begin
								tmp_operation = CMP;
								tmp_addr_mode = ZPG;
							end

                        8'hC9: begin
								tmp_operation = CMP;
								tmp_addr_mode = IMM;
							end

                        8'hCD: begin
								tmp_operation = CMP;
								tmp_addr_mode = ABS;
							end

                        8'hD1: begin
								tmp_operation = CMP;
								tmp_addr_mode = ZIIY;
							end

                        8'hD2: begin
								tmp_operation = CMP;
								tmp_addr_mode = ZIY;
							end

                        8'hD5: begin
								tmp_operation = CMP;
								tmp_addr_mode = ZIX;
							end

                        8'hD9: begin
								tmp_operation = CMP;
								tmp_addr_mode = AIY;
							end

                        8'hDD: begin
								tmp_operation = CMP;
								tmp_addr_mode = AIX;
							end

                        8'hE0: begin
								tmp_operation = CPX;
								tmp_addr_mode = IMM;
							end

                        8'hE4: begin
								tmp_operation = CPX;
								tmp_addr_mode = ZPG;
							end

                        8'hEC: begin
								tmp_operation = CPX;
								tmp_addr_mode = ABS;
							end

                        8'hC0: begin
								tmp_operation = CPY;
								tmp_addr_mode = IMM;
							end

                        8'hC4: begin
								tmp_operation = CPY;
								tmp_addr_mode = ZPG;
							end

                        8'hCC: begin
								tmp_operation = CPY;
								tmp_addr_mode = ABS;
							end

                        8'h3A: begin
								tmp_operation = DEC;
								tmp_addr_mode = ACC;
							end

                        8'hC6: begin
								tmp_operation = DEC;
								tmp_addr_mode = ZPG;
							end

                        8'hCE: begin
								tmp_operation = DEC;
								tmp_addr_mode = ABS;
							end

                        8'hD6: begin
								tmp_operation = DEC;
								tmp_addr_mode = ZIX;
							end

                        8'hDE: begin
								tmp_operation = DEC;
								tmp_addr_mode = AIX;
							end

                        8'hCA: begin
								tmp_operation = DEX;
								tmp_addr_mode = IMP;
							end

                        8'h88: begin
								tmp_operation = DEY;
								tmp_addr_mode = IMP;
							end

                        8'h41: begin
								tmp_operation = EOR;
								tmp_addr_mode = ZII;
							end

                        8'h45: begin
								tmp_operation = EOR;
								tmp_addr_mode = ZPG;
							end

                        8'h49: begin
								tmp_operation = EOR;
								tmp_addr_mode = IMM;
							end

                        8'h4D: begin
								tmp_operation = EOR;
								tmp_addr_mode = ABS;
							end

                        8'h51: begin
								tmp_operation = EOR;
								tmp_addr_mode = ZIIY;
							end

                        8'h52: begin
								tmp_operation = EOR;
								tmp_addr_mode = ZIY;
							end

                        8'h55: begin
								tmp_operation = EOR;
								tmp_addr_mode = ZIX;
							end

                        8'h59: begin
								tmp_operation = EOR;
								tmp_addr_mode = AIY;
							end

                        8'h5D: begin
								tmp_operation = EOR;
								tmp_addr_mode = AIX;
							end

                        8'h1A: begin
								tmp_operation = INC;
								tmp_addr_mode = ACC;
							end

                        8'hE6: begin
								tmp_operation = INC;
								tmp_addr_mode = ZPG;
							end

                        8'hEE: begin
								tmp_operation = INC;
								tmp_addr_mode = ABS;
							end

                        8'hF6: begin
								tmp_operation = INC;
								tmp_addr_mode = ZIX;
							end

                        8'hFE: begin
								tmp_operation = INC;
								tmp_addr_mode = AIX;
							end

                        8'hE8: begin
								tmp_operation = INX;
								tmp_addr_mode = IMP;
							end

                        8'hC8: begin
								tmp_operation = INY;
								tmp_addr_mode = IMP;
							end

                        8'h4C: begin
								tmp_operation = JMP;
								tmp_addr_mode = ABS;
							end

                        8'h6C: begin
								tmp_operation = JMP;
								tmp_addr_mode = AIA;
							end

                        8'h7C: begin
								tmp_operation = JMP;
								tmp_addr_mode = AII;
							end

                        8'h20: begin
								tmp_operation = JSR;
								tmp_addr_mode = ABS;
							end

                        8'hA1: begin
								tmp_operation = LDA;
								tmp_addr_mode = ZII;
							end

                        8'hA5: begin
								tmp_operation = LDA;
								tmp_addr_mode = ZPG;
							end

                        8'hA9: begin
								tmp_operation = LDA;
								tmp_addr_mode = IMM;
							end

                        8'hAD: begin
								tmp_operation = LDA;
								tmp_addr_mode = ABS;
							end

                        8'hB1: begin
								tmp_operation = LDA;
								tmp_addr_mode = ZIIY;
							end

                        8'hB2: begin
								tmp_operation = LDA;
								tmp_addr_mode = ZIY;
							end

                        8'hB5: begin
								tmp_operation = LDA;
								tmp_addr_mode = ZIX;
							end

                        8'hB9: begin
								tmp_operation = LDA;
								tmp_addr_mode = AIY;
							end

                        8'hBD: begin
								tmp_operation = LDA;
								tmp_addr_mode = AIX;
							end

                        8'hA2: begin
								tmp_operation = LDX;
								tmp_addr_mode = IMM;
							end

                        8'hA6: begin
								tmp_operation = LDX;
								tmp_addr_mode = ZPG;
							end

                        8'hAE: begin
								tmp_operation = LDX;
								tmp_addr_mode = ABS;
							end

                        8'hB6: begin
								tmp_operation = LDX;
								tmp_addr_mode = ZIY;
							end

                        8'hBE: begin
								tmp_operation = LDX;
								tmp_addr_mode = AIY;
							end

                        8'hA0: begin
								tmp_operation = LDY;
								tmp_addr_mode = IMM;
							end

                        8'hA4: begin
								tmp_operation = LDY;
								tmp_addr_mode = ZPG;
							end

                        8'hAC: begin
								tmp_operation = LDY;
								tmp_addr_mode = ABS;
							end

                        8'hB4: begin
								tmp_operation = LDY;
								tmp_addr_mode = ZIX;
							end

                        8'hBC: begin
								tmp_operation = LDY;
								tmp_addr_mode = AIX;
							end

                        8'h46: begin
								tmp_operation = LSR;
								tmp_addr_mode = ZPG;
							end

                        8'h4A: begin
								tmp_operation = LSR;
								tmp_addr_mode = ACC;
							end

                        8'h4E: begin
								tmp_operation = LSR;
								tmp_addr_mode = ABS;
							end

                        8'h56: begin
								tmp_operation = LSR;
								tmp_addr_mode = ZIX;
							end

                        8'h5E: begin
								tmp_operation = LSR;
								tmp_addr_mode = AIX;
							end

                        8'hEA: begin
								tmp_operation = NOP;
								tmp_addr_mode = IMP;
							end

                        8'h01: begin
								tmp_operation = ORA;
								tmp_addr_mode = ZIX;
							end

                        8'h05: begin
								tmp_operation = ORA;
								tmp_addr_mode = ZPG;
							end

                        8'h09: begin
								tmp_operation = ORA;
								tmp_addr_mode = IMM;
							end

                        8'h0D: begin
								tmp_operation = ORA;
								tmp_addr_mode = ABS;
							end

                        8'h11: begin
								tmp_operation = ORA;
								tmp_addr_mode = ZIIY;
							end

                        8'h12: begin
								tmp_operation = ORA;
								tmp_addr_mode = ZIY;
							end

                        8'h15: begin
								tmp_operation = ORA;
								tmp_addr_mode = ZIX;
							end

                        8'h19: begin
								tmp_operation = ORA;
								tmp_addr_mode = AIY;
							end

                        8'h1D: begin
								tmp_operation = ORA;
								tmp_addr_mode = AIX;
							end

                        8'h48: begin
								tmp_operation = PHA;
								tmp_addr_mode = STK;
							end

                        8'h08: begin
								tmp_operation = PHP;
								tmp_addr_mode = STK;
							end

                        8'hDA: begin
								tmp_operation = PHX;
								tmp_addr_mode = STK;
							end

                        8'h5A: begin
								tmp_operation = PHY;
								tmp_addr_mode = STK;
							end

                        8'h68: begin
								tmp_operation = PLA;
								tmp_addr_mode = STK;
							end

                        8'h28: begin
								tmp_operation = PLP;
								tmp_addr_mode = STK;
							end

                        8'hFA: begin
								tmp_operation = PLX;
								tmp_addr_mode = STK;
							end

                        8'h7A: begin
								tmp_operation = PLY;
								tmp_addr_mode = STK;
							end

                        8'h07, 8'h17, 8'h27, 8'h37,
                        8'h47, 8'h57, 8'h67, 8'h77:
                            begin
								tmp_operation = RMB;
								tmp_addr_mode = ZPG;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h26: begin
								tmp_operation = ROL;
								tmp_addr_mode = ZPG;
							end

                        8'h2A: begin
								tmp_operation = ROL;
								tmp_addr_mode = ACC;
							end

                        8'h2E: begin
								tmp_operation = ROL;
								tmp_addr_mode = ABS;
							end

                        8'h36: begin
								tmp_operation = ROL;
								tmp_addr_mode = ZIX;
							end

                        8'h3E: begin
								tmp_operation = ROL;
								tmp_addr_mode = AIX;
							end

                        8'h66: begin
								tmp_operation = ROR;
								tmp_addr_mode = ZPG;
							end

                        8'h6A: begin
								tmp_operation = ROR;
								tmp_addr_mode = ACC;
							end

                        8'h6E: begin
								tmp_operation = ROR;
								tmp_addr_mode = ABS;
							end

                        8'h76: begin
								tmp_operation = ROR;
								tmp_addr_mode = ZIX;
							end

                        8'h7E: begin
								tmp_operation = ROR;
								tmp_addr_mode = AIX;
							end

                        8'h40: begin
								tmp_operation = RTI;
								tmp_addr_mode = STK;
							end

                        8'h60: begin
								tmp_operation = RTS;
								tmp_addr_mode = STK;
							end

                        8'hE1: begin
								tmp_operation = SBC;
								tmp_addr_mode = ZII;
							end

                        8'hE5: begin
								tmp_operation = SBC;
								tmp_addr_mode = ZPG;
							end

                        8'hE9: begin
								tmp_operation = SBC;
								tmp_addr_mode = IMM;
							end

                        8'hED: begin
								tmp_operation = SBC;
								tmp_addr_mode = ABS;
							end

                        8'hF1: begin
								tmp_operation = SBC;
								tmp_addr_mode = ZIIY;
							end

                        8'hF2: begin
								tmp_operation = SBC;
								tmp_addr_mode = ZIY;
							end

                        8'hF5: begin
								tmp_operation = SBC;
								tmp_addr_mode = ZIX;
							end

                        8'hF9: begin
								tmp_operation = SBC;
								tmp_addr_mode = AIY;
							end

                        8'hFD: begin
								tmp_operation = SBC;
								tmp_addr_mode = AIX;
							end

                        8'h38: begin
								tmp_operation = SEC;
								tmp_addr_mode = IMP;
							end

                        8'hF8: begin
								tmp_operation = SED;
								tmp_addr_mode = IMP;
							end

                        8'h78: begin
								tmp_operation = SEI;
								tmp_addr_mode = IMP;
							end

                        8'h87, 8'h97, 8'hA7, 8'hB7,
                        8'hC7, 8'hD7, 8'hE7, 8'hF7:
                            begin
								tmp_operation = SMB;
								tmp_addr_mode = ZPG;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h81: begin
								tmp_operation = STA;
								tmp_addr_mode = ZII;
							end

                        8'h85: begin
								tmp_operation = STA;
								tmp_addr_mode = ZPG;
							end

                        8'h8D: begin
								tmp_operation = STA;
								tmp_addr_mode = ABS;
							end

                        8'h91: begin
								tmp_operation = STA;
								tmp_addr_mode = ZIIY;
							end

                        8'h92: begin
								tmp_operation = STA;
								tmp_addr_mode = ZIY;
							end

                        8'h95: begin
								tmp_operation = STA;
								tmp_addr_mode = ZIX;
							end

                        8'h99: begin
								tmp_operation = STA;
								tmp_addr_mode = AIY;
							end

                        8'h9D: begin
								tmp_operation = STA;
								tmp_addr_mode = AIX;
							end

                        8'hDB: begin
								tmp_operation = STP;
								tmp_addr_mode = IMP;
							end

                        8'h86: begin
								tmp_operation = STX;
								tmp_addr_mode = ZPG;
							end

                        8'h8E: begin
								tmp_operation = STX;
								tmp_addr_mode = ABS;
							end

                        8'h96: begin
								tmp_operation = STX;
								tmp_addr_mode = ZIY;
							end

                        8'h84: begin
								tmp_operation = STY;
								tmp_addr_mode = ZPG;
							end

                        8'h8C: begin
								tmp_operation = STY;
								tmp_addr_mode = ABS;
							end

                        8'h94: begin
								tmp_operation = STY;
								tmp_addr_mode = ZIX;
							end

                        8'h64: begin
								tmp_operation = STZ;
								tmp_addr_mode = ZPG;
							end

                        8'h74: begin
								tmp_operation = STZ;
								tmp_addr_mode = ZIX;
							end

                        8'h9C: begin
								tmp_operation = STZ;
								tmp_addr_mode = ABS;
							end

                        8'h9E: begin
								tmp_operation = STZ;
								tmp_addr_mode = AIX;
							end

                        8'hAA: begin
								tmp_operation = TAX;
								tmp_addr_mode = IMP;
							end

                        8'hA8: begin
								tmp_operation = TAY;
								tmp_addr_mode = IMP;
							end

                        8'h14: begin
								tmp_operation = TRB;
								tmp_addr_mode = ZPG;
							end

                        8'h1B: begin
								tmp_operation = TRB;
								tmp_addr_mode = ABS;
							end

                        8'h04: begin
								tmp_operation = TSB;
								tmp_addr_mode = ZPG;
							end

                        8'h0C: begin
								tmp_operation = TSB;
								tmp_addr_mode = ABS;
							end

                        8'hBA: begin
								tmp_operation = TSX;
								tmp_addr_mode = IMP;
							end

                        8'h8A: begin
								tmp_operation = TXA;
								tmp_addr_mode = IMP;
							end

                        8'h9A: begin
								tmp_operation = TXS;
								tmp_addr_mode = IMP;
							end

                        8'h98: begin
								tmp_operation = TYA;
								tmp_addr_mode = IMP;
							end

                        8'hCB: begin
								tmp_operation = WAI;
								tmp_addr_mode = IMP;
							end
 
                    endcase
                end
        endcase
    end
end

endmodule
