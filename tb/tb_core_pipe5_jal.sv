`timescale 1ns/1ps
module tb_core_pipe5_jal;

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

  initial begin
    $display("SIM START (PIPE JAL)");
    rst = 1; #20 rst = 0;

    #600;

    if (illegal) $display("FAIL: illegal_insn=1");
    else if (x10 == 32'd12) $display("PASS: x10=%0d", x10);
    else $display("FAIL: x10=%0d expected 12", x10);

    $finish;
  end
endmodule
