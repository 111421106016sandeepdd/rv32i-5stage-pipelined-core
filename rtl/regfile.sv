`timescale 1ns/1ps
module regfile #(
  parameter XLEN = 32,
  parameter REG_COUNT = 32
)(
  input              clk,
  input              rst,
  input              we,
  input  [4:0]       rs1,
  input  [4:0]       rs2,
  input  [4:0]       rd,
  input  [XLEN-1:0]  wd,
  output [XLEN-1:0]  rd1,
  output [XLEN-1:0]  rd2,

  input  [4:0]       dbg_addr,
  output [XLEN-1:0]  dbg_data
);

  reg [XLEN-1:0] regs [0:REG_COUNT-1];
  integer i;

  // Write on NEGEDGE to avoid same-edge race with core's wb signals (Icarus-stable)
  always @(negedge clk) begin
    if (rst) begin
      for (i = 0; i < REG_COUNT; i = i + 1)
        regs[i] <= 0;
    end else begin
      if (we && rd != 0)
        regs[rd] <= wd;
    end
  end

  // Combinational reads
  assign rd1 = (rs1 == 0) ? 0 : regs[rs1];
  assign rd2 = (rs2 == 0) ? 0 : regs[rs2];

  assign dbg_data = (dbg_addr == 0) ? 0 : regs[dbg_addr];

endmodule
