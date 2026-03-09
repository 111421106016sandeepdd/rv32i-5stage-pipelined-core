# RV32I 5-Stage Pipelined Processor (SystemVerilog)

This project implements a simple RV32I processor using a classic **5-stage pipeline**.  
The design was written in SystemVerilog and verified using simulation with Icarus Verilog.

The goal of the project was to understand how pipelined CPUs work in practice, including
datapath design, hazard handling, and basic verification using directed tests.

---

## Pipeline Stages

The processor uses the standard five pipeline stages:

| Stage | Description |
|------|-------------|
| IF   | Instruction Fetch |
| ID   | Instruction Decode and Register Read |
| EX   | Execute (ALU operations) |
| MEM  | Data Memory Access |
| WB   | Write Back to Register File |

The PC increments by 4 bytes for sequential instruction fetch.

---

## Implemented Features

The core supports a subset of the **RV32I instruction set** and includes:

- 5-stage pipelined datapath
- Register file (x0 hardwired to zero)
- Arithmetic and logical ALU operations
- Load and store instructions
- JAL (jump and link)
- Hazard handling logic
- Illegal instruction detection

---

## Hazard Handling

### Data Hazards (Forwarding)

Forwarding paths are used so that dependent instructions do not need to wait
for the writeback stage.

Example:
add x1, x2, x3
add x4, x1, x5

The result of the first instruction is forwarded directly to the second instruction.

---

### Load-Use Hazard

If an instruction depends on a value loaded from memory, the pipeline inserts
a **single stall cycle**.

Example:
lw x5, 0(x1)
add x6, x5, x2

The dependent instruction waits one cycle until the load result becomes available.

---

### Control Hazards

When a branch is taken, incorrect instructions already in the pipeline are flushed.

---

## Verification

The design was verified using directed simulation tests.

Each test loads a small RISC-V program into instruction memory and checks
the resulting register or memory state.

Tests include:

- ALU operations
- Branch taken
- Branch not taken
- Data forwarding
- Load-use hazard
- Store forwarding
- Memory operations (LW/SW)
- JAL instruction
- Illegal instruction detection

All tests pass in the regression flow.

---

## Project Structure
proj1_rv32i/

rtl/
core_pipe5.sv
regfile.sv

tb/
pipeline testbenches

scripts/
pad_hex.sh
run_all_pipe5.sh

build/
simulation outputs

Makefile
run_demo.sh
README.md
---

## Running the Project

Run the full regression test suite:

This executes all pipeline verification tests including:

- ALU operations  
- branch taken  
- branch not taken  
- forwarding hazards  
- load-use hazards  
- store forwarding  
- memory operations (LW/SW)  
- JAL instruction  
- illegal instruction detection  

---

### Demo Run

A short demo script is included for quickly showing the processor during interviews.

Run:
./run_demo.sh

Example output:


===== RV32I 5-Stage Pipeline Demo =====

[1/3] ALU test
PASS: x10=12

[2/3] Load-use hazard test
PASS

[3/3] Branch flush test
PASS

===== Demo complete =====


---

## Tools Used

- SystemVerilog
- Icarus Verilog
- GTKWave
- Ubuntu (WSL)

---

## Author

Sandeep Gorrepati  
ECE Graduate Digital Design / VLSI
