module aes_shift_rows (
    input  logic [3:0][3:0][7:0] data_i,
    output logic [3:0][3:0][7:0] data_o
);

  // Row 0 
  assign data_o[0] = data_i[0];

  // Row 1
  assign data_o[1][0] = data_i[1][1];
  assign data_o[1][1] = data_i[1][2];
  assign data_o[1][2] = data_i[1][3];
  assign data_o[1][3] = data_i[1][0];

  // Row 2
  assign data_o[2][0] = data_i[2][2];
  assign data_o[2][1] = data_i[2][3];
  assign data_o[2][2] = data_i[2][0];
  assign data_o[2][3] = data_i[2][1];

  // Row 3
  assign data_o[3][0] = data_i[3][3];
  assign data_o[3][1] = data_i[3][0];
  assign data_o[3][2] = data_i[3][1];
  assign data_o[3][3] = data_i[3][2];


endmodule
