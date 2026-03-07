// tb/tb_alu.sv
module tb_alu;

  localparam int XLEN = 32;

  logic [XLEN-1:0] a, b;
  logic [3:0]      op;
  logic [XLEN-1:0] y;
  logic            zero;

  alu #(.XLEN(XLEN)) dut (
    .a(a), .b(b), .op(op),
    .y(y), .zero(zero)
  );

  localparam logic [3:0]
    ALU_ADD  = 4'h0,
    ALU_SUB  = 4'h1,
    ALU_AND  = 4'h2,
    ALU_OR   = 4'h3,
    ALU_XOR  = 4'h4,
    ALU_SLL  = 4'h5,
    ALU_SRL  = 4'h6,
    ALU_SRA  = 4'h7,
    ALU_SLT  = 4'h8,
    ALU_SLTU = 4'h9;

  function automatic logic [XLEN-1:0] golden(
    input logic [XLEN-1:0] ga,
    input logic [XLEN-1:0] gb,
    input logic [3:0]      gop
  );
    logic signed [XLEN-1:0] gas, gbs;
    gas = $signed(ga);
    gbs = $signed(gb);

    case (gop)
      ALU_ADD : golden = ga + gb;
      ALU_SUB : golden = ga - gb;
      ALU_AND : golden = ga & gb;
      ALU_OR  : golden = ga | gb;
      ALU_XOR : golden = ga ^ gb;
      ALU_SLL : golden = ga << gb[4:0];
      ALU_SRL : golden = ga >> gb[4:0];
      ALU_SRA : golden = gas >>> gb[4:0];
      ALU_SLT : golden = (gas < gbs) ? 32'd1 : 32'd0;
      ALU_SLTU: golden = (ga  < gb ) ? 32'd1 : 32'd0;
      default : golden = '0;
    endcase
  endfunction

  task automatic check_one(
    input logic [XLEN-1:0] ta,
    input logic [XLEN-1:0] tbv,
    input logic [3:0]      top
  );
    logic [XLEN-1:0] exp;
    exp = golden(ta, tbv, top);

    a  = ta;
    b  = tbv;
    op = top;

    #1;

    if (y !== exp) begin
      $display("FAIL: op=%0h a=%h b=%h  got y=%h exp=%h", op, a, b, y, exp);
      $finish;
    end

    if (zero !== (exp == '0)) begin
      $display("FAIL(zero): op=%0h a=%h b=%h  got zero=%0b exp zero=%0b",
               op, a, b, zero, (exp=='0));
      $finish;
    end
  endtask

  initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_alu);

    // Basic tests
    check_one(32'd10, 32'd3, ALU_ADD);
    check_one(32'd10, 32'd3, ALU_SUB);
    check_one(32'hF0F0, 32'h0FF0, ALU_AND);
    check_one(32'hF0F0, 32'h0FF0, ALU_OR);
    check_one(32'hAAAA, 32'h5555, ALU_XOR);
    check_one(32'd1, 32'd5, ALU_SLL);
    check_one(32'h8000_0000, 32'd1, ALU_SRL);
    check_one(32'h8000_0000, 32'd1, ALU_SRA);
    check_one(32'hFFFF_FFFF, 32'd1, ALU_SLT);
    check_one(32'hFFFF_FFFF, 32'd1, ALU_SLTU);

    // Random regression
    for (int i = 0; i < 2000; i++) begin
      check_one($urandom(), $urandom(), $urandom_range(0, 9));
    end

    $display("PASS: ALU random regression ok");
    $finish;
  end

endmodule