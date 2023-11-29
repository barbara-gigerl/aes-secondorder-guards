`ifdef YOSYS
`include "aes_pkg_verilog.sv"
`endif
module aes_mix_single_column (
    input  logic [3:0][7:0] data_i,
    output logic [3:0][7:0] data_o
);

  logic [3:0][7:0] x;

  logic [3:0][7:0] x_mul2;


  // Drive x
  assign x[0] = data_i[0] ^ data_i[3];
  assign x[1] = data_i[3] ^ data_i[2];
  assign x[2] = data_i[2] ^ data_i[1];
  assign x[3] = data_i[1] ^ data_i[0];

  // Mul2(x)
  assign x_mul2[0] = aes_mul2(x[0]);
  assign x_mul2[1] = aes_mul2(x[1]);
  assign x_mul2[2] = aes_mul2(x[2]);
  assign x_mul2[3] = aes_mul2(x[3]);

  // Drive outputs
  assign data_o[0] = data_i[1] ^ x_mul2[3] ^ x[1];
  assign data_o[1] = data_i[0] ^ x_mul2[2] ^ x[1];
  assign data_o[2] = data_i[3] ^ x_mul2[1] ^ x[3];
  assign data_o[3] = data_i[2] ^ x_mul2[0] ^ x[3];

endmodule

