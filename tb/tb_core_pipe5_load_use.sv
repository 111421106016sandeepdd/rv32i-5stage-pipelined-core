`timescale 1ns/1ps
module tb_core_pipe5_load_use;

  reg clk;
  reg rst;
  wire [31:0] pc;
  wire illegal;
  wire [31:0] x10;

  core_pipe5 #(
    .IMEM_WORDS(64),
    .IMEM_HEX("build/padded.hex"),
    .DMEM_WORDS(64)
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
    $display("SIM START (PIPE LOAD-USE)");
    rst = 1; #20 rst = 0;

    for (cyc = 0; cyc < 120; cyc = cyc + 1) begin
      @(posedge clk);

      if (illegal) begin
        $display("FAIL: illegal_insn=1 at cyc=%0d pc=%h", cyc, pc);
        $fatal;
      end

      if (x10 == 32'd6) begin
        $display("PASS: x10=%0d at cyc=%0d pc=%h dmem0=%0d", x10, cyc, pc, dut.dmem[0]);
        $finish;
      end
    end

    $display("FAIL: timeout. x10=%0d dmem0=%0d pc=%h", x10, dut.dmem[0], pc);
    $fatal;
  end

endmodule
