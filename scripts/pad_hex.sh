#!/usr/bin/env bash
set -euo pipefail

IN="$1"
OUT="$2"
WORDS="${3:-64}"

# Remove blank lines/comments, keep pure hex lines
grep -E '^[0-9a-fA-F]{8}$' "$IN" > "$OUT" || true

count=$(wc -l < "$OUT" | tr -d ' ')
if [ "$count" -gt "$WORDS" ]; then
  echo "ERROR: $IN has $count lines > $WORDS words"
  exit 1
fi

# Pad with NOP (ADDI x0,x0,0 = 00000013)
pad=$((WORDS - count))
for ((i=0; i<pad; i++)); do
  echo "00000013" >> "$OUT"
done
