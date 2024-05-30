/*
 * cpu.v
 *
 * This module defines a 6502-compatible CPU with 65832 enhancements for
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


`define VB  [7:0]
`define VHW [15:0]
`define VW  [31:0]

// 6502 CPU registers

reg `VB reg_a;              // Accumulator
reg `VB reg_x;              // X index
reg `VB reg_y;              // Y index
reg `VHW reg_pc;            // Program counter
reg `VHW reg_sp;            // Stack pointer
reg `VB reg_status;         // Processor status

`define A   reg_a           // Accumulator
`define X   reg_x           // X index
`define Y   reg_y           // Y index
`define PC  reg_pc          // Program counter
`define SP  reg_sp          // Stack pointer

`define P   reg_status      // Processor status
`define N   reg_status[7]   // Negative
`define V   reg_status[6]   // Overflow
`define U   reg_status[5]   // User status/mode
`define B   reg_status[4]   // Interrupt type (1=BRK, 0=IRQB)
`define D   reg_status[3]   // Decimal
`define I   reg_status[2]   // IRQB disable
`define Z   reg_status[1]   // Zero
`define C   reg_status[0]   // Carry

`define NN   ~reg_status[7]   // Not Negative
`define NV   ~reg_status[6]   // Not Overflow
`define NU   ~reg_status[5]   // Not User status/mode
`define NB   ~reg_status[4]   // Not Interrupt type (1=BRK, 0=IRQB)
`define ND   ~reg_status[3]   // Not Decimal
`define NI   ~reg_status[2]   // Not IRQB disable
`define NZ   ~reg_status[1]   // Not Zero
`define NC   ~reg_status[0]   // Not Carry

// 65832 CPU registers (enhanced/extended)

reg `VW reg_ea;             // Accumulator
reg `VW reg_ex;             // X index
reg `VW reg_ey;             // Y index
reg `VW reg_epc;            // Program counter
reg `VW reg_esp;            // Stack pointer
reg `VB reg_estatus;        // Processor status

`define eA  reg_ea          // Accumulator
`define eX  reg_ex          // X index
`define eY  reg_ey          // Y index
`define ePC reg_epc         // Program counter
`define eSP reg_esp         // Stack pointer

`define eP  reg_estatus     // Processor status
`define eN  reg_estatus[7]  // Negative
`define eV  reg_estatus[6]  // Overflow
`define eU  reg_estatus[5]  // User status/mode
`define eB  reg_estatus[4]  // Interrupt type (1=BRK, 0=IRQB)
`define eD  reg_estatus[3]  // Decimal
`define eI  reg_estatus[2]  // IRQB disable
`define eZ  reg_estatus[1]  // Zero
`define eC  reg_estatus[0]  // Carry

`define eNN ~reg_estatus[7]  // Not Negative
`define eNV ~reg_estatus[6]  // Not Overflow
`define eNU ~reg_estatus[5]  // Not User status/mode
`define eNB ~reg_estatus[4]  // Not Interrupt type (1=BRK, 0=IRQB)
`define eND ~reg_estatus[3]  // Not Decimal
`define eNI ~reg_estatus[2]  // Not IRQB disable
`define eNZ ~reg_estatus[1]  // Not Zero
`define eNC ~reg_estatus[0]  // Not Carry

// Working/Temporary registers

`define RVB     reg_read_val`VB
`define RVHW    reg_read_val`VHW
`define RVW     reg_read_val`VW
`define WVB     reg_write_val`VB
`define WVHW    reg_write_val`VHW
`define WVW     reg_write_val`VW
`define ADDR    reg_address`VHW
`define EADDR   reg_address`VW

`define ZERO_7 7'd0
`define ZERO_8 8'd0
`define ZERO_9 9'd0
`define ZERO_16 16'd0
`define ZERO_17 17'd0
`define ZERO_24 24'd0
`define ZERO_25 25'd0
`define ZERO_31 24'd0
`define ZERO_32 24'd0
`define ZERO_33 24'd0

`define ONES_24 24'hFFFFFF
`define ONES_25 25'h1FFFFFF
`define ONES_32 32'hFFFFFFFF
`define ONES_33 33'h1FFFFFFFF

// Address modes
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

// Instruction (operation) mnemonics
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

// Processing registers
reg [2:0] reg_stage;
reg [7:0] reg_operation;
reg [4:0] reg_address_mode;
reg reg_6502;
reg reg_65832;
reg [2:0] reg_which;
reg `VW reg_address;
reg `VW reg_src_data;
reg `VW reg_dst_data;

`define SRC reg_src_data`VB
`define eSRC reg_src_data`VW

reg `VW reg_ram[0:16383];

initial $readmemh("../ram/ram.bits", reg_ram);

`define LOGIC_8     logic [7:0]
`define LOGIC_9     logic [8:0]
`define LOGIC_17    logic [17:0]
`define LOGIC_32    logic [31:0]
`define LOGIC_33    logic [32:0]

`LOGIC_9 sext_a_9; assign sext_a_9 = {`A[7], `A};
`LOGIC_32 sext_a_32; assign sext_a_32 = {`A[7] ? `ONES_24 : `ZERO_24, `A};
`LOGIC_33 sext_a_33; assign sext_a_33 = {`A[7] ? `ONES_25 : `ZERO_25, `A};
`LOGIC_33 sext_ea_33; assign sext_ea_33 = {`eA[31], `eA};

`LOGIC_8 sext_c_8; assign sext_c_8 = `C ? 8'hFF : `ZERO_8;
`LOGIC_9 sext_c_9; assign sext_c_9 = `C ? 9'h1FF : `ZERO_9;
`LOGIC_32 sext_c_32; assign sext_c_32 = `C ? `ONES_32 : `ZERO_32;
`LOGIC_33 sext_c_33; assign sext_c_33 = `C ? `ONES_33 : `ZERO_33;

`LOGIC_9 sext_src_9; assign sext_src_9 = {reg_src_data[7], `SRC};
`LOGIC_32 sext_src_32; assign sext_src_32 = {reg_src_data[7] ? `ONES_24 : `ZERO_24, `SRC};
`LOGIC_33 sext_src_33; assign sext_src_33 = {reg_src_data[7] ? `ONES_25 : `ZERO_25, `SRC};
`LOGIC_33 sext_esrc_33; assign sext_esrc_33 = {reg_src_data[31], `eSRC};

`LOGIC_9 sext_x_9; assign sext_x_9 = {`X[7], `X};
`LOGIC_32 sext_x_32; assign sext_x_32 = {`X[7] ? `ONES_24 : `ZERO_24, `X};
`LOGIC_33 sext_x_33; assign sext_x_33 = {`X[7] ? `ONES_25 : `ZERO_25, `X};
`LOGIC_33 sext_ex_33; assign sext_ex_33 = {`eX[31], `eX};

`LOGIC_9 sext_y_9; assign sext_y_9 = {`Y[7], `Y};
`LOGIC_32 sext_y_32; assign sext_y_32 = {`Y[7] ? `ONES_24 : `ZERO_24, `Y};
`LOGIC_33 sext_y_33; assign sext_y_33 = {`Y[7] ? `ONES_25 : `ZERO_25, `Y};
`LOGIC_33 sext_ey_33; assign sext_ey_33 = {`eY[31], `eY};

`LOGIC_9 uext_a_9; assign uext_a_9 = { 1'd0, `A};
`LOGIC_32 uext_a_32; assign uext_a_32 = { `ZERO_24, `A};
`LOGIC_33 uext_a_33; assign uext_a_33 = { `ZERO_25, `A};
`LOGIC_33 uext_ea_33; assign uext_ea_33 = { 1'd0, `eA};

`LOGIC_8 uext_c_8; assign uext_c_8 = { `ZERO_7, `C};
`LOGIC_9 uext_c_9; assign uext_c_9 = { `ZERO_8, `C};
`LOGIC_32 uext_c_32; assign uext_c_32 = { `ZERO_31, `C};
`LOGIC_33 uext_c_33; assign uext_c_33 = { `ZERO_32, `C};

`LOGIC_8 uext_nc_8; assign uext_nc_8 = { `ZERO_7, `NC};
`LOGIC_9 uext_nc_9; assign uext_nc_9 = { `ZERO_8, `NC};
`LOGIC_32 uext_nc_32; assign uext_nc_32 = { `ZERO_31, `NC};
`LOGIC_33 uext_nc_33; assign uext_nc_33 = { `ZERO_32, `NC};

`LOGIC_17 uext_pc_17; assign uext_pc_17 = { 1'd0, `PC};
`LOGIC_32 uext_pc_32; assign uext_pc_32 = { `ZERO_16, `PC};
`LOGIC_33 uext_pc_33; assign uext_pc_33 = { `ZERO_17, `PC};
`LOGIC_33 uext_epc_33; assign uext_epc_33 = { 1'd0, `ePC};

`LOGIC_17 uext_sp_17; assign uext_sp_17 = { 1'd0, `SP};
`LOGIC_32 uext_sp_32; assign uext_sp_32 = { `ZERO_16, `SP};
`LOGIC_33 uext_sp_33; assign uext_sp_33 = { `ZERO_17, `SP};
`LOGIC_33 uext_esp_33; assign uext_esp_33 = { 1'd0, `eSP};

`LOGIC_9 uext_src_9; assign uext_src_9 = { 1'd0, `SRC};
`LOGIC_32 uext_src_32; assign uext_src_32 = { `ZERO_24, `SRC};
`LOGIC_33 uext_src_33; assign uext_src_33 = { `ZERO_25, `SRC};
`LOGIC_33 uext_esrc_33; assign uext_esrc_33 = { 1'd0, `eSRC};

`LOGIC_9 uext_x_9; assign uext_x_9 = { 1'd0, `X};
`LOGIC_32 uext_x_32; assign uext_x_32 = { `ZERO_24, `X};
`LOGIC_33 uext_x_33; assign uext_x_33 = { `ZERO_25, `X};
`LOGIC_33 uext_ex_33; assign uext_ex_33 = { 1'd0, `eX};

`LOGIC_9 uext_y_9; assign uext_y_9 = { 1'd0, `Y};
`LOGIC_32 uext_y_32; assign uext_y_32 = { `ZERO_24, `Y};
`LOGIC_33 uext_y_33; assign uext_y_33 = { `ZERO_25, `Y};
`LOGIC_33 uext_ey_33; assign uext_ey_33 = { 1'd0, `eY};

`LOGIC_9 add_a_src; assign add_a_src = uext_a_9 + uext_src_9;
logic add_8_n; assign add_8_n = add_a_src[7];
logic add_8_v; assign add_8_v = add_a_src[8] ^ add_a_src[7];
logic add_8_z; assign add_8_z = (add_a_src`VB == `ZERO_8) ? 1 : 0;
logic add_8_c; assign add_8_c = add_a_src[8];

`LOGIC_33 add_ea_src; assign add_ea_src = uext_ea_33 + uext_esrc_33;
logic add_32_n; assign add_32_n = add_ea_src[31];
logic add_32_v; assign add_32_v = add_ea_src[32] ^ add_ea_src[31];
logic add_32_z; assign add_32_z = (add_ea_src`VW == `ZERO_32) ? 1 : 0;
logic add_32_c; assign add_32_c = add_ea_src[32];

`LOGIC_9 adc_a_src; assign adc_a_src = uext_a_9 + uext_src_9 + uext_c_9;
logic adc_8_n; assign adc_8_n = adc_a_src[7];
logic adc_8_v; assign adc_8_v = adc_a_src[8] ^ adc_a_src[7];
logic adc_8_z; assign adc_8_z = (adc_a_src`VB == `ZERO_8) ? 1 : 0;
logic adc_8_c; assign adc_8_c = adc_a_src[8];

`LOGIC_33 adc_ea_src; assign adc_ea_src = uext_ea_33 + uext_esrc_33 + uext_c_33;
logic adc_32_n; assign adc_32_n = adc_ea_src[31];
logic adc_32_v; assign adc_32_v = adc_ea_src[32] ^ adc_ea_src[31];
logic adc_32_z; assign adc_32_z = (adc_ea_src`VW == `ZERO_32) ? 1 : 0;
logic adc_32_c; assign adc_32_c = adc_ea_src[32];

`LOGIC_8 and_a_src; assign and_a_src = `A & `SRC;
logic and_8_n; assign and_8_n = and_a_src[7];
logic and_8_z; assign and_8_z = (and_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 and_ea_src; assign and_ea_src = `eA & `eSRC;
logic and_32_n; assign and_32_n = and_ea_src[31];
logic and_32_z; assign and_32_z = (and_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 asl_a_src; assign asl_a_src = {`A[6:0], 1'b0};
logic asl_8_n; assign asl_8_n = asl_a_src[7];
logic asl_8_z; assign asl_8_z = (asl_a_src == `ZERO_8) ? 1 : 0;
logic asl_8_c; assign asl_8_c = `A[7];

`LOGIC_32 asl_ea_src; assign asl_ea_src = {`eA[30:0], 1'b0};
logic asl_32_n; assign asl_32_n = asl_ea_src[31];
logic asl_32_z; assign asl_32_z = (asl_ea_src == `ZERO_32) ? 1 : 0;
logic asl_32_c; assign asl_32_c = `eA[31];

`LOGIC_8 eor_a_src; assign eor_a_src = `A ^ `SRC;
logic eor_8_n; assign eor_8_n = eor_a_src[7];
logic eor_8_z; assign eor_8_z = (eor_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 eor_ea_src; assign eor_ea_src = `eA ^ `eSRC;
logic eor_32_n; assign eor_32_n = eor_ea_src[31];
logic eor_32_z; assign eor_32_z = (eor_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 neg_a_src; assign neg_a_src = `ZERO_8 - `A;
logic neg_8_n; assign neg_8_n = neg_a_src[7];
logic neg_8_z; assign neg_8_z = (neg_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 neg_ea_src; assign neg_ea_src = `ZERO_32 - `eA;
logic neg_32_n; assign neg_32_n = neg_ea_src[31];
logic neg_32_z; assign neg_32_z = (neg_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 not_a_src; assign not_a_src = ~`A;
logic not_8_n; assign not_8_n = not_a_src[7];
logic not_8_z; assign not_8_z = (not_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 not_ea_src; assign not_ea_src = ~`eA;
logic not_32_n; assign not_32_n = not_ea_src[31];
logic not_32_z; assign not_32_z = (not_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 or_a_src; assign or_a_src = `A | `SRC;
logic or_8_n; assign or_8_n = or_a_src[7];
logic or_8_z; assign or_8_z = (or_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 or_ea_src; assign or_ea_src = `eA | `eSRC;
logic or_32_n; assign or_32_n = or_ea_src[31];
logic or_32_z; assign or_32_z = (or_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 rol_a_src; assign rol_a_src = {`A[6:0], `C};
logic rol_8_n; assign rol_8_n = rol_a_src[7];
logic rol_8_z; assign rol_8_z = (rol_a_src == `ZERO_8) ? 1 : 0;
logic rol_8_c; assign rol_8_c = `A[7];

`LOGIC_32 rol_ea_src; assign rol_ea_src = {`eA[30:0], `eC};
logic rol_32_n; assign rol_32_n = rol_ea_src[31];
logic rol_32_z; assign rol_32_z = (rol_ea_src == `ZERO_32) ? 1 : 0;
logic rol_32_c; assign rol_32_c = `eA[31];

`LOGIC_8 ror_a_src; assign ror_a_src = {`C, `A[7:1]};
logic ror_8_n; assign ror_8_n = ror_a_src[7];
logic ror_8_z; assign ror_8_z = (ror_a_src == `ZERO_8) ? 1 : 0;
logic ror_8_c; assign ror_8_c = `A[0];

`LOGIC_32 ror_ea_src; assign ror_ea_src = {`eC, `eA[30:0]};
logic ror_32_n; assign ror_32_n = ror_ea_src[31];
logic ror_32_z; assign ror_32_z = (ror_ea_src == `ZERO_32) ? 1 : 0;
logic ror_32_c; assign ror_32_c = `eA[0];

`LOGIC_9 sbc_a_src; assign sbc_a_src = uext_a_9 - uext_src_9 - uext_nc_9;
logic sbc_8_n; assign sbc_8_n = sbc_a_src[7];
logic sbc_8_v; assign sbc_8_v = sbc_a_src[8] ^ sbc_a_src[7];
logic sbc_8_z; assign sbc_8_z = (sbc_a_src`VB == `ZERO_8) ? 1 : 0;
logic sbc_8_c; assign sbc_8_c = sbc_a_src[8];

`LOGIC_33 sbc_ea_src; assign sbc_ea_src = uext_ea_33 - uext_esrc_33 - uext_nc_33;
logic sbc_32_n; assign sbc_32_n = sbc_ea_src[31];
logic sbc_32_v; assign sbc_32_v = sbc_ea_src[32] ^ sbc_ea_src[31];
logic sbc_32_z; assign sbc_32_z = (sbc_ea_src`VW == `ZERO_32) ? 1 : 0;
logic sbc_32_c; assign sbc_32_c = sbc_ea_src[32];

`LOGIC_9 sub_a_src; assign sub_a_src = uext_a_9 - uext_src_9;
logic sub_8_n; assign sub_8_n = sub_a_src[7];
logic sub_8_v; assign sub_8_v = sub_a_src[8] ^ sub_a_src[7];
logic sub_8_z; assign sub_8_z = (sub_a_src`VB == `ZERO_8) ? 1 : 0;
logic sub_8_c; assign sub_8_c = sub_a_src[8];

`LOGIC_33 sub_ea_src; assign sub_ea_src = uext_ea_33 - uext_esrc_33;
logic sub_32_n; assign sub_32_n = sub_ea_src[31];
logic sub_32_v; assign sub_32_v = sub_ea_src[32] ^ sub_ea_src[31];
logic sub_32_z; assign sub_32_z = (sub_ea_src`VW == `ZERO_32) ? 1 : 0;
logic sub_32_c; assign sub_32_c = sub_ea_src[32];

always @(posedge i_rst or posedge i_clk) begin
    integer i;

    if (i_rst) begin
        reg_6502 <= 1;
        `PC <= 16'hFFFC;
        `SP <= 16'h0100;
        `P <= 8'b00110100;
        `X <= `ZERO_8;
        `Y <= `ZERO_8;

        reg_65832 <= 0;
        `ePC <= `ZERO_32;
        `eSP <= `ZERO_32;
        `eP <= 8'b00110100;
        `eX <= `ZERO_32;
        `eY <= `ZERO_32;

        reg_operation <= 0;
        reg_address_mode <= 0;
        reg_which <= 0;
        reg_address <= 0;
        reg_src_data <= 0;
        reg_dst_data <= 0;
    end else begin

    end
end

endmodule
