// tb/tb_regfile.sv
module tb_regfile;

  localparam int XLEN = 32;
  localparam int REG_COUNT = 32;

  logic clk, rst;
  logic we;
  logic [$clog2(REG_COUNT)-1:0] rs1, rs2, rd;
  logic [XLEN-1:0] wd;
  logic [XLEN-1:0] rd1, rd2;

  regfile #(.XLEN(XLEN), .REG_COUNT(REG_COUNT)) dut (
    .clk(clk), .rst(rst),
    .we(we),
    .rs1(rs1), .rs2(rs2), .rd(rd),
    .wd(wd),
    .rd1(rd1), .rd2(rd2)
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // model
  logic [XLEN-1:0] model [REG_COUNT-1:0];

  // helper vars for random loop (declare OUTSIDE for Icarus)
  integer r, r1, r2, k;
  logic [XLEN-1:0] d;

  // write one register
  task automatic write_reg(input integer wr, input logic [XLEN-1:0] data);
    begin
      @(negedge clk);
      we = 1;
      rd = wr[$clog2(REG_COUNT)-1:0];
      wd = data;
      @(negedge clk);
      we = 0;
    end
  endtask

  // check read ports
  task automatic check_read(
    input integer cr1, input integer cr2,
    input logic [XLEN-1:0] exp1,
    input logic [XLEN-1:0] exp2
  );
    begin
      rs1 = cr1[$clog2(REG_COUNT)-1:0];
      rs2 = cr2[$clog2(REG_COUNT)-1:0];
      #1;
      if (rd1 !== exp1) begin
        $display("FAIL rd1: rs1=%0d got=%h exp=%h", cr1, rd1, exp1);
        $finish;
      end
      if (rd2 !== exp2) begin
        $display("FAIL rd2: rs2=%0d got=%h exp=%h", cr2, rd2, exp2);
        $finish;
      end
    end
  endtask

  initial begin
    // init signals
    we = 0; rs1 = 0; rs2 = 0; rd = 0; wd = '0;

    // waves
    $dumpfile("build/wave_regfile.vcd");
    $dumpvars(0, tb_regfile);

    // reset
    rst = 1;
    repeat (2) @(negedge clk);
    rst = 0;

    // model reset
    for (integer i = 0; i < REG_COUNT; i = i + 1)
      model[i] = '0;

    // x0 must read 0 always
    check_read(0, 0, 32'd0, 32'd0);

    // write some regs and verify
    write_reg(1, 32'h1111_1111); model[1]  = 32'h1111_1111;
    write_reg(2, 32'h2222_2222); model[2]  = 32'h2222_2222;
    write_reg(31,32'hDEAD_BEEF); model[31] = 32'hDEAD_BEEF;

    check_read(1, 2, model[1], model[2]);
    check_read(31,0, model[31], 32'd0);

    // attempt to write x0 (should be ignored)
    write_reg(0, 32'hFFFF_FFFF);
    model[0] = 32'd0;
    check_read(0, 1, 32'd0, model[1]);

    // random regression
    for (k = 0; k < 500; k = k + 1) begin
      r  = $urandom_range(0, REG_COUNT-1);
      d  = $urandom();

      write_reg(r, d);
      if (r != 0) model[r] = d;
      else        model[0] = 32'd0;

      r1 = $urandom_range(0, REG_COUNT-1);
      r2 = $urandom_range(0, REG_COUNT-1);

      check_read(
        r1, r2,
        (r1==0) ? 32'd0 : model[r1],
        (r2==0) ? 32'd0 : model[r2]
      );
    end

    $display("PASS: regfile random regression ok");
    $finish;
  end

endmodule