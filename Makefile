TEST ?= test_pipe_alu.hex
EXPECT_X10 ?= 12

run:
	rm -rf build/*
	mkdir -p build
	scripts/pad_hex.sh tb/programs/$(TEST) build/padded.hex 64
	iverilog -g2012 -Wall -Wimplicit -Wportbind -Wselect-range \
	  -DEXPECT_X10=$(EXPECT_X10) \
	  -s tb_core_pipe5 \
	  rtl/regfile.sv rtl/alu.sv rtl/hazard_detection_unit.sv rtl/forwarding_unit.sv rtl/core_pipe5.sv tb/tb_core_pipe5.sv \
	  -o build/core_pipe5.out
	vvp build/core_pipe5.out

alu:
	$(MAKE) run TEST=test_pipe_alu.hex EXPECT_X10=12

forward:
	$(MAKE) run TEST=test_pipe_forward.hex EXPECT_X10=6

load_use:
	$(MAKE) run TEST=test_pipe_load_use.hex EXPECT_X10=6

branch_taken:
	$(MAKE) run TEST=test_pipe_branch.hex EXPECT_X10=12

branch_not_taken:
	$(MAKE) run TEST=test_pipe_branch_not_taken.hex EXPECT_X10=12

store_forward:
	$(MAKE) run TEST=test_pipe_store_forward.hex EXPECT_X10=7
