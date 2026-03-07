#!/usr/bin/env bash
set -euo pipefail
echo "=== RUN ALL TESTS ==="
scripts/run_test.sh tb/programs/test_lw_sw.hex
scripts/run_test.sh tb/programs/test_branch.hex
scripts/run_test.sh tb/programs/test_jal.hex
echo "=== ALL DONE ==="
