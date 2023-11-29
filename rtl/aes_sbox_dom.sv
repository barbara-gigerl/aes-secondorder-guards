module aes_sbox_dom (
    input logic clk_i,
    input logic rst_ni,
    input logic [3:0] we_i,
    input logic [7:0] in_data_basis_x_q,
    input logic [7:0] in_mask0_basis_x_q,
    input logic [7:0] in_mask1_basis_x_q,
    input logic [101:0] prd_i,
    output logic [7:0] data_o,
    output logic [7:0] mask0_o,
    output logic [7:0] mask1_o
);


  logic [ 7:0] out_data_basis_x;
  logic [ 7:0] out_mask0_basis_x;
  logic [ 7:0] out_mask1_basis_x;

  logic [23:0] prd_stage1;
  logic [17:0] prd_stage2;
  logic [ 9:0] prd_stage3A;
  logic [ 9:0] prd_stage3B;
  logic [19:0] prd_stage4A;
  logic [19:0] prd_stage4B;

  assign prd_stage1  = prd_i[0+:24];  //   24 bit
  assign prd_stage2  = prd_i[24+:18];  //   18 bit
  assign prd_stage3A = prd_i[42+:10];  //    6 (+4) bit
  assign prd_stage3B = prd_i[52+:10];  //    6 (+4) bit

  assign prd_stage4A = prd_i[62+:20];  //   12 (+8) bit
  assign prd_stage4B = prd_i[82+:20];  //   12 (+8) bit

  //----------------------------------------------------------------------------------------------

  aes_dom_inverse_gf2p8 #() inv_gf2p8 (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .we_i       (we_i),
      .P0         (in_data_basis_x_q),
      .P1         (in_mask0_basis_x_q),
      .P2         (in_mask1_basis_x_q),
      .prd_stage1 (prd_stage1),
      .prd_stage2 (prd_stage2),
      .prd_stage3A(prd_stage3A),
      .prd_stage3B(prd_stage3B),
      .prd_stage4A(prd_stage4A),
      .prd_stage4B(prd_stage4B),
      .P0_inv     (out_data_basis_x),
      .P1_inv     (out_mask0_basis_x),
      .P2_inv     (out_mask1_basis_x)
  );



  // Convert to basis S or A.
  always_comb begin
    data_o[0] = out_data_basis_x[6] ^ out_data_basis_x[4] ^ out_data_basis_x[1];
    data_o[1] = out_data_basis_x[5] ^ out_data_basis_x[4] ^ out_data_basis_x[1];
    data_o[2] = out_data_basis_x[6] ^ out_data_basis_x[5] ^ out_data_basis_x[3] ^ out_data_basis_x[2] ^ out_data_basis_x[0] ;
    data_o[3] = out_data_basis_x[7] ^ out_data_basis_x[6] ^ out_data_basis_x[5] ^ out_data_basis_x[4] ^ out_data_basis_x[3] ;
    data_o[4] = out_data_basis_x[7] ^ out_data_basis_x[5] ^ out_data_basis_x[3];
    data_o[5] = out_data_basis_x[6] ^ out_data_basis_x[0];
    data_o[6] = out_data_basis_x[7] ^ out_data_basis_x[3];
    data_o[7] = out_data_basis_x[5] ^ out_data_basis_x[3];
    data_o = data_o ^ 8'h63;

    mask0_o[0] = out_mask0_basis_x[6] ^ out_mask0_basis_x[4] ^ out_mask0_basis_x[1];
    mask0_o[1] = out_mask0_basis_x[5] ^ out_mask0_basis_x[4] ^ out_mask0_basis_x[1];
    mask0_o[2] = out_mask0_basis_x[6] ^ out_mask0_basis_x[5] ^ out_mask0_basis_x[3] ^ out_mask0_basis_x[2] ^ out_mask0_basis_x[0] ;
    mask0_o[3] = out_mask0_basis_x[7] ^ out_mask0_basis_x[6] ^ out_mask0_basis_x[5] ^ out_mask0_basis_x[4] ^ out_mask0_basis_x[3] ;
    mask0_o[4] = out_mask0_basis_x[7] ^ out_mask0_basis_x[5] ^ out_mask0_basis_x[3];
    mask0_o[5] = out_mask0_basis_x[6] ^ out_mask0_basis_x[0];
    mask0_o[6] = out_mask0_basis_x[7] ^ out_mask0_basis_x[3];
    mask0_o[7] = out_mask0_basis_x[5] ^ out_mask0_basis_x[3];

    mask1_o[0] = out_mask1_basis_x[6] ^ out_mask1_basis_x[4] ^ out_mask1_basis_x[1];
    mask1_o[1] = out_mask1_basis_x[5] ^ out_mask1_basis_x[4] ^ out_mask1_basis_x[1];
    mask1_o[2] = out_mask1_basis_x[6] ^ out_mask1_basis_x[5] ^ out_mask1_basis_x[3] ^ out_mask1_basis_x[2] ^ out_mask1_basis_x[0] ;
    mask1_o[3] = out_mask1_basis_x[7] ^ out_mask1_basis_x[6] ^ out_mask1_basis_x[5] ^ out_mask1_basis_x[4] ^ out_mask1_basis_x[3] ;
    mask1_o[4] = out_mask1_basis_x[7] ^ out_mask1_basis_x[5] ^ out_mask1_basis_x[3];
    mask1_o[5] = out_mask1_basis_x[6] ^ out_mask1_basis_x[0];
    mask1_o[6] = out_mask1_basis_x[7] ^ out_mask1_basis_x[3];
    mask1_o[7] = out_mask1_basis_x[5] ^ out_mask1_basis_x[3];
  end





endmodule
