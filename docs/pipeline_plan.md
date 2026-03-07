# 5-Stage Pipeline Plan (RV32I subset)

Stages:
1) IF:  PC -> IMEM fetch, compute PC+4
2) ID:  decode, regfile read, imm gen
3) EX:  ALU ops, branch compare/target, effective addr calc
4) MEM: data memory access for LW/SW
5) WB:  write result back to regfile

Pipeline registers:
- IF/ID: pc_if, instr_if
- ID/EX: pc_id, rs1_val, rs2_val, rd, imm, control signals
- EX/MEM: alu_res, rs2_val_fwd(for store), rd, control
- MEM/WB: wb_data, rd, control

Initial hazard policy (v0):
- Stall on load-use hazard (LW followed by dependent op)
- Forwarding for ALU results:
  - EX/MEM -> EX
  - MEM/WB -> EX
- Branch resolved in EX:
  - If taken: flush IF/ID and ID/EX, set PC to target
