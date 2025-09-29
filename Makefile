RM    = rm -rf

CC_TOOL=/home/curtis/gatemate/oss-cad-suite-linux-x64-20250929/oss-cad-suite
CC_TOOL_DIR=$(CC_TOOL)
YOSYS = $(CC_TOOL)/bin/yosys
P_R   = $(CC_TOOL)/bin/nextpnr-himbaechel
OFL   = $(CC_TOOL)/bin/openFPGALoader

YS_OPTS = --verbose 3 -D DISP_640x480_60Hz=1
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
#OBJS += $(SOURCEDIR)/char_gen8x8.v
#OBJS += $(SOURCEDIR)/component_blender.v
#OBJS += $(SOURCEDIR)/color_blender.v
#OBJS += $(SOURCEDIR)/char_gen8x8.v
#OBJS += $(SOURCEDIR)/char_blender8x8.v
#OBJS += $(SOURCEDIR)/text_area8x8.v
#OBJS += $(SOURCEDIR)/text_array8x8.v
#OBJS += $(SOURCEDIR)/canvas.v
#OBJS += $(SOURCEDIR)/frame_buffer.v
OBJS += $(SOURCEDIR)/gatemate_100MHz_pll.v
OBJS += $(SOURCEDIR)/psram.v

info:
	@echo "       To build: make all"
	@echo "    To clean up: make clean"

all:impl

synth: $(TOP)_synth.v
       
$(TOP)_synth.v: $(OBJS)
	$(YOSYS) -ql synth.log -p 'read_verilog -sv $^; synth_gatemate -top $(TOP) -nomx8 -vlog -luttree -nomx8 -nomult; write_json gm_netlist.json; write_verilog gm_netlist.v;'
	echo '** SYNTH ENDED **'
  
$(TOP)_00.cfg: gm_netlist.json $(CONSTR)
	$(P_R) -o ccf=$(CONSTR) -o out=$(TOP).bit --device=CCGM1A1 --json gm_netlist.json --router router2
	echo '** P-R ENDED **'

impl:$(TOP)_00.cfg

# ------ APPLE 1 ------
ogege: dir ogege.bit

ogege.bin: ogege.asc
ogege.asc: ogege.json
ogege.json: $(SOURCEDIR)/ogege.v \

jtag: $(TOP).bit
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) --bitstream $^

jtag-flash: $(TOP).bit
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) -f --verify $^

# ------ HELPERS ------
clean:
	$(RM) *.log *_synth.v *.history *.txt *.refwire *.refparam
	$(RM) *.refcomp *.pos *.pathes *.path_struc *.net *.id *.prn
	$(RM) *_00.v *_00pre* *.used *.sdf *.place *.pin *.cfg* *.cdf *.idh

.SECONDARY:
.PHONY: all jtag jtag-flash clean
