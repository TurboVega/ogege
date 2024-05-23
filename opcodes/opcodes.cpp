#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <string>
#include <algorithm>

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

typedef const char* AddressMode;

static AddressMode AM_NONE = "AM_NONE";         // None (invalid)
static AddressMode ABS_a = "ABS_a";             // Absolute a
static AddressMode AIIX_A_X = "AIIX_A_X";       // Absolute Indexed Indirect with X (a,x)
static AddressMode AIX_a_x = "AIX_a_x";         // Absolute Indexed with X a,x
static AddressMode AIY_a_y = "AIY_a_y";         // Absolute Indexed with Y a,y
static AddressMode AIIY_A_y = "AIIY_A_y";       // Absolute Indexed Indirect with Y (a),y
static AddressMode AIA_A = "AIA_A";             // Absolute Indirect (a)
static AddressMode ACC_A = "ACC_A";             // Accumulator A
static AddressMode IMM_m = "IMM_m";             // Immediate Addressing #
static AddressMode IMP_i = "IMP_i";             // Implied i
static AddressMode PCR_r = "PCR_r";             // Program Counter Relative r
static AddressMode STK_s = "STK_s";             // Stack s
static AddressMode ZPG_zp = "ZPG_zp";           // Zero Page zp
static AddressMode ZIIX_ZP_X = "ZIIX_ZP_X";     // Zero Page Indexed Indirect (zp,x)
static AddressMode ZIX_zp_x = "ZIX_zp_x";       // Zero Page Indexed with X zp,x
static AddressMode ZIY_zp_y = "ZIY_zp_y";       // Zero Page Indexed with Y zp,y
static AddressMode ZPI_ZP = "ZPI_ZP";           // Zero Page Indirect (zp)
static AddressMode ZIIY_ZP_y = "ZIIY_ZP_y";     // Zero Page Indirect Indexed with Y (zp),y

typedef const char* Register;

static Register A = "`A";
static Register X = "`X";
static Register Y = "`Y";
static Register PC = "`PC";
static Register SP = "`SP";
static Register EA = "`EA";
static Register EX = "`EX";
static Register EY = "`EY";
static Register EPC = "`EPC";
static Register ESP = "`ESP";
static Register P = "P";
static Register N = "`N";
static Register V = "`V";
static Register U = "`U";
static Register B = "`B";
static Register D = "`D";
static Register I = "`I";
static Register Z = "`Z";
static Register C = "`C";
static Register RB = "`RB";
static Register RHW = "`RHW";
static Register RW = "`RW";
static Register RDW = "`RDW";
static Register RQW = "`RQW";
static Register WB = "`WB";
static Register WHW = "`WHW";
static Register WW = "`WW";
static Register WDW = "`WDW";
static Register WQW = "`WQW";
static Register ADDR = "`ADDR";
static Register EADDR = "`EADDR";

typedef const char* CpuMode;

CpuMode MODE_NONE = "MODE_NONE";
CpuMode MODE_6502 = "MODE_6502";
CpuMode MODE_65832 = "MODE_65832";
CpuMode MODE_OVERLAY = "MODE_OVERLAY";

void flush_mode();
void flush_instruction();

class MicroInstruction {
    public:
    CpuMode     cpu_mode;
    uint8_t     opcode;
    Operation   operation;
    AddressMode address_mode;
    uint8_t     which;
    uint8_t     cycle;
    std::string action;

    MicroInstruction() {
        cpu_mode = MODE_NONE;
        opcode = 0;
        operation = OP_NONE;
        address_mode = AM_NONE;
        which = 0;
        cycle = 0;
    }

    MicroInstruction(const MicroInstruction& mi) {
        cpu_mode = mi.cpu_mode;
        opcode = mi.opcode;
        operation = mi.operation;
        address_mode = mi.address_mode;
        which = mi.which;
        cycle = mi.cycle;
        action = mi.action;
    }
};

int compare_mi_objects(const MicroInstruction& a, const MicroInstruction& b) {
    if (a.cycle < b.cycle) return -1;
    if (a.cycle > b.cycle) return 1;

    auto cmp = strcmp(a.address_mode, b.address_mode);
    if (cmp != 0) return cmp;

    cmp = a.action.compare(b.action);
    if (cmp != 0) return cmp;

    cmp = strcmp(a.operation, b.operation);
    if (cmp != 0) return cmp;

    cmp = strcmp(a.cpu_mode, b.cpu_mode);
    if (cmp != 0) return cmp;

    if (a.which < b.which) return -1;
    if (a.which > b.which) return 1;

    if (a.opcode < b.opcode) return -1;
    if (a.opcode > b.opcode) return 1;

    return 0; // equal
}

bool compare_mi(const MicroInstruction& a, const MicroInstruction& b) {
    return compare_mi_objects(a, b) < 0;
}

typedef std::vector<MicroInstruction> ActionList;

MicroInstruction g_mi;
ActionList g_actions;

void set_mode(CpuMode cpu_mode) {
    flush_mode();
    g_mi.cpu_mode = cpu_mode;
}

void set_opcode(uint8_t opcode) {
    flush_instruction();
    g_mi.opcode = opcode;
}

void set_operation(Operation operation) {
    g_mi.operation = operation;
}

void set_address_mode(AddressMode address_mode) {
    g_mi.address_mode = address_mode;
}

void set_which(uint8_t which) {
    g_mi.which = which;
}

void flush_mode() {
    flush_instruction();
}

void save_instruction() {
    if (g_mi.operation != OP_NONE && !g_mi.action.empty()) {
        g_actions.push_back(g_mi);
    }
    g_mi.action.clear();
}

void flush_instruction() {
    save_instruction();
    g_mi.operation = OP_NONE;
    g_mi.cycle = 0;
}

void flush_cycle() {
    save_instruction();
    g_mi.cycle++;
}

std::string bit_of(Register reg, uint8_t bit_nbr) {
    static char combined[20];
    sprintf(combined, "%s[%hu]", reg, bit_nbr);
    return std::string(combined);
}

std::string part(Register reg, uint8_t highest, uint8_t lowest) {
    static char combined[20];
    sprintf(combined, "%s[%hu:%hu]", reg, highest, lowest);
    return std::string(combined);
}

std::string bit(uint8_t b) {
    static char val[2];
    sprintf(val, "%hu", b);
    return std::string(val);
}

std::string combine2(const char* a, const char* b) {
    std::string combined("{");
    combined += a;
    combined += ",";
    combined += b;
    combined += "}";
    return combined;
}

std::string combine3(const char* a,
    const char* b, const char* c) {
    std::string combined("{");
    combined += a;
    combined += ",";
    combined += b;
    combined += ",";
    combined += c;
    combined += "}";
    return combined;
}

void assign(Register reg, uint32_t n) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= ";
    char nbr[11];
    sprintf(nbr, "%u", n);
    g_mi.action += nbr;
    g_mi.action += ";";
}

void assign(Register reg, const char* val) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= ";
    g_mi.action += val;
    g_mi.action += ";";
}

std::string get_write_byte_action(const char* address, const char* val) {
    std::string action("`WRITE_BYTE(");
    action += address;
    action += ",";
    action += val;
    action += ");";
    return action;
}

void push_byte(const char* val) {
    save_instruction();
    std::string action("tmp_SP = SP - 1;");
    action += " ";
    action += get_write_byte_action("tmp_SP", val);
    action += " SP <= tmp_SP;";
    g_mi.action = action;
    flush_cycle();
}

void push_half_word(const char* val) {
    save_instruction();
    assign(part(WQW, 7, 0).c_str(), part(val, 7, 0).c_str());
    push_byte(part(val, 15, 8).c_str());
    push_byte(part(WQW, 7, 0).c_str());
}

void push_word(const char* val) {
    save_instruction();
    assign(part(WQW, 23, 0).c_str(), part(val, 23, 0).c_str());
    push_byte(part(val, 31, 24).c_str());
    push_byte(part(WQW, 23, 16).c_str());
    push_byte(part(WQW, 15, 8).c_str());
    push_byte(part(WQW, 7, 0).c_str());
}

void push_double_word(const char* val) {
    save_instruction();
    assign(part(WQW, 55, 0).c_str(), part(val, 55, 0).c_str());
    push_byte(part(val, 63, 56).c_str());
    push_byte(part(WQW, 55, 48).c_str());
    push_byte(part(WQW, 47, 40).c_str());
    push_byte(part(WQW, 39, 32).c_str());
    push_byte(part(WQW, 31, 24).c_str());
    push_byte(part(WQW, 23, 16).c_str());
    push_byte(part(WQW, 15, 8).c_str());
    push_byte(part(WQW, 7, 0).c_str());
}

void push_quad_word(const char* val) {
    save_instruction();
    assign(part(WQW, 119, 0).c_str(), part(val, 119, 0).c_str());
    push_byte(part(val, 127, 120).c_str());
    push_byte(part(WQW, 119, 112).c_str());
    push_byte(part(WQW, 111, 104).c_str());
    push_byte(part(WQW, 103, 96).c_str());
    push_byte(part(WQW, 95, 88).c_str());
    push_byte(part(WQW, 87, 80).c_str());
    push_byte(part(WQW, 79, 72).c_str());
    push_byte(part(WQW, 71, 64).c_str());
    push_byte(part(WQW, 63, 56).c_str());
    push_byte(part(WQW, 55, 48).c_str());
    push_byte(part(WQW, 47, 40).c_str());
    push_byte(part(WQW, 39, 32).c_str());
    push_byte(part(WQW, 31, 24).c_str());
    push_byte(part(WQW, 23, 16).c_str());
    push_byte(part(WQW, 15, 8).c_str());
    push_byte(part(WQW, 7, 0).c_str());
}

std::string get_read_byte_action(const char* address, const char* dst) {
    std::string action("`READ_BYTE(");
    action += address;
    action += ",";
    action += dst;
    action += ");";
    return action;
}

void pop_byte(const char* dst) {
    save_instruction();
    std::string action = get_read_byte_action(SP, dst);
    action += " SP <= SP + 1;";
    g_mi.action = action;
    flush_cycle();
}

void pop_half_word(const char* dst) {
    save_instruction();
    pop_byte(part(RQW, 7, 0).c_str());
    assign(part(dst, 7, 0).c_str(), part(RQW, 7, 0).c_str());
    pop_byte(part(dst, 15, 8).c_str());
}

void pop_word(const char* dst) {
    save_instruction();
    pop_byte(part(RQW, 7, 0).c_str());
    pop_byte(part(RQW, 15, 8).c_str());
    pop_byte(part(RQW, 23, 16).c_str());
    assign(part(dst, 23, 0).c_str(), part(RQW, 23, 0).c_str());
    pop_byte(part(dst, 31, 24).c_str());
}

void pop_double_word(const char* dst) {
    save_instruction();
    pop_byte(part(RQW, 7, 0).c_str());
    pop_byte(part(RQW, 15, 8).c_str());
    pop_byte(part(RQW, 23, 16).c_str());
    pop_byte(part(RQW, 31, 24).c_str());
    pop_byte(part(RQW, 39, 32).c_str());
    pop_byte(part(RQW, 47, 40).c_str());
    pop_byte(part(RQW, 55, 48).c_str());
    assign(part(dst, 55, 0).c_str(), part(RQW, 55, 0).c_str());
    pop_byte(part(dst, 63, 56).c_str());
}

void pop_quad_word(const char* dst) {
    save_instruction();
    pop_byte(part(RQW, 7, 0).c_str());
    pop_byte(part(RQW, 15, 8).c_str());
    pop_byte(part(RQW, 23, 16).c_str());
    pop_byte(part(RQW, 31, 24).c_str());
    pop_byte(part(RQW, 39, 32).c_str());
    pop_byte(part(RQW, 47, 40).c_str());
    pop_byte(part(RQW, 55, 48).c_str());
    pop_byte(part(RQW, 63, 56).c_str());
    pop_byte(part(RQW, 71, 64).c_str());
    pop_byte(part(RQW, 79, 72).c_str());
    pop_byte(part(RQW, 87, 80).c_str());
    pop_byte(part(RQW, 95, 88).c_str());
    pop_byte(part(RQW, 103, 96).c_str());
    pop_byte(part(RQW, 111, 104).c_str());
    pop_byte(part(RQW, 119, 112).c_str());
    assign(part(dst, 119, 0).c_str(), part(RQW, 119, 0).c_str());
    pop_byte(part(dst, 127, 120).c_str());
}

void load_byte(const char* dst) {
    save_instruction();
    std::string action = get_read_byte_action(EPC, dst);
    action += " EPC <= EPC + 1;";
    g_mi.action = action;
    flush_cycle();
}

void load_half_word(const char* dst) {
    save_instruction();
    load_byte(part(RQW, 7, 0).c_str());
    assign(part(dst, 7, 0).c_str(), part(RQW, 7, 0).c_str());
    load_byte(part(dst, 15, 8).c_str());
}

void load_word(const char* dst) {
    save_instruction();
    load_byte(part(RQW, 7, 0).c_str());
    load_byte(part(RQW, 15, 8).c_str());
    load_byte(part(RQW, 23, 16).c_str());
    assign(part(dst, 23, 0).c_str(), part(RQW, 23, 0).c_str());
    load_byte(part(dst, 31, 24).c_str());
}

void load_double_word(const char* dst) {
    save_instruction();
    load_byte(part(RQW, 7, 0).c_str());
    load_byte(part(RQW, 15, 8).c_str());
    load_byte(part(RQW, 23, 16).c_str());
    load_byte(part(RQW, 31, 24).c_str());
    load_byte(part(RQW, 39, 32).c_str());
    load_byte(part(RQW, 47, 40).c_str());
    load_byte(part(RQW, 55, 48).c_str());
    assign(part(dst, 55, 0).c_str(), part(RQW, 55, 0).c_str());
    load_byte(part(dst, 63, 56).c_str());
}

void load_quad_word(const char* dst) {
    save_instruction();
    load_byte(part(RQW, 7, 0).c_str());
    load_byte(part(RQW, 15, 8).c_str());
    load_byte(part(RQW, 23, 16).c_str());
    load_byte(part(RQW, 31, 24).c_str());
    load_byte(part(RQW, 39, 32).c_str());
    load_byte(part(RQW, 47, 40).c_str());
    load_byte(part(RQW, 55, 48).c_str());
    load_byte(part(RQW, 63, 56).c_str());
    load_byte(part(RQW, 71, 64).c_str());
    load_byte(part(RQW, 79, 72).c_str());
    load_byte(part(RQW, 87, 80).c_str());
    load_byte(part(RQW, 95, 88).c_str());
    load_byte(part(RQW, 103, 96).c_str());
    load_byte(part(RQW, 111, 104).c_str());
    load_byte(part(RQW, 119, 112).c_str());
    assign(part(dst, 119, 0).c_str(), part(RQW, 119, 0).c_str());
    load_byte(part(dst, 127, 120).c_str());
}

void update(Register reg, const char* oper, uint32_t n) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= ";
    g_mi.action += reg;
    g_mi.action += " ";
    g_mi.action += oper;
    g_mi.action += " ";
    char nbr[11];
    sprintf(nbr, "%u", n);
    g_mi.action += nbr;
    g_mi.action += ";";
}

void update(Register reg, const char* oper, const char* val) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= ";
    g_mi.action += reg;
    g_mi.action += " ";
    g_mi.action += oper;
    g_mi.action += " ";
    g_mi.action += val;
    g_mi.action += ";";
}

void add(Register reg, uint32_t n) {
    update(reg, "+", n);
}

void inc(Register reg) {
    add(reg, 1);
}

void read_byte(Register address, const char* dst) {
    save_instruction();
    std::string action = get_read_byte_action(address, dst);
    g_mi.action = action;
    flush_cycle();
}

void read_byte_with_inc(Register address, const char* dst) {
    save_instruction();
    std::string action = get_read_byte_action(address, dst);
    inc(address);
    g_mi.action = action;
    flush_cycle();
}

void read_half_word(Register address, const char* dst) {
    save_instruction();
    read_byte_with_inc(address, part(RQW, 7, 0).c_str());
    assign(part(dst, 7, 0).c_str(), part(RQW, 7, 0).c_str());
    read_byte(address, part(dst, 15, 8).c_str());
}

void read_word(Register address, const char* dst) {
    save_instruction();
    read_byte_with_inc(address, part(RQW, 7, 0).c_str());
    read_byte_with_inc(address, part(RQW, 15, 8).c_str());
    read_byte_with_inc(address, part(RQW, 23, 16).c_str());
    assign(part(dst, 23, 0).c_str(), part(RQW, 23, 0).c_str());
    read_byte(address, part(dst, 31, 24).c_str());
}

void read_double_word(Register address, const char* dst) {
    save_instruction();
    read_byte_with_inc(address, part(RQW, 7, 0).c_str());
    read_byte_with_inc(address, part(RQW, 15, 8).c_str());
    read_byte_with_inc(address, part(RQW, 23, 16).c_str());
    read_byte_with_inc(address, part(RQW, 31, 24).c_str());
    read_byte_with_inc(address, part(RQW, 39, 32).c_str());
    read_byte_with_inc(address, part(RQW, 47, 40).c_str());
    read_byte_with_inc(address, part(RQW, 55, 48).c_str());
    assign(part(dst, 55, 0).c_str(), part(RQW, 55, 0).c_str());
    read_byte(address, part(dst, 63, 56).c_str());
}

void read_quad_word(Register address, const char* dst) {
    save_instruction();
    read_byte_with_inc(address, part(RQW, 7, 0).c_str());
    read_byte_with_inc(address, part(RQW, 15, 8).c_str());
    read_byte_with_inc(address, part(RQW, 23, 16).c_str());
    read_byte_with_inc(address, part(RQW, 31, 24).c_str());
    read_byte_with_inc(address, part(RQW, 39, 32).c_str());
    read_byte_with_inc(address, part(RQW, 47, 40).c_str());
    read_byte_with_inc(address, part(RQW, 55, 48).c_str());
    read_byte_with_inc(address, part(RQW, 63, 56).c_str());
    read_byte_with_inc(address, part(RQW, 71, 64).c_str());
    read_byte_with_inc(address, part(RQW, 79, 72).c_str());
    read_byte_with_inc(address, part(RQW, 87, 80).c_str());
    read_byte_with_inc(address, part(RQW, 95, 88).c_str());
    read_byte_with_inc(address, part(RQW, 103, 96).c_str());
    read_byte_with_inc(address, part(RQW, 111, 104).c_str());
    read_byte_with_inc(address, part(RQW, 119, 112).c_str());
    assign(part(dst, 119, 0).c_str(), part(RQW, 119, 0).c_str());
    read_byte(address, part(dst, 127, 120).c_str());
}

void write_byte(Register address, const char* src) {
    save_instruction();
    std::string action = get_write_byte_action(address, src);
    g_mi.action = action;
    flush_cycle();
}

void write_byte_with_inc(Register address, const char* src) {
    save_instruction();
    std::string action = get_write_byte_action(address, src);
    inc(address);
    g_mi.action = action;
    flush_cycle();
}

void write_half_word(Register address, const char* src) {
    save_instruction();
    assign(part(RQW, 15, 8).c_str(), part(src, 15, 8).c_str());
    write_byte_with_inc(address, part(src, 7, 0).c_str());
    write_byte(address, part(RQW, 15, 8).c_str());
}

void write_word(Register address, const char* src) {
    save_instruction();
    assign(part(RQW, 31, 8).c_str(), part(RQW, 31, 8).c_str());
    write_byte_with_inc(address, part(src, 7, 0).c_str());
    write_byte_with_inc(address, part(RQW, 15, 8).c_str());
    write_byte_with_inc(address, part(RQW, 23, 16).c_str());
    write_byte(address, part(RQW, 31, 24).c_str());
}

void write_double_word(Register address, const char* src) {
    save_instruction();
    assign(part(src, 63, 8).c_str(), part(RQW, 63, 8).c_str());
    write_byte_with_inc(address, part(src, 7, 0).c_str());
    write_byte_with_inc(address, part(RQW, 15, 8).c_str());
    write_byte_with_inc(address, part(RQW, 23, 16).c_str());
    write_byte_with_inc(address, part(RQW, 31, 24).c_str());
    write_byte_with_inc(address, part(RQW, 39, 32).c_str());
    write_byte_with_inc(address, part(RQW, 47, 40).c_str());
    write_byte_with_inc(address, part(RQW, 55, 48).c_str());
    write_byte(address, part(RQW, 63, 56).c_str());
}

void write_quad_word(Register address, const char* src) {
    save_instruction();
    assign(part(src, 127, 8).c_str(), part(RQW, 127, 8).c_str());
    write_byte_with_inc(address, part(src, 7, 0).c_str());
    write_byte_with_inc(address, part(RQW, 15, 8).c_str());
    write_byte_with_inc(address, part(RQW, 23, 16).c_str());
    write_byte_with_inc(address, part(RQW, 31, 24).c_str());
    write_byte_with_inc(address, part(RQW, 39, 32).c_str());
    write_byte_with_inc(address, part(RQW, 47, 40).c_str());
    write_byte_with_inc(address, part(RQW, 55, 48).c_str());
    write_byte_with_inc(address, part(RQW, 63, 56).c_str());
    write_byte_with_inc(address, part(RQW, 71, 64).c_str());
    write_byte_with_inc(address, part(RQW, 79, 72).c_str());
    write_byte_with_inc(address, part(RQW, 87, 80).c_str());
    write_byte_with_inc(address, part(RQW, 95, 88).c_str());
    write_byte_with_inc(address, part(RQW, 103, 96).c_str());
    write_byte_with_inc(address, part(RQW, 111, 104).c_str());
    write_byte_with_inc(address, part(RQW, 119, 112).c_str());
    write_byte(address, part(RQW, 127, 120).c_str());
}

void sub(Register reg, uint32_t n) {
    update(reg, "-", n);
}

void dec(Register reg) {
    sub(reg, 1);
}

void mul(Register reg, uint32_t n) {
    update(reg, "*", n);
}

void div(Register reg, uint32_t n) {
    update(reg, "/", n);
}

void bitwise_or(Register reg, uint32_t n) {
    update(reg, "|", n);
}

void bitwise_or(Register dst, Register src) {
    update(dst, "|", src);
}

void eor(Register reg, uint32_t n) {
    update(reg, "^", n);
}

void neg(Register reg) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= 0 - ";
    g_mi.action += reg;
    g_mi.action += ";";
}

void invert(Register reg) {
    save_instruction();
    g_mi.action = reg;
    g_mi.action += " <= ~";
    g_mi.action += reg;
    g_mi.action += ";";
}

void copy(Register src, Register dst) {
    save_instruction();
    g_mi.action = dst;
    g_mi.action += " <= ";
    g_mi.action += src;
    g_mi.action += ";";
}

void set_flag(Register reg) {
    assign(reg, 1);
}

void clear_flag(Register reg) {
    assign(reg, (uint32_t)0);
}

void increment(Register reg) {
    add(reg, 1);
}

void decrement(Register reg) {
    sub(reg, 1);
}

void lsl_byte(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 7).c_str());
    auto part_a = part(reg, 6, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsl_half_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 15).c_str());
    auto part_a = part(reg, 14, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsl_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 31).c_str());
    auto part_a = part(reg, 30, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsl_double_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 63).c_str());
    auto part_a = part(reg, 62, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsl_quad_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 127).c_str());
    auto part_a = part(reg, 126, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsr_byte(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(0);
    auto part_b = part(reg, 7, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsr_half_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(0);
    auto part_b = part(reg, 15, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsr_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(0);
    auto part_b = part(reg, 31, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsr_double_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(0);
    auto part_b = part(reg, 63, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void lsr_quad_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(0);
    auto part_b = part(reg, 127, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asl_byte(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 7).c_str());
    auto part_a = part(reg, 6, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asl_half_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 15).c_str());
    auto part_a = part(reg, 14, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asl_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 31).c_str());
    auto part_a = part(reg, 30, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asl_double_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 63).c_str());
    auto part_a = part(reg, 62, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asl_quad_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 127).c_str());
    auto part_a = part(reg, 126, 0);
    auto part_b = bit(0);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asr_byte(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(7);
    auto part_b = part(reg, 7, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asr_half_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(15);
    auto part_b = part(reg, 15, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asr_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(31);
    auto part_b = part(reg, 31, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asr_double_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(63);
    auto part_b = part(reg, 63, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void asr_quad_word(Register reg) {
    save_instruction();
    assign(C, bit_of(reg, 0).c_str());
    auto part_a = bit(127);
    auto part_b = part(reg, 127, 1);
    auto combined = combine2(part_a.c_str(), part_b.c_str());
    assign(reg, combined.c_str());
}

void gen_6502_instructions() {

    set_mode(MODE_6502);

    set_opcode(0x00);
    set_operation(OP_BRK);
    set_address_mode(STK_s);
    set_flag(I);
    assign(PC, 0xFFFE);
    push_half_word(PC);
    auto part_a = part(P, 7, 5);
    auto part_b = bit(1);
    auto part_c = part(P, 3, 0);
    auto combined = combine3(part_a.c_str(), part_b.c_str(), part_c.c_str());
    push_byte(combined.c_str());

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
    load_half_word(ADDR);
    read_byte(ADDR, RB);
    bitwise_or(A, RB);

    set_opcode(0x0E);
    set_operation(OP_ASL);
    set_address_mode(ABS_a);
    load_half_word(ADDR);
    read_byte(ADDR, RB);
    asl_byte(RB);
    write_byte(ADDR, RB);

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
    clear_flag(C);

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
    set_flag(C);

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
    clear_flag(I);

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
    set_flag(I);

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
    decrement(Y);

    set_opcode(0x89);
    set_operation(OP_BIT);
    set_address_mode(IMM_m);

    set_opcode(0x8A);
    set_operation(OP_TXA);
    set_address_mode(IMP_i);
    copy(X, A);

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
    copy(Y, A);

    set_opcode(0x99);
    set_operation(OP_STA);
    set_address_mode(AIY_a_y);

    set_opcode(0x9A);
    set_operation(OP_TXS);
    set_address_mode(IMP_i);
    copy(X, SP);

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
    copy(A, Y);


    set_opcode(0xA9);
    set_operation(OP_LDA);
    set_address_mode(IMM_m);

    set_opcode(0xAA);
    set_operation(OP_TAX);
    set_address_mode(IMP_i);
    copy(A, X);


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
    clear_flag(V);

    set_opcode(0xB9);
    set_operation(OP_LDA);
    set_address_mode(AIY_a_y);

    set_opcode(0xBA);
    set_operation(OP_TSX);
    set_address_mode(IMP_i);
    copy(SP, X);


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
    increment(Y);

    set_opcode(0xC9);
    set_operation(OP_CMP);
    set_address_mode(IMM_m);

    set_opcode(0xCA);
    set_operation(OP_DEX);
    set_address_mode(IMP_i);
    decrement(X);

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
    clear_flag(D);


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
    increment(X);

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
    set_flag(D);

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

    set_mode(MODE_65832);

    set_opcode(0x00);
    set_operation(OP_BRK);
    set_address_mode(STK_s);

    set_opcode(0x01);
    set_operation(OP_ORA);
    set_address_mode(AIIX_A_X);

    set_opcode(0x06);
    set_operation(OP_ASL);
    set_address_mode(ABS_a);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0x12);
    set_operation(OP_ORA);
    set_address_mode(AIA_A);

    set_opcode(0x16);
    set_operation(OP_ASL);
    set_address_mode(AIX_a_x);

    set_opcode(0x18);
    set_operation(OP_CLC);
    set_address_mode(IMP_i);
    clear_flag(C);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0x22);
    set_operation(OP_JSR);
    set_address_mode(AIA_A);

    set_opcode(0x26);
    set_operation(OP_ROL);
    set_address_mode(ABS_a);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0x32);
    set_operation(OP_AND);
    set_address_mode(AIA_A);

    set_opcode(0x36);
    set_operation(OP_ROL);
    set_address_mode(AIX_a_x);

    set_opcode(0x38);
    set_operation(OP_SEC);
    set_address_mode(IMP_i);
    set_flag(C);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0x46);
    set_operation(OP_LSR);
    set_address_mode(ABS_a);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0x52);
    set_operation(OP_EOR);
    set_address_mode(AIA_A);

    set_opcode(0x56);
    set_operation(OP_LSR);
    set_address_mode(AIX_a_x);

    set_opcode(0x58);
    set_operation(OP_CLI);
    set_address_mode(IMP_i);
    clear_flag(I);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0x66);
    set_operation(OP_ROR);
    set_address_mode(ABS_a);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0x72);
    set_operation(OP_ADC);
    set_address_mode(AIA_A);

    set_opcode(0x76);
    set_operation(OP_ROR);
    set_address_mode(AIX_a_x);

    set_opcode(0x78);
    set_operation(OP_SEI);
    set_address_mode(IMP_i);
    set_flag(I);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0x86);
    set_operation(OP_STX);
    set_address_mode(ABS_a);

    set_opcode(0x88);
    set_operation(OP_DEY);
    set_address_mode(IMP_i);
    decrement(Y);

    set_opcode(0x89);
    set_operation(OP_BIT);
    set_address_mode(IMM_m);

    set_opcode(0x8A);
    set_operation(OP_TXA);
    set_address_mode(IMP_i);
    copy(X, A);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0x92);
    set_operation(OP_STA);
    set_address_mode(AIA_A);

    set_opcode(0x96);
    set_operation(OP_STZ);
    set_address_mode(AIX_a_x);

    set_opcode(0x98);
    set_operation(OP_TYA);
    set_address_mode(IMP_i);
    copy(Y, A);

    set_opcode(0x99);
    set_operation(OP_STA);
    set_address_mode(AIY_a_y);

    set_opcode(0x9A);
    set_operation(OP_TXS);
    set_address_mode(IMP_i);
    copy(X, SP);

    set_opcode(0x9C);
    set_operation(OP_STY);
    set_address_mode(AIX_a_x);

    set_opcode(0x9D);
    set_operation(OP_STA);
    set_address_mode(AIX_a_x);

    set_opcode(0x9E);
    set_operation(OP_STX);
    set_address_mode(AIY_a_y);

    set_opcode(0xA0);
    set_operation(OP_LDY);
    set_address_mode(IMM_m);

    set_opcode(0xA1);
    set_operation(OP_LDA);
    set_address_mode(AIIX_A_X);

    set_opcode(0xA2);
    set_operation(OP_LDX);
    set_address_mode(IMM_m);

    set_opcode(0xA8);
    set_operation(OP_TAY);
    set_address_mode(IMP_i);
    copy(A, Y);

    set_opcode(0xA9);
    set_operation(OP_LDA);
    set_address_mode(IMM_m);

    set_opcode(0xAA);
    set_operation(OP_TAX);
    set_address_mode(IMP_i);
    copy(A, X);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0xB2);
    set_operation(OP_LDA);
    set_address_mode(AIA_A);

    set_opcode(0xB8);
    set_operation(OP_CLV);
    set_address_mode(IMP_i);
    clear_flag(V);

    set_opcode(0xB9);
    set_operation(OP_LDA);
    set_address_mode(AIY_a_y);

    set_opcode(0xBA);
    set_operation(OP_TSX);
    set_address_mode(IMP_i);
    copy(SP, X);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0xC6);
    set_operation(OP_DEC);
    set_address_mode(ABS_a);

    set_opcode(0xC8);
    set_operation(OP_INY);
    set_address_mode(IMP_i);
    increment(Y);

    set_opcode(0xC9);
    set_operation(OP_CMP);
    set_address_mode(IMM_m);

    set_opcode(0xCA);
    set_operation(OP_DEX);
    set_address_mode(IMP_i);
    decrement(X);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0xD2);
    set_operation(OP_CMP);
    set_address_mode(AIA_A);

    set_opcode(0xD6);
    set_operation(OP_DEC);
    set_address_mode(AIX_a_x);

    set_opcode(0xD8);
    set_operation(OP_CLD);
    set_address_mode(IMP_i);
    clear_flag(D);

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
    set_address_mode(AIIX_A_X);

    set_opcode(0xE6);
    set_operation(OP_INC);
    set_address_mode(ABS_a);

    set_opcode(0xE8);
    set_operation(OP_INX);
    set_address_mode(IMP_i);
    increment(X);

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
    set_address_mode(AIIY_A_y);

    set_opcode(0xF2);
    set_operation(OP_SBC);
    set_address_mode(AIA_A);

    set_opcode(0xF6);
    set_operation(OP_INC);
    set_address_mode(AIX_a_x);

    set_opcode(0xF8);
    set_operation(OP_SED);
    set_address_mode(IMP_i);
    set_flag(D);

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
/*
void gen_overlay_instructions() {

    set_mode(MODE_OVERLAY);

    set_opcode(0x00);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x01);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x12);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x14);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x15);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x16);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x22);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x23);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x24);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x25);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x26);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x32);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x34);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x35);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x36);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x45);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x46);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x52);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x55);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x56);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x64);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x65);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x66);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x72);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x74);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x75);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x76);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x84);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x85);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x86);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x92);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x94);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x95);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x96);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0x9D);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0x9E);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA0);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xA1);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0xB2);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0xC4);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xC6);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0xD2);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xD6);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0xE4);
    set_operation(OP_);

    set_opcode(0xE5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xE6);
    set_operation(OP_);
    set_address_mode();

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

    set_opcode(0xF2);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF5);
    set_operation(OP_);
    set_address_mode();

    set_opcode(0xF6);
    set_operation(OP_);
    set_address_mode();

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
*/

int gen_code_for_action(int index) {
    auto first_mi = &g_actions[index];
    MicroInstruction* last_mi = NULL;
    printf("        if (\n");
    while (index < g_actions.size()) {
        auto mi = &g_actions[index];
        if (mi->cycle != first_mi->cycle) {
            break;
        }
        if (strcmp(mi->address_mode, first_mi->address_mode)) {
            break;
        }
        if (mi->action != first_mi->action) {
            break;
        }

        if (last_mi && !strcmp(last_mi->operation, mi->operation)) {
            printf("                                // also: %s %s [%02hX]\n",
                mi->operation, mi->cpu_mode, mi->opcode);
        } else {
            if (mi != first_mi) {
                printf("            || ");
            } else {
                printf("            ");
            }
            printf("reg_operation_%s // %s [%02hX]\n",
                mi->operation, mi->cpu_mode, mi->opcode);
            last_mi = mi;
        }
        index++;
    }
    printf("        ) begin\n");
    printf("            %s\n", first_mi->action.c_str());
    printf("        end\n");
    return index;
}

int gen_code_for_address_mode(int index) {
    auto first_mi = &g_actions[index];
    printf("    if (reg_address_mode_%s) begin\n", first_mi->address_mode);
    while (index < g_actions.size()) {
        auto mi = &g_actions[index];
        if (mi->cycle != first_mi->cycle) {
            break;
        }
        if (strcmp(mi->address_mode, first_mi->address_mode)) {
            break;
        }

        index = gen_code_for_action(index);
    }
    printf("    end // %s\n", first_mi->address_mode);
    return index;
}

int gen_code_for_cycle(int index) {
    auto first_mi = &g_actions[index];
    printf("if (reg_cyle == %hu) begin\n", first_mi->cycle);
    while (index < g_actions.size()) {
        auto mi = &g_actions[index];
        if (mi->cycle != first_mi->cycle) {
            break;
        }

        index = gen_code_for_address_mode(index);
    }
    printf("end // cycle %hu\n", first_mi->cycle);
    return index;
}

int main() {
    gen_6502_instructions();
    gen_65832_instructions();
    //gen_overlay_instructions();
    flush_mode();

    std::sort(g_actions.begin(), g_actions.end(), compare_mi);
    int index = 0;
    while (index < g_actions.size()) {
        index = gen_code_for_cycle(index);
    }
    return 0;
}
