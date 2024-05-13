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
typedef enum bit [2:0] {
    DATA_WIDTH_8 = 0,
    DATA_WIDTH_16 = 1,
    DATA_WIDTH_32 = 2,
    DATA_WIDTH_64 = 3,
    DATA_WIDTH_128 = 4
} DataWidth;

// CPU registers

reg [127:0] reg_bank [2:0]; // Data registers for ALU
reg [31:0] reg_pc;          // Program counter
reg [31:0] reg_sp;          // Stack pointer
reg [31:0] reg_ir;          // Instruction
reg [7:0] reg_status;       // Processor status

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
`define B   reg_status[4]   // Interrupt type (1=BRK, 0=IRQB)
`define D   reg_status[3]   // Decimal
`define I   reg_status[2]   // IRQB disable
`define Z   reg_status[1]   // Zero
`define C   reg_status[0]   // Carry

// 6502 Address modes

typedef enum bit [4:0] {
    AM_INVALID, // Invalid (none)
    ABS_a,      // Absolute a
    AIIX_A_X,   // Absolute Indexed Indirect with X (a,x)
    AIX_a_x,    // Absolute Indexed with X a,x
    AIY_a_y,    // Absolute Indexed with Y a,y
    AIIY_A_y,   // Absolute Indexed Indirect with Y (a),y
    AIA_A,      // Absolute Indirect (a)
    ACC_A,      // Accumulator A
    IMM_m,      // Immediate Addressing #
    IMP_i,      // Implied i
    PCR_r,      // Program Counter Relative r
    STK_s,      // Stack s
    ZPG_zp,     // Zero Page zp
    ZIIX_ZP_X,  // Zero Page Indexed Indirect (zp,x)
    ZIX_zp_x,   // Zero Page Indexed with X zp,x
    ZIY_zp_y,   // Zero Page Indexed with Y zp,y
    ZPI_ZP,     // Zero Page Indirect (zp)
    ZIIY_ZP_y   // Zero Page Indirect Indexed with Y (zp),y
} AddressMode;

typedef enum bit [7:0] {
    ADD,
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
    SUB,
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

typedef enum bit [2:0] {
    Decode,         // Initial breakdown of opcode
    ReadImmediate,  // Read immediate data
    ReadAddress,    // Read address of data
    Execute         // Execute the instruction
} ProcessingStage;

// 6502 Instructions

// Processing registers

reg [2:0] reg_stage;
reg [7:0] reg_operation;
reg [4:0] reg_address_mode;
reg [2:0] reg_data_width;
reg reg_6502;
reg reg_65832;
reg reg_overlay;
reg [2:0] reg_src_bank;
reg [3:0] reg_src_index;
reg [2:0] reg_dst_bank;
reg [3:0] reg_dst_index;
reg [2:0] reg_which;
reg [31:0] reg_address;
reg [31:0] reg_src_data;
reg [31:0] reg_dst_data;

ProcessingStage tmp_next_stage;
Operation tmp_operation;
AddressMode tmp_6502_addr_mode;
AddressMode tmp_65832_addr_mode;
AddressMode tmp_overlay_addr_mode;
DataWidth tmp_data_width;
logic tmp_6502;
logic tmp_65832;
logic tmp_overlay;
logic [2:0] tmp_src_bank;
logic [3:0] tmp_src_index;
logic [2:0] tmp_dst_bank;
logic [3:0] tmp_dst_index;
logic [2:0] tmp_which;
logic [31:0] tmp_address;
logic [31:0] tmp_src_data;
logic [31:0] tmp_dst_data;

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
        reg_operation <= 0;
        reg_address_mode <= 0;
        reg_data_width <= 0;
        reg_6502 <= 1;
        reg_65832 <= 0;
        reg_src_bank <= 0;
        reg_src_index <= 0;
        reg_dst_bank <= 0;
        reg_dst_index <= 0;
        reg_which <= 0;
        reg_address <= 0;
        reg_src_data <= 0;
        reg_dst_data <= 0;
    end else begin
        case (reg_stage)
            Decode: begin
                    // Decode instruction
                    tmp_next_stage = Execute;
                    tmp_data_width = DATA_WIDTH_8;
                    tmp_src_bank = 0;
                    tmp_src_index = 0;
                    tmp_dst_bank = 0;
                    tmp_dst_index = 0;
                    tmp_which = 0;
                    tmp_6502 = reg_6502;
                    tmp_65832 = reg_65832;
                    tmp_overlay = reg_overlay;

                    // Determine operation
                    case (`IR0)

                        8'h00: begin
                                tmp_operation = BRK;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h01: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h02: begin
                                tmp_operation = ADD;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                            end

                        8'h04: begin
                                tmp_operation = TSB;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h05: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h06: begin
                                tmp_operation = ASL;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'h07, 8'h17, 8'h27, 8'h37,
                        8'h47, 8'h57, 8'h67, 8'h77:
                            begin
                                tmp_operation = RMB;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h08: begin
                                tmp_operation = PHP;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h09: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'h0A: begin
                                tmp_operation = ASL;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h0C: begin
                                tmp_operation = TSB;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h0D: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h0E: begin
                                tmp_operation = ASL;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h0F, 8'h1F, 8'h2F, 8'h3F,
                        8'h4F, 8'h5F, 8'h6F, 8'h7F:
                            begin
                                tmp_operation = BBR;
                                tmp_6502_addr_mode = PCR_r;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h10: begin
                                tmp_operation = BPL;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h11: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'h12: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'h14: begin
                                tmp_operation = TRB;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h15: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h16: begin
                                tmp_operation = ASL;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'h18: begin
                                tmp_operation = CLC;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h19: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'h1A: begin
                                tmp_operation = INC;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h1C: begin
                                tmp_operation = TRB;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h1D: begin
                                tmp_operation = ORA;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h1E: begin
                                tmp_operation = ASL;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h20: begin
                                tmp_operation = JSR;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h21: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h22: begin
                                tmp_operation = JSR;
                                tmp_6502_addr_mode = AIA_A;
                            end

                        8'h23: begin
                                tmp_operation = SUB;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h24: begin
                                tmp_operation = BIT;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h25: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h26: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'h25: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h26: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h28: begin
                                tmp_operation = PLP;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h29: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'h2A: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h2C: begin
                                tmp_operation = BIT;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h2D: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h2E: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h30: begin
                                tmp_operation = BMI;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h31: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'h32: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'h34: begin
                                tmp_operation = BIT;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h35: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h36: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'h38: begin
                                tmp_operation = SEC;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h39: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'h3A: begin
                                tmp_operation = DEC;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h3C: begin
                                tmp_operation = BIT;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h3D: begin
                                tmp_operation = AND;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h3E: begin
                                tmp_operation = ROL;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h40: begin
                                tmp_operation = RTI;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h41: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h45: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h46: begin
                                tmp_operation = LSR;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'h48: begin
                                tmp_operation = PHA;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h49: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'h4A: begin
                                tmp_operation = LSR;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h4C: begin
                                tmp_operation = JMP;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h4D: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h4E: begin
                                tmp_operation = LSR;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h50: begin
                                tmp_operation = BVC;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h51: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'h52: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'h55: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h56: begin
                                tmp_operation = LSR;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'h58: begin
                                tmp_operation = CLI;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h59: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'h5A: begin
                                tmp_operation = PHY;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h5C: begin
                                tmp_operation = JSR;
                                tmp_6502_addr_mode = AIIX_A_X;
                            end

                        8'h5D: begin
                                tmp_operation = EOR;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h5E: begin
                                tmp_operation = LSR;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h60: begin
                                tmp_operation = RTS;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h61: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h64: begin
                                tmp_operation = STZ;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h65: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h66: begin
                                tmp_operation = ROR;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'h68: begin
                                tmp_operation = PLA;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h69: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'h6A: begin
                                tmp_operation = ROR;
                                tmp_6502_addr_mode = ACC_A;
                            end

                        8'h6C: begin
                                tmp_operation = JMP;
                                tmp_6502_addr_mode = AIA_A;
                            end

                        8'h6D: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h6E: begin
                                tmp_operation = ROR;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h70: begin
                                tmp_operation = BVS;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h71: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'h72: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'h74: begin
                                tmp_operation = STZ;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h75: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h76: begin
                                tmp_operation = ROR;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'h78: begin
                                tmp_operation = SEI;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h79: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'h7A: begin
                                tmp_operation = PLY;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'h7C: begin
                                tmp_operation = JMP;
                                tmp_6502_addr_mode = AIIX_A_X;
                            end

                        8'h7D: begin
                                tmp_operation = ADC;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h7E: begin
                                tmp_operation = ROR;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h80: begin
                                tmp_operation = BRA;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h81: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'h84: begin
                                tmp_operation = STY;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h85: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'h86: begin
                                tmp_operation = STX;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'h87, 8'h97, 8'hA7, 8'hB7,
                        8'hC7, 8'hD7, 8'hE7, 8'hF7:
                            begin
                                tmp_operation = SMB;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h88: begin
                                tmp_operation = DEY;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h89: begin
                                tmp_operation = BIT;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'h8A: begin
                                tmp_operation = TXA;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h8C: begin
                                tmp_operation = STY;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h8D: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h8E: begin
                                tmp_operation = STX;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'h8F, 8'h9F, 8'hAF, 8'hBF,
                        8'hCF, 8'hDF, 8'hEF, 8'hFF:
                            begin
                                tmp_operation = BBS;
                                tmp_6502_addr_mode = PCR_r;
                                tmp_which = reg_ir[6:4];
                            end

                        8'h90: begin
                                tmp_operation = BCC;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'h91: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'h92: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ZIY_zp_y;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'h94: begin
                                tmp_operation = STY;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h95: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'h96: begin
                                tmp_operation = STX;
                                tmp_6502_addr_mode = ZIY_zp_y;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'h98: begin
                                tmp_operation = TYA;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h99: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'h9A: begin
                                tmp_operation = TXS;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'h9C: begin
                                if (tmp_6502) begin
                                    tmp_operation = STZ;
                                    tmp_6502_addr_mode = ABS_a;
                                end else begin
                                    tmp_operation = STY;
                                    tmp_65832_addr_mode = AIX_a_x;
                                end
                            end

                        8'h9D: begin
                                tmp_operation = STA;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'h9E: begin
                                if (tmp_6502) begin
                                    tmp_operation = STZ;
                                    tmp_6502_addr_mode = AIX_a_x;
                                end else begin
                                    tmp_operation = STX;
                                    tmp_65832_addr_mode = AIY_a_y;
                                end
                            end

                        8'hA0: begin
                                tmp_operation = LDY;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hA1: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'hA2: begin
                                tmp_operation = LDX;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hA4: begin
                                tmp_operation = LDY;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hA5: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hA6: begin
                                tmp_operation = LDX;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hA8: begin
                                tmp_operation = TAY;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hA9: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hAA: begin
                                tmp_operation = TAX;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hAC: begin
                                tmp_operation = LDY;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hAD: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hAE: begin
                                tmp_operation = LDX;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hB0: begin
                                tmp_operation = BCS;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'hB1: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'hB2: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'hB4: begin
                                tmp_operation = LDY;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'hB5: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'hB6: begin
                                tmp_operation = LDX;
                                tmp_6502_addr_mode = ZIY_zp_y;
                            end

                        8'hB8: begin
                                tmp_operation = CLV;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hB9: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'hBA: begin
                                tmp_operation = TSX;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hBC: begin
                                tmp_operation = LDY;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'hBD: begin
                                tmp_operation = LDA;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'hBE: begin
                                tmp_operation = LDX;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'hC0: begin
                                tmp_operation = CPY;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hC1: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'hC4: begin
                                tmp_operation = CPY;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hC5: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hC6: begin
                                tmp_operation = DEC;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'hC8: begin
                                tmp_operation = INY;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hC9: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hCA: begin
                                tmp_operation = DEX;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hCB: begin
                                tmp_operation = WAI;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hCC: begin
                                tmp_operation = CPY;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hCD: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hCE: begin
                                tmp_operation = DEC;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hD0: begin
                                tmp_operation = BNE;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'hD1: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'hD2: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'hD5: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'hD6: begin
                                tmp_operation = DEC;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'hD8: begin
                                tmp_operation = CLD;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hD9: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'hDA: begin
                                tmp_operation = PHX;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'hDB: begin
                                tmp_operation = STP;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hDD: begin
                                tmp_operation = CMP;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'hDE: begin
                                tmp_operation = DEC;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'hE0: begin
                                tmp_operation = CPX;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hE1: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ZIIX_ZP_X;
                                tmp_65832_addr_mode = AIIX_A_X;
                            end

                        8'hE4: begin
                                tmp_operation = CPX;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hE5: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ZPG_zp;
                            end

                        8'hE6: begin
                                tmp_operation = INC;
                                tmp_6502_addr_mode = ZPG_zp;
                                tmp_65832_addr_mode = ABS_a;
                            end

                        8'hE8: begin
                                tmp_operation = INX;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hE9: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = IMM_m;
                            end

                        8'hEA: begin
                                tmp_operation = NOP;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hEC: begin
                                tmp_operation = CPX;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hED: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hEE: begin
                                tmp_operation = INC;
                                tmp_6502_addr_mode = ABS_a;
                            end

                        8'hF0: begin
                                tmp_operation = BEQ;
                                tmp_6502_addr_mode = PCR_r;
                            end

                        8'hF1: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ZIIY_ZP_y;
                                tmp_65832_addr_mode = AIIY_A_y;
                            end

                        8'hF2: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ZPI_ZP;
                                tmp_65832_addr_mode = AIA_A;
                            end

                        8'hF5: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = ZIX_zp_x;
                            end

                        8'hF6: begin
                                tmp_operation = INC;
                                tmp_6502_addr_mode = ZIX_zp_x;
                                tmp_65832_addr_mode = AIX_a_x;
                            end

                        8'hF8: begin
                                tmp_operation = SED;
                                tmp_6502_addr_mode = IMP_i;
                            end

                        8'hF9: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = AIY_a_y;
                            end

                        8'hFA: begin
                                tmp_operation = PLX;
                                tmp_6502_addr_mode = STK_s;
                            end

                        8'hFD: begin
                                tmp_operation = SBC;
                                tmp_6502_addr_mode = AIX_a_x;
                            end

                        8'hFE: begin
                                tmp_operation = INC;
                                tmp_6502_addr_mode = AIX_a_x;
                            end
                    endcase // IR0

                    case (tmp_6502_addr_mode)
                        ABS_a: begin   // Absolute a
                                tmp_next_stage = ReadAddress;
                            end

                        AIIX_A_X: begin   // Absolute Indexed Indirect (a,x)
                            end

                        AIX_a_x: begin   // Absolute Indexed with X a,x
                            end

                        AIY_a_y: begin   // Absolute Indexed with Y a,y
                            end

                        AIA_A: begin   // Absolute Indirect (a)
                            end

                        ACC_A: begin   // Accumulator A
                            end

                        IMM_m: begin   // Immediate Addressing #
                            end

                        IMP_i: begin   // Implied i
                            end

                        PCR_r: begin   // Program Counter Relative r
                            end

                        STK_s: begin   // Stack s
                            end

                        ZPG_zp: begin   // Zero Page zp
                            end

                        ZIIX_ZP_X: begin   // Zero Page Indexed Indirect (zp,x)
                            end

                        ZIX_zp_x: begin   // Zero Page Indexed with X zp,x
                            end

                        ZIY_zp_y: begin   // Zero Page Indexed with Y zp,y
                            end

                        ZPI_ZP: begin   // Zero Page Indirect (zp)
                            end

                        ZIIY_ZP_y: begin  // Zero Page Indirect Indexed with Y (zp),y
                            end
                    endcase // tmp_6502_addr_mode

                    reg_stage <= tmp_next_stage;
                    reg_6502 <= tmp_6502;
                    reg_65832 <= tmp_65832;
                    reg_overlay <= tmp_overlay;
                    reg_operation <= tmp_operation;
                    reg_address_mode <= tmp_6502_addr_mode;
                    reg_data_width <= tmp_data_width;
                end // Decode

            ReadImmediate: begin
                end // ReadImmediate

            ReadAddress: begin
                end // ReadAddress

        endcase // reg_stage
    end
end

endmodule
