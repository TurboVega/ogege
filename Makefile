OFL   = openFPGALoader
RM    = rm -rf

CC_TOOL_DIR=$(CC_TOOL)
YOSYS = $(CC_TOOL)/bin/yosys/yosys
P_R   = $(CC_TOOL)/bin/p_r/p_r

PRFLAGS = --verbose -cCP
YS_OPTS = -D DISP_640x480_60Hz=1
BOARD = gatemate_evb_jtag
OFLFLAGS = --cable dirtyJtag --verbose

SOURCEDIR = src
TOP    = ogege
CONSTR = src/gatemate1a_evb.ccf

#all: ogege prog

ogege.bin: ogege.asc
ogege.asc: ogege.blif
ogege.blif: ogege.v
OBJS += $(SOURCEDIR)/ogege.v
OBJS += $(SOURCEDIR)/vga_core.v
OBJS += $(SOURCEDIR)/color_bar.v
OBJS += ../fpgalibs/clocks/gatemate_25MHz_pll.v

info:
	@echo "       To build: make all"
	@echo "    To clean up: make clean"

all:impl
synth: $(TOP)_synth.v
$(TOP)_synth.v: $(OBJS)
	$(YOSYS) -ql synth.log -p 'read -sv $^; synth_gatemate -top $(TOP) -nomx8 -vlog $(TOP)_synth.v'

$(TOP)_00.cfg: $(TOP)_synth.v $(CONSTR)
	$(P_R) -v -i $(TOP)_synth.v -ccf $(CONSTR) -o $(TOP) $(PRFLAGS)
impl:$(TOP)_00.cfg

# ------ APPLE 1 ------
ogege: dir ogege.bit

ogege.bin: ogege.asc
ogege.asc: ogege.json
ogege.json: $(SOURCEDIR)/ogege.v \

jtag: $(TOP)_00.cfg.bit
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) --bitstream $^

jtag-flash: $(TOP)_00.cfg
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) -f --verify $^

# ------ HELPERS ------
clean:
	$(RM) *.log *_synth.v *.history *.txt *.refwire *.refparam
	$(RM) *.refcomp *.pos *.pathes *.path_struc *.net *.id *.prn
	$(RM) *_00.v *_00pre* *.used *.sdf *.place *.pin *.cfg* *.cdf

.SECONDARY:
.PHONY: all jtag jtag-flash clean