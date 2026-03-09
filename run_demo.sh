#!/bin/bash
set -e

echo "===== RV32I 5-Stage Pipeline Demo ====="

echo
echo "[1/3] ALU test"
make alu

echo
echo "[2/3] Load-use hazard test"
make load_use

echo
echo "[3/3] Branch flush test"
make branch

echo
echo "===== Demo complete ====="
