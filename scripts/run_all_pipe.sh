#!/usr/bin/env bash
set -euo pipefail

echo "=== RUN ALL PIPELINE TESTS ==="

run_one () {
  local hex="$1"
  local tb="$2"
  local top="$3"
  local out="$4"

  echo
  echo "SIM START ($hex)"

  scripts/pad_hex.sh "$hex" build/padded.hex 64

  rm -f "$out"
  iverilog -g2012 -Wall -s "$top" \
    rtl/regfile.sv rtl/core_pipe5.sv \
    "$tb" \
    -o "$out"

  vvp "$out"
}

mkdir -p build

run_one tb/programs/test_pipe_alu.hex               tb/tb_core_pipe5.sv                    tb_core_pipe5                  build/core_pipe5_alu.out
run_one tb/programs/test_pipe_lw_sw.hex             tb/tb_core_pipe5_lw_sw.sv              tb_core_pipe5_lw_sw            build/core_pipe5_lw_sw.out
run_one tb/programs/test_pipe_branch.hex            tb/tb_core_pipe5_branch.sv             tb_core_pipe5_branch           build/core_pipe5_branch.out
run_one tb/programs/test_pipe_jal.hex               tb/tb_core_pipe5_jal.sv                tb_core_pipe5_jal              build/core_pipe5_jal.out
run_one tb/programs/test_pipe_forward.hex           tb/tb_core_pipe5_forward.sv            tb_core_pipe5_forward          build/core_pipe5_forward.out
run_one tb/programs/test_pipe_branch_not_taken.hex  tb/tb_core_pipe5_branch_not_taken.sv   tb_core_pipe5_branch_not_taken build/core_pipe5_branch_not_taken.out
run_one tb/programs/test_pipe_load_use.hex          tb/tb_core_pipe5_load_use.sv           tb_core_pipe5_load_use         build/core_pipe5_load_use.out
run_one tb/programs/test_pipe_store_forward.hex     tb/tb_core_pipe5_store_forward.sv      tb_core_pipe5_store_forward    build/core_pipe5_store_forward.out
run_one tb/programs/test_pipe_illegal.hex           tb/tb_core_pipe5_illegal.sv            tb_core_pipe5_illegal          build/core_pipe5_illegal.out

echo
echo "=== ALL PIPELINE TESTS PASSED ==="