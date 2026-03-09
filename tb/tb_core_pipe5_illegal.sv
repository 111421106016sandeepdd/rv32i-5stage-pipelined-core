`timescale 1ns/1ps
module tb_core_pipe5_illegal;

  reg clk;
  reg rst;
  wire [31:0] pc;
  wire illegal;
  wire [31:0] x10;

  core_pipe5 #(
    .IMEM_WORDS(64),
    .IMEM_HEX("build/padded.hex")
  ) dut (
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .illegal_insn(illegal),
    .dbg_x10(x10)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer cyc;

  initial begin
    $display("SIM START (PIPE ILLEGAL)");
    rst = 1; #20 rst = 0;

    for (cyc = 0; cyc < 40; cyc = cyc + 1) begin
      @(posedge clk);

      if (illegal) begin
        $display("PASS: illegal_insn=1 at cyc=%0d pc=%h", cyc, pc);
        $finish;
      end
    end

    $display("FAIL: illegal_insn never asserted. pc=%h x10=%0d", pc, x10);
    $fatal;
  end

endmodule
