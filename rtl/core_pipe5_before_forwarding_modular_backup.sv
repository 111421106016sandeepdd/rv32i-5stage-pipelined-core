`timescale 1ns/1ps
// RV32I 5-stage pipeline
// IF -> ID -> EX -> MEM -> WB
// Includes forwarding + load-use hazard stall
// Control hazard fix: flushes both IF/ID and ID/EX on taken branch / JAL

module core_pipe5 #(
  parameter XLEN = 32,
  parameter IMEM_WORDS = 64,
  parameter IMEM_HEX = "build/padded.hex",
  parameter DMEM_WORDS = 64
)(
  input  wire             clk,
  input  wire             rst,
  output reg  [XLEN-1:0]  pc,
  output reg              illegal_insn,
  output wire [XLEN-1:0]  dbg_x10
);

  reg [31:0] imem [0:IMEM_WORDS-1];
  reg [31:0] dmem [0:DMEM_WORDS-1];
  integer i;

  localparam NOP = 32'h00000013;

  initial begin
    for (i = 0; i < IMEM_WORDS; i = i + 1)
      imem[i] = NOP;
    for (i = 0; i < DMEM_WORDS; i = i + 1)
      dmem[i] = 0;
    $readmemh(IMEM_HEX, imem);
  end

  wire [31:0] instr_f = imem[pc[($clog2(IMEM_WORDS)+1):2]];

  // ---------------- IF/ID ----------------
  reg [31:0] ifid_pc;
  reg [31:0] ifid_instr;

  // ---------------- Decode ----------------
  wire [6:0] op_d  = ifid_instr[6:0];
  wire [4:0] rd_d  = ifid_instr[11:7];
  wire [2:0] f3_d  = ifid_instr[14:12];
  wire [4:0] rs1_d = ifid_instr[19:15];
  wire [4:0] rs2_d = ifid_instr[24:20];
  wire [6:0] f7_d  = ifid_instr[31:25];

  wire [31:0] imm_i_d = {{20{ifid_instr[31]}}, ifid_instr[31:20]};
  wire [31:0] imm_s_d = {{20{ifid_instr[31]}}, ifid_instr[31:25], ifid_instr[11:7]};
  wire [31:0] imm_b_d = {{19{ifid_instr[31]}}, ifid_instr[31], ifid_instr[7],
                         ifid_instr[30:25], ifid_instr[11:8], 1'b0};
  wire [31:0] imm_j_d = {{11{ifid_instr[31]}}, ifid_instr[31], ifid_instr[19:12],
                         ifid_instr[20], ifid_instr[30:21], 1'b0};

  wire [31:0] rf_rd1, rf_rd2;

  // ---------------- WB -> regfile ----------------
  reg        wb_we;
  reg [4:0]  wb_rd;
  reg [31:0] wb_wd;

  regfile u_rf(
    .clk(clk),
    .rst(rst),
    .we(wb_we),
    .rs1(rs1_d),
    .rs2(rs2_d),
    .rd(wb_rd),
    .wd(wb_wd),
    .rd1(rf_rd1),
    .rd2(rf_rd2),
    .dbg_addr(5'd10),
    .dbg_data(dbg_x10)
  );

  // ---------------- ID/EX ----------------
  reg [31:0] idex_pc;
  reg [31:0] idex_rs1_val;
  reg [31:0] idex_rs2_val;
  reg [31:0] idex_imm;
  reg [4:0]  idex_rd;
  reg [4:0]  idex_rs1;
  reg [4:0]  idex_rs2;
  reg [2:0]  idex_f3;
  reg        idex_regwrite;
  reg        idex_is_load;
  reg        idex_is_store;
  reg        idex_is_branch;
  reg        idex_is_jal;
  reg        idex_alu_imm;
  reg [3:0]  idex_alu_op;

  localparam ALU_ADD = 4'd0;
  localparam ALU_SUB = 4'd1;

  function [31:0] alu_fn;
    input [3:0]  op;
    input [31:0] a;
    input [31:0] b;
    begin
      case (op)
        ALU_ADD: alu_fn = a + b;
        ALU_SUB: alu_fn = a - b;
        default: alu_fn = 0;
      endcase
    end
  endfunction

  // ---------------- EX/MEM ----------------
  reg [31:0] exmem_alu;
  reg [31:0] exmem_store_data;
  reg [31:0] exmem_wb_data;
  reg [4:0]  exmem_rd;
  reg        exmem_regwrite;
  reg        exmem_is_load;
  reg        exmem_is_store;

  // ---------------- MEM/WB ----------------
  reg [31:0] memwb_wdata;
  reg [4:0]  memwb_rd;
  reg        memwb_we;

  wire [31:0] dmem_rdata = dmem[exmem_alu[($clog2(DMEM_WORDS)+1):2]];

  // ---------------- Hazard detect ----------------
  wire id_uses_rs2;
  wire load_use_hazard;

  hazard_detection_unit u_hazard_detection (
    .op_d(op_d),
    .idex_is_load(idex_is_load),
    .idex_rd(idex_rd),
    .rs1_d(rs1_d),
    .rs2_d(rs2_d),
    .id_uses_rs2(id_uses_rs2),
    .load_use_hazard(load_use_hazard)
  );

  // ---------------- Forwarding ----------------
  reg [31:0] ex_rs1_fwd;
  reg [31:0] ex_rs2_fwd;

  always @(*) begin
    ex_rs1_fwd = idex_rs1_val;
    ex_rs2_fwd = idex_rs2_val;

    // Newest result must win:
    // EX/MEM has priority over MEM/WB.
    // Also, do NOT forward exmem_alu for loads, because for loads
    // exmem_alu is only the address, not the loaded data.

    // rs1 forwarding
    if (exmem_regwrite && !exmem_is_load && (exmem_rd != 0) && (exmem_rd == idex_rs1)) begin
      ex_rs1_fwd = exmem_alu;
    end
    else if (memwb_we && (memwb_rd != 0) && (memwb_rd == idex_rs1)) begin
      ex_rs1_fwd = memwb_wdata;
    end

    // rs2 forwarding
    if (exmem_regwrite && !exmem_is_load && (exmem_rd != 0) && (exmem_rd == idex_rs2)) begin
      ex_rs2_fwd = exmem_alu;
    end
    else if (memwb_we && (memwb_rd != 0) && (memwb_rd == idex_rs2)) begin
      ex_rs2_fwd = memwb_wdata;
    end
  end

  // ---------------- Execute ----------------
  wire [31:0] ex_a   = ex_rs1_fwd;
  wire [31:0] ex_b   = idex_alu_imm ? idex_imm : ex_rs2_fwd;
  wire [31:0] ex_alu = alu_fn(idex_alu_op, ex_a, ex_b);

  wire ex_beq         = (ex_rs1_fwd == ex_rs2_fwd);
  wire ex_take_branch = idex_is_branch && ex_beq;

  wire [31:0] ex_branch_tgt = idex_pc + idex_imm;
  wire [31:0] ex_jal_tgt    = idex_pc + idex_imm;
  wire [31:0] ex_pc_plus4   = idex_pc + 4;

  // ---------------- Control redirect ----------------
  reg        flush_ifid;
  reg [31:0] pc_next;

  always @(*) begin
    flush_ifid = 0;
    pc_next    = pc + 4;

    if (ex_take_branch) begin
      pc_next    = ex_branch_tgt;
      flush_ifid = 1;
    end

    if (idex_is_jal) begin
      pc_next    = ex_jal_tgt;
      flush_ifid = 1;
    end
  end

  // ---------------- Sequential pipeline update ----------------
  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
      ifid_instr <= NOP;
      ifid_pc <= 0;
      illegal_insn <= 0;

      wb_we <= 0;
      wb_rd <= 0;
      wb_wd <= 0;

      memwb_wdata <= 0;
      memwb_rd <= 0;
      memwb_we <= 0;

      exmem_alu <= 0;
      exmem_store_data <= 0;
      exmem_wb_data <= 0;
      exmem_rd <= 0;
      exmem_regwrite <= 0;
      exmem_is_load <= 0;
      exmem_is_store <= 0;

      idex_pc <= 0;
      idex_rs1_val <= 0;
      idex_rs2_val <= 0;
      idex_imm <= 0;
      idex_rd <= 0;
      idex_rs1 <= 0;
      idex_rs2 <= 0;
      idex_f3 <= 0;
      idex_regwrite <= 0;
      idex_is_load <= 0;
      idex_is_store <= 0;
      idex_is_branch <= 0;
      idex_is_jal <= 0;
      idex_alu_imm <= 0;
      idex_alu_op <= ALU_ADD;
    end
    else begin
      illegal_insn <= 0;

      // WB stage
      wb_we <= memwb_we;
      wb_rd <= memwb_rd;
      wb_wd <= memwb_wdata;

      // MEM stage
      if (exmem_is_store)
        dmem[exmem_alu[($clog2(DMEM_WORDS)+1):2]] <= exmem_store_data;

      memwb_wdata <= exmem_is_load ? dmem_rdata : exmem_wb_data;
      memwb_rd    <= exmem_rd;
      memwb_we    <= exmem_regwrite;

      // EX stage -> EX/MEM
      exmem_alu        <= ex_alu;
      exmem_store_data <= ex_rs2_fwd;
      exmem_rd         <= idex_rd;
      exmem_regwrite   <= idex_regwrite;
      exmem_is_load    <= idex_is_load;
      exmem_is_store   <= idex_is_store;
      exmem_wb_data    <= idex_is_jal ? ex_pc_plus4 : ex_alu;

      // ID stage -> ID/EX
      // Bubble ID/EX on both load-use hazard and control redirect.
      if (load_use_hazard || flush_ifid) begin
        idex_pc        <= 0;
        idex_rs1_val   <= 0;
        idex_rs2_val   <= 0;
        idex_imm       <= 0;
        idex_rd        <= 0;
        idex_rs1       <= 0;
        idex_rs2       <= 0;
        idex_f3        <= 0;
        idex_regwrite  <= 0;
        idex_is_load   <= 0;
        idex_is_store  <= 0;
        idex_is_branch <= 0;
        idex_is_jal    <= 0;
        idex_alu_imm   <= 0;
        idex_alu_op    <= ALU_ADD;
      end
      else begin
        idex_pc      <= ifid_pc;
        idex_rs1_val <= rf_rd1;
        idex_rs2_val <= rf_rd2;
        idex_rs1     <= rs1_d;
        idex_rs2     <= rs2_d;
        idex_rd      <= rd_d;
        idex_f3      <= f3_d;

        idex_regwrite  <= 0;
        idex_is_load   <= 0;
        idex_is_store  <= 0;
        idex_is_branch <= 0;
        idex_is_jal    <= 0;
        idex_alu_imm   <= 0;
        idex_alu_op    <= ALU_ADD;
        idex_imm       <= imm_i_d;

        case (op_d)
          7'b0110011: begin
            idex_regwrite <= 1;
            if ((f3_d == 3'b000) && (f7_d == 7'b0100000))
              idex_alu_op <= ALU_SUB;
            else
              idex_alu_op <= ALU_ADD;
          end

          7'b0010011: begin
            idex_regwrite <= 1;
            idex_alu_imm  <= 1;
            idex_alu_op   <= ALU_ADD;
          end

          7'b0000011: begin
            idex_regwrite <= 1;
            idex_is_load  <= 1;
            idex_alu_imm  <= 1;
            idex_alu_op   <= ALU_ADD;
          end

          7'b0100011: begin
            idex_is_store <= 1;
            idex_alu_imm  <= 1;
            idex_alu_op   <= ALU_ADD;
            idex_imm      <= imm_s_d;
          end

          7'b1100011: begin
            idex_is_branch <= 1;
            idex_imm       <= imm_b_d;
            idex_alu_op    <= ALU_SUB;
          end

          7'b1101111: begin
            idex_regwrite <= 1;
            idex_is_jal   <= 1;
            idex_imm      <= imm_j_d;
          end

          7'b0000000: begin
            // Treat empty / bubble as harmless
          end

          default: begin
            illegal_insn <= 1;
          end
        endcase
      end

      // IF stage / IFID register
      if (flush_ifid) begin
        ifid_pc    <= 0;
        ifid_instr <= NOP;
        pc         <= pc_next;
      end
      else if (load_use_hazard) begin
        pc         <= pc;
        ifid_pc    <= ifid_pc;
        ifid_instr <= ifid_instr;
      end
      else begin
        ifid_pc    <= pc;
        ifid_instr <= instr_f;
        pc         <= pc_next;
      end
    end
  end

endmodule
