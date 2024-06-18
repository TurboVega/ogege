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

`define BRK_IRQ_ADDRESS             16'hFFFE // Break/IRQ interrupt handler
`define RESET_PC_ADDRESS            16'hFFFC // Initial program counter
`define NMI_ADDRESS                 16'hFFFA // Non-maskable interrupt handler
`define RESET_SP_ADDRESS            16'h0100 // Initial stack pointer
`define RESET_STATUS_BITS           8'b00110100 // initial program status flags

`define TEXT_PERIPH_BASE_ADDRESS    16'hFF00 // location of text area peripheral
`define TEXT_PERIPH_BASE_HIGH_PART  9'h1FE   // highest 9 bits of address

`define VB  [7:0]
`define VHW [15:0]
`define VW  [31:0]

module cpu (
    input   logic i_rst,
    input   logic i_clk,
    output  reg   o_bus_clk,
    output  reg   o_bus_we,
    output  reg `VW o_bus_addr,
    output  reg `VW o_bus_data,
    input   logic `VW i_bus_data,
    input   logic i_bus_data_ready,
    output  logic [3:0] o_cycle,
    output  logic [15:0] o_pc,
    output  logic [15:0] o_ad,
    output  logic [7:0] o_cb,
    output  logic [7:0] o_rb,
    output  logic [7:0] o_a,
    output  logic [7:0] o_x,
    output  logic [7:0] o_y
);

// BRAM (lower 64KB of CPU RAM)

reg bram_wea,           // write enable A
reg bram_web,           // write enable B
reg bram_clka,          // clock A
reg bram_clkb,          // clock B
reg `VB bram_dia,       // data in A
reg `VB bram_dib,       // data in B
reg `VHW bram_addra,    // address A
reg `VHW bram_addrb,    // address B
reg `VB bram_doa,       // data out A
reg `VB bram_dob        // data out B

bram_64kb bram_64kb_inst (
        .wea(bram_wea),
        .web(bram_web),
        .clka(bram_clka),
        .clkb(bram_clkb),
        .dia(bram_dia),
        .dib(bram_dib),
        .addra(bram_addra),
        .addrb(bram_addrb),
        .doa(bram_doa),
        .dob(bram_dob)
    );

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
`define ADDR0   reg_address[7:0]
`define ADDR1   reg_address[15:8]
`define ADDR2   reg_address[23:16]
`define ADDR3   reg_address[31:24]

`define IADDR   reg_ind_address`VHW
`define IADDR0  reg_ind_address[7:0]
`define IADDR1  reg_ind_address[15:8]
`define IADDR2  reg_ind_address[23:16]
`define IADDR3  reg_ind_address[31:24]

`define EADDR   reg_address`VW
`define EADDR0  reg_address[7:0]
`define EADDR1  reg_address[15:8]
`define EADDR2  reg_address[23:16]
`define EADDR3  reg_address[31:24]

`define EIADDR   reg_ind_address`VW
`define EIADDR0  reg_ind_address[7:0]
`define EIADDR1  reg_ind_address[15:8]
`define EIADDR2  reg_ind_address[23:16]
`define EIADDR3  reg_ind_address[31:24]

`define OFFSET   reg_offset

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

`define ONE_8 8'd1
`define ONE_9 9'd1
`define ONE_16 16'd1
`define ONE_32 32'd1
`define ONE_33 33'd1

`define ONES_8 8'hFF
`define ONES_9 9'h1FF
`define ONES_24 24'hFFFFFF
`define ONES_25 25'h1FFFFFF
`define ONES_32 32'hFFFFFFFF
`define ONES_33 33'h1FFFFFFFF

`define TWO_16 16'd2;

`define FOUR_32 32'd4;

`define LOGIC_8     logic [7:0]
`define LOGIC_9     logic [8:0]
`define LOGIC_16    logic [15:0]
`define LOGIC_17    logic [16:0]
`define LOGIC_32    logic [31:0]
`define LOGIC_33    logic [32:0]

// Processing registers
reg [3:0] reg_cycle;
reg reg_6502;
reg reg_65832;
reg [2:0] reg_which;
reg `VW reg_address;
reg `VW reg_ind_address;
reg `VW reg_src_data;
reg `VW reg_dst_data;
reg `VB reg_code_byte;
reg `VB reg_data_byte;
reg `VW reg_offset;
reg load_from_address; // Load from or use the computed address
reg store_to_address; // Store computed value at address
reg transfer_in_progress; // Load/store in progress


`LOGIC_8 var_code_byte;
`LOGIC_8 var_ram_byte;
`LOGIC_8 var_new_val;
`LOGIC_16 var_hw_address;
`LOGIC_32 var_w_address;

reg am_ABS_a;       // Absolute a (6502)
reg am_ACC_A;       // Accumulator A (6502)
reg am_AIA_A;       // Absolute Indirect (a) (6502)
reg am_AIIX_A_X;    // Absolute Indexed Indirect with X (a,x) (6502)
reg am_AIX_a_x;     // Absolute Indexed with X a,x (6502)
reg am_AIY_a_y;     // Absolute Indexed with Y a,y (6502)
reg am_IMM_m;       // Immediate Addressing # (6502)
reg am_PCR_r;       // Program Counter Relative r (6502)
reg am_STK_s;       // Stack s (6502)
reg am_ZIIX_ZP_X;   // Zero Page Indexed Indirect (zp,x) (6502)
reg am_ZIIY_ZP_y;   // Zero Page Indirect Indexed with Y (zp),y (6502)
reg am_ZIX_zp_x;    // Zero Page Indexed with X zp,x (6502)
reg am_ZIY_zp_y;    // Zero Page Indexed with Y zp,y (6502)
reg am_ZPG_zp;      // Zero Page zp (6502)
reg am_ZPI_ZP;      // Zero Page Indirect (zp) (6502)

reg ame_ABS_a;      // Absolute a (65832)
reg ame_ACC_A;      // Accumulator A (65832)
reg ame_AIA_A;      // Absolute Indirect (a) (65832)
reg ame_AIIX_A_X;   // Absolute Indexed Indirect with X (a,x) (65832)
reg ame_AIIY_A_y;   // Absolute Indexed Indirect with Y (a),y (65832)
reg ame_AIX_a_x;    // Absolute Indexed with X a,x (65832)
reg ame_AIY_a_y;    // Absolute Indexed with Y a,y (65832)
reg ame_IMM_m;      // Immediate Addressing # (65832)
reg ame_PCR_r;      // Program Counter Relative r (65832)
reg ame_STK_s;      // Stack s (65832)

reg op_ADC;
reg op_ADD;
reg op_AND;
reg op_ASL;
reg op_BBR;
reg op_BRANCH;
reg op_BBS;
reg op_BIT;
reg op_BRK;
reg op_CMP;
reg op_CPX;
reg op_CPY;
reg op_DEC;
reg op_EOR;
reg op_INC;
reg op_JMP;
reg op_JSR;
reg op_LDA;
reg op_LDX;
reg op_LDY;
reg op_LSR;
reg op_ORA;
reg op_PHA;
reg op_PHP;
reg op_PHX;
reg op_PHY;
reg op_PLA;
reg op_PLP;
reg op_PLX;
reg op_PLY;
reg op_RMB;
reg op_ROL;
reg op_ROR;
reg op_RTI;
reg op_RTS;
reg op_SBC;
reg op_SMB;
reg op_STA;
reg op_STP;
reg op_STX;
reg op_STX;
reg op_STY;
reg op_STY;
reg op_STZ;
reg op_STZ;
reg op_SUB;
reg op_TRB;
reg op_TSB;
reg op_WAI;

`define SRC reg_src_data`VB
`define eSRC reg_src_data`VW
`define eSRC0 reg_src_data[7:0]
`define eSRC1 reg_src_data[15:8]
`define eSRC2 reg_src_data[23:16]
`define eSRC3 reg_src_data[31:24]

`define DST reg_dst_data`VB
`define eDST reg_dst_data`VW
`define eDST0 reg_dst_data[7:0]
`define eDST1 reg_dst_data[15:8]
`define eDST2 reg_dst_data[23:16]
`define eDST3 reg_dst_data[31:24]

//-------------------------------------------------------------------------------

`define CODE_BYTE reg_bram[`PC]
`define DATA_BYTE reg_bram[`ADDR]
`define STACK_BYTE reg_bram[`SP]

`LOGIC_9 sext_a_9; assign sext_a_9 = {`A[7], `A};
`LOGIC_32 sext_a_32; assign sext_a_32 = {`A[7] ? `ONES_24 : `ZERO_24, `A};
`LOGIC_33 sext_a_33; assign sext_a_33 = {`A[7] ? `ONES_25 : `ZERO_25, `A};
`LOGIC_33 sext_ea_33; assign sext_ea_33 = {`eA[31], `eA};

`LOGIC_8 sext_c_8; assign sext_c_8 = `C ? 8'hFF : `ZERO_8;
`LOGIC_9 sext_c_9; assign sext_c_9 = `C ? 9'h1FF : `ZERO_9;
`LOGIC_32 sext_c_32; assign sext_c_32 = `C ? `ONES_32 : `ZERO_32;
`LOGIC_33 sext_c_33; assign sext_c_33 = `C ? `ONES_33 : `ZERO_33;

`LOGIC_9 sext_src_9; assign sext_src_9 = {reg_src_data[7], `SRC};
`LOGIC_16 sext_src_16; assign sext_src_16 = {reg_src_data[7] ? `ONES_8 : `ZERO_8, `SRC};
`LOGIC_32 sext_src_32; assign sext_src_32 = {reg_src_data[7] ? `ONES_24 : `ZERO_24, `SRC};
`LOGIC_33 sext_src_33; assign sext_src_33 = {reg_src_data[7] ? `ONES_25 : `ZERO_25, `SRC};
`LOGIC_33 sext_esrc_33; assign sext_esrc_33 = {reg_src_data[31], `eSRC};

`LOGIC_32 sext_esrc_24_32; assign sext_esrc_24_32 = {reg_src_data[23] ? `ONES_8 : `ZERO_8, reg_src_data[23:0]};
`LOGIC_33 sext_esrc_24_33; assign sext_esrc_24_33 = {reg_src_data[23] ? `ONES_9 : `ZERO_9, reg_src_data[23:0]};
`LOGIC_33 sext_esrc_32_33; assign sext_esrc_32_33 = {reg_src_data[31], `eSRC};

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
`LOGIC_16 uext_src_16; assign uext_src_16 = { `ZERO_8, `SRC};
`LOGIC_32 uext_src_32; assign uext_src_32 = { `ZERO_24, `SRC};
`LOGIC_33 uext_src_33; assign uext_src_33 = { `ZERO_25, `SRC};
`LOGIC_33 uext_esrc_33; assign uext_esrc_33 = { 1'd0, `eSRC};

`LOGIC_9 uext_x_9; assign uext_x_9 = { 1'd0, `X};
`LOGIC_16 uext_x_16; assign uext_x_16 = { `ZERO_8, `X};
`LOGIC_32 uext_x_32; assign uext_x_32 = { `ZERO_24, `X};
`LOGIC_33 uext_x_33; assign uext_x_33 = { `ZERO_25, `X};
`LOGIC_33 uext_ex_33; assign uext_ex_33 = { 1'd0, `eX};

`LOGIC_9 uext_y_9; assign uext_y_9 = { 1'd0, `Y};
`LOGIC_16 uext_y_16; assign uext_y_16 = { `ZERO_8, `Y};
`LOGIC_32 uext_y_32; assign uext_y_32 = { `ZERO_24, `Y};
`LOGIC_33 uext_y_33; assign uext_y_33 = { `ZERO_25, `Y};
`LOGIC_33 uext_ey_33; assign uext_ey_33 = { 1'd0, `eY};

//-------------------------------------------------------------------------------

`LOGIC_9 add_a_src; assign add_a_src = uext_a_9 + uext_src_9;
logic add_a_src_n; assign add_a_src_n = add_a_src[7];
logic add_a_src_v; assign add_a_src_v = add_a_src[8] ^ add_a_src[7];
logic add_a_src_z; assign add_a_src_z = (add_a_src`VB == `ZERO_8) ? 1 : 0;
logic add_a_src_c; assign add_a_src_c = add_a_src[8];

`LOGIC_33 add_ea_src; assign add_ea_src = uext_ea_33 + uext_esrc_33;
logic add_ea_src_n; assign add_ea_src_n = add_ea_src[31];
logic add_ea_src_v; assign add_ea_src_v = add_ea_src[32] ^ add_ea_src[31];
logic add_ea_src_z; assign add_ea_src_z = (add_ea_src`VW == `ZERO_32) ? 1 : 0;
logic add_ea_src_c; assign add_ea_src_c = add_ea_src[32];

`LOGIC_16 add_pc_src; assign add_pc_src = `PC + sext_src_16;
`LOGIC_16 add_pc_2; assign add_pc_2 = `PC + `TWO_16;

`LOGIC_16 add_epc_4; assign add_epc_4 = `PC + `FOUR_32;

`LOGIC_32 add_epc_src; assign add_epc_src = `ePC + sext_src_32;
`LOGIC_32 add_epc_src_24; assign add_epc_src_24 = `ePC + sext_esrc_24_32;

`LOGIC_9 adc_a_src; assign adc_a_src = uext_a_9 + uext_src_9 + uext_c_9;
logic adc_a_src_n; assign adc_a_src_n = adc_a_src[7];
logic adc_a_src_v; assign adc_a_src_v = adc_a_src[8] ^ adc_a_src[7];
logic adc_a_src_z; assign adc_a_src_z = (adc_a_src`VB == `ZERO_8) ? 1 : 0;
logic adc_a_src_c; assign adc_a_src_c = adc_a_src[8];

`LOGIC_33 adc_ea_src; assign adc_ea_src = uext_ea_33 + uext_esrc_33 + uext_c_33;
logic adc_ea_src_n; assign adc_ea_src_n = adc_ea_src[31];
logic adc_ea_src_v; assign adc_ea_src_v = adc_ea_src[32] ^ adc_ea_src[31];
logic adc_ea_src_z; assign adc_ea_src_z = (adc_ea_src`VW == `ZERO_32) ? 1 : 0;
logic adc_ea_src_c; assign adc_ea_src_c = adc_ea_src[32];

`LOGIC_8 and_a_src; assign and_a_src = `A & `SRC;
logic and_a_src_n; assign and_a_src_n = and_a_src[7];
logic and_a_src_v; assign and_a_src_v = and_a_src[6];
logic and_a_src_z; assign and_a_src_z = (and_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 and_ea_src; assign and_ea_src = `eA & `eSRC;
logic and_ea_src_n; assign and_ea_src_n = and_ea_src[31];
logic and_ea_src_v; assign and_ea_src_v = and_ea_src[30];
logic and_ea_src_z; assign and_ea_src_z = (and_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 and_not_a_src; assign and_not_a_src = ~`A & `SRC;
logic and_not_a_src_n; assign and_not_a_src_n = and_not_a_src[7];
logic and_not_a_src_v; assign and_not_a_src_v = and_not_a_src[6];
logic and_not_a_src_z; assign and_not_a_src_z = (and_not_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 and_not_ea_src; assign and_not_ea_src = ~`eA & `eSRC;
logic and_not_ea_src_n; assign and_not_ea_src_n = and_not_ea_src[31];
logic and_not_ea_src_v; assign and_not_ea_src_v = and_not_ea_src[30];
logic and_not_ea_src_z; assign and_not_ea_src_z = (and_not_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 asl_a; assign asl_a = {`A[6:0], 1'b0};
logic asl_a_n; assign asl_a_n = asl_a[7];
logic asl_a_z; assign asl_a_z = (asl_a == `ZERO_8) ? 1 : 0;
logic asl_a_c; assign asl_a_c = `A[7];

`LOGIC_32 asl_ea; assign asl_ea = {`eA[30:0], 1'b0};
logic asl_ea_n; assign asl_ea_n = asl_ea[31];
logic asl_ea_z; assign asl_ea_z = (asl_ea == `ZERO_32) ? 1 : 0;
logic asl_ea_c; assign asl_ea_c = `eA[31];

`LOGIC_8 dec_a; assign dec_a = `A - `ONE_8;
logic dec_a_n; assign dec_a_n = dec_a[7];
logic dec_a_z; assign dec_a_z = (dec_a == `ZERO_8) ? 1 : 0;

`LOGIC_32 dec_ea; assign dec_ea = `eA - `ONE_32;
logic dec_ea_n; assign dec_ea_n = dec_ea[31];
logic dec_ea_z; assign dec_ea_z = (dec_ea == `ZERO_32) ? 1 : 0;

`LOGIC_8 dec_pc; assign dec_pc = `PC - `ONE_8;

`LOGIC_32 dec_epc; assign dec_epc = `ePC - `ONE_32;

`LOGIC_8 dec_sp; assign dec_sp = `SP - `ONE_8;

`LOGIC_32 dec_esp; assign dec_esp = `eSP - `ONE_32;

`LOGIC_8 dec_x; assign dec_x = `X - `ONE_8;
logic dec_x_n; assign dec_x_n = dec_x[7];
logic dec_x_z; assign dec_x_z = (dec_x == `ZERO_8) ? 1 : 0;

`LOGIC_32 dec_ex; assign dec_ex = `eX - `ONE_32;
logic dec_ex_n; assign dec_ex_n = dec_ex[31];
logic dec_ex_z; assign dec_ex_z = (dec_ex == `ZERO_32) ? 1 : 0;

`LOGIC_8 dec_y; assign dec_y = `Y - `ONE_8;
logic dec_y_n; assign dec_y_n = dec_y[7];
logic dec_y_z; assign dec_y_z = (dec_y == `ZERO_8) ? 1 : 0;

`LOGIC_32 dec_ey; assign dec_ey = `eY - `ONE_32;
logic dec_ey_n; assign dec_ey_n = dec_ey[31];
logic dec_ey_z; assign dec_ey_z = (dec_ey == `ZERO_32) ? 1 : 0;

`LOGIC_8 eor_a_src; assign eor_a_src = `A ^ `SRC;
logic eor_a_src_n; assign eor_a_src_n = eor_a_src[7];
logic eor_a_src_z; assign eor_a_src_z = (eor_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 eor_ea_src; assign eor_ea_src = `eA ^ `eSRC;
logic eor_ea_src_n; assign eor_ea_src_n = eor_ea_src[31];
logic eor_ea_src_z; assign eor_ea_src_z = (eor_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 inc_a; assign inc_a = `A + `ONE_8;
logic inc_a_n; assign inc_a_n = inc_a[7];
logic inc_a_z; assign inc_a_z = (inc_a == `ZERO_8) ? 1 : 0;

`LOGIC_32 inc_ea; assign inc_ea = `eA + `ONE_32;
logic inc_ea_n; assign inc_ea_n = inc_ea[31];
logic inc_ea_z; assign inc_ea_z = (inc_ea == `ZERO_32) ? 1 : 0;

`LOGIC_16 inc_addr; assign inc_addr = `ADDR + `ONE_16;

`LOGIC_16 inc_pc; assign inc_pc = `PC + `ONE_16;

`LOGIC_32 inc_epc; assign inc_epc = `ePC + `ONE_32;

`LOGIC_8 inc_sp; assign inc_sp = `SP + `ONE_8;

`LOGIC_32 inc_esp; assign inc_esp = `eSP + `ONE_32;

`LOGIC_8 inc_x; assign inc_x = `X + `ONE_8;
logic inc_x_n; assign inc_x_n = inc_x[7];
logic inc_x_z; assign inc_x_z = (inc_x == `ZERO_8) ? 1 : 0;

`LOGIC_32 inc_ex; assign inc_ex = `eX + `ONE_32;
logic inc_ex_n; assign inc_ex_n = inc_ex[31];
logic inc_ex_z; assign inc_ex_z = (inc_ex == `ZERO_32) ? 1 : 0;

`LOGIC_8 inc_y; assign inc_y = `Y + `ONE_8;
logic inc_y_n; assign inc_y_n = inc_y[7];
logic inc_y_z; assign inc_y_z = (inc_y == `ZERO_8) ? 1 : 0;

`LOGIC_32 inc_ey; assign inc_ey = `eY + `ONE_32;
logic inc_ey_n; assign inc_ey_n = inc_ey[31];
logic inc_ey_z; assign inc_ey_z = (inc_ey == `ZERO_32) ? 1 : 0;

`LOGIC_8 lsr_a; assign lsr_a = {1'b0, `A[7:1]};
logic lsr_a_n; assign lsr_a_n = lsr_a[7];
logic lsr_a_z; assign lsr_a_z = (lsr_a == `ZERO_8) ? 1 : 0;
logic lsr_a_c; assign lsr_a_c = `A[0];

`LOGIC_9 neg_a; assign neg_a = `ZERO_9 - uext_a_9;
logic neg_a_n; assign neg_a_n = neg_a[7];
logic neg_a_v; assign neg_a_v = neg_a[8] ^ neg_a[7];
logic neg_a_z; assign neg_a_z = (neg_a`VB == `ZERO_8) ? 1 : 0;
logic neg_a_c; assign neg_a_c = neg_a[8];

`LOGIC_33 neg_ea; assign neg_ea = `ZERO_33 - uext_ea_33;
logic neg_ea_n; assign neg_ea_n = neg_ea[31];
logic neg_ea_v; assign neg_ea_v = neg_ea[32] ^ neg_ea[31];
logic neg_ea_z; assign neg_ea_z = (neg_ea`VW == `ZERO_32) ? 1 : 0;
logic neg_ea_c; assign neg_ea_c = neg_ea[32];

`LOGIC_8 not_a; assign not_a = ~`A;
logic not_a_n; assign not_a_n = not_a[7];
logic not_a_z; assign not_a_z = (not_a == `ZERO_8) ? 1 : 0;

`LOGIC_32 not_ea; assign not_ea = ~`eA;
logic not_ea_n; assign not_ea_n = not_ea[31];
logic not_ea_z; assign not_ea_z = (not_ea == `ZERO_32) ? 1 : 0;

`LOGIC_8 or_a_src; assign or_a_src = `A | `SRC;
logic or_a_src_n; assign or_a_src_n = or_a_src[7];
logic or_a_src_z; assign or_a_src_z = (or_a_src == `ZERO_8) ? 1 : 0;

`LOGIC_32 or_ea_src; assign or_ea_src = `eA | `eSRC;
logic or_ea_src_n; assign or_ea_src_n = or_ea_src[31];
logic or_ea_src_z; assign or_ea_src_z = (or_ea_src == `ZERO_32) ? 1 : 0;

`LOGIC_8 rol_a; assign rol_a = {`A[6:0], `C};
logic rol_a_n; assign rol_a_n = rol_a[7];
logic rol_a_z; assign rol_a_z = (rol_a == `ZERO_8) ? 1 : 0;
logic rol_a_c; assign rol_a_c = `A[7];

`LOGIC_32 rol_ea; assign rol_ea = {`eA[30:0], `eC};
logic rol_ea_n; assign rol_ea_n = rol_ea[31];
logic rol_ea_z; assign rol_ea_z = (rol_ea == `ZERO_32) ? 1 : 0;
logic rol_ea_c; assign rol_ea_c = `eA[31];

`LOGIC_8 ror_a; assign ror_a = {`C, `A[7:1]};
logic ror_a_n; assign ror_a_n = ror_a[7];
logic ror_a_z; assign ror_a_z = (ror_a == `ZERO_8) ? 1 : 0;
logic ror_a_c; assign ror_a_c = `A[0];

`LOGIC_32 ror_ea; assign ror_ea = {`eC, `eA[30:0]};
logic ror_ea_n; assign ror_ea_n = ror_ea[31];
logic ror_ea_z; assign ror_ea_z = (ror_ea == `ZERO_32) ? 1 : 0;
logic ror_ea_c; assign ror_ea_c = `eA[0];

`LOGIC_9 sbc_a_src; assign sbc_a_src = uext_a_9 - uext_src_9 - uext_nc_9;
logic sbc_a_src_n; assign sbc_a_src_n = sbc_a_src[7];
logic sbc_a_src_v; assign sbc_a_src_v = sbc_a_src[8] ^ sbc_a_src[7];
logic sbc_a_src_z; assign sbc_a_src_z = (sbc_a_src`VB == `ZERO_8) ? 1 : 0;
logic sbc_a_src_c; assign sbc_a_src_c = sbc_a_src[8];

`LOGIC_33 sbc_ea_src; assign sbc_ea_src = uext_ea_33 - uext_esrc_33 - uext_nc_33;
logic sbc_ea_src_n; assign sbc_ea_src_n = sbc_ea_src[31];
logic sbc_ea_src_v; assign sbc_ea_src_v = sbc_ea_src[32] ^ sbc_ea_src[31];
logic sbc_ea_src_z; assign sbc_ea_src_z = (sbc_ea_src`VW == `ZERO_32) ? 1 : 0;
logic sbc_ea_src_c; assign sbc_ea_src_c = sbc_ea_src[32];

`LOGIC_9 sub_a_src; assign sub_a_src = uext_a_9 - uext_src_9;
logic sub_a_src_n; assign sub_a_src_n = sub_a_src[7];
logic sub_a_src_v; assign sub_a_src_v = sub_a_src[8] ^ sub_a_src[7];
logic sub_a_src_z; assign sub_a_src_z = (sub_a_src`VB == `ZERO_8) ? 1 : 0;
logic sub_a_src_c; assign sub_a_src_c = sub_a_src[8];

`LOGIC_33 sub_ea_src; assign sub_ea_src = uext_ea_33 - uext_esrc_33;
logic sub_ea_src_n; assign sub_ea_src_n = sub_ea_src[31];
logic sub_ea_src_v; assign sub_ea_src_v = sub_ea_src[32] ^ sub_ea_src[31];
logic sub_ea_src_z; assign sub_ea_src_z = (sub_ea_src`VW == `ZERO_32) ? 1 : 0;
logic sub_ea_src_c; assign sub_ea_src_c = sub_ea_src[32];

`LOGIC_32 offset_address; assign offset_address = reg_address + reg_offset;

//-------------------------------------------------------------------------------

`define do_sext_var_9  `LOGIC_9 sext_var_9; sext_var_9 = {var_ram_byte[7], var_ram_byte};
`define do_sext_var_16  `LOGIC_16 sext_var_16; sext_var_16 = {var_ram_byte[7] ? `ONES_8 : `ZERO_8, var_ram_byte};
`define do_sext_var_32  `LOGIC_32 sext_var_32; sext_var_32 = {var_ram_byte[7] ? `ONES_24 : `ZERO_24, var_ram_byte};
`define do_sext_var_33  `LOGIC_33 sext_var_33; sext_var_33 = {var_ram_byte[7] ? `ONES_25 : `ZERO_25, var_ram_byte};
`define do_sext_evar_33  `LOGIC_33 sext_evar_33; sext_evar_33 = {var_ram_word[31], var_ram_word};

`define do_sext_evar_24_32  `LOGIC_32 sext_evar_24_32; sext_evar_24_32 = {var_ram_word[23] ? `ONES_8 : `ZERO_8, var_ram_word[23:0]};
`define do_sext_evar_24_33  `LOGIC_33 sext_evar_24_33; sext_evar_24_33 = {var_ram_word[23] ? `ONES_9 : `ZERO_9, var_ram_word[23:0]};
`define do_sext_evar_32_33  `LOGIC_33 sext_evar_32_33; sext_evar_24_33 = {var_ram_word[31], var_ram_word};

`define do_uext_var_9  `LOGIC_9 uext_var_9; uext_var_9 = { 1'd0, var_ram_byte};
`define do_uext_var_16  `LOGIC_16 uext_var_16; uext_var_16 = { `ZERO_8, var_ram_byte};
`define do_uext_var_32  `LOGIC_32 uext_var_32; uext_var_32 = { `ZERO_24, var_ram_byte};
`define do_uext_var_33  `LOGIC_33 uext_var_33; uext_var_33 = { `ZERO_25, var_ram_byte};
`define do_uext_evar_33  `LOGIC_33 uext_evar_33; uext_evar_33 = { 1'd0, var_ram_word};

//-------------------------------------------------------------------------------

`define do_add_a_var  `LOGIC_9 add_a_var; add_a_var = uext_a_9 + uext_var_9;
`define do_add_a_var_n  logic add_a_var_n; add_a_var_n = add_a_var[7];
`define do_add_a_var_v  logic add_a_var_v; add_a_var_v = add_a_var[8] ^ add_a_var[7];
`define do_add_a_var_z  logic add_a_var_z; add_a_var_z = (add_a_var`VB == `ZERO_8) ? 1 : 0;
`define do_add_a_var_c  logic add_a_var_c; add_a_var_c = add_a_var[8];

`define do_add_ea_var  `LOGIC_33 add_ea_var; add_ea_var = uext_ea_33 + uext_evar_33;
`define do_add_ea_var_n  logic add_ea_var_n; add_ea_var_n = add_ea_var[31];
`define do_add_ea_var_v  logic add_ea_var_v; add_ea_var_v = add_ea_var[32] ^ add_ea_var[31];
`define do_add_ea_var_z  logic add_ea_var_z; add_ea_var_z = (add_ea_var`VW == `ZERO_32) ? 1 : 0;
`define do_add_ea_var_c  logic add_ea_var_c; add_ea_var_c = add_ea_var[32];

`define do_add_pc_var  `LOGIC_16 add_pc_var; add_pc_var = `PC + sext_var_16;

`define do_add_epc_var  `LOGIC_32 add_epc_var; add_epc_var = `ePC + sext_var_32;
`define do_add_epc_var_24  `LOGIC_32 add_epc_var_24; add_epc_var_24 = `ePC + sext_evar_24_32;

`define do_adc_a_var  `LOGIC_9 adc_a_var; adc_a_var = uext_a_9 + uext_var_9 + uext_c_9;
`define do_adc_a_var_n  logic adc_a_var_n; adc_a_var_n = adc_a_var[7];
`define do_adc_a_var_v  logic adc_a_var_v; adc_a_var_v = adc_a_var[8] ^ adc_a_var[7];
`define do_adc_a_var_z  logic adc_a_var_z; adc_a_var_z = (adc_a_var`VB == `ZERO_8) ? 1 : 0;
`define do_adc_a_var_c  logic adc_a_var_c; adc_a_var_c = adc_a_var[8];

`define do_adc_ea_var  `LOGIC_33 adc_ea_var; adc_ea_var = uext_ea_33 + uext_evar_33 + uext_c_33;
`define do_adc_ea_var_n  logic adc_ea_var_n; adc_ea_var_n = adc_ea_var[31];
`define do_adc_ea_var_v  logic adc_ea_var_v; adc_ea_var_v = adc_ea_var[32] ^ adc_ea_var[31];
`define do_adc_ea_var_z  logic adc_ea_var_z; adc_ea_var_z = (adc_ea_var`VW == `ZERO_32) ? 1 : 0;
`define do_adc_ea_var_c  logic adc_ea_var_c; adc_ea_var_c = adc_ea_var[32];

`define do_and_a_var  `LOGIC_8 and_a_var; and_a_var = `A & var_ram_byte;
`define do_and_a_var_n  logic and_a_var_n; and_a_var_n = and_a_var[7];
`define do_and_a_var_v  logic and_a_var_v; and_a_var_v = and_a_var[6];
`define do_and_a_var_z  logic and_a_var_z; and_a_var_z = (and_a_var == `ZERO_8) ? 1 : 0;

`define do_and_ea_var  `LOGIC_32 and_ea_var; and_ea_var = `eA & var_ram_word;
`define do_and_ea_var_n  logic and_ea_var_n; and_ea_var_n = and_ea_var[31];
`define do_and_ea_var_v  logic and_ea_var_v; and_ea_var_v = and_ea_var[30];
`define do_and_ea_var_z  logic and_ea_var_z; and_ea_var_z = (and_ea_var == `ZERO_32) ? 1 : 0;

`define do_and_not_a_var  `LOGIC_8 and_not_a_var; and_not_a_var = ~`A & var_ram_byte;
`define do_and_not_a_var_n  logic and_not_a_var_n; and_not_a_var_n = and_not_a_var[7];
`define do_and_not_a_var_v  logic and_not_a_var_v; and_not_a_var_v = and_not_a_var[6];
`define do_and_not_a_var_z  logic and_not_a_var_z; and_not_a_var_z = (and_not_a_var == `ZERO_8) ? 1 : 0;

`define do_and_not_ea_var  `LOGIC_32 and_not_ea_var; and_not_ea_var = ~`eA & var_ram_word;
`define do_and_not_ea_var_n  logic and_not_ea_var_n; and_not_ea_var_n = and_not_ea_var[31];
`define do_and_not_ea_var_v  logic and_not_ea_var_v; and_not_ea_var_v = and_not_ea_var[30];
`define do_and_not_ea_var_z  logic and_not_ea_var_z; and_not_ea_var_z = (and_not_ea_var == `ZERO_32) ? 1 : 0;

`define do_asl_var  `LOGIC_8 asl_var; asl_var = {var_ram_byte[6:0], 1'b0};
`define do_asl_var_n  logic asl_var_n; asl_var_n = asl_var[7];
`define do_asl_var_z  logic asl_var_z; asl_var_z = (asl_var == `ZERO_8) ? 1 : 0;
`define do_asl_var_c  logic asl_var_c; asl_var_c = var_ram_byte[7];

`define do_asl_evar  `LOGIC_32 asl_evar; asl_evar = {var_ram_word[30:0], 1'b0};
`define do_asl_evar_n  logic asl_evar_n; asl_evar_n = asl_evar[31];
`define do_asl_evar_z  logic asl_evar_z; asl_evar_z = (asl_evar == `ZERO_32) ? 1 : 0;
`define do_asl_evar_c  logic asl_evar_c; asl_evar_c = var_ram_word[31];

`define do_dec_var  `LOGIC_8 dec_var; dec_var = var_ram_byte - `ONE_8;
`define do_dec_var_n  logic dec_var_n; dec_var_n = dec_var[7];
`define do_dec_var_z  logic dec_var_z; dec_var_z = (dec_var == `ZERO_8) ? 1 : 0;

`define do_dec_evar  `LOGIC_32 dec_evar; dec_evar = var_ram_word - `ONE_32;
`define do_dec_evar_n  logic dec_evar_n; dec_evar_n = dec_evar[31];
`define do_dec_evar_z  logic dec_evar_z; dec_evar_z = (dec_evar == `ZERO_32) ? 1 : 0;

`define do_eor_a_var  `LOGIC_8 eor_a_var; eor_a_var = `A ^ var_ram_byte;
`define do_eor_a_var_n  logic eor_a_var_n; eor_a_var_n = eor_a_var[7];
`define do_eor_a_var_z  logic eor_a_var_z; eor_a_var_z = (eor_a_var == `ZERO_8) ? 1 : 0;

`define do_eor_ea_var  `LOGIC_32 eor_ea_var; eor_ea_var = `eA ^ var_ram_word;
`define do_eor_ea_var_n  logic eor_ea_var_n; eor_ea_var_n = eor_ea_var[31];
`define do_eor_ea_var_z  logic eor_ea_var_z; eor_ea_var_z = (eor_ea_var == `ZERO_32) ? 1 : 0;

`define do_inc_var  `LOGIC_8 inc_var; inc_var = var_ram_byte + `ONE_8;
`define do_inc_var_n  logic inc_var_n; inc_var_n = inc_var[7];
`define do_inc_var_z  logic inc_var_z; inc_var_z = (inc_var == `ZERO_8) ? 1 : 0;

`define do_inc_evar  `LOGIC_32 inc_evar; inc_evar = var_ram_word + `ONE_32;
`define do_inc_evar_n  logic inc_evar_n; inc_evar_n = inc_evar[31];
`define do_inc_evar_z  logic inc_evar_z; inc_evar_z = (inc_evar == `ZERO_32) ? 1 : 0;

`define do_lsr_var  `LOGIC_8 lsr_var; lsr_var = {1'b0, var_ram_byte[7:1]};
`define do_lsr_var_n  logic lsr_var_n; lsr_var_n = lsr_var[7];
`define do_lsr_var_z  logic lsr_var_z; lsr_var_z = (lsr_var == `ZERO_8) ? 1 : 0;
`define do_lsr_var_c  logic lsr_var_c; lsr_var_c = var_ram_byte[0];

`define do_neg_var  `LOGIC_8 neg_var; neg_var = `ZERO_8 - var_ram_byte;
`define do_neg_var_n  logic neg_var_n; neg_var_n = neg_var[7];
`define do_neg_var_z  logic neg_var_z; neg_var_z = (neg_var == `ZERO_8) ? 1 : 0;

`define do_neg_evar  `LOGIC_32 neg_evar; neg_evar = `ZERO_32 - var_ram_word;
`define do_neg_evar_n  logic neg_evar_n; neg_evar_n = neg_evar[31];
`define do_neg_evar_z  logic neg_evar_z; neg_evar_z = (neg_evar == `ZERO_32) ? 1 : 0;

`define do_not_var  `LOGIC_8 not_var; not_var = ~var_ram_byte;
`define do_not_var_n  logic not_var_n; not_var_n = not_var[7];
`define do_not_var_z  logic not_var_z; not_var_z = (not_var == `ZERO_8) ? 1 : 0;

`define do_not_evar  `LOGIC_32 not_evar; not_evar = ~var_ram_word;
`define do_not_evar_n  logic not_evar_n; not_evar_n = not_evar[31];
`define do_not_evar_z  logic not_evar_z; not_evar_z = (not_evar == `ZERO_32) ? 1 : 0;

`define do_or_a_var  `LOGIC_8 or_a_var; or_a_var = `A | var_ram_byte;
`define do_or_a_var_n  logic or_a_var_n; or_a_var_n = or_a_var[7];
`define do_or_a_var_z  logic or_a_var_z; or_a_var_z = (or_a_var == `ZERO_8) ? 1 : 0;

`define do_or_ea_var  `LOGIC_32 or_ea_var; or_ea_var = `eA | var_ram_word;
`define do_or_ea_var_n  logic or_ea_var_n; or_ea_var_n = or_ea_var[31];
`define do_or_ea_var_z  logic or_ea_var_z; or_ea_var_z = (or_ea_var == `ZERO_32) ? 1 : 0;

`define do_rol_var  `LOGIC_8 rol_var; rol_var = {var_ram_byte[6:0], `C};
`define do_rol_var_n  logic rol_var_n; rol_var_n = rol_var[7];
`define do_rol_var_z  logic rol_var_z; rol_var_z = (rol_var == `ZERO_8) ? 1 : 0;
`define do_rol_var_c  logic rol_var_c; rol_var_c = var_ram_byte[7];

`define do_rol_evar  `LOGIC_32 rol_evar; rol_evar = {var_ram_word[30:0], `eC};
`define do_rol_evar_n  logic rol_evar_n; rol_evar_n = rol_evar[31];
`define do_rol_evar_z  logic rol_evar_z; rol_evar_z = (rol_evar == `ZERO_32) ? 1 : 0;
`define do_rol_evar_c  logic rol_evar_c; rol_evar_c = var_ram_word[31];

`define do_ror_var  `LOGIC_8 ror_var; ror_var = {`C, var_ram_byte[7:1]};
`define do_ror_var_n  logic ror_var_n; ror_var_n = ror_var[7];
`define do_ror_var_z  logic ror_var_z; ror_var_z = (ror_var == `ZERO_8) ? 1 : 0;
`define do_ror_var_c  logic ror_var_c; ror_var_c = var_ram_byte[0];

`define do_ror_evar  `LOGIC_32 ror_evar; ror_evar = {`eC, var_ram_word[30:0]};
`define do_ror_evar_n  logic ror_evar_n; ror_evar_n = ror_evar[31];
`define do_ror_evar_z  logic ror_evar_z; ror_evar_z = (ror_evar == `ZERO_32) ? 1 : 0;
`define do_ror_evar_c  logic ror_evar_c; ror_evar_c = var_ram_word[0];

`define do_sbc_a_var  `LOGIC_9 sbc_a_var; sbc_a_var = uext_a_9 - uext_var_9 - uext_nc_9;
`define do_sbc_a_var_n  logic sbc_a_var_n; sbc_a_var_n = sbc_a_var[7];
`define do_sbc_a_var_v  logic sbc_a_var_v; sbc_a_var_v = sbc_a_var[8] ^ sbc_a_var[7];
`define do_sbc_a_var_z  logic sbc_a_var_z; sbc_a_var_z = (sbc_a_var`VB == `ZERO_8) ? 1 : 0;
`define do_sbc_a_var_c  logic sbc_a_var_c; sbc_a_var_c = sbc_a_var[8];

`define do_sbc_ea_var  `LOGIC_33 sbc_ea_var; sbc_ea_var = uext_ea_33 - uext_evar_33 - uext_nc_33;
`define do_sbc_ea_var_n  logic sbc_ea_var_n; sbc_ea_var_n = sbc_ea_var[31];
`define do_sbc_ea_var_v  logic sbc_ea_var_v; sbc_ea_var_v = sbc_ea_var[32] ^ sbc_ea_var[31];
`define do_sbc_ea_var_z  logic sbc_ea_var_z; sbc_ea_var_z = (sbc_ea_var`VW == `ZERO_32) ? 1 : 0;
`define do_sbc_ea_var_c  logic sbc_ea_var_c; sbc_ea_var_c = sbc_ea_var[32];

`define do_sub_a_var  `LOGIC_9 sub_a_var; sub_a_var = uext_a_9 - uext_var_9;
`define do_sub_a_var_n  logic sub_a_var_n; sub_a_var_n = sub_a_var[7];
`define do_sub_a_var_v  logic sub_a_var_v; sub_a_var_v = sub_a_var[8] ^ sub_a_var[7];
`define do_sub_a_var_z  logic sub_a_var_z; sub_a_var_z = (sub_a_var`VB == `ZERO_8) ? 1 : 0;
`define do_sub_a_var_c  logic sub_a_var_c; sub_a_var_c = sub_a_var[8];

`define do_sub_ea_var  `LOGIC_33 sub_ea_var; sub_ea_var = uext_ea_33 - uext_evar_33;
`define do_sub_ea_var_n  logic sub_ea_var_n; sub_ea_var_n = sub_ea_var[31];
`define do_sub_ea_var_v  logic sub_ea_var_v; sub_ea_var_v = sub_ea_var[32] ^ sub_ea_var[31];
`define do_sub_ea_var_z  logic sub_ea_var_z; sub_ea_var_z = (sub_ea_var`VW == `ZERO_32) ? 1 : 0;
`define do_sub_ea_var_c  logic sub_ea_var_c; sub_ea_var_c = sub_ea_var[32];

`define do_sub_x_var  `LOGIC_9 sub_x_var; sub_x_var = uext_x_9 - uext_var_9;
`define do_sub_x_var_n  logic sub_x_var_n; sub_x_var_n = sub_x_var[7];
`define do_sub_x_var_v  logic sub_x_var_v; sub_x_var_v = sub_x_var[8] ^ sub_x_var[7];
`define do_sub_x_var_z  logic sub_x_var_z; sub_x_var_z = (sub_x_var`VB == `ZERO_8) ? 1 : 0;
`define do_sub_x_var_c  logic sub_x_var_c; sub_x_var_c = sub_x_var[8];

`define do_sub_ex_var  `LOGIC_33 sub_ex_var; sub_ex_var = uext_ex_33 - uext_evar_33;
`define do_sub_ex_var_n  logic sub_ex_var_n; sub_ex_var_n = sub_ex_var[31];
`define do_sub_ex_var_v  logic sub_ex_var_v; sub_ex_var_v = sub_ex_var[32] ^ sub_ex_var[31];
`define do_sub_ex_var_z  logic sub_ex_var_z; sub_ex_var_z = (sub_ex_var`VW == `ZERO_32) ? 1 : 0;
`define do_sub_ex_var_c  logic sub_ex_var_c; sub_ex_var_c = sub_ex_var[32];

`define do_sub_y_var  `LOGIC_9 sub_y_var; sub_y_var = uext_y_9 - uext_var_9;
`define do_sub_y_var_n  logic sub_y_var_n; sub_y_var_n = sub_y_var[7];
`define do_sub_y_var_v  logic sub_y_var_v; sub_y_var_v = sub_y_var[8] ^ sub_y_var[7];
`define do_sub_y_var_z  logic sub_y_var_z; sub_y_var_z = (sub_y_var`VB == `ZERO_8) ? 1 : 0;
`define do_sub_y_var_c  logic sub_y_var_c; sub_y_var_c = sub_y_var[8];

`define do_sub_ey_var  `LOGIC_33 sub_ey_var; sub_ey_var = uext_ey_33 - uext_evar_33;
`define do_sub_ey_var_n  logic sub_ey_var_n; sub_ey_var_n = sub_ey_var[31];
`define do_sub_ey_var_v  logic sub_ey_var_v; sub_ey_var_v = sub_ey_var[32] ^ sub_ey_var[31];
`define do_sub_ey_var_z  logic sub_ey_var_z; sub_ey_var_z = (sub_ey_var`VW == `ZERO_32) ? 1 : 0;
`define do_sub_ey_var_c  logic sub_ey_var_c; sub_ey_var_c = sub_ey_var[32];

//-------------------------------------------------------------------------------

`define END_INSTR           reg_cycle <= 0
`define END_OPER(op)        op <= 0
`define END_OPER_INSTR(op)  `END_OPER(op); `END_INSTR
`define STORE_AFTER_OP(op)  `END_OPER(op); store_to_address <= 1
`define STORE_DST           store_to_address <= 1

logic address_text_peripheral;
assign address_text_peripheral = (reg_address[15:7] == `TEXT_PERIPH_BASE_HIGH_PART);

logic initiate_read_text;
assign initiate_read_text =
    ~transfer_in_progress &
    load_from_address &
    ~o_bus_clk &
    address_text_peripheral &
    ~i_bus_data_ready;

logic reading_text;
assign reading_text =
    transfer_in_progress &
    load_from_address &
    o_bus_clk &
    address_text_peripheral &
    ~i_bus_data_ready;

logic initiate_write_text;
assign initiate_write_text =
    ~transfer_in_progress &
    store_to_address &
    ~o_bus_clk &
    address_text_peripheral;

logic writing_text;
assign writing_text =
    transfer_in_progress &
    store_to_address &
    o_bus_clk &
    address_text_peripheral;

assign o_cycle = reg_cycle;
assign o_pc = reg_pc;
assign o_ad = reg_address;
assign o_cb = reg_code_byte;
assign o_rb = reg_data_byte;
assign o_a = `A;
assign o_x = `X;
assign o_y = `Y;

logic push_edst0;
logic push_edst1;

always @(posedge i_clk) begin
    if (i_rst) begin
        o_bus_clk <= 0;
        o_bus_we <= 0;
        o_bus_addr <= 0;
        o_bus_data <= 0;
    end else begin
        if (load_from_address) begin
            if (initiate_read_text) begin
                o_bus_clk <= 1;
                o_bus_we <= 0;
                o_bus_addr <= offset_address;
            end else if (o_bus_clk && i_bus_data_ready) begin
                o_bus_clk <= 0;
            end
        end else if (store_to_address) begin
            if (initiate_write_text) begin
                o_bus_clk <= 1;
                o_bus_we <= 1;
                o_bus_addr <= offset_address;
                o_bus_data <= {`ZERO_24, `DST};
            end else if (o_bus_clk) begin
                o_bus_clk <= 0;
            end
        end
    end
end

always @(posedge i_clk) begin
    if (i_rst) begin
        o_bus_clk <= 0;
        o_bus_we <= 0;
        o_bus_addr <= 0;
        o_bus_data <= 0;
    end else begin
        if (load_from_address) begin
            if (initiate_read_text) begin
                o_bus_clk <= 1;
                o_bus_we <= 0;
                o_bus_addr <= offset_address;
            end else if (o_bus_clk && i_bus_data_ready) begin
                o_bus_clk <= 0;
            end
        end else if (store_to_address) begin
            if (initiate_write_text) begin
                o_bus_clk <= 1;
                o_bus_we <= 1;
                o_bus_addr <= offset_address;
                o_bus_data <= {`ZERO_24, `DST};
            end else if (o_bus_clk) begin
                o_bus_clk <= 0;
            end
        end
    end
end

reg bram_wea,           // write enable A
reg bram_web,           // write enable B
reg bram_clka,          // clock A
reg bram_clkb,          // clock B
reg `VB bram_dia,       // data in A
reg `VB bram_dib,       // data in B
reg `VHW bram_addra,    // address A
reg `VHW bram_addrb,    // address B
reg `VB bram_doa,       // data out A
reg `VB bram_dob        // data out B


always @(posedge i_clk) begin
    if (push_edst1) begin
        `STACK_BYTE <= `eDST1;
    end else if (push_edst0) begin
        `STACK_BYTE <= `eDST0;
    end
end

`LOGIC_32 delay;

always @(posedge i_rst or posedge i_clk) begin
    integer i;

    if (i_rst) begin
        delay <= 0;

        reg_6502 <= 1;
        `PC <= `RESET_PC_ADDRESS;
        `SP <= `RESET_SP_ADDRESS;
        `P <= `RESET_STATUS_BITS;
        `X <= `ZERO_8;
        `Y <= `ZERO_8;

        reg_65832 <= 0;
        `ePC <= `ZERO_32;
        `eSP <= `ZERO_32;
        `eP <= `RESET_STATUS_BITS;
        `eX <= `ZERO_32;
        `eY <= `ZERO_32;

        reg_cycle <= 2; // Force JMP via Reset vector
        reg_which <= 0;
        reg_address <= 0;
        reg_src_data <= 0;
        reg_dst_data <= 0;
        reg_code_byte <= 8'hCC;
        reg_data_byte <= 8'hDD;

        am_ABS_a <= 1; // Force JMP via Reset vector
        am_ACC_A <= 0;
        am_AIA_A <= 0;
        am_AIIX_A_X <= 0;
        am_AIX_a_x <= 0;
        am_AIY_a_y <= 0;
        am_IMM_m <= 0;
        am_PCR_r <= 0;
        am_STK_s <= 0;
        am_ZIIX_ZP_X <= 0;
        am_ZIIY_ZP_y <= 0;
        am_ZIX_zp_x <= 0;
        am_ZIY_zp_y <= 0;
        am_ZPG_zp <= 0;
        am_ZPI_ZP <= 0;

        ame_ABS_a <= 0;
        ame_AIA_A <= 0;
        ame_AIIX_A_X <= 0;
        ame_AIIY_A_y <= 0;
        ame_AIX_a_x <= 0;
        ame_AIY_a_y <= 0;
        ame_STK_s <= 0;

        load_from_address <= 0;
        store_to_address <= 0;
        transfer_in_progress <= 0;
        push_edst0 <= 0;
        push_edst1 <= 1;

        op_ADC <= 0;
        op_ADD <= 0;
        op_AND <= 0;
        op_ASL <= 0;
        op_BBR <= 0;
        op_BRANCH <= 0;
        op_BBS <= 0;
        op_BIT <= 0;
        op_BRK <= 0;
        op_CMP <= 0;
        op_CPX <= 0;
        op_CPY <= 0;
        op_DEC <= 0;
        op_EOR <= 0;
        op_INC <= 0;
        op_JMP <= 1; // Force JMP via Reset vector
        op_JSR <= 0;
        op_LDA <= 0;
        op_LDX <= 0;
        op_LDY <= 0;
        op_LSR <= 0;
        op_ORA <= 0;
        op_PHA <= 0;
        op_PHP <= 0;
        op_PHX <= 0;
        op_PHY <= 0;
        op_PLA <= 0;
        op_PLP <= 0;
        op_PLX <= 0;
        op_PLY <= 0;
        op_RMB <= 0;
        op_ROL <= 0;
        op_ROR <= 0;
        op_RTI <= 0;
        op_RTS <= 0;
        op_SBC <= 0;
        op_SMB <= 0;
        op_STA <= 0;
        op_STP <= 0;
        op_STX <= 0;
        op_STY <= 0;
        op_STZ <= 0;
        op_SUB <= 0;
        op_TRB <= 0;
        op_TSB <= 0;
        op_WAI <= 0;

    end else if (push_edst1) begin
        push_edst1 <= 0;
        push_edst0 <= 1;
    end else if (push_edst0) begin
        push_edst0 <= 0;
        `END_INSTR;
    end else if (~transfer_in_progress & (load_from_address | store_to_address)) begin
        transfer_in_progress <= 1;
    end else if (transfer_in_progress) begin
        if (~o_bus_clk) begin
            load_from_address <= 0;
            store_to_address <= 0;
            transfer_in_progress <= 0;
            `END_INSTR;
        end
    end else if (delay < 5000000) begin
        delay <= delay + 1;
    end else begin
        delay <= 0;
        reg_cycle <= reg_cycle + 1; // Assume micro-instructions will continue.

        if (reg_6502) begin
            if (load_from_address) begin
                load_from_address <= 0;

                if (i_bus_data_ready) begin
                    var_ram_byte = i_bus_data`VB;
                end else begin
                    var_ram_byte = `DATA_BYTE;
                end

                if (op_ADC) begin
                    `do_uext_var_9;
                    `do_adc_a_var; `A <= adc_a_var;
                    `do_adc_a_var_n; `N <= adc_a_var_n;
                    `do_adc_a_var_v; `V <= adc_a_var_v;
                    `do_adc_a_var_z; `Z <= adc_a_var_z;
                    `do_adc_a_var_c; `C <= adc_a_var_c;
                    `END_OPER_INSTR(op_ADC);
                end else if (op_AND) begin
                    `do_and_a_var; `A <= and_a_var;
                    `do_and_a_var_n; `N <= and_a_var_n;
                    `do_and_a_var_z; `Z <= and_a_var_z;
                    `END_OPER_INSTR(op_AND);
                end else if (op_ASL) begin
                    `do_asl_var; `DST <= var_ram_byte;
                    `do_asl_var_n; `N <= asl_var_n;
                    `do_asl_var_z; `Z <= asl_var_z;
                    `do_asl_var_c; `C <= asl_var_c;
                    `STORE_AFTER_OP(op_ASL);
                end else if (op_BIT) begin
                    `do_and_a_var;
                    `do_and_a_var_n; `N <= and_a_var_n;
                    `do_and_a_var_v; `V <= and_a_var_v;
                    `do_and_a_var_z; `Z <= and_a_var_z;
                    `END_OPER_INSTR(op_BIT);
                end else if (op_CMP) begin
                    `do_uext_var_9;
                    `do_sub_a_var;
                    `do_sub_a_var_n; `N <= sub_a_var_n;
                    `do_sub_a_var_v; `V <= sub_a_var_v;
                    `do_sub_a_var_z; `Z <= sub_a_var_z;
                    `do_sub_a_var_c; `C <= sub_a_var_c;
                    `END_OPER_INSTR(op_CMP);
                end else if (op_CPX) begin
                    `do_uext_var_9;
                    `do_sub_x_var;
                    `do_sub_x_var_n; `N <= sub_x_var_n;
                    `do_sub_x_var_v; `V <= sub_x_var_v;
                    `do_sub_x_var_z; `Z <= sub_x_var_z;
                    `do_sub_x_var_c; `C <= sub_x_var_c;
                    `END_OPER_INSTR(op_CPX);
                end else if (op_CPY) begin
                    `do_uext_var_9;
                    `do_sub_y_var;
                    `do_sub_y_var_n; `N <= sub_y_var_n;
                    `do_sub_y_var_v; `V <= sub_y_var_v;
                    `do_sub_y_var_z; `Z <= sub_y_var_z;
                    `do_sub_y_var_c; `C <= sub_y_var_c;
                    `END_OPER_INSTR(op_CPY);
                end else if (op_DEC) begin
                    `do_dec_var; `DST <= var_ram_byte;
                    `do_dec_var_n; `N <= dec_var_n;
                    `do_dec_var_z; `Z <= dec_var_z;
                    `STORE_AFTER_OP(op_DEC);
                end else if (op_EOR) begin
                    `do_eor_a_var; `A <= eor_a_var;
                    `do_eor_a_var_n; `N <= eor_a_var_n;
                    `do_eor_a_var_z; `Z <= eor_a_var_z;
                    `END_OPER_INSTR(op_EOR);
                end else if (op_INC) begin
                    `do_inc_var; `DST <= var_ram_byte;
                    `do_inc_var_n; `N <= inc_var_n;
                    `do_inc_var_z; `Z <= inc_var_z;
                    `STORE_AFTER_OP(op_INC);
                end else if (op_LDA | op_PLA) begin
                    `A <= var_ram_byte;
                    `N <= var_ram_byte[7];
                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                    `END_OPER(op_PLA);
                    `END_OPER_INSTR(op_LDA);
                end else if (op_LDX | op_PLX) begin
                    `X <= var_ram_byte;
                    `N <= var_ram_byte[7];
                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                    `END_OPER(op_PLX);
                    `END_OPER_INSTR(op_LDX);
                end else if (op_LDY | op_PLY) begin
                    `Y <= var_ram_byte;
                    `N <= var_ram_byte[7];
                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                    `END_OPER(op_PLY);
                    `END_OPER_INSTR(op_LDY);
                end else if (op_PLP) begin
                    `P <= var_ram_byte;
                    `END_OPER_INSTR(op_PLP);
                end else if (op_LSR) begin
                    `do_lsr_var; `DST <= var_ram_byte;
                    `do_lsr_var_n; `N <= lsr_var_n;
                    `do_lsr_var_z; `Z <= lsr_var_z;
                    `do_lsr_var_c; `C <= lsr_var_c;
                    `STORE_AFTER_OP(op_LSR);
                end else if (op_ORA) begin
                    `do_or_a_var; `A <= or_a_var;
                    `do_or_a_var_n; `N <= or_a_var_n;
                    `do_or_a_var_z; `Z <= or_a_var_z;
                    `END_OPER_INSTR(op_ORA);
                end else if (op_RMB) begin
                    `DST <= var_ram_byte &(~reg_which);
                    `STORE_AFTER_OP(op_RMB);
                end else if (op_ROL) begin
                    `do_rol_var; `DST <= var_ram_byte;
                    `do_rol_var_n; `N <= rol_var_n;
                    `do_rol_var_z; `Z <= rol_var_z;
                    `do_rol_var_c; `C <= rol_var_c;
                    `STORE_AFTER_OP(op_ROL);
                end else if (op_ROR) begin
                    `do_ror_var; `DST <= var_ram_byte;
                    `do_ror_var_n; `N <= ror_var_n;
                    `do_ror_var_z; `Z <= ror_var_z;
                    `do_ror_var_c; `C <= ror_var_c;
                    `STORE_AFTER_OP(op_ROR);
                end else if (op_SBC) begin
                    `do_uext_var_9;
                    `do_sbc_a_var; `A <= sbc_a_var;
                    `do_sbc_a_var_c; `C <= sbc_a_var_c;
                    `do_sbc_a_var_v; `V <= sbc_a_var_v;
                    `do_sbc_a_var_n; `N <= sbc_a_var_n;
                    `do_sbc_a_var_z; `Z <= sbc_a_var_z;
                    `END_OPER_INSTR(op_SBC);
                end else if (op_SMB) begin
                    `DST <= var_ram_byte | reg_which;
                    `STORE_AFTER_OP(op_RMB);
                end else if (op_SUB) begin
                    `do_uext_var_9;
                    `do_sub_a_var; `A <= sub_a_var;
                    `do_sub_a_var_n; `N <= sub_a_var_n;
                    `do_sub_a_var_v; `V <= sub_a_var_v;
                    `do_sub_a_var_z; `Z <= sub_a_var_z;
                    `do_sub_a_var_c; `C <= sub_a_var_c;
                    `END_OPER_INSTR(op_SUB);
                end else if (op_TRB) begin
                    `do_and_a_var;
                    `do_and_a_var_z; `Z <= and_a_var_z;
                    `do_and_not_a_var;
                    `STORE_AFTER_OP(op_TRB);
                end else if (op_TSB) begin
                    `do_and_a_var;
                    `do_and_a_var_z; `Z <= and_a_var_z;
                    `do_or_a_var;
                    `STORE_AFTER_OP(op_TSB);
                end
            end else begin
                case (reg_cycle)
                    0: begin // 6502 cycle 0
                            reg_code_byte <= `CODE_BYTE;
                            `PC <= inc_pc;
                        end
                    1: begin // 6502 cycle 1
                            case (reg_code_byte)
                                8'h00: begin
                                        op_BRK <= 1;
                                        am_STK_s <= 1;
                                    end

                                8'h01: begin
                                        op_ORA <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h02: begin
                                        op_ADD <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h03: begin
                                        op_SUB <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h04: begin
                                        op_TSB <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h05: begin
                                        op_ORA <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h06: begin
                                        op_ASL <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h07, 8'h17, 8'h27, 8'h37,
                                8'h47, 8'h57, 8'h67, 8'h77:
                                    begin
                                        op_RMB <= 1;
                                        am_ZPG_zp <= 1;
                                        reg_which <= (`ONE_8 << reg_code_byte[6:4]);
                                    end

                                8'h08: begin
                                        // PHP
                                        var_hw_address = dec_sp;
                                        `SP <= var_hw_address;
                                        `ADDR <= var_hw_address;
                                        `DST <= `P;
                                        `STORE_DST;
                                    end

                                8'h09: begin
                                        op_ORA <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h0A: begin
                                        // ASL
                                        `A <= asl_a;
                                        `N <= asl_a_n;
                                        `Z <= asl_a_z;
                                        `C <= asl_a_c;
                                        `END_INSTR;
                                    end

                                8'h0C: begin
                                        op_TSB <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h0D: begin
                                        op_ORA <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h0E: begin
                                        op_ASL <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h0F, 8'h1F, 8'h2F, 8'h3F,
                                8'h4F, 8'h5F, 8'h6F, 8'h7F:
                                    begin
                                        op_BBR <= 1;
                                        am_PCR_r <= 1;
                                        reg_which <= (`ONE_8 << reg_code_byte[6:4]);
                                    end

                                8'h10: begin
                                        if (`NN) begin // BPL
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'h11: begin
                                        op_ORA <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'h12: begin
                                        op_ORA <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'h13: begin
                                        // NEG
                                        `A <= neg_a;
                                        `C <= neg_a_c;
                                        `N <= neg_a_n;
                                        `Z <= neg_a_z;
                                        `END_INSTR;
                                    end

                                8'h14: begin
                                        // NOT
                                        `A <= not_a;
                                        `N <= not_a_n;
                                        `Z <= not_a_z;
                                        `END_INSTR;
                                    end

                                8'h14: begin
                                        op_TRB <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h15: begin
                                        op_ORA <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h16: begin
                                        op_ASL <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h18: begin
                                        `C <= 0; // CLC
                                        `END_INSTR;
                                    end

                                8'h19: begin
                                        op_ORA <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'h1A: begin
                                        // INC
                                        `A <= inc_a;
                                        `N <= inc_a_n;
                                        `Z <= inc_a_z;
                                        `END_INSTR;
                                    end

                                8'h1C: begin
                                        op_TRB <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h1D: begin
                                        op_ORA <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h1E: begin
                                        op_ASL <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h20: begin
                                        op_JSR <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h21: begin
                                        op_AND <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h24: begin
                                        op_BIT <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h25: begin
                                        op_AND <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h26: begin
                                        op_ROL <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h28: begin
                                        op_PLP <= 1;
                                        `ADDR = `SP;
                                        `SP = inc_sp;
                                        load_from_address <= 1;
                                    end

                                8'h29: begin
                                        op_AND <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h2A: begin
                                        // ROL
                                        `A <= rol_a;
                                        `N <= rol_a_n;
                                        `Z <= rol_a_z;
                                        `C <= rol_a_c;
                                        `END_INSTR;
                                    end

                                8'h2C: begin
                                        op_BIT <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h2D: begin
                                        op_AND <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h2E: begin
                                        op_ROL <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h30: begin
                                        if (`N) begin // BMI
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'h31: begin
                                        op_AND <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'h32: begin
                                        op_AND <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'h34: begin
                                        op_BIT <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h35: begin
                                        op_AND <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h36: begin
                                        op_ROL <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h38: begin
                                        `C <= 1; // SEC
                                        `END_INSTR;
                                    end

                                8'h39: begin
                                        op_AND <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'h3A: begin
                                        // DEC
                                        `A <= dec_a;
                                        `N <= dec_a_n;
                                        `Z <= dec_a_z;
                                        `END_INSTR;
                                    end

                                8'h3C: begin
                                        op_BIT <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h3D: begin
                                        op_AND <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h3E: begin
                                        op_ROL <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h40: begin
                                        op_RTI <= 1;
                                        am_STK_s <= 1;
                                    end

                                8'h41: begin
                                        op_EOR <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h45: begin
                                        op_EOR <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h46: begin
                                        op_LSR <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h48: begin
                                        // PHA
                                        var_hw_address = dec_sp;
                                        `SP <= var_hw_address;
                                        `ADDR <= var_hw_address;
                                        `DST <= `A;
                                        `STORE_DST;
                                    end

                                8'h49: begin
                                        op_EOR <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h4A: begin
                                        // LSR
                                        `A <= lsr_a;
                                        `N <= lsr_a_n;
                                        `Z <= lsr_a_z;
                                        `C <= lsr_a_c;
                                        `END_INSTR;
                                    end

                                8'h4C: begin
                                        op_JMP <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h4D: begin
                                        op_EOR <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h4E: begin
                                        op_LSR <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h50: begin
                                        if (`NV) begin // BVC
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'h51: begin
                                        op_EOR <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'h52: begin
                                        op_EOR <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h55: begin
                                        op_EOR <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h56: begin
                                        op_LSR <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h58: begin
                                        `I <= 0; // CLI
                                    end

                                8'h59: begin
                                        op_EOR <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'h5A: begin
                                        // PHY
                                        var_hw_address = dec_sp;
                                        `SP <= var_hw_address;
                                        `ADDR <= var_hw_address;
                                        `DST <= `Y;
                                        `STORE_DST;
                                    end

                                8'h5D: begin
                                        op_EOR <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h5E: begin
                                        op_LSR <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h60: begin
                                        op_RTS <= 1;
                                        am_STK_s <= 1;
                                    end

                                8'h61: begin
                                        op_ADC <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h64: begin
                                        op_STZ <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h65: begin
                                        op_ADC <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h66: begin
                                        op_ROR <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h68: begin
                                        op_PLA <= 1;
                                        `ADDR = `SP;
                                        `SP = inc_sp;
                                        load_from_address <= 1;
                                    end

                                8'h69: begin
                                        op_ADC <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h6A: begin
                                        // ROR
                                        `A <= ror_a;
                                        `N <= ror_a_n;
                                        `Z <= ror_a_z;
                                        `C <= ror_a_c;
                                        `END_INSTR;
                                    end

                                8'h6C: begin
                                        op_JMP <= 1;
                                        am_AIA_A <= 1;
                                    end

                                8'h6D: begin
                                        op_ADC <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h6E: begin
                                        op_ROR <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h70: begin
                                        if (`V) begin // BVS
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'h71: begin
                                        op_ADC <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'h72: begin
                                        op_ADC <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'h74: begin
                                        op_STZ <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h75: begin
                                        op_ADC <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h76: begin
                                        op_ROR <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h78: begin
                                        `I <= 1; // SEI
                                        `END_INSTR;
                                    end

                                8'h79: begin
                                        op_ADC <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'h7A: begin
                                        op_PLY <= 1;
                                        `ADDR = `SP;
                                        `SP = inc_sp;
                                        load_from_address <= 1;
                                    end

                                8'h7C: begin
                                        op_JMP <= 1;
                                        am_AIIX_A_X <= 1;
                                    end

                                8'h7D: begin
                                        op_ADC <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h7E: begin
                                        op_ROR <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h80: begin
                                        op_BRANCH <= 1; // BRA
                                        am_PCR_r <= 1;
                                    end

                                8'h81: begin
                                        op_STA <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'h84: begin
                                        op_STY <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h85: begin
                                        op_STA <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h86: begin
                                        op_STX <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'h87, 8'h97, 8'hA7, 8'hB7,
                                8'hC7, 8'hD7, 8'hE7, 8'hF7:
                                    begin
                                        op_SMB <= 1;
                                        am_ZPG_zp <= 1;
                                        reg_which <= (`ONE_8 << reg_code_byte[6:4]);
                                    end

                                8'h88: begin
                                        // DEY
                                        `Y <= dec_y;
                                        `N <= dec_y_n;
                                        `Z <= dec_y_z;
                                        `END_INSTR;
                                    end

                                8'h89: begin
                                        op_BIT <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'h8A: begin
                                        // TXA
                                        `A <= `X;
                                        `END_INSTR;
                                    end

                                8'h8C: begin
                                        op_STY <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h8D: begin
                                        op_STA <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h8E: begin
                                        op_STX <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h8F, 8'h9F, 8'hAF, 8'hBF,
                                8'hCF, 8'hDF, 8'hEF, 8'hFF:
                                    begin
                                        op_BBS <= 1;
                                        am_PCR_r <= 1;
                                        reg_which <= (`ONE_8 << reg_code_byte[6:4]);
                                    end

                                8'h90: begin
                                        if (`NC) begin // BCC
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'h91: begin
                                        op_STA <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'h92: begin
                                        op_STA <= 1;
                                        am_ZIY_zp_y <= 1;
                                    end

                                8'h94: begin
                                        op_STY <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h95: begin
                                        op_STA <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'h96: begin
                                        op_STX <= 1;
                                        am_ZIY_zp_y <= 1;
                                    end

                                8'h98: begin
                                        // TYA
                                        `A <= `Y;
                                        `END_INSTR;
                                    end

                                8'h99: begin
                                        op_STA <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'h9A: begin
                                        // TXS
                                        `SP <= `X;
                                        `END_INSTR;
                                    end

                                8'h9C: begin
                                        op_STZ <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'h9D: begin
                                        op_STA <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'h9E: begin
                                        op_STZ <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hA0: begin
                                        op_LDY <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hA1: begin
                                        op_LDA <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'hA2: begin
                                        op_LDX <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hA4: begin
                                        op_LDY <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hA5: begin
                                        op_LDA <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hA6: begin
                                        op_LDX <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hA8: begin
                                        // TAY
                                        `Y <= `A;
                                        `END_INSTR;
                                    end

                                8'hA9: begin
                                        op_LDA <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hAA: begin
                                        // TAX
                                        `X <= `A;
                                        `END_INSTR;
                                    end

                                8'hAC: begin
                                        op_LDY <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hAD: begin
                                        op_LDA <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hAE: begin
                                        op_LDX <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hB0: begin
                                        if (`C) begin // BCS
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'hB1: begin
                                        op_LDA <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'hB2: begin
                                        op_LDA <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'hB4: begin
                                        op_LDY <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hB5: begin
                                        op_LDA <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hB6: begin
                                        op_LDX <= 1;
                                        am_ZIY_zp_y <= 1;
                                    end

                                8'hB8: begin
                                        `V <= 0; // CLV
                                        `END_INSTR;
                                    end

                                8'hB9: begin
                                        op_LDA <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'hBA: begin
                                        // TSX
                                        `X <= `SP;
                                        `END_INSTR;
                                    end

                                8'hBC: begin
                                        op_LDY <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hBD: begin
                                        op_LDA <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hBE: begin
                                        op_LDX <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'hC0: begin
                                        op_CPY <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hC1: begin
                                        op_CMP <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'hC4: begin
                                        op_CPY <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hC5: begin
                                        op_CMP <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hC6: begin
                                        op_DEC <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hC8: begin
                                        // INY
                                        `Y <= inc_y;
                                        `N <= inc_y_n;
                                        `Z <= inc_y_z;
                                        `END_INSTR;
                                    end

                                8'hC9: begin
                                        op_CMP <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hCA: begin
                                        // DEX
                                        `X <= dec_x;
                                        `N <= dec_x_n;
                                        `Z <= dec_x_z;
                                        `END_INSTR;
                                    end

                                8'hCB: begin
                                        op_WAI <= 1;
                                    end

                                8'hCC: begin
                                        op_CPY <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hCD: begin
                                        op_CMP <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hCE: begin
                                        op_DEC <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hD0: begin
                                        if (`NZ) begin // BNE
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'hD1: begin
                                        op_CMP <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'hD2: begin
                                        op_CMP <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'hD5: begin
                                        op_CMP <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hD6: begin
                                        op_DEC <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hD8: begin
                                        `D <= 0; // CLD
                                        `END_INSTR;
                                    end

                                8'hD9: begin
                                        op_CMP <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'hDA: begin
                                        // PHX
                                        var_hw_address = dec_sp;
                                        `SP <= var_hw_address;
                                        `ADDR <= var_hw_address;
                                        `DST <= `X;
                                        `STORE_DST;
                                    end

                                8'hDB: begin
                                        op_STP <= 1;
                                    end

                                8'hDD: begin
                                        op_CMP <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hDE: begin
                                        op_DEC <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hE0: begin
                                        op_CPX <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hE1: begin
                                        op_SBC <= 1;
                                        am_ZIIX_ZP_X <= 1;
                                    end

                                8'hE4: begin
                                        op_CPX <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hE5: begin
                                        op_SBC <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hE6: begin
                                        op_INC <= 1;
                                        am_ZPG_zp <= 1;
                                    end

                                8'hE8: begin
                                        // INX
                                        `X <= inc_x;
                                        `N <= inc_x_n;
                                        `Z <= inc_x_z;
                                        `END_INSTR;
                                    end

                                8'hE9: begin
                                        op_SBC <= 1;
                                        am_IMM_m <= 1;
                                    end

                                8'hEA: begin
                                        // NOP
                                        `END_INSTR;
                                    end

                                8'hEC: begin
                                        op_CPX <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hED: begin
                                        op_SBC <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hEE: begin
                                        op_INC <= 1;
                                        am_ABS_a <= 1;
                                    end

                                8'hF0: begin
                                        if (`Z) begin // BEQ
                                            op_BRANCH <= 1;
                                            am_PCR_r <= 1;
                                        end else begin
                                            `PC <= add_pc_2;
                                            `END_INSTR;
                                        end
                                    end

                                8'hF1: begin
                                        op_SBC <= 1;
                                        am_ZIIY_ZP_y <= 1;
                                    end

                                8'hF2: begin
                                        op_SBC <= 1;
                                        am_ZPI_ZP <= 1;
                                    end

                                8'hF5: begin
                                        op_SBC <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hF6: begin
                                        op_INC <= 1;
                                        am_ZIX_zp_x <= 1;
                                    end

                                8'hF8: begin
                                        `D <= 1; // SED
                                        `END_INSTR;
                                    end

                                8'hF9: begin
                                        op_SBC <= 1;
                                        am_AIY_a_y <= 1;
                                    end

                                8'hFA: begin
                                        op_PLX <= 1;
                                        `ADDR = `SP;
                                        `SP = inc_sp;
                                        load_from_address <= 1;
                                    end

                                8'hFD: begin
                                        op_SBC <= 1;
                                        am_AIX_a_x <= 1;
                                    end

                                8'hFE: begin
                                        op_INC <= 1;
                                        am_AIX_a_x <= 1;
                                    end
                            endcase;
                    end
                    2: begin // 6502 cycle 2
                            `ADDR0 = `CODE_BYTE;
                            `ADDR1 <= 0;
                            `ADDR2 <= 0;
                            `ADDR3 <= 0;
                            `OFFSET <= 0;
                            `PC <= inc_pc;
                            if (am_ZPG_zp) begin
                                am_ZPG_zp <= 0;
                                load_from_address <= 1;
                            end else if (am_ZIX_zp_x) begin
                                `OFFSET <= {`ZERO_8, `X};
                                am_ZIX_zp_x <= 0;
                                load_from_address <= 1;
                            end else if (am_ZIY_zp_y) begin
                                `OFFSET <= {`ZERO_8, `Y};
                                am_ZIY_zp_y <= 0;
                                load_from_address <= 1;
                            end else if (am_ZIIX_ZP_X) begin
                                `OFFSET <= {`ZERO_8, `X};
                            end
                        end
                    3: begin // 6502 cycle 3
                            if (am_IMM_m) begin
                                am_IMM_m <= 0;
                                var_ram_byte <= `ADDR0;
                                if (op_ADC) begin
                                    `do_uext_var_9;
                                    `do_adc_a_var; `A <= adc_a_var;
                                    `do_adc_a_var_n; `N <= adc_a_var_n;
                                    `do_adc_a_var_v; `V <= adc_a_var_v;
                                    `do_adc_a_var_z; `Z <= adc_a_var_z;
                                    `do_adc_a_var_c; `C <= adc_a_var_c;
                                    `END_OPER_INSTR(op_ADC);
                                end else if (op_AND) begin
                                    `do_and_a_var; `A <= and_a_var;
                                    `do_and_a_var_n; `N <= and_a_var_n;
                                    `do_and_a_var_z; `Z <= and_a_var_z;
                                    `END_OPER_INSTR(op_AND);
                                end else if (op_ASL) begin
                                    `do_asl_var; `DST <= var_ram_byte;
                                    `do_asl_var_n; `N <= asl_var_n;
                                    `do_asl_var_z; `Z <= asl_var_z;
                                    `do_asl_var_c; `C <= asl_var_c;
                                    `STORE_AFTER_OP(op_ASL);
                                end else if (op_BIT) begin
                                    `do_and_a_var;
                                    `do_and_a_var_n; `N <= and_a_var_n;
                                    `do_and_a_var_v; `V <= and_a_var_v;
                                    `do_and_a_var_z; `Z <= and_a_var_z;
                                    `END_OPER_INSTR(op_BIT);
                                end else if (op_CMP) begin
                                    `do_uext_var_9;
                                    `do_sub_a_var;
                                    `do_sub_a_var_n; `N <= sub_a_var_n;
                                    `do_sub_a_var_v; `V <= sub_a_var_v;
                                    `do_sub_a_var_z; `Z <= sub_a_var_z;
                                    `do_sub_a_var_c; `C <= sub_a_var_c;
                                    `END_OPER_INSTR(op_CMP);
                                end else if (op_CPX) begin
                                    `do_uext_var_9;
                                    `do_sub_x_var;
                                    `do_sub_x_var_n; `N <= sub_x_var_n;
                                    `do_sub_x_var_v; `V <= sub_x_var_v;
                                    `do_sub_x_var_z; `Z <= sub_x_var_z;
                                    `do_sub_x_var_c; `C <= sub_x_var_c;
                                    `END_OPER_INSTR(op_CPX);
                                end else if (op_CPY) begin
                                    `do_uext_var_9;
                                    `do_sub_y_var;
                                    `do_sub_y_var_n; `N <= sub_y_var_n;
                                    `do_sub_y_var_v; `V <= sub_y_var_v;
                                    `do_sub_y_var_z; `Z <= sub_y_var_z;
                                    `do_sub_y_var_c; `C <= sub_y_var_c;
                                    `END_OPER_INSTR(op_CPY);
                                end else if (op_EOR) begin
                                    `do_eor_a_var; `A <= eor_a_var;
                                    `do_eor_a_var_n; `N <= eor_a_var_n;
                                    `do_eor_a_var_z; `Z <= eor_a_var_z;
                                    `END_OPER_INSTR(op_EOR);
                                end else if (op_LDA) begin
                                    `A <= var_ram_byte;
                                    `N <= var_ram_byte[7];
                                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                                    `END_OPER_INSTR(op_LDA);
                                end else if (op_LDX) begin
                                    `X <= var_ram_byte;
                                    `N <= var_ram_byte[7];
                                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                                    `END_OPER_INSTR(op_LDX);
                                end else if (op_LDY) begin
                                    `Y <= var_ram_byte;
                                    `N <= var_ram_byte[7];
                                    `Z <= (var_ram_byte == `ZERO_8) ? 1 : 0;
                                    `END_OPER_INSTR(op_LDY);
                                end else if (op_ORA) begin
                                    `do_or_a_var; `A <= or_a_var;
                                    `do_or_a_var_n; `N <= or_a_var_n;
                                    `do_or_a_var_z; `Z <= or_a_var_z;
                                    `END_OPER_INSTR(op_ORA);
                                end else if (op_SBC) begin
                                    `do_uext_var_9;
                                    `do_sbc_a_var; `A <= sbc_a_var;
                                    `do_sbc_a_var_c; `C <= sbc_a_var_c;
                                    `do_sbc_a_var_v; `V <= sbc_a_var_v;
                                    `do_sbc_a_var_n; `N <= sbc_a_var_n;
                                    `do_sbc_a_var_z; `Z <= sbc_a_var_z;
                                    `END_OPER_INSTR(op_SBC);
                                end else if (op_SUB) begin
                                    `do_uext_var_9;
                                    `do_sub_a_var; `A <= sub_a_var;
                                    `do_sub_a_var_n; `N <= sub_a_var_n;
                                    `do_sub_a_var_v; `V <= sub_a_var_v;
                                    `do_sub_a_var_z; `Z <= sub_a_var_z;
                                    `do_sub_a_var_c; `C <= sub_a_var_c;
                                    `END_OPER_INSTR(op_SUB);
                                end
                            end else if (am_PCR_r) begin
                                if (op_BBR | op_BBS) begin
                                    `SRC = `CODE_BYTE;
                                end else begin
                                    am_PCR_r <= 0;
                                    `PC <= `PC + {(reg_address[7] ? `ONES_8 : `ZERO_8), `ADDR0};
                                    `END_INSTR;
                                end
                            end else begin
                                `ADDR1 = `CODE_BYTE;
                                `PC <= inc_pc;
                            end
                        end
                    4: begin // 6502 cycle 4
                            if (am_ZIIX_ZP_X | am_ZIIY_ZP_y) begin
                                `IADDR1 <= `DATA_BYTE;
                                `ADDR <= inc_addr;
                            end else if (op_BBR | op_BBS) begin
                                reg_data_byte <= `DATA_BYTE;
                            end else begin
                                if (am_ABS_a) begin
                                    am_ABS_a <= 0;
                                    if (op_JMP) begin
                                        `PC <= `ADDR;
                                        `END_OPER_INSTR(op_JMP);
                                    end else if (op_JSR) begin
                                        `PC <= `ADDR;
                                        `END_OPER(op_JSR);
                                        `eDST0 <= `PC[7:0];
                                        `eDST1 <= `PC[15:8];
                                        push_edst0 <= 1;
                                    end else if (op_STA) begin
                                        `DST <= `A;
                                        `STORE_AFTER_OP(op_STA);
                                    end else if (op_STX) begin
                                        `DST <= `X;
                                        `STORE_AFTER_OP(op_STX);
                                    end else if (op_STY) begin
                                        `DST <= `Y;
                                        `STORE_AFTER_OP(op_STY);
                                    end else if (op_STZ) begin
                                        `DST <= `ZERO_8;
                                        `STORE_AFTER_OP(op_STZ);
                                    end else begin
                                        load_from_address <= 1;
                                    end
                                end else if (am_AIIX_A_X) begin
                                        `ADDR <= {`ZERO_8, reg_code_byte} + uext_x_16;
                                end else if (am_AIA_A) begin
                                        `ADDR1 <= reg_code_byte;
                                end else if (am_AIX_a_x) begin
                                    `ADDR <= {`ZERO_8, reg_code_byte} + uext_x_16;
                                    am_AIX_a_x <= 0;
                                    load_from_address <= 1;
                                end else if (am_AIY_a_y) begin
                                    `ADDR <= {`ZERO_8, reg_code_byte} + uext_y_16;
                                    am_AIY_a_y <= 0;
                                    load_from_address <= 1;
                                end
                            end
                        end
                    5: begin // 6502 cycle 5
                            if (am_AIIX_A_X | am_AIA_A) begin
                                `IADDR0 <= `DATA_BYTE;
                                `ADDR <= inc_addr;
                            end else if (am_ZIIX_ZP_X) begin
                                `IADDR1 <= `DATA_BYTE;
                                am_ZIIX_ZP_X <= 0;
                                load_from_address <= 1;
                            end else if (am_ZIIY_ZP_y) begin
                                `IADDR1 <= `DATA_BYTE + `Y;
                                am_ZIIY_ZP_y <= 0;
                                load_from_address <= 1;
                            end else if (op_BBR) begin
                                am_PCR_r <= 0;
                                if ((reg_src_data & reg_which) == 0) begin
                                    `PC <= `PC + {(reg_src_data[7] ? `ONES_8 : `ZERO_8), reg_src_data};
                                end
                                `END_OPER_INSTR(op_BBR);
                            end else if (op_BBS) begin
                                am_PCR_r <= 0;
                                if ((reg_src_data & reg_which) != 0) begin
                                    `PC <= `PC + {(reg_src_data[7] ? `ONES_8 : `ZERO_8), reg_src_data};
                                end
                                `END_OPER_INSTR(op_BBS);
                            end
                        end
                    6: begin // 6502 cycle 6
                            if (am_AIIX_A_X | am_AIA_A) begin
                                var_ram_byte = `DATA_BYTE;
                                am_AIIX_A_X <= 0;
                                am_AIA_A <= 0;
                                `END_INSTR;
                                if (op_JMP) begin
                                    `PC <= {var_ram_byte, `IADDR0};
                                    `END_OPER(op_JMP);
                                end
                            end
                        end
                    7: begin // 6502 cycle 7
                        end
                endcase
            end
        end else begin // 65832
            case (reg_cycle)
                0: begin // 65832 cycle 0
                        var_code_byte = reg_bram[`ePC`VHW];
                        `ePC <= inc_epc;
                        case (var_code_byte)
                            8'h00: begin
                                    op_BRK <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h01: begin
                                    op_ORA <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h06: begin
                                    op_ASL <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h08: begin
                                    op_PHP <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h09: begin
                                    op_ORA <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'h0A: begin
                                    op_ASL <= 1;
                                    ame_ACC_A <= 1;
                                end

                            8'h0C: begin
                                    op_TSB <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h0D: begin
                                    op_ORA <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h10: begin
                                    if (`eNN) begin // BPL
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'h11: begin
                                    op_ORA <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'h12: begin
                                    op_ORA <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h16: begin
                                    op_ASL <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h18: begin
                                    `C <= 0; // CLC
                                    `END_INSTR;
                                end

                            8'h19: begin
                                    op_ORA <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'h1A: begin
                                    // INC
                                    `eA <= inc_ea;
                                    `eN <= inc_ea_n;
                                    `eZ <= inc_ea_z;
                                    `END_INSTR;
                                end

                            8'h1C: begin
                                    op_TRB <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h1D: begin
                                    op_ORA <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h20: begin
                                    op_JSR <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h21: begin
                                    op_AND <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h22: begin
                                    op_JSR <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h23: begin
                                    op_SUB <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h26: begin
                                    op_ROL <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h28: begin
                                    op_PLP <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h29: begin
                                    op_AND <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'h2A: begin
                                    op_ROL <= 1;
                                    ame_ACC_A <= 1;
                                end

                            8'h2C: begin
                                    op_BIT <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h2D: begin
                                    op_AND <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h30: begin
                                    if (`eN) begin // BMI
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'h31: begin
                                    op_AND <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'h32: begin
                                    op_AND <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h36: begin
                                    op_ROL <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h38: begin
                                    `C <= 1; // SEC
                                    `END_INSTR;
                                end

                            8'h39: begin
                                    op_AND <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'h3A: begin
                                    // DEC
                                    `eA <= dec_ea;
                                    `eN <= dec_ea_n;
                                    `eZ <= dec_ea_z;
                                    `END_INSTR;
                                end

                            8'h3C: begin
                                    op_BIT <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h3D: begin
                                    op_AND <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h40: begin
                                    op_RTI <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h41: begin
                                    op_EOR <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h46: begin
                                    op_LSR <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h48: begin
                                    op_PHA <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h49: begin
                                    op_EOR <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'h4A: begin
                                    op_LSR <= 1;
                                    ame_ACC_A <= 1;
                                end

                            8'h4C: begin
                                    op_JMP <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h4D: begin
                                    op_EOR <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h50: begin
                                    if (`eNV) begin // BVC
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'h51: begin
                                    op_EOR <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'h52: begin
                                    op_EOR <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h56: begin
                                    op_LSR <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h58: begin
                                    `I <= 0; // CLI
                                    `END_INSTR;
                                end

                            8'h59: begin
                                    op_EOR <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'h5A: begin
                                    op_PHY <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h5C: begin
                                    op_JSR <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h5D: begin
                                    op_EOR <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h60: begin
                                    op_RTS <= 1;
                                    ame_PCR_r <= 1;
                                end

                            8'h61: begin
                                    op_ADC <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h66: begin
                                    op_ROR <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h68: begin
                                    op_PLA <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h69: begin
                                    op_ADC <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'h6A: begin
                                    op_ROR <= 1;
                                    ame_ACC_A <= 1;
                                end

                            8'h6C: begin
                                    op_JMP <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h6D: begin
                                    op_ADC <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h70: begin
                                    if (`eV) begin // BVS
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'h71: begin
                                    op_ADC <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'h72: begin
                                    op_ADC <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h76: begin
                                    op_ROR <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h78: begin
                                    `I <= 1; // SEI
                                    `END_INSTR;
                                end

                            8'h79: begin
                                    op_ADC <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'h7A: begin
                                    op_PLY <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'h7C: begin
                                    op_JMP <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h7D: begin
                                    op_ADC <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h80: begin
                                    // BRA
                                    op_BRANCH <= 1;
                                    ame_PCR_r <= 1;
                                end

                            8'h81: begin
                                    op_STA <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'h86: begin
                                    op_STZ <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h88: begin
                                    // DEY
                                    `eY <= dec_ey;
                                    `eN <= dec_ey_n;
                                    `eZ <= dec_ey_z;
                                    `END_INSTR;
                                end

                            8'h89: begin
                                    op_BIT <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'h8A: begin
                                    // TXA
                                    reg_a <= reg_x;
                                    `END_INSTR;
                                end

                            8'h8C: begin
                                    op_STY <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h8D: begin
                                    op_STA <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h8E: begin
                                    op_STX <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'h90: begin
                                    if (`eNC) begin // BCC
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'h91: begin
                                    op_STA <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'h92: begin
                                    op_STA <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'h96: begin
                                    op_STZ <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h98: begin
                                    // TYA
                                    reg_a <= reg_y;
                                    `END_INSTR;
                                end

                            8'h99: begin
                                    op_STA <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'h9A: begin
                                    // TXS
                                    `eSP <= `eX;
                                    `END_INSTR;
                                end

                            8'h9C: begin
                                    op_STY <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h9D: begin
                                    op_STA <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'h9E: begin
                                    op_STX <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'hA0: begin
                                    op_LDY <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hA1: begin
                                    op_LDA <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'hA2: begin
                                    op_LDX <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hA8: begin
                                    // TAY
                                    `eY <= `eA;
                                    `END_INSTR;
                                end

                            8'hA9: begin
                                    op_LDA <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hAA: begin
                                    // TAX
                                    `eX <= `eA;
                                    `END_INSTR;
                                end

                            8'hAC: begin
                                    op_LDY <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hAD: begin
                                    op_LDA <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hAE: begin
                                    op_LDX <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hB0: begin
                                    if (`eC) begin // BCS
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'hB1: begin
                                    op_LDA <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'hB2: begin
                                    op_LDA <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'hB8: begin
                                    `V <= 0; // CLV
                                    `END_INSTR;
                                end

                            8'hB9: begin
                                    op_LDA <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'hBA: begin
                                    // TSX
                                    `eX <= `eSP;
                                    `END_INSTR;
                                end

                            8'hBC: begin
                                    op_LDY <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'hBD: begin
                                    op_LDA <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'hBE: begin
                                    op_LDX <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'hC0: begin
                                    op_CPY <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hC1: begin
                                    op_CMP <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'hC6: begin
                                    op_DEC <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hC8: begin
                                    // INY
                                    `eY <= inc_ey;
                                    `eN <= inc_ey_n;
                                    `eZ <= inc_ey_z;
                                    `END_INSTR;
                                end

                            8'hC9: begin
                                    op_CMP <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hCA: begin
                                    // DEX
                                    `eX <= dec_ex;
                                    `eN <= dec_ex_n;
                                    `eZ <= dec_ex_z;
                                    `END_INSTR;
                                end

                            8'hCC: begin
                                    op_CPY <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hCD: begin
                                    op_CMP <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hD0: begin
                                    if (`eNZ) begin // BNE
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'hD1: begin
                                    op_CMP <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'hD2: begin
                                    op_CMP <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'hD6: begin
                                    op_DEC <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'hD8: begin
                                    `D <= 0; // CLD
                                    `END_INSTR;
                                end

                            8'hD9: begin
                                    op_CMP <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'hDA: begin
                                    op_PHX <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'hDD: begin
                                    op_CMP <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'hE0: begin
                                    op_CPX <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hE1: begin
                                    op_SBC <= 1;
                                    ame_AIIX_A_X <= 1;
                                end

                            8'hE6: begin
                                    op_INC <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hE8: begin
                                    // INX
                                    `eX <= inc_ex;
                                    `eN <= inc_ex_n;
                                    `eZ <= inc_ex_z;
                                    `END_INSTR;
                                end

                            8'hE9: begin
                                    op_SBC <= 1;
                                    ame_IMM_m <= 1;
                                end

                            8'hEA: begin
                                    // NOP
                                    `END_INSTR;
                                end

                            8'hEC: begin
                                    op_CPX <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hED: begin
                                    op_SBC <= 1;
                                    ame_ABS_a <= 1;
                                end

                            8'hF0: begin
                                    if (`eZ) begin // BEQ
                                        op_BRANCH <= 1;
                                        ame_PCR_r <= 1;
                                    end else begin
                                        `ePC <= add_epc_4;
                                        `END_INSTR;
                                    end
                                end

                            8'hF1: begin
                                    op_SBC <= 1;
                                    ame_AIIY_A_y <= 1;
                                end

                            8'hF2: begin
                                    op_SBC <= 1;
                                    ame_AIA_A <= 1;
                                end

                            8'hF6: begin
                                    op_INC <= 1;
                                    ame_AIX_a_x <= 1;
                                end

                            8'hF8: begin
                                    `D <= 1; // SED
                                    `END_INSTR;
                                end

                            8'hF9: begin
                                    op_SBC <= 1;
                                    ame_AIY_a_y <= 1;
                                end

                            8'hFA: begin
                                    op_PLX <= 1;
                                    ame_STK_s <= 1;
                                end

                            8'hFD: begin
                                    op_SBC <= 1;
                                    ame_AIX_a_x <= 1;
                                end
                        endcase;
                    end
                1: begin // 65832 cycle 1
                        if (am_PCR_r) begin
                            `eSRC0 <= `CODE_BYTE;
                            `ePC <= inc_epc;
                        end
                    end
                2: begin // 65832 cycle 2
                        if (am_PCR_r) begin
                            `eSRC1 <= `CODE_BYTE;
                            `ePC <= inc_epc;
                        end
                    end
                3: begin // 65832 cycle 3
                        if (am_PCR_r) begin
                            `eSRC2 <= `CODE_BYTE;
                            `ePC <= inc_epc;
                            am_PCR_r <= 0;
                        end
                    end
                4: begin // 65832 cycle 4
                        if (op_BRANCH) begin
                            `ePC <= add_epc_src_24;
                            op_BRANCH <= 0;
                            `END_INSTR;
                        end
                    end
                5: begin // 65832 cycle 5
                    end
            endcase
        end
    end
end

endmodule
