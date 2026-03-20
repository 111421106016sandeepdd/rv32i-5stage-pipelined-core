`timescale 1ns/1ps

module hazard_detection_unit (
    input  wire [6:0] op_d,
    input  wire       idex_is_load,
    input  wire [4:0] idex_rd,
    input  wire [4:0] rs1_d,
    input  wire [4:0] rs2_d,
    output wire       id_uses_rs2,
    output wire       load_use_hazard
);

assign id_uses_rs2 =
    (op_d == 7'b0110011) ||  // R-type
    (op_d == 7'b0100011) ||  // SW
    (op_d == 7'b1100011);    // BEQ

assign load_use_hazard =
    idex_is_load &&
    (idex_rd != 5'd0) &&
    ((idex_rd == rs1_d) || (id_uses_rs2 && (idex_rd == rs2_d)));

endmodule
