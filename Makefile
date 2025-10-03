RM    = rm -rf

CC_TOOL=/home/curtis/gatemate/oss-cad-suite-linux-x64-20250929/oss-cad-suite
CC_TOOL_DIR=$(CC_TOOL)
YOSYS = $(CC_TOOL)/bin/yosys
P_R   = $(CC_TOOL)/bin/nextpnr-himbaechel
OFL   = $(CC_TOOL)/bin/openFPGALoader
GMPACK = $(CC_TOOL)/bin/gmpack

YS_OPTS = --verbose 3 -D DISP_640x480_60Hz=1
BOARD = olimex_gatemateevb --cable dirtyJtag
OFLFLAGS = --verbose

SOURCEDIR = src
TOP    = ogege
CONSTR = src/gatemate1a_evb.ccf

OBJS += $(SOURCEDIR)/ogege.v
OBJS += $(SOURCEDIR)/vga_core.v
OBJS += $(SOURCEDIR)/component_blender.v
OBJS += $(SOURCEDIR)/color_blender.v
OBJS += $(SOURCEDIR)/char_gen8x8.v
OBJS += $(SOURCEDIR)/char_blender8x8.v
OBJS += $(SOURCEDIR)/text_area8x8.v
OBJS += $(SOURCEDIR)/text_array8x8.v
#OBJS += $(SOURCEDIR)/canvas.v
#OBJS += $(SOURCEDIR)/frame_buffer.v
OBJS += $(SOURCEDIR)/gatemate_50MHz_pll.v
OBJS += $(SOURCEDIR)/psram.v
#OBJS += $(SOURCEDIR)/cpu.v

info:
	@echo "       To build: make all"
	@echo "    To clean up: make clean"

all:$(TOP).bit

synth: $(TOP)_synth.v

gm_netlist.json: $(OBJS) ./font/sample_text8x8.bits ./font/font8x8.bits
	$(YOSYS) -ql synth.log -p 'read_verilog -sv $(OBJS); synth_gatemate -nomx8 -nomult -luttree -top $(TOP) -json gm_netlist.json -vlog gm_netlist.v;'
	echo '** SYNTH ENDED **'
  
$(TOP).asc: gm_netlist.json $(CONSTR)
	$(P_R) -o ccf=$(CONSTR) -o out=$(TOP).asc --device=CCGM1A1 --json gm_netlist.json --router router2 --log nextpnr.log
	echo '** P-R ENDED **'

$(TOP).bit:	$(TOP).asc
	$(GMPACK) $(TOP).asc $(TOP).bit
	echo '** BITS PACKED **'

./font/sample_text: ./font/sample_text.c
	gcc -o ./font/sample_text ./font/sample_text.c
	echo '** TEXT COMPILED **'

./font/sample_text8x8.bits: ./font/sample_text
	./font/sample_text >./font/sample_text8x8.bits
	echo '** TEXT CONVERTED **'

jtag: $(TOP).bit
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) --bitstream $^

jtag-flash: $(TOP).bit
	sudo $(OFL) $(OFLFLAGS) -b $(BOARD) -f --verify $^

# ------ HELPERS ------
clean:
	$(RM) *.log *_synth.v *.history *.txt *.refwire *.refparam *.asc
	$(RM) *.refcomp *.pos *.pathes *.path_struc *.net *.id *.prn *.bit
	$(RM) *_00.v *_00pre* *.used *.sdf *.place *.pin *.cfg* *.cdf *.idh

.SECONDARY:
.PHONY: all jtag jtag-flash clean