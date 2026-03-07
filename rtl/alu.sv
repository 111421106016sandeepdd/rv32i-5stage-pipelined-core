// rtl/alu.sv (Icarus-friendly)
module alu #(
  parameter XLEN = 32
)(
  input  wire [XLEN-1:0] a,
  input  wire [XLEN-1:0] b,
  input  wire [3:0]      op,
  output reg  [XLEN-1:0] y,
  output reg             zero
);

  // op encoding must match core_single.sv
  localparam [3:0]
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

  wire signed [XLEN-1:0] as = a;
  wire signed [XLEN-1:0] bs = b;
  wire [4:0] shamt = b[4:0];

  always @* begin
    y = {XLEN{1'b0}};
    case (op)
      ALU_ADD : y = a + b;
      ALU_SUB : y = a - b;
      ALU_AND : y = a & b;
      ALU_OR  : y = a | b;
      ALU_XOR : y = a ^ b;
      ALU_SLL : y = a << shamt;
      ALU_SRL : y = a >> shamt;
      ALU_SRA : y = as >>> shamt;
      ALU_SLT : y = (as < bs) ? {{(XLEN-1){1'b0}}, 1'b1} : {XLEN{1'b0}};
      ALU_SLTU: y = (a  < b ) ? {{(XLEN-1){1'b0}}, 1'b1} : {XLEN{1'b0}};
      default : y = {XLEN{1'b0}};
    endcase

    zero = (y == {XLEN{1'b0}});
  end

endmodule
