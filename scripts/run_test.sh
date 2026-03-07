#!/usr/bin/env bash
set -euo pipefail

TEST_HEX="${1:?Usage: scripts/run_test.sh tb/programs/test_x.hex}"
IMEM_WORDS="${2:-64}"

mkdir -p build

# Pad to avoid Icarus warnings
PADDED="build/padded.hex"
scripts/pad_hex.sh "$TEST_HEX" "$PADDED" "$IMEM_WORDS"

# Generate TB that points to padded.hex and expects x10=12 (for our current tests)
cat > tb/tb_core_single.sv <<TB
\`timescale 1ns/1ps
module tb_core_single;
  reg clk; reg rst;
  wire [31:0] pc; wire illegal; wire [31:0] x10;

  core_single #(
    .IMEM_WORDS($IMEM_WORDS),
    .IMEM_HEX("$PADDED")
  ) dut (
    .clk(clk), .rst(rst), .pc(pc), .illegal_insn(illegal), .dbg_x10(x10)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    \$display("SIM START (%s)", "$TEST_HEX");
    rst = 1; #20 rst = 0;
    #300;
    if (illegal) \$display("FAIL: illegal_insn=1");
    else if (x10 == 32'd12) \$display("PASS: x10=%0d", x10);
    else \$display("FAIL: x10=%0d expected 12", x10);
    \$finish;
  end
endmodule
TB

rm -f build/core_single.out
iverilog -g2012 -s tb_core_single rtl/alu.sv rtl/regfile.sv rtl/core_single.sv tb/tb_core_single.sv -o build/core_single.out
vvp build/core_single.out
