#include <stdio.h>
#include <stdint.h>

typedef const char * Operation;

static Operation OP_NONE = "NONE";
static Operation OP_ADD = "ADD";
static Operation OP_ADC = "ADC";
static Operation OP_AND = "AND";
static Operation OP_ASL = "ASL";
static Operation OP_BEQ = "BEQ";
static Operation OP_BIT = "BIT";
static Operation OP_BBR = "BBR";
static Operation OP_BBS = "BBS";
static Operation OP_BCC = "BCC";
static Operation OP_BCS = "BCS";
static Operation OP_BMI = "BMI";
static Operation OP_BNE = "BNE";
static Operation OP_BPL = "BPL";
static Operation OP_BRA = "BRA";
static Operation OP_BRK = "BRK";
static Operation OP_BVC = "BVC";
static Operation OP_BVS = "BVS";
static Operation OP_CLC = "CLC";
static Operation OP_CLD = "CLD";
static Operation OP_CLI = "CLI";
static Operation OP_CLV = "CLV";
static Operation OP_CMP = "CMP";
static Operation OP_CPX = "CPX";
static Operation OP_CPY = "CPY";
static Operation OP_DEC = "DEC";
static Operation OP_DEX = "DEX";
static Operation OP_DEY = "DEY";
static Operation OP_EOR = "EOR";
static Operation OP_INC = "INC";
static Operation OP_INX = "INX";
static Operation OP_INY = "INY";
static Operation OP_JMP = "JMP";
static Operation OP_JSR = "JSR";
static Operation OP_LDA = "LDA";
static Operation OP_LDX = "LDX";
static Operation OP_LDY = "LDY";
static Operation OP_LSR = "LSR";
static Operation OP_NOP = "NOP";
static Operation OP_ORA = "ORA";
static Operation OP_PHA = "PHA";
static Operation OP_PHP = "PHP";
static Operation OP_PHX = "PHX";
static Operation OP_PHY = "PHY";
static Operation OP_PLA = "PLA";
static Operation OP_PLP = "PLP";
static Operation OP_PLX = "PLX";
static Operation OP_PLY = "PLY";
static Operation OP_RMB = "RMB";
static Operation OP_ROL = "ROL";
static Operation OP_ROR = "ROR";
static Operation OP_RTI = "RTI";
static Operation OP_RTS = "RTS";
static Operation OP_SBC = "SBC";
static Operation OP_SEC = "SEC";
static Operation OP_SED = "SED";
static Operation OP_SEI = "SEI";
static Operation OP_SMB = "SMB";
static Operation OP_STA = "STA";
static Operation OP_STP = "STP";
static Operation OP_STX = "STX";
static Operation OP_STY = "STY";
static Operation OP_STZ = "STZ";
static Operation OP_SUB = "SUB";
static Operation OP_TAX = "TAX";
static Operation OP_TAY = "TAY";
static Operation OP_TRB = "TRB";
static Operation OP_TSB = "TSB";
static Operation OP_TSX = "TSX";
static Operation OP_TXA = "TXA";
static Operation OP_TXS = "TXS";
static Operation OP_TYA = "TYA";
static Operation OP_WAI = "WAI";

typedef enum {
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

typedef enum {
    MODE_6502,
    MODE_65832,
    MODE_OVERLAY
} CpuMode;

void flush_mode();
void flush_instruction();

CpuMode g_cpu_mode;
uint8_t g_opcode;
Operation g_operation;
AddressMode g_address_mode;
uint8_t g_which;

void set_mode(CpuMode cpu_mode) {
    flush_mode();
    g_cpu_mode = cpu_mode;
}

void set_opcode(uint8_t opcode) {
    flush_instruction();
    g_opcode = opcode;
}

void set_operation(Operation operation) {
    g_operation = operation;
}

void set_address_mode(AddressMode address_mode) {
    g_address_mode = address_mode;
}

void set_which(uint8_t which) {
    g_which = which;
}

void flush_mode() {
    flush_instruction();
}

void flush_instruction() {
    if (g_opcode != OP_NONE) {
        g_opcode = OP_NONE;
    }
}

void gen_6502_instructions() {

    set_mode(MODE_6502);

    set_opcode(0x00);
    set_operation(OP_BRK);
    set_address_mode(STK_s);

    set_opcode(0x01);
    set_operation(OP_ORA);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x02);
    set_operation(OP_ADD);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x04);
    set_operation(OP_TSB);
    set_address_mode(ZPG_zp);

    set_opcode(0x05);
    set_operation(OP_ORA);
    set_address_mode(ZPG_zp);

    set_opcode(0x06);
    set_operation(OP_ASL);
    set_address_mode(ZPG_zp);

    set_opcode(0x07);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(0);

    set_opcode(0x17);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(1);

    set_opcode(0x27);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(2);

    set_opcode(0x37);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(3);

    set_opcode(0x47);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(4);

    set_opcode(0x57);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(5);

    set_opcode(0x67);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(6);

    set_opcode(0x77);
    set_operation(OP_RMB);
    set_address_mode(ZPG_zp);
    set_which(7);

    set_opcode(0x08);
    set_operation(OP_PHP);
    set_address_mode(STK_s);

    set_opcode(0x09);
    set_operation(OP_ORA);
    set_address_mode(IMM_m);

    set_opcode(0x0A);
    set_operation(OP_ASL);
    set_address_mode(ACC_A);

    set_opcode(0x0C);
    set_operation(OP_TSB);
    set_address_mode(ABS_a);

    set_opcode(0x0D);
    set_operation(OP_ORA);
    set_address_mode(ABS_a);

    set_opcode(0x0E);
    set_operation(OP_ASL);
    set_address_mode(ABS_a);

    set_opcode(0x0F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(0);

    set_opcode(0x1F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(1);

    set_opcode(0x2F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(2);

    set_opcode(0x3F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(3);

    set_opcode(0x4F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(4);

    set_opcode(0x5F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(5);

    set_opcode(0x6F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(6);

    set_opcode(0x7F);
    set_operation(OP_BBR);
    set_address_mode(PCR_r);
    set_which(7);

    set_opcode(0x10);
    set_operation(OP_BPL);
    set_address_mode(PCR_r);

    set_opcode(0x11);
    set_operation(OP_ORA);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0x12);
    set_operation(OP_ORA);
    set_address_mode(ZPI_ZP);

    set_opcode(0x14);
    set_operation(OP_TRB);
    set_address_mode(ZPG_zp);

    set_opcode(0x15);
    set_operation(OP_ORA);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x16);
    set_operation(OP_ASL);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x18);
    set_operation(OP_CLC);
    set_address_mode(IMP_i);

    set_opcode(0x19);
    set_operation(OP_ORA);
    set_address_mode(AIY_a_y);

    set_opcode(0x1A);
    set_operation(OP_INC);
    set_address_mode(ACC_A);

    set_opcode(0x1C);
    set_operation(OP_TRB);
    set_address_mode(ABS_a);

    set_opcode(0x1D);
    set_operation(OP_ORA);
    set_address_mode(AIX_a_x);

    set_opcode(0x1E);
    set_operation(OP_ASL);
    set_address_mode(AIX_a_x);

    set_opcode(0x20);
    set_operation(OP_JSR);
    set_address_mode(ABS_a);

    set_opcode(0x21);
    set_operation(OP_AND);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x22);
    set_operation(OP_JSR);
    set_address_mode(AIA_A);

    set_opcode(0x23);
    set_operation(OP_SUB);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x24);
    set_operation(OP_BIT);
    set_address_mode(ZPG_zp);

    set_opcode(0x25);
    set_operation(OP_AND);
    set_address_mode(ZPG_zp);

    set_opcode(0x26);
    set_operation(OP_ROL);
    set_address_mode(ZPG_zp);

    set_opcode(0x28);
    set_operation(OP_PLP);
    set_address_mode(STK_s);

    set_opcode(0x29);
    set_operation(OP_AND);
    set_address_mode(IMM_m);

    set_opcode(0x2A);
    set_operation(OP_ROL);
    set_address_mode(ACC_A);

    set_opcode(0x2C);
    set_operation(OP_BIT);
    set_address_mode(ABS_a);

    set_opcode(0x2D);
    set_operation(OP_AND);
    set_address_mode(ABS_a);

    set_opcode(0x2E);
    set_operation(OP_ROL);
    set_address_mode(ABS_a);

    set_opcode(0x30);
    set_operation(OP_BMI);
    set_address_mode(PCR_r);

    set_opcode(0x31);
    set_operation(OP_AND);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0x32);
    set_operation(OP_AND);
    set_address_mode(ZPI_ZP);

    set_opcode(0x34);
    set_operation(OP_BIT);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x35);
    set_operation(OP_AND);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x36);
    set_operation(OP_ROL);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x38);
    set_operation(OP_SEC);
    set_address_mode(IMP_i);

    set_opcode(0x39);
    set_operation(OP_AND);
    set_address_mode(AIY_a_y);

    set_opcode(0x3A);
    set_operation(OP_DEC);
    set_address_mode(ACC_A);

    set_opcode(0x3C);
    set_operation(OP_BIT);
    set_address_mode(AIX_a_x);

    set_opcode(0x3D);
    set_operation(OP_AND);
    set_address_mode(AIX_a_x);

    set_opcode(0x3E);
    set_operation(OP_ROL);
    set_address_mode(AIX_a_x);

    set_opcode(0x40);
    set_operation(OP_RTI);
    set_address_mode(STK_s);

    set_opcode(0x41);
    set_operation(OP_EOR);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x45);
    set_operation(OP_EOR);
    set_address_mode(ZPG_zp);

    set_opcode(0x46);
    set_operation(OP_LSR);
    set_address_mode(ZPG_zp);

    set_opcode(0x48);
    set_operation(OP_PHA);
    set_address_mode(STK_s);

    set_opcode(0x49);
    set_operation(OP_EOR);
    set_address_mode(IMM_m);

    set_opcode(0x4A);
    set_operation(OP_LSR);
    set_address_mode(ACC_A);

    set_opcode(0x4C);
    set_operation(OP_JMP);
    set_address_mode(ABS_a);

    set_opcode(0x4D);
    set_operation(OP_EOR);
    set_address_mode(ABS_a);

    set_opcode(0x4E);
    set_operation(OP_LSR);
    set_address_mode(ABS_a);

    set_opcode(0x50);
    set_operation(OP_BVC);
    set_address_mode(PCR_r);

    set_opcode(0x51);
    set_operation(OP_EOR);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0x52);
    set_operation(OP_EOR);
    set_address_mode(ZPG_zp);

    set_opcode(0x55);
    set_operation(OP_EOR);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x56);
    set_operation(OP_LSR);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x58);
    set_operation(OP_CLI);
    set_address_mode(IMP_i);

    set_opcode(0x59);
    set_operation(OP_EOR);
    set_address_mode(AIY_a_y);

    set_opcode(0x5A);
    set_operation(OP_PHY);
    set_address_mode(STK_s);

    set_opcode(0x5C);
    set_operation(OP_JSR);
    set_address_mode(AIIX_A_X);

    set_opcode(0x5D);
    set_operation(OP_EOR);
    set_address_mode(AIX_a_x);

    set_opcode(0x5E);
    set_operation(OP_LSR);
    set_address_mode(AIX_a_x);

    set_opcode(0x60);
    set_operation(OP_RTS);
    set_address_mode(STK_s);

    set_opcode(0x61);
    set_operation(OP_ADC);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x64);
    set_operation(OP_STZ);
    set_address_mode(ZPG_zp);

    set_opcode(0x65);
    set_operation(OP_ADC);
    set_address_mode(ZPG_zp);

    set_opcode(0x66);
    set_operation(OP_ROR);
    set_address_mode(ZPG_zp);

    set_opcode(0x68);
    set_operation(OP_PLA);
    set_address_mode(STK_s);

    set_opcode(0x69);
    set_operation(OP_ADC);
    set_address_mode(IMM_m);

    set_opcode(0x6A);
    set_operation(OP_ROR);
    set_address_mode(ACC_A);

    set_opcode(0x6C);
    set_operation(OP_JMP);
    set_address_mode(AIA_A);

    set_opcode(0x6D);
    set_operation(OP_ADC);
    set_address_mode(ABS_a);

    set_opcode(0x6E);
    set_operation(OP_ROR);
    set_address_mode(ABS_a);

    set_opcode(0x70);
    set_operation(OP_BVS);
    set_address_mode(PCR_r);

    set_opcode(0x71);
    set_operation(OP_ADC);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0x72);
    set_operation(OP_ADC);
    set_address_mode(ZPI_ZP);

    set_opcode(0x74);
    set_operation(OP_STZ);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x75);
    set_operation(OP_ADC);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x76);
    set_operation(OP_ROR);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x78);
    set_operation(OP_SEI);
    set_address_mode(IMP_i);

    set_opcode(0x79);
    set_operation(OP_ADC);
    set_address_mode(AIY_a_y);

    set_opcode(0x7A);
    set_operation(OP_PLY);
    set_address_mode(STK_s);

    set_opcode(0x7C);
    set_operation(OP_JMP);
    set_address_mode(AIIX_A_X);

    set_opcode(0x7D);
    set_operation(OP_ADC);
    set_address_mode(AIX_a_x);

    set_opcode(0x7E);
    set_operation(OP_ROR);
    set_address_mode(AIX_a_x);

    set_opcode(0x80);
    set_operation(OP_BRA);
    set_address_mode(PCR_r);

    set_opcode(0x81);
    set_operation(OP_STA);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0x84);
    set_operation(OP_STY);
    set_address_mode(ZPG_zp);

    set_opcode(0x85);
    set_operation(OP_STA);
    set_address_mode(ZPG_zp);

    set_opcode(0x86);
    set_operation(OP_STX);
    set_address_mode(ZPG_zp);

    set_opcode(0x87);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(0);

    set_opcode(0x97);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(1);

    set_opcode(0xA7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(2);

    set_opcode(0xB7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(3);

    set_opcode(0xC7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(4);

    set_opcode(0xD7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(5);

    set_opcode(0xE7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(6);

    set_opcode(0xF7);
    set_operation(OP_SMB);
    set_address_mode(ZPG_zp);
    set_which(7);

    set_opcode(0x88);
    set_operation(OP_DEY);
    set_address_mode(IMP_i);

    set_opcode(0x89);
    set_operation(OP_BIT);
    set_address_mode(IMM_m);

    set_opcode(0x8A);
    set_operation(OP_TXA);
    set_address_mode(IMP_i);

    set_opcode(0x8C);
    set_operation(OP_STY);
    set_address_mode(ABS_a);

    set_opcode(0x8D);
    set_operation(OP_STA);
    set_address_mode(ABS_a);

    set_opcode(0x8E);
    set_operation(OP_STX);
    set_address_mode(ABS_a);

    set_opcode(0x8F);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(0);

    set_opcode(0x9F);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(1);

    set_opcode(0xAF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(2);

    set_opcode(0xBF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(3);

    set_opcode(0xCF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(4);

    set_opcode(0xDF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(5);

    set_opcode(0xEF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(6);

    set_opcode(0xFF);
    set_operation(OP_BBS);
    set_address_mode(PCR_r);
    set_which(7);

    set_opcode(0x90);
    set_operation(OP_BCC);
    set_address_mode(PCR_r);

    set_opcode(0x91);
    set_operation(OP_STA);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0x92);
    set_operation(OP_STA);
    set_address_mode(ZIY_zp_y);

    set_opcode(0x94);
    set_operation(OP_STY);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x95);
    set_operation(OP_STA);
    set_address_mode(ZIX_zp_x);

    set_opcode(0x96);
    set_operation(OP_STX);
    set_address_mode(ZIY_zp_y);

    set_opcode(0x98);
    set_operation(OP_TYA);
    set_address_mode(IMP_i);

    set_opcode(0x99);
    set_operation(OP_STA);
    set_address_mode(AIY_a_y);

    set_opcode(0x9A);
    set_operation(OP_TXS);
    set_address_mode(IMP_i);

    set_opcode(0x9C);
    set_operation(OP_STZ);
    set_address_mode(ABS_a);

    set_opcode(0x9D);
    set_operation(OP_STA);
    set_address_mode(AIX_a_x);

    set_opcode(0x9E);
    set_operation(OP_STZ);
    set_address_mode(AIX_a_x);

    set_opcode(0xA0);
    set_operation(OP_LDY);
    set_address_mode(IMM_m);

    set_opcode(0xA1);
    set_operation(OP_LDA);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0xA2);
    set_operation(OP_LDX);
    set_address_mode(IMM_m);

    set_opcode(0xA4);
    set_operation(OP_LDY);
    set_address_mode(ZPG_zp);

    set_opcode(0xA5);
    set_operation(OP_LDA);
    set_address_mode(ZPG_zp);

    set_opcode(0xA6);
    set_operation(OP_LDX);
    set_address_mode(ZPG_zp);

    set_opcode(0xA8);
    set_operation(OP_TAY);
    set_address_mode(IMP_i);


    set_opcode(0xA9);
    set_operation(OP_LDA);
    set_address_mode(IMM_m);

    set_opcode(0xAA);
    set_operation(OP_TAX);
    set_address_mode(IMP_i);


    set_opcode(0xAC);
    set_operation(OP_LDY);
    set_address_mode(ABS_a);

    set_opcode(0xAD);
    set_operation(OP_LDA);
    set_address_mode(ABS_a);

    set_opcode(0xAE);
    set_operation(OP_LDX);
    set_address_mode(ABS_a);

    set_opcode(0xB0);
    set_operation(OP_BCS);
    set_address_mode(PCR_r);

    set_opcode(0xB1);
    set_operation(OP_LDA);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0xB2);
    set_operation(OP_LDA);
    set_address_mode(ZPI_ZP);

    set_opcode(0xB4);
    set_operation(OP_LDY);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xB5);
    set_operation(OP_LDA);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xB6);
    set_operation(OP_LDX);
    set_address_mode(ZIY_zp_y);

    set_opcode(0xB8);
    set_operation(OP_CLV);
    set_address_mode(IMP_i);

    set_opcode(0xB9);
    set_operation(OP_LDA);
    set_address_mode(AIY_a_y);

    set_opcode(0xBA);
    set_operation(OP_TSX);
    set_address_mode(IMP_i);


    set_opcode(0xBC);
    set_operation(OP_LDY);
    set_address_mode(AIX_a_x);

    set_opcode(0xBD);
    set_operation(OP_LDA);
    set_address_mode(AIX_a_x);

    set_opcode(0xBE);
    set_operation(OP_LDX);
    set_address_mode(AIY_a_y);

    set_opcode(0xC0);
    set_operation(OP_CPY);
    set_address_mode(IMM_m);

    set_opcode(0xC1);
    set_operation(OP_CMP);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0xC4);
    set_operation(OP_CPY);
    set_address_mode(ZPG_zp);

    set_opcode(0xC5);
    set_operation(OP_CMP);
    set_address_mode(ZPG_zp);

    set_opcode(0xC6);
    set_operation(OP_DEC);
    set_address_mode(ZPG_zp);

    set_opcode(0xC8);
    set_operation(OP_INY);
    set_address_mode(IMP_i);

    set_opcode(0xC9);
    set_operation(OP_CMP);
    set_address_mode(IMM_m);

    set_opcode(0xCA);
    set_operation(OP_DEX);
    set_address_mode(IMP_i);

    set_opcode(0xCB);
    set_operation(OP_WAI);
    set_address_mode(IMP_i);

    set_opcode(0xCC);
    set_operation(OP_CPY);
    set_address_mode(ABS_a);

    set_opcode(0xCD);
    set_operation(OP_CMP);
    set_address_mode(ABS_a);

    set_opcode(0xCE);
    set_operation(OP_DEC);
    set_address_mode(ABS_a);

    set_opcode(0xD0);
    set_operation(OP_BNE);
    set_address_mode(PCR_r);

    set_opcode(0xD1);
    set_operation(OP_CMP);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0xD2);
    set_operation(OP_CMP);
    set_address_mode(ZPI_ZP);

    set_opcode(0xD5);
    set_operation(OP_CMP);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xD6);
    set_operation(OP_DEC);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xD8);
    set_operation(OP_CLD);
    set_address_mode(IMP_i);


    set_opcode(0xD9);
    set_operation(OP_CMP);
    set_address_mode(AIY_a_y);

    set_opcode(0xDA);
    set_operation(OP_PHX);
    set_address_mode(STK_s);

    set_opcode(0xDB);
    set_operation(OP_STP);
    set_address_mode(IMP_i);

    set_opcode(0xDD);
    set_operation(OP_CMP);
    set_address_mode(AIX_a_x);

    set_opcode(0xDE);
    set_operation(OP_DEC);
    set_address_mode(AIX_a_x);

    set_opcode(0xE0);
    set_operation(OP_CPX);
    set_address_mode(IMM_m);

    set_opcode(0xE1);
    set_operation(OP_SBC);
    set_address_mode(ZIIX_ZP_X);

    set_opcode(0xE4);
    set_operation(OP_CPX);
    set_address_mode(ZPG_zp);

    set_opcode(0xE5);
    set_operation(OP_SBC);
    set_address_mode(ZPG_zp);

    set_opcode(0xE6);
    set_operation(OP_INC);
    set_address_mode(ZPG_zp);

    set_opcode(0xE8);
    set_operation(OP_INX);
    set_address_mode(IMP_i);

    set_opcode(0xE9);
    set_operation(OP_SBC);
    set_address_mode(IMM_m);

    set_opcode(0xEA);
    set_operation(OP_NOP);
    set_address_mode(IMP_i);


    set_opcode(0xEC);
    set_operation(OP_CPX);
    set_address_mode(ABS_a);

    set_opcode(0xED);
    set_operation(OP_SBC);
    set_address_mode(ABS_a);

    set_opcode(0xEE);
    set_operation(OP_INC);
    set_address_mode(ABS_a);

    set_opcode(0xF0);
    set_operation(OP_BEQ);
    set_address_mode(PCR_r);

    set_opcode(0xF1);
    set_operation(OP_SBC);
    set_address_mode(ZIIY_ZP_y);

    set_opcode(0xF2);
    set_operation(OP_SBC);
    set_address_mode(ZPI_ZP);

    set_opcode(0xF5);
    set_operation(OP_SBC);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xF6);
    set_operation(OP_INC);
    set_address_mode(ZIX_zp_x);

    set_opcode(0xF8);
    set_operation(OP_SED);
    set_address_mode(IMP_i);

    set_opcode(0xF9);
    set_operation(OP_SBC);
    set_address_mode(AIY_a_y);

    set_opcode(0xFA);
    set_operation(OP_PLX);
    set_address_mode(STK_s);

    set_opcode(0xFD);
    set_operation(OP_SBC);
    set_address_mode(AIX_a_x);

    set_opcode(0xFE);
    set_operation(OP_INC);
    set_address_mode(AIX_a_x);

    flush_instruction();
}

void gen_65832_instructions() {

    set_mode(MODE_6502);

    set_opcode(0x00);
    set_operation(OP_BRK);
    set_address_mode(STK_s);

    set_opcode(0x01);
    set_operation(OP_ORA);
    set_address_mode(ZIIX_ZP_X);
    ,,,AIIX_A_X,,

    set_opcode(0x06);
    set_operation(OP_ASL);
    set_address_mode(ZPG_zp);
    ,,,ABS_a,,

    set_opcode(0x08);
    set_operation(OP_PHP);
    set_address_mode(STK_s);

    set_opcode(0x09);
    set_operation(OP_ORA);
    set_address_mode(IMM_m);

    set_opcode(0x0A);
    set_operation(OP_ASL);
    set_address_mode(ACC_A);

    set_opcode(0x0C);
    set_operation(OP_TSB);
    set_address_mode(ABS_a);

    set_opcode(0x0D);
    set_operation(OP_ORA);
    set_address_mode(ABS_a);

    set_opcode(0x10);
    set_operation(OP_BPL);
    set_address_mode(PCR_r);

    set_opcode(0x11);
    set_operation(OP_ORA);
    set_address_mode(ZIIY_ZP_y);
    ,,ORA,AIIY_A_y,,

    set_opcode(0x12);
    set_operation(OP_ORA);
    set_address_mode(ZPI_ZP);
    ,,ORA,AIA_A,,

    set_opcode(0x16);
    set_operation(OP_ASL);
    set_address_mode(ZIX_zp_x);
    ,,ASL,AIX_a_x,,

    set_opcode(0x18);
    set_operation(OP_CLC);
    set_address_mode(IMP_i);

    set_opcode(0x19);
    set_operation(OP_ORA);
    set_address_mode(AIY_a_y);

    set_opcode(0x1A);
    set_operation(OP_INC);
    set_address_mode(ACC_A);

    set_opcode(0x1C);
    set_operation(OP_TRB);
    set_address_mode(ABS_a);

    set_opcode(0x1D);
    set_operation(OP_ORA);
    set_address_mode(AIX_a_x);

    set_opcode(0x20);
    set_operation(OP_JSR);
    set_address_mode(ABS_a);

    set_opcode(0x21);
    set_operation(OP_AND);
    set_address_mode(ZIIX_ZP_X);
    ,,AND,AIIX_A_X,,

    set_opcode(0x22);
    set_operation(OP_JSR);
    set_address_mode(AIA_A);

    set_opcode(0x26);
    set_operation(OP_ROL);
    set_address_mode(ZPG_zp);
    ,,ROL,ABS_a,,

    set_opcode(0x28);
    set_operation(OP_PLP);
    set_address_mode(STK_s);

    set_opcode(0x29);
    set_operation(OP_AND);
    set_address_mode(IMM_m);

    set_opcode(0x2A);
    set_operation(OP_ROL);
    set_address_mode(ACC_A);

    set_opcode(0x2C);
    set_operation(OP_BIT);
    set_address_mode(ABS_a);

    set_opcode(0x2D);
    set_operation(OP_AND);
    set_address_mode(ABS_a);

    set_opcode(0x30);
    set_operation(OP_BMI);
    set_address_mode(PCR_r);

    set_opcode(0x31);
    set_operation(OP_AND);
    set_address_mode(ZIIY_ZP_y);
    ,,AND,AIIY_A_y,,

    set_opcode(0x32);
    set_operation(OP_AND);
    set_address_mode(ZPI_ZP);
    ,,AND,AIA_A,,

    set_opcode(0x36);
    set_operation(OP_ROL);
    set_address_mode(ZIX_zp_x);
    ,,ROL,AIX_a_x,,

    set_opcode(0x38);
    set_operation(OP_SEC);
    set_address_mode(IMP_i);

    set_opcode(0x39);
    set_operation(OP_AND);
    set_address_mode(AIY_a_y);

    set_opcode(0x3A);
    set_operation(OP_DEC);
    set_address_mode(ACC_A);

    set_opcode(0x3C);
    set_operation(OP_BIT);
    set_address_mode(AIX_a_x);

    set_opcode(0x3D);
    set_operation(OP_AND);
    set_address_mode(AIX_a_x);

    set_opcode(0x40);
    set_operation(OP_RTI);
    set_address_mode(STK_s);

    set_opcode(0x41);
    set_operation(OP_EOR);
    set_address_mode(ZIIX_ZP_X);
    ,,EOR,AIIX_A_X,,

    set_opcode(0x46);
    set_operation(OP_LSR);
    set_address_mode(ZPG_zp);
    ,,LSR,ABS_a,,

    set_opcode(0x48);
    set_operation(OP_PHA);
    set_address_mode(STK_s);

    set_opcode(0x49);
    set_operation(OP_EOR);
    set_address_mode(IMM_m);

    set_opcode(0x4A);
    set_operation(OP_LSR);
    set_address_mode(ACC_A);

    set_opcode(0x4C);
    set_operation(OP_JMP);
    set_address_mode(ABS_a);

    set_opcode(0x4D);
    set_operation(OP_EOR);
    set_address_mode(ABS_a);

    set_opcode(0x50);
    set_operation(OP_BVC);
    set_address_mode(PCR_r);

    set_opcode(0x51);
    set_operation(OP_EOR);
    set_address_mode(ZIIY_ZP_y);
    ,,EOR,AIIY_A_y,,

    set_opcode(0x52);
    set_operation(OP_EOR);
    set_address_mode(ZPG_zp);
    ,,EOR,AIA_A,,

    set_opcode(0x56);
    set_operation(OP_LSR);
    set_address_mode(ZIX_zp_x);
    ,,LSR,AIX_a_x,,

    set_opcode(0x58);
    set_operation(OP_CLI);
    set_address_mode(IMP_i);

    set_opcode(0x59);
    set_operation(OP_EOR);
    set_address_mode(AIY_a_y);

    set_opcode(0x5A);
    set_operation(OP_PHY);
    set_address_mode(STK_s);

    set_opcode(0x5C);
    set_operation(OP_JSR);
    set_address_mode(AIIX_A_X);

    set_opcode(0x5D);
    set_operation(OP_EOR);
    set_address_mode(AIX_a_x);

    set_opcode(0x60);
    set_operation(OP_RTS);
    set_address_mode(STK_s);

    set_opcode(0x61);
    set_operation(OP_ADC);
    set_address_mode(ZIIX_ZP_X);
    ,,ADC,AIIX_A_X,,

    set_opcode(0x66);
    set_operation(OP_ROR);
    set_address_mode(ZPG_zp);
    ,,ROR,ABS_a,,

    set_opcode(0x68);
    set_operation(OP_PLA);
    set_address_mode(STK_s);

    set_opcode(0x69);
    set_operation(OP_ADC);
    set_address_mode(IMM_m);

    set_opcode(0x6A);
    set_operation(OP_ROR);
    set_address_mode(ACC_A);

    set_opcode(0x6C);
    set_operation(OP_JMP);
    set_address_mode(AIA_A);

    set_opcode(0x6D);
    set_operation(OP_ADC);
    set_address_mode(ABS_a);

    set_opcode(0x70);
    set_operation(OP_BVS);
    set_address_mode(PCR_r);

    set_opcode(0x71);
    set_operation(OP_ADC);
    set_address_mode(ZIIY_ZP_y);
    ,,ADC,AIIY_A_y,,

    set_opcode(0x72);
    set_operation(OP_ADC);
    set_address_mode(ZPI_ZP);
    ,,ADC,AIA_A,,

    set_opcode(0x76);
    set_operation(OP_ROR);
    set_address_mode(ZIX_zp_x);
    ,,ROR,AIX_a_x,,

    set_opcode(0x78);
    set_operation(OP_SEI);
    set_address_mode(IMP_i);

    set_opcode(0x79);
    set_operation(OP_ADC);
    set_address_mode(AIY_a_y);

    set_opcode(0x7A);
    set_operation(OP_PLY);
    set_address_mode(STK_s);

    set_opcode(0x7C);
    set_operation(OP_JMP);
    set_address_mode(AIIX_A_X);

    set_opcode(0x7D);
    set_operation(OP_ADC);
    set_address_mode(AIX_a_x);

    set_opcode(0x80);
    set_operation(OP_BRA);
    set_address_mode(PCR_r);

    set_opcode(0x81);
    set_operation(OP_STA);
    set_address_mode(ZIIX_ZP_X);
    ,,STA,AIIX_A_X,,

    set_opcode(0x86);
    set_operation(OP_STX);
    set_address_mode(ZPG_zp);
    ,,STX,ABS_a,,

    set_opcode(0x88);
    set_operation(OP_DEY);
    set_address_mode(IMP_i);

    set_opcode(0x89);
    set_operation(OP_BIT);
    set_address_mode(IMM_m);

    set_opcode(0x8A);
    set_operation(OP_TXA);
    set_address_mode(IMP_i);

    set_opcode(0x8C);
    set_operation(OP_STY);
    set_address_mode(ABS_a);

    set_opcode(0x8D);
    set_operation(OP_STA);
    set_address_mode(ABS_a);

    set_opcode(0x8E);
    set_operation(OP_STX);
    set_address_mode(ABS_a);

    set_opcode(0x90);
    set_operation(OP_BCC);
    set_address_mode(PCR_r);

    set_opcode(0x91);
    set_operation(OP_STA);
    set_address_mode(ZIIY_ZP_y);
    ,,STA,AIIY_A_y,,

    set_opcode(0x92);
    set_operation(OP_STA);
    set_address_mode(ZIY_zp_y);
    ,,STA,AIA_A,,

    set_opcode(0x96);
    set_operation(OP_STX);
    set_address_mode(ZIY_zp_y);
    ,,STZ,AIX_a_x,,

    set_opcode(0x98);
    set_operation(OP_TYA);
    set_address_mode(IMP_i);

    set_opcode(0x99);
    set_operation(OP_STA);
    set_address_mode(AIY_a_y);

    set_opcode(0x9A);
    set_operation(OP_TXS);
    set_address_mode(IMP_i);

    set_opcode(0x9C);
    set_operation(OP_STZ);
    set_address_mode(ABS_a);
    ,,STY,AIX_a_x,,

    set_opcode(0x9D);
    set_operation(OP_STA);
    set_address_mode(AIX_a_x);

    set_opcode(0x9E);
    set_operation(OP_STZ);
    set_address_mode(AIX_a_x);
    ,,STX,AIY_a_y,,

    set_opcode(0xA0);
    set_operation(OP_LDY);
    set_address_mode(IMM_m);

    set_opcode(0xA1);
    set_operation(OP_LDA);
    set_address_mode(ZIIX_ZP_X);
    ,,LDA,AIIX_A_X,,

    set_opcode(0xA2);
    set_operation(OP_LDX);
    set_address_mode(IMM_m);

    set_opcode(0xA8);
    set_operation(OP_TAY);
    set_address_mode(IMP_i);

    set_opcode(0xA9);
    set_operation(OP_LDA);
    set_address_mode(IMM_m);

    set_opcode(0xAA);
    set_operation(OP_TAX);
    set_address_mode(IMP_i);

    set_opcode(0xAC);
    set_operation(OP_LDY);
    set_address_mode(ABS_a);

    set_opcode(0xAD);
    set_operation(OP_LDA);
    set_address_mode(ABS_a);

    set_opcode(0xAE);
    set_operation(OP_LDX);
    set_address_mode(ABS_a);

    set_opcode(0xB0);
    set_operation(OP_BCS);
    set_address_mode(PCR_r);

    set_opcode(0xB1);
    set_operation(OP_LDA);
    set_address_mode(ZIIY_ZP_y);
    ,,LDA,AIIY_A_y,,

    set_opcode(0xB2);
    set_operation(OP_LDA);
    set_address_mode(ZPI_ZP);
    ,,LDA,AIA_A,,

    set_opcode(0xB8);
    set_operation(OP_CLV);
    set_address_mode(IMP_i);

    set_opcode(0xB9);
    set_operation(OP_LDA);
    set_address_mode(AIY_a_y);

    set_opcode(0xBA);
    set_operation(OP_TSX);
    set_address_mode(IMP_i);

    set_opcode(0xBC);
    set_operation(OP_LDY);
    set_address_mode(AIX_a_x);

    set_opcode(0xBD);
    set_operation(OP_LDA);
    set_address_mode(AIX_a_x);

    set_opcode(0xBE);
    set_operation(OP_LDX);
    set_address_mode(AIY_a_y);

    set_opcode(0xC0);
    set_operation(OP_CPY);
    set_address_mode(IMM_m);

    set_opcode(0xC1);
    set_operation(OP_CMP);
    set_address_mode(ZIIX_ZP_X);
    ,,CMP,AIIX_A_X,,

    set_opcode(0xC6);
    set_operation(OP_DEC);
    set_address_mode(ZPG_zp);
    ,,DEC,ABS_a,,

    set_opcode(0xC8);
    set_operation(OP_INY);
    set_address_mode(IMP_i);

    set_opcode(0xC9);
    set_operation(OP_CMP);
    set_address_mode(IMM_m);

    set_opcode(0xCA);
    set_operation(OP_DEX);
    set_address_mode(IMP_i);

    set_opcode(0xCC);
    set_operation(OP_CPY);
    set_address_mode(ABS_a);

    set_opcode(0xCD);
    set_operation(OP_CMP);
    set_address_mode(ABS_a);

    set_opcode(0xD0);
    set_operation(OP_BNE);
    set_address_mode(PCR_r);

    set_opcode(0xD1);
    set_operation(OP_CMP);
    set_address_mode(ZIIY_ZP_y);
    ,,CMP,AIIY_A_y,,

    set_opcode(0xD2);
    set_operation(OP_CMP);
    set_address_mode(ZPI_ZP);
    ,,CMP,AIA_A,,

    set_opcode(0xD6);
    set_operation(OP_DEC);
    set_address_mode(ZIX_zp_x);
    ,,DEC,AIX_a_x,,

    set_opcode(0xD8);
    set_operation(OP_CLD);
    set_address_mode(IMP_i);

    set_opcode(0xD9);
    set_operation(OP_CMP);
    set_address_mode(AIY_a_y);

    set_opcode(0xDA);
    set_operation(OP_PHX);
    set_address_mode(STK_s);

    set_opcode(0xDD);
    set_operation(OP_CMP);
    set_address_mode(AIX_a_x);

    set_opcode(0xE0);
    set_operation(OP_CPX);
    set_address_mode(IMM_m);

    set_opcode(0xE1);
    set_operation(OP_SBC);
    set_address_mode(ZIIX_ZP_X);
    ,,SBC,AIIX_A_X,,

    set_opcode(0xE6);
    set_operation(OP_INC);
    set_address_mode(ZPG_zp);
    ,,INC,ABS_a,,

    set_opcode(0xE8);
    set_operation(OP_INX);
    set_address_mode(IMP_i);

    set_opcode(0xE9);
    set_operation(OP_SBC);
    set_address_mode(IMM_m);

    set_opcode(0xEA);
    set_operation(OP_NOP);
    set_address_mode(IMP_i);

    set_opcode(0xEC);
    set_operation(OP_CPX);
    set_address_mode(ABS_a);

    set_opcode(0xED);
    set_operation(OP_SBC);
    set_address_mode(ABS_a);

    set_opcode(0xF0);
    set_operation(OP_BEQ);
    set_address_mode(PCR_r);

    set_opcode(0xF1);
    set_operation(OP_SBC);
    set_address_mode(ZIIY_ZP_y);
    ,,SBC,AIIY_A_y,,

    set_opcode(0xF2);
    set_operation(OP_SBC);
    set_address_mode(ZPI_ZP);
    ,,SBC,AIA_A,,

    set_opcode(0xF6);
    set_operation(OP_INC);
    set_address_mode(ZIX_zp_x);
    ,,INC,AIX_a_x,,

    set_opcode(0xF8);
    set_operation(OP_SED);
    set_address_mode(IMP_i);

    set_opcode(0xF9);
    set_operation(OP_SBC);
    set_address_mode(AIY_a_y);

    set_opcode(0xFA);
    set_operation(OP_PLX);
    set_address_mode(STK_s);

    set_opcode(0xFD);
    set_operation(OP_SBC);
    set_address_mode(AIX_a_x);

    flush_instruction();
}

void gen_overlay_instructions() {

    set_mode(MODE_OVERLAY);

    set_opcode(0x00);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x01);
    set_operation(OP_);
    set_address_mode();
    ,,,AIIX_A_X,,

    set_opcode(0x02);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x04);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x05);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x06);
    set_operation(OP_);
    set_address_mode();
    ,,,ABS_a,,

    set_opcode(0x07);
    set_operation(OP_);
    set_address_mode();
    set_which(0);

    set_opcode(0x17);
    set_operation(OP_);
    set_address_mode();
    set_which(1);

    set_opcode(0x27);
    set_operation(OP_);
    set_address_mode();
    set_which(2);

    set_opcode(0x37);
    set_operation(OP_);
    set_address_mode();
    set_which(3);

    set_opcode(0x47);
    set_operation(OP_);
    set_address_mode();
    set_which(4);

    set_opcode(0x57);
    set_operation(OP_);
    set_address_mode();
    set_which(5);

    set_opcode(0x67);
    set_operation(OP_);
    set_address_mode();
    set_which(6);

    set_opcode(0x77);
    set_operation(OP_);
    set_address_mode();
    set_which(7);

    set_opcode(0x08);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x09);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x0A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x0C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x0D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x0E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x0F);
    set_operation(OP_);
    set_address_mode();
    set_which(0);

    set_opcode(0x1F);
    set_operation(OP_);
    set_address_mode();
    set_which(1);

    set_opcode(0x2F);
    set_operation(OP_);
    set_address_mode();
    set_which(2);

    set_opcode(0x3F);
    set_operation(OP_);
    set_address_mode();
    set_which(3);

    set_opcode(0x4F);
    set_operation(OP_);
    set_address_mode();
    set_which(4);

    set_opcode(0x5F);
    set_operation(OP_);
    set_address_mode();
    set_which(5);

    set_opcode(0x6F);
    set_operation(OP_);
    set_address_mode();
    set_which(6);

    set_opcode(0x7F);
    set_operation(OP_);
    set_address_mode();
    set_which(7);

    set_opcode(0x10);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x11);
    set_operation(OP_);
    set_address_mode();
    ,,ORA,AIIY_A_y,,

    set_opcode(0x12);
    set_operation(OP_);
    set_address_mode();
    ,,ORA,AIA_A,,

    set_opcode(0x14);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x15);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x16);
    set_operation(OP_);
    set_address_mode();
    ,,ASL,AIX_a_x,,

    set_opcode(0x18);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x19);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x1A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x1C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x1D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x1E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x20);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x21);
    set_operation(OP_);
    set_address_mode();
    ,,AND,AIIX_A_X,,

    set_opcode(0x22);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x23);
    set_operation(OP_);
    set_address_mode();
    ,,AND,AIIX_A_X,,

    set_opcode(0x24);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x25);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x26);
    set_operation(OP_);
    set_address_mode();
    ,,ROL,ABS_a,,

    set_opcode(0x28);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x29);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x2A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x2C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x2D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x2E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x30);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x31);
    set_operation(OP_);
    set_address_mode();
    ,,AND,AIIY_A_y,,

    set_opcode(0x32);
    set_operation(OP_);
    set_address_mode();
    ,,AND,AIA_A,,

    set_opcode(0x34);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x35);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x36);
    set_operation(OP_);
    set_address_mode();
    ,,ROL,AIX_a_x,,

    set_opcode(0x38);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x39);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x3A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x3C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x3D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x3E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x40);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x41);
    set_operation(OP_);
    set_address_mode();
    ,,EOR,AIIX_A_X,,

    set_opcode(0x45);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x46);
    set_operation(OP_);
    set_address_mode();
    ,,LSR,ABS_a,,

    set_opcode(0x48);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x49);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x4A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x4C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x4D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x4E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x50);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x51);
    set_operation(OP_);
    set_address_mode();
    ,,EOR,AIIY_A_y,,

    set_opcode(0x52);
    set_operation(OP_);
    set_address_mode();
    ,,EOR,AIA_A,,

    set_opcode(0x55);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x56);
    set_operation(OP_);
    set_address_mode();
    ,,LSR,AIX_a_x,,

    set_opcode(0x58);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x59);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x5A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x5C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x5D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x5E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x60);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x61);
    set_operation(OP_);
    set_address_mode();
    ,,ADC,AIIX_A_X,,

    set_opcode(0x64);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x65);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x66);
    set_operation(OP_);
    set_address_mode();
    ,,ROR,ABS_a,,

    set_opcode(0x68);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x69);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x6A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x6C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x6D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x6E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x70);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x71);
    set_operation(OP_);
    set_address_mode();
    ,,ADC,AIIY_A_y,,

    set_opcode(0x72);
    set_operation(OP_);
    set_address_mode();
    ,,ADC,AIA_A,,

    set_opcode(0x74);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x75);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x76);
    set_operation(OP_);
    set_address_mode();
    ,,ROR,AIX_a_x,,

    set_opcode(0x78);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x79);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x7A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x7C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x7D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x7E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x80);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x81);
    set_operation(OP_);
    set_address_mode();
    ,,STA,AIIX_A_X,,

    set_opcode(0x84);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x85);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x86);
    set_operation(OP_);
    set_address_mode();
    ,,STX,ABS_a,,

    set_opcode(0x87);
    set_operation(OP_);
    set_address_mode();
    set_which(0);

    set_opcode(0x97);
    set_operation(OP_);
    set_address_mode();
    set_which(1);

    set_opcode(0xA7);
    set_operation(OP_);
    set_address_mode();
    set_which(2);

    set_opcode(0xB7);
    set_operation(OP_);
    set_address_mode();
    set_which(3);

    set_opcode(0xC7);
    set_operation(OP_);
    set_address_mode();
    set_which(4);

    set_opcode(0xD7);
    set_operation(OP_);
    set_address_mode();
    set_which(5);

    set_opcode(0xE7);
    set_operation(OP_);
    set_address_mode();
    set_which(6);

    set_opcode(0xF7);
    set_operation(OP_);
    set_address_mode();
    set_which(7);

    set_opcode(0x88);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x89);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x8A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x8C);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x8D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x8E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x8F);
    set_operation(OP_);
    set_address_mode();
    set_which(0);

    set_opcode(0x9F);
    set_operation(OP_);
    set_address_mode();
    set_which(1);

    set_opcode(0xAF);
    set_operation(OP_);
    set_address_mode();
    set_which(2);

    set_opcode(0xBF);
    set_operation(OP_);
    set_address_mode();
    set_which(3);

    set_opcode(0xCF);
    set_operation(OP_);
    set_address_mode();
    set_which(4);

    set_opcode(0xDF);
    set_operation(OP_);
    set_address_mode();
    set_which(5);

    set_opcode(0xEF);
    set_operation(OP_);
    set_address_mode();
    set_which(6);

    set_opcode(0xFF);
    set_operation(OP_);
    set_address_mode();
    set_which(7);

    set_opcode(0x90);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x91);
    set_operation(OP_);
    set_address_mode();
    ,,STA,AIIY_A_y,,

    set_opcode(0x92);
    set_operation(OP_);
    set_address_mode();
    ,,STA,AIA_A,,

    set_opcode(0x94);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x95);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x96);
    set_operation(OP_);
    set_address_mode();
    ,,STX,AIX_a_x,,

    set_opcode(0x98);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x99);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x9A);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x9C);
    set_operation(OP_);
    set_address_mode();
    ,,STY,AIX_a_x,,

    set_opcode(0x9D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x9E);
    set_operation(OP_);
    set_address_mode();
    ,,STX,AIY_a_y,,

    set_opcode(0xA0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA1);
    set_operation(OP_);
    set_address_mode();
    ,,LDA,AIIX_A_X,,

    set_opcode(0xA2);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA4);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA6);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA8);
    set_operation(OP_);
    set_address_mode();


    set_opcode(0xA9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xAA);
    set_operation(OP_);
    set_address_mode();


    set_opcode(0xAC);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xAD);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xAE);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB1);
    set_operation(OP_);
    set_address_mode();
    ,,LDA,AIIY_A_y,,

    set_opcode(0xB2);
    set_operation(OP_);
    set_address_mode();
    ,,LDA,AIA_A,,

    set_opcode(0xB4);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB6);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB8);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xB9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xBA);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xBC);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xBD);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xBE);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC1);
    set_operation(OP_);
    set_address_mode();
    ,,CMP,AIIX_A_X,,

    set_opcode(0xC4);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC6);
    set_operation(OP_);
    set_address_mode();
    ,,DEC,ABS_a,,

    set_opcode(0xC8);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xCA);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xCB);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xCC);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xCD);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xCE);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD1);
    set_operation(OP_);
    set_address_mode();
    ,,CMP,AIIY_A_y,,

    set_opcode(0xD2);
    set_operation(OP_);
    set_address_mode();
    ,,CMP,AIA_A,,

    set_opcode(0xD5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD6);
    set_operation(OP_);
    set_address_mode();
    ,,DEC,AIX_a_x,,

    set_opcode(0xD8);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xDA);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xDB);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xDD);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xDE);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE1);
    set_operation(OP_);
    set_address_mode();
    ,,SBC,AIIX_A_X,,

    set_opcode(0xE4);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE6);
    set_operation(OP_);
    set_address_mode();
    ,,INC,ABS_a,,

    set_opcode(0xE8);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xEA);
    set_operation(OP_);
    set_address_mode();


    set_opcode(0xEC);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xED);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xEE);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF1);
    set_operation(OP_);
    set_address_mode();
    ,,SBC,AIIY_A_y,,

    set_opcode(0xF2);
    set_operation(OP_);
    set_address_mode();
    ,,SBC,AIA_A,,

    set_opcode(0xF5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF6);
    set_operation(OP_);
    set_address_mode();
    ,,INC,AIX_a_x,,

    set_opcode(0xF8);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF9);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xFA);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xFD);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xFE);
    set_operation(OP_);
    set_address_mode();

    flush_instruction();
}

int main() {
    gen_6502_instructions();
    gen_65832_instructions();
    gen_overlay_instructions();
    return 0;
}
