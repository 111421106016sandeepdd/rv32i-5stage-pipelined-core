#!/bin/bash
set -e

echo "===== Running all PIPE5 tests ====="

echo
echo "=== ALU ==="
make alu

echo
echo "=== BRANCH TAKEN ==="
make branch

echo
echo "=== BRANCH NOT TAKEN ==="
make branch_nt

echo
echo "=== FORWARD ==="
make forward

echo
echo "=== LOAD USE ==="
make load_use

echo
echo "=== STORE FORWARD ==="
make store_forward

echo
echo "=== LW/SW ==="
make lw_sw

echo
echo "=== JAL ==="
make jal

echo
echo "=== ILLEGAL ==="
make illegal

echo
echo "===== All PIPE5 tests completed ====="
