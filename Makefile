TOP=tb_core_single
IMEM_WORDS?=64

RTL=rtl/alu.sv rtl/regfile.sv rtl/core_single.sv
TB=tb/tb_core_single.sv
OUT=build/core_single.out

.PHONY: all clean test lw_sw branch jal

all: test

clean:
	rm -rf build
	mkdir -p build

build: clean
	iverilog -g2012 -s $(TOP) $(RTL) $(TB) -o $(OUT)

run: build
	vvp $(OUT)

test:
	scripts/run_all.sh

lw_sw:
	scripts/run_test.sh tb/programs/test_lw_sw.hex $(IMEM_WORDS)

branch:
	scripts/run_test.sh tb/programs/test_branch.hex $(IMEM_WORDS)

jal:
	scripts/run_test.sh tb/programs/test_jal.hex $(IMEM_WORDS)
