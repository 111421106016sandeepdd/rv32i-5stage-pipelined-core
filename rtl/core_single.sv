// rtl/core_single.sv - RV32I subset: OP + OP-IMM + LW/SW + BEQ/BNE + JAL (Icarus-stable)
module core_single #(
  parameter XLEN = 32,
  parameter IMEM_WORDS = 64,
  parameter IMEM_HEX = "programs/test_branch.hex"
)(
  input  wire            clk,
  input  wire            rst,
  output reg [XLEN-1:0]  pc,
  output reg             illegal_insn,
  output wire [XLEN-1:0] dbg_x10
);

  // -----------------------
  // Instruction memory
  // -----------------------
  reg [31:0] imem [0:IMEM_WORDS-1];
  integer i;
  initial begin
    for (i = 0; i < IMEM_WORDS; i = i + 1)
      imem[i] = 32'h00000013; // NOP
    $readmemh(IMEM_HEX, imem);
    pc = 0;
    illegal_insn = 0;
  end

  // Registered instruction
  reg [31:0] instr;

  // Decode fields
  wire [6:0] opcode = instr[6:0];
  wire [4:0] rd     = instr[11:7];
  wire [2:0] funct3 = instr[14:12];
  wire [4:0] rs1    = instr[19:15];
  wire [4:0] rs2    = instr[24:20];
  wire [6:0] funct7 = instr[31:25];

  // immediates
  wire [XLEN-1:0] imm_i = {{(XLEN-12){instr[31]}}, instr[31:20]};
  wire [XLEN-1:0] imm_s = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
  wire [XLEN-1:0] imm_b = {{(XLEN-13){instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [XLEN-1:0] imm_j = {{(XLEN-21){instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
  wire [4:0]      shamt = instr[24:20];

  // -----------------------
  // Regfile (REGISTERED writeback)
  // -----------------------
  wire [XLEN-1:0] rf_rd1, rf_rd2;

  reg             wb_we_r;
  reg  [4:0]      wb_rd_r;
  reg  [XLEN-1:0] wb_data_r;

  regfile #(.XLEN(XLEN), .REG_COUNT(32)) u_rf (
    .clk(clk),
    .rst(rst),
    .we(wb_we_r),
    .rs1(rs1),
    .rs2(rs2),
    .rd(wb_rd_r),
    .wd(wb_data_r),
    .rd1(rf_rd1),
    .rd2(rf_rd2),
    .dbg_addr(5'd10),
    .dbg_data(dbg_x10)
  );

  // -----------------------
  // ALU function
  // -----------------------
  function [XLEN-1:0] alu_fn;
    input [3:0] op;
    input [XLEN-1:0] a;
    input [XLEN-1:0] b;
    reg signed [XLEN-1:0] as;
    reg signed [XLEN-1:0] bs;
    begin
      as = a; bs = b;
      case (op)
        4'h0: alu_fn = a + b;               // ADD
        4'h1: alu_fn = a - b;               // SUB
        4'h2: alu_fn = a & b;               // AND
        4'h3: alu_fn = a | b;               // OR
        4'h4: alu_fn = a ^ b;               // XOR
        4'h5: alu_fn = a << b[4:0];         // SLL
        4'h6: alu_fn = a >> b[4:0];         // SRL
        4'h7: alu_fn = as >>> b[4:0];       // SRA
        4'h8: alu_fn = (as < bs) ? 32'd1:0; // SLT
        4'h9: alu_fn = (a  < b ) ? 32'd1:0; // SLTU
        default: alu_fn = 0;
      endcase
    end
  endfunction

  // -----------------------
  // Data memory (DMEM)
  // -----------------------
  localparam DMEM_WORDS = 256;
  reg [31:0] dmem [0:DMEM_WORDS-1];
  integer j;
  initial begin
    for (j = 0; j < DMEM_WORDS; j = j + 1)
      dmem[j] = 32'h00000000;
  end

  // -----------------------
  // Combinational execute -> next WB/store + pc_next
  // -----------------------
  reg             next_wb_we;
  reg  [4:0]      next_wb_rd;
  reg  [XLEN-1:0] next_wb_data;

  reg             do_store;
  reg  [31:0]     store_addr;
  reg  [31:0]     store_data;

  reg             next_illegal;

  reg  [3:0]      op_sel;
  reg  [XLEN-1:0] a_sel, b_sel;

  reg  [31:0]     eff_addr;
  wire [7:0]      store_index = store_addr[9:2];
  wire [31:0]     load_rdata  = dmem[eff_addr[9:2]];

  reg  [XLEN-1:0] pc_next;
  wire [31:0]     instr_next = imem[pc_next[($clog2(IMEM_WORDS)+1):2]];

  always @* begin
    // defaults
    next_illegal = 1'b0;

    next_wb_we   = 1'b0;
    next_wb_rd   = rd;
    next_wb_data = 32'h00000000;

    do_store   = 1'b0;
    store_addr = 32'h00000000;
    store_data = rf_rd2;

    op_sel   = 4'h0;   // ADD
    a_sel    = rf_rd1;
    b_sel    = rf_rd2;
    eff_addr = 32'h0;

    pc_next  = pc + 4;

    case (opcode)
      7'b0110011: begin // OP
        next_wb_we = 1'b1;
        case (funct3)
          3'b000: op_sel = (funct7 == 7'b0100000) ? 4'h1 : 4'h0;
          3'b111: op_sel = 4'h2;
          3'b110: op_sel = 4'h3;
          3'b100: op_sel = 4'h4;
          3'b001: op_sel = 4'h5;
          3'b101: op_sel = (funct7 == 7'b0100000) ? 4'h7 : 4'h6;
          3'b010: op_sel = 4'h8;
          3'b011: op_sel = 4'h9;
          default: begin next_illegal = 1'b1; next_wb_we = 1'b0; end
        endcase
        next_wb_data = alu_fn(op_sel, a_sel, b_sel);
      end

      7'b0010011: begin // OP-IMM
        next_wb_we = 1'b1;
        case (funct3)
          3'b000: begin op_sel = 4'h0; b_sel = imm_i; end
          3'b111: begin op_sel = 4'h2; b_sel = imm_i; end
          3'b110: begin op_sel = 4'h3; b_sel = imm_i; end
          3'b100: begin op_sel = 4'h4; b_sel = imm_i; end
          3'b010: begin op_sel = 4'h8; b_sel = imm_i; end
          3'b011: begin op_sel = 4'h9; b_sel = imm_i; end
          3'b001: begin op_sel = 4'h5; b_sel = {27'b0, shamt}; end
          3'b101: begin
                    op_sel = (funct7 == 7'b0100000) ? 4'h7 : 4'h6;
                    b_sel  = {27'b0, shamt};
                  end
          default: begin next_illegal = 1'b1; next_wb_we = 1'b0; end
        endcase
        next_wb_data = alu_fn(op_sel, a_sel, b_sel);
      end

      7'b0000011: begin // LW
        if (funct3 == 3'b010) begin
          eff_addr     = rf_rd1 + imm_i;
          next_wb_we   = 1'b1;
          next_wb_data = load_rdata;
        end else next_illegal = 1'b1;
      end

      7'b0100011: begin // SW
        if (funct3 == 3'b010) begin
          store_addr = rf_rd1 + imm_s;
          store_data = rf_rd2;
          do_store   = 1'b1;
          next_wb_we = 1'b0;
        end else next_illegal = 1'b1;
      end

      7'b1100011: begin // BEQ/BNE
        if (funct3 == 3'b000) begin
          if (rf_rd1 == rf_rd2) pc_next = pc + imm_b;
        end else if (funct3 == 3'b001) begin
          if (rf_rd1 != rf_rd2) pc_next = pc + imm_b;
        end else next_illegal = 1'b1;
      end

      7'b1101111: begin // JAL
        // rd = pc+4 ; pc = pc + imm_j
        next_wb_we   = 1'b1;
        next_wb_rd   = rd;
        next_wb_data = pc + 4;
        pc_next      = pc + imm_j;
      end

      default: next_illegal = 1'b1;
    endcase

    if (next_illegal) begin
      next_wb_we = 1'b0;
      do_store   = 1'b0;
      pc_next    = pc + 4;
    end
  end

  // -----------------------
  // Sequential: commit store + register WB + update PC/instr
  // -----------------------
  always @(posedge clk) begin
    if (rst) begin
      pc           <= 0;
      instr        <= 32'h00000013;
      illegal_insn <= 1'b0;

      wb_we_r      <= 1'b0;
      wb_rd_r      <= 5'd0;
      wb_data_r    <= 32'h0;
    end else begin
      if (do_store) dmem[store_index] <= store_data;

      wb_we_r      <= next_wb_we;
      wb_rd_r      <= next_wb_rd;
      wb_data_r    <= next_wb_data;

      illegal_insn <= next_illegal;

      pc    <= pc_next;
      instr <= instr_next;
    end
  end

endmodule
