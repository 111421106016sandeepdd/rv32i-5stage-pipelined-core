`timescale 1ns/1ps

module forwarding_unit (
    input  wire [31:0] idex_rs1_val,
    input  wire [31:0] idex_rs2_val,
    input  wire [4:0]  idex_rs1,
    input  wire [4:0]  idex_rs2,

    input  wire        exmem_regwrite,
    input  wire        exmem_is_load,
    input  wire [4:0]  exmem_rd,
    input  wire [31:0] exmem_alu,

    input  wire        memwb_we,
    input  wire [4:0]  memwb_rd,
    input  wire [31:0] memwb_wdata,

    output reg  [31:0] ex_rs1_fwd,
    output reg  [31:0] ex_rs2_fwd
);

always @(*) begin
    ex_rs1_fwd = idex_rs1_val;
    ex_rs2_fwd = idex_rs2_val;

    // rs1 forwarding
    if (exmem_regwrite && !exmem_is_load && (exmem_rd != 5'd0) && (exmem_rd == idex_rs1)) begin
        ex_rs1_fwd = exmem_alu;
    end
    else if (memwb_we && (memwb_rd != 5'd0) && (memwb_rd == idex_rs1)) begin
        ex_rs1_fwd = memwb_wdata;
    end

    // rs2 forwarding
    if (exmem_regwrite && !exmem_is_load && (exmem_rd != 5'd0) && (exmem_rd == idex_rs2)) begin
        ex_rs2_fwd = exmem_alu;
    end
    else if (memwb_we && (memwb_rd != 5'd0) && (memwb_rd == idex_rs2)) begin
        ex_rs2_fwd = memwb_wdata;
    end
end

endmodule
