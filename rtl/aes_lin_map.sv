module aes_lin_map #(
) (
    input  logic [7:0] data_i,
    input  logic [7:0] mask0_i,
    input  logic [7:0] mask1_i,
    output logic [7:0] data_o,
    output logic [7:0] mask0_o,
    output logic [7:0] mask1_o
);


  always_comb begin
    data_o[0]  = data_i[6] ^ data_i[3] ^ data_i[2] ^ data_i[1] ^ data_i[0];
    data_o[1]  = data_i[6] ^ data_i[5] ^ data_i[0];
    data_o[2]  = data_i[0];
    data_o[3]  = data_i[7] ^ data_i[4] ^ data_i[3] ^ data_i[1] ^ data_i[0];
    data_o[4]  = data_i[7] ^ data_i[6] ^ data_i[5] ^ data_i[0];
    data_o[5]  = data_i[6] ^ data_i[5] ^ data_i[1] ^ data_i[0];
    data_o[6]  = data_i[6] ^ data_i[5] ^ data_i[4] ^ data_i[0];
    data_o[7]  = data_i[7] ^ data_i[6] ^ data_i[5] ^ data_i[2] ^ data_i[1] ^ data_i[0];

    mask0_o[0] = mask0_i[6] ^ mask0_i[3] ^ mask0_i[2] ^ mask0_i[1] ^ mask0_i[0];
    mask0_o[1] = mask0_i[6] ^ mask0_i[5] ^ mask0_i[0];
    mask0_o[2] = mask0_i[0];
    mask0_o[3] = mask0_i[7] ^ mask0_i[4] ^ mask0_i[3] ^ mask0_i[1] ^ mask0_i[0];
    mask0_o[4] = mask0_i[7] ^ mask0_i[6] ^ mask0_i[5] ^ mask0_i[0];
    mask0_o[5] = mask0_i[6] ^ mask0_i[5] ^ mask0_i[1] ^ mask0_i[0];
    mask0_o[6] = mask0_i[6] ^ mask0_i[5] ^ mask0_i[4] ^ mask0_i[0];
    mask0_o[7] = mask0_i[7] ^ mask0_i[6] ^ mask0_i[5] ^ mask0_i[2] ^ mask0_i[1] ^ mask0_i[0];

    mask1_o[0] = mask1_i[6] ^ mask1_i[3] ^ mask1_i[2] ^ mask1_i[1] ^ mask1_i[0];
    mask1_o[1] = mask1_i[6] ^ mask1_i[5] ^ mask1_i[0];
    mask1_o[2] = mask1_i[0];
    mask1_o[3] = mask1_i[7] ^ mask1_i[4] ^ mask1_i[3] ^ mask1_i[1] ^ mask1_i[0];
    mask1_o[4] = mask1_i[7] ^ mask1_i[6] ^ mask1_i[5] ^ mask1_i[0];
    mask1_o[5] = mask1_i[6] ^ mask1_i[5] ^ mask1_i[1] ^ mask1_i[0];
    mask1_o[6] = mask1_i[6] ^ mask1_i[5] ^ mask1_i[4] ^ mask1_i[0];
    mask1_o[7] = mask1_i[7] ^ mask1_i[6] ^ mask1_i[5] ^ mask1_i[2] ^ mask1_i[1] ^ mask1_i[0];
  end
endmodule

