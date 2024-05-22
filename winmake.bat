echo -- winmake %1%

:: toolchain
set CC_TOOL=D:\cc-toolchain-win\bin
set YOSYS=%CC_TOOL%/yosys/yosys.exe
set PR=%CC_TOOL%/p_r/p_r.exe
set OFL=%CC_TOOL%/openFPGALoader/openFPGALoader.exe
set DISP_640x480_60Hz=1

:: project name and sources
set TOP=ogege
set VLOG_SRC=src/ogege.v src/char_gen8x8.v src/vga_core.v src/component_blender.v src/color_blender.v
set VLOG_SRC=%VLOG_SRC% src/char_gen8x8.v src/text_area8x8.v src/text_array8x8.v src/canvas.v
set VLOG_SRC=%VLOG_SRC% src/frame_buffer.v src/psram.v src/cpu.v
set VLOG_SRC=%VLOG_SRC% src/char_blender8x8.v src/gatemate_100MHz_pll.v
set VHDL_SRC=src/ogege.vhd
set LOG=0

if not exist log (
  md log
)

if not exist net (
  md net
)

:: Place&Route arguments
set PRFLAGS=--verbose -ccf src/gatemate1a_evb.ccf -cCP

:: do not change
if "%1"=="synth_vlog" (
  if %LOG%==1 (
    start /WAIT /B %YOSYS% -l log/synth.log -p "read -sv %VLOG_SRC%; synth_gatemate -top %TOP% -nomx8 -vlog net/%TOP%_synth.v"
  ) else (
    start /WAIT /B %YOSYS% -ql log/synth.log -p "read -sv %VLOG_SRC%; synth_gatemate -top %TOP% -nomx8 -vlog net/%TOP%_synth.v"
  )
)

if ERRORLEVEL 1 EXIT /b 1

if "%1"=="synth_vhdl" (
  if %LOG%==1 (
    start /WAIT /B %YOSYS% -l log/synth.log -p "ghdl --warn-no-binding -C --ieee=synopsys %VHDL_SRC% -e %TOP%; synth_gatemate -top %TOP% -nomx8 -vlog net/%TOP%_synth.v"
  ) else (
    start /WAIT /B %YOSYS% -ql log/synth.log -p "ghdl --warn-no-binding -C --ieee=synopsys %VHDL_SRC% -e %TOP%; synth_gatemate -top %TOP% -nomx8 -vlog net/%TOP%_synth.v"
  )
)

if ERRORLEVEL 1 EXIT /b 2

if "%1"=="impl" (
  if %LOG%==1 (
    start /WAIT /B %PR% -i net/%TOP%_synth.v -o %TOP% %PRFLAGS% >&1 | tee log/impl.log
  ) else (
    start /WAIT /B %PR% -i net/%TOP%_synth.v -o %TOP% %PRFLAGS% > log/impl.log
  )
)

if ERRORLEVEL 1 EXIT /b 3

if "%1"=="jtag" (
  start /WAIT /B %OFL% -b gatemate_evb_jtag --cable dirtyJtag --verbose --bitstream %TOP%_00.cfg.bit
)

if ERRORLEVEL 1 EXIT /b 4

if "%1"=="jtag-flash" (
  start /WAIT /B %OFL% -b gatemate_evb_jtag -f --verify %TOP%_00.cfg
)

if ERRORLEVEL 1 EXIT /b 5

if "%1"=="spi" (
  start /WAIT /B %OFL% -b gatemate_evb_spi -m %TOP%_00.cfg
)

if ERRORLEVEL 1 EXIT /b 6

if "%1"=="spi-flash" (
  start /WAIT /B %OFL% -b gatemate_evb_spi -f --verify %TOP%_00.cfg
)

if ERRORLEVEL 1 EXIT /b 7

if "%1"=="clean" (
  del log\*.log 2>NUL
  del net\*_synth.v 2>NUL
  del *.history 2>NUL
  del *.txt 2>NUL
  del *.refwire 2>NUL
  del *.refparam 2>NUL
  del *.refcomp 2>NUL
  del *.pos 2>NUL
  del *.pathes 2>NUL
  del *.path_struc 2>NUL
  del *.net 2>NUL
  del *.id 2>NUL
  del *.prn 2>NUL
  del *_00.V 2>NUL
  del *.used 2>NUL
  del *.sdf 2>NUL
  del *.place 2>NUL
  del *.pin 2>NUL
  del *.cfg* 2>NUL
  del *.cdf 2>NUL
  del opcodes/opcodes 2>NUL
  exit /b 0
)
