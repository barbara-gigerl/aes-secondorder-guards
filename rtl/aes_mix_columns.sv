`ifdef YOSYS
`include "aes_pkg_verilog.sv"
`endif
module aes_mix_columns (
    input  logic [3:0][3:0][7:0] data_i,
    output logic [3:0][3:0][7:0] data_o
);

  logic [3:0][3:0][7:0] data_i_transposed;
  logic [3:0][3:0][7:0] data_o_transposed;

  assign data_i_transposed = aes_transpose(data_i);


  aes_mix_single_column u_aes_mix_column_0 (
      .data_i(data_i_transposed[0]),
      .data_o(data_o_transposed[0])
  );
  aes_mix_single_column u_aes_mix_column_1 (
      .data_i(data_i_transposed[1]),
      .data_o(data_o_transposed[1])
  );
  aes_mix_single_column u_aes_mix_column_2 (
      .data_i(data_i_transposed[2]),
      .data_o(data_o_transposed[2])
  );
  aes_mix_single_column u_aes_mix_column_3 (
      .data_i(data_i_transposed[3]),
      .data_o(data_o_transposed[3])
  );


  assign data_o = aes_transpose(data_o_transposed);

endmodule
