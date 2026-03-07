# RV32I Subset Core (RTL + Self-Checking Regression)

A small, **deterministic** RV32I subset CPU core written in SystemVerilog with an automated regression harness (Icarus Verilog friendly).
Designed to be clean, explainable, and extensible.

## Features
### Implemented ISA subset
| Category | Instructions |
|---|---|
| OP (R-type) | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| OP-IMM (I-type) | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| Loads/Stores | LW, SW (word-aligned) |
| Branch | BEQ, BNE |
| Jump | JAL |
| Other | illegal instruction flagging |

### Verification
- Self-checking tests (PASS/FAIL)
- Regression runner that executes all tests in one command
- Hex padding to avoid partial-memory warnings and ensure deterministic fetch

## Repo Layout
- `rtl/` — core RTL
- `tb/` — testbench + programs
- `scripts/` — pad/run/regression scripts
- `docs/` — architecture + verification notes

## How to Run
### Run all tests
```bash
make test


ADD
SUB
