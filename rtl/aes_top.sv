`ifdef YOSYS
`include "aes_pkg_verilog.sv"
`endif
module aes_top #(
    parameter int unsigned NumShares = 3
) (
    input clk_i,
    input rst_ni,
    input start_i,
    output logic busy_o,
    input logic [3:0][3:0][7:0] key_i[NumShares],
    input logic [3:0][3:0][7:0] plain_i[NumShares],
    output logic [3:0][3:0][7:0] ct_o[NumShares],
    input [63:0] trivium_prd_i
);

  logic [3:0][3:0][7:0] state_q[NumShares];
  logic [3:0][3:0][7:0] state_d[NumShares];
  logic [3:0][3:0][7:0] key_q[NumShares];
  logic [3:0][3:0][7:0] key_d[NumShares];
  logic [3:0][7:0] key_lin_map_q[NumShares];
  logic [3:0][7:0] key_lin_map_d[NumShares];
  logic [3:0][3:0][101:0] prd;

  logic [101:0] prd_key_0;
  logic [101:0] prd_key_1;
  logic [101:0] prd_key_2;
  logic [101:0] prd_key_3;

  logic [3:0][3:0][7:0] lin_map_i[NumShares];
  logic [3:0][3:0][7:0] lin_map_o[NumShares];
  logic [3:0][3:0][7:0] sub_bytes_o[NumShares];

  logic [3:0][3:0][7:0] shift_rows_i[NumShares];
  logic [3:0][3:0][7:0] shift_rows_o[NumShares];

  logic [3:0][3:0][7:0] mix_columns_i[NumShares];
  logic [3:0][3:0][7:0] mix_columns_o[NumShares];

  logic [3:0][3:0][7:0] add_rk_i[NumShares];
  logic [3:0][3:0][7:0] add_rk_o[NumShares];

  logic [3:0][3:0][7:0] rk_o[NumShares];
  logic [3:0][3:0][7:0] key_lin_map_o[NumShares];
  logic [3:0][7:0] key_lin_map_i[NumShares];

  logic [3:0][7:0] key_sub_bytes_o[NumShares];
  logic [3:0][7:0] w0[NumShares];
  logic [3:0][7:0] w1[NumShares];
  logic [3:0][7:0] w2[NumShares];
  logic [3:0][7:0] w3[NumShares];
  logic [3:0][7:0] w3_transformed[NumShares];
  logic [3:0][7:0] w4[NumShares];
  logic [3:0][7:0] w5[NumShares];
  logic [3:0][7:0] w6[NumShares];
  logic [3:0][7:0] w7[NumShares];


  logic [3:0] ns;
  logic [3:0] round_ctr;
  logic [3:0] cs;
  logic [3:0] we_sbox;
  logic [3:0] we_key_sbox;


  logic [7:0] rcon_q;
  logic [7:0] rcon_d;

  logic [3:0][3:0][23:0] prd_sbox_data;



  //-----------------------------------------------------------
  //--------------- RANDOMNESS AND GUARDS ---------------------
  //-----------------------------------------------------------

  genvar prd_i;
  genvar prd_j;


  for (prd_i = 0; prd_i < 4; prd_i++) begin
    for (prd_j = 0; prd_j < 4; prd_j++) begin

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          prd_sbox_data[prd_i][prd_j] <= 24'b0;
        end else if (cs == INIT_LIN_MAP_RK || cs == ROUND_END) begin
          prd_sbox_data[prd_i][prd_j] <= {
            trivium_prd_i[(prd_i*16+8)+:8] ^ add_rk_o[1][((prd_i+2)%4)][((prd_j+2)%4)],
            trivium_prd_i[(prd_i*16)+:8],
            add_rk_o[0][((prd_i+1)%4)][((prd_j+1)%4)]
          };
        end else if (cs == SBOX1) begin
          prd_sbox_data[prd_i][prd_j] <= {
            6'b0,
            add_rk_o[1][((prd_i+2)%4)][((prd_j+3)%4)][1:0],
            add_rk_o[0][((prd_i+1)%4)][((prd_j+2)%4)] ^ trivium_prd_i[(prd_i*16+8)+:8],
            trivium_prd_i[(prd_i*16)+:8]
          };
        end else if (cs == SBOX2) begin
          prd_sbox_data[prd_i][prd_j] <= {
            4'b0,
            trivium_prd_i[(prd_i*16+8)+:2],
            trivium_prd_i[(prd_i*16+6)+:2],
            trivium_prd_i[(prd_i*16+8)+:6] ^ add_rk_o[0][((prd_i+3)%4)][((prd_j+3)%4)][5:0],
            trivium_prd_i[(prd_i*16+8)+:2],
            trivium_prd_i[(prd_i*16+6)+:2],
            trivium_prd_i[(prd_i*16)+:6] ^ add_rk_o[2][((prd_i+2)%4)][((prd_j+2)%4)][5:0]
          };
        end else begin
          prd_sbox_data[prd_i][prd_j] <= 24'b0;
        end
      end

      assign prd[prd_i][prd_j][0+:24] = prd_sbox_data[prd_i][prd_j][0+:24] & {24{(cs == SBOX1)}};
      assign prd[prd_i][prd_j][24+:18] = prd_sbox_data[prd_i][prd_j][0+:18] & {18{(cs == SBOX2)}};
      assign prd[prd_i][prd_j][42+:20] = prd_sbox_data[prd_i][prd_j][0+:20] & {20{(cs == SBOX3)}};
      assign prd[prd_i][prd_j][62+:40] = {trivium_prd_i[(prd_i*16+8)+:8],
                    add_rk_o[2][(prd_i)][((prd_j+3)%4)][7:4],
                    add_rk_o[1][(prd_i)][((prd_j+2)%4)][7:4],
                    add_rk_o[0][(prd_i)][((prd_j+1)%4)][7:4],
                    
                    trivium_prd_i[(prd_i*16)+:8],
                    add_rk_o[2][(prd_i)][((prd_j+3)%4)][3:0],
                    add_rk_o[1][(prd_i)][((prd_j+2)%4)][3:0],
                    add_rk_o[0][(prd_i)][((prd_j+1)%4)][3:0]} & {40{(cs == SBOX4)}};
    end
  end


  assign prd_key_0 = {
    8'b0,    trivium_prd_i[15:4],    8'b0,    trivium_prd_i[3:0],    rk_o[1][2][2],
    rk_o[0][2][1][5:0],    rk_o[2][2][0],
    rk_o[0][1][2],    rk_o[2][1][1],    rk_o[1][1][0],
    rk_o[2][0][2],    rk_o[1][0][1],    rk_o[0][0][0]
  };

  assign prd_key_1 = {
    8'b0,    trivium_prd_i[31:20],    8'b0,    trivium_prd_i[19:16],    rk_o[1][3][2],
    rk_o[0][3][1][5:0],    rk_o[2][3][0],
    rk_o[0][2][2],    rk_o[2][2][1],    rk_o[1][2][0],
    rk_o[2][1][2],    rk_o[1][1][1],    rk_o[0][1][0]
  };

  assign prd_key_2 = {
    8'b0,    trivium_prd_i[47:36],    8'b0,    trivium_prd_i[35:32],    rk_o[1][0][2],
    rk_o[0][0][1][5:0],    rk_o[2][0][0],
    rk_o[0][3][2],    rk_o[2][3][1],    rk_o[1][3][0],
    rk_o[2][2][2],    rk_o[1][2][1],    rk_o[0][2][0]
  };

  assign prd_key_3 = {
    8'b0,    trivium_prd_i[63:52],    8'b0,    trivium_prd_i[51:48],    rk_o[1][1][2],
    rk_o[0][1][1][5:0],    rk_o[2][1][0],
    rk_o[0][0][2],    rk_o[2][0][1],    rk_o[1][0][0],
    rk_o[2][3][2],    rk_o[1][3][1],    rk_o[0][3][0]
  };


  //-----------------------------------------------------------
  //--------------- STATE AND KEY REGISTERS -------------------
  //-----------------------------------------------------------

  always_comb begin
    state_d = '{default: 0};
    if (cs == INIT) state_d = plain_i;
    else if (cs == INIT_KEY) state_d = '{default: 0};
    else if (cs == INIT_LIN_MAP_RK || cs == ROUND_END) state_d = lin_map_o;
    else if (cs == LAST_ROUND_END) state_d = add_rk_o;
    else state_d = state_q;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= '{default: 0};
    end else begin
      state_q <= state_d;
    end
  end

  assign ct_o = (cs == FINISH || cs == IDLE) ? state_q : '{default: 0};


  always_comb begin
    key_d = '{default: 0};
    if (cs == INIT_KEY) key_d = key_i;
    else if (cs == SBOX4) key_d = rk_o;
    else key_d = key_q;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      key_q <= '{default: 0};
    end else begin
      key_q <= key_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      key_lin_map_q <= '{default: 0};
    end else begin
      key_lin_map_q <= key_lin_map_d;
    end
  end

  //--------------------------------------------------------------
  //--------------------- SBOXES+LINEAR MAPS ---------------------
  //--------------------------------------------------------------


  genvar sbox_i;
  genvar sbox_j;

  assign lin_map_i = add_rk_o;

  for (sbox_i = 0; sbox_i < 4; sbox_i++) begin
    for (sbox_j = 0; sbox_j < 4; sbox_j++) begin
      aes_lin_map lin_map_ij (
        .data_i (lin_map_i[0][sbox_i][sbox_j]),
        .mask0_i(lin_map_i[1][sbox_i][sbox_j]),
        .mask1_i(lin_map_i[2][sbox_i][sbox_j]),
        .data_o (lin_map_o[0][sbox_i][sbox_j]),
        .mask0_o(lin_map_o[1][sbox_i][sbox_j]),
        .mask1_o(lin_map_o[2][sbox_i][sbox_j])
      );

      aes_sbox_dom u_aes_sbox_ij (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),
      .we_i              (we_sbox),
      .in_data_basis_x_q (state_q[0][sbox_i][sbox_j]),
      .in_mask0_basis_x_q(state_q[1][sbox_i][sbox_j]),
      .in_mask1_basis_x_q(state_q[2][sbox_i][sbox_j]),
      .prd_i             (prd[sbox_i][sbox_j]),
      .data_o            (sub_bytes_o[0][sbox_i][sbox_j]),
      .mask0_o           (sub_bytes_o[1][sbox_i][sbox_j]),
      .mask1_o           (sub_bytes_o[2][sbox_i][sbox_j])
      );
    end
  end
  
  //--------------------------------------------------------------
  //--------------------- SHIFT ROWS + MC + ARK ------------------
  //--------------------------------------------------------------

  assign shift_rows_i[0] = sub_bytes_o[0];
  assign shift_rows_i[1] = sub_bytes_o[1];
  assign shift_rows_i[2] = sub_bytes_o[2];

  aes_shift_rows u_aes_shift_rows0 (
      .data_i(shift_rows_i[0]),
      .data_o(shift_rows_o[0])
  );
  aes_shift_rows u_aes_shift_rows1 (
      .data_i(shift_rows_i[1]),
      .data_o(shift_rows_o[1])
  );

  aes_shift_rows u_aes_shift_rows2 (
      .data_i(shift_rows_i[2]),
      .data_o(shift_rows_o[2])
  );

  assign mix_columns_i[0] = shift_rows_o[0];
  assign mix_columns_i[1] = shift_rows_o[1];
  assign mix_columns_i[2] = shift_rows_o[2];

  aes_mix_columns u_aes_mix_columns0 (
      .data_i(mix_columns_i[0]),
      .data_o(mix_columns_o[0])
  );

  aes_mix_columns u_aes_mix_columns1 (
      .data_i(mix_columns_i[1]),
      .data_o(mix_columns_o[1])
  );

  aes_mix_columns u_aes_mix_columns2 (
      .data_i(mix_columns_i[2]),
      .data_o(mix_columns_o[2])
  );

  assign add_rk_i[0] = (cs == INIT_LIN_MAP_RK) ? state_q[0] : (cs == LAST_ROUND_END) ? shift_rows_o[0] : mix_columns_o[0];
  assign add_rk_i[1] = (cs == INIT_LIN_MAP_RK) ? state_q[1] : (cs == LAST_ROUND_END) ? shift_rows_o[1] : mix_columns_o[1];
  assign add_rk_i[2] = (cs == INIT_LIN_MAP_RK) ? state_q[2] : (cs == LAST_ROUND_END) ? shift_rows_o[2] : mix_columns_o[2];

  assign add_rk_o[0] = add_rk_i[0] ^ key_q[0];
  assign add_rk_o[1] = add_rk_i[1] ^ key_q[1];
  assign add_rk_o[2] = add_rk_i[2] ^ key_q[2];

  //--------------------------------------------------------------
  //--------------------- KEY SCHEDULE----------------------------
  //--------------------------------------------------------------

  genvar key_j;

  for(key_j = 0; key_j < 4; key_j ++) begin
    assign key_lin_map_i[0][key_j] = (cs == INIT) ? key_q[0][key_j][3] : rk_o[0][key_j][3];
    assign key_lin_map_i[1][key_j] = (cs == INIT) ? key_q[1][key_j][3] : rk_o[1][key_j][3];
    assign key_lin_map_i[2][key_j] = (cs == INIT) ? key_q[2][key_j][3] : rk_o[2][key_j][3];

      aes_lin_map key_lin_map_j (
      .data_i (key_lin_map_i[0][key_j]),
      .mask0_i(key_lin_map_i[1][key_j]),
      .mask1_i(key_lin_map_i[2][key_j]),
      .data_o (key_lin_map_d[0][key_j]),
      .mask0_o(key_lin_map_d[1][key_j]),
      .mask1_o(key_lin_map_d[2][key_j])
    );

    aes_sbox_dom key_sbox_j (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),
      .we_i              (we_key_sbox),
      .in_data_basis_x_q (key_lin_map_q[0][key_j]),
      .in_mask0_basis_x_q(key_lin_map_q[1][key_j]),
      .in_mask1_basis_x_q(key_lin_map_q[2][key_j]),
      .prd_i             (prd_key_0),
      .data_o            (key_sub_bytes_o[0][key_j]),
      .mask0_o           (key_sub_bytes_o[1][key_j]),
      .mask1_o           (key_sub_bytes_o[2][key_j])
  );

  end


  assign w0[0][0] = key_q[0][0][0];
  assign w0[1][0] = key_q[1][0][0];
  assign w0[2][0] = key_q[2][0][0];

  assign w0[0][1] = key_q[0][1][0];
  assign w0[1][1] = key_q[1][1][0];
  assign w0[2][1] = key_q[2][1][0];

  assign w0[0][2] = key_q[0][2][0];
  assign w0[1][2] = key_q[1][2][0];
  assign w0[2][2] = key_q[2][2][0];

  assign w0[0][3] = key_q[0][3][0];
  assign w0[1][3] = key_q[1][3][0];
  assign w0[2][3] = key_q[2][3][0];



  assign w1[0][0] = key_q[0][0][1];
  assign w1[1][0] = key_q[1][0][1];
  assign w1[2][0] = key_q[2][0][1];

  assign w1[0][1] = key_q[0][1][1];
  assign w1[1][1] = key_q[1][1][1];
  assign w1[2][1] = key_q[2][1][1];

  assign w1[0][2] = key_q[0][2][1];
  assign w1[1][2] = key_q[1][2][1];
  assign w1[2][2] = key_q[2][2][1];

  assign w1[0][3] = key_q[0][3][1];
  assign w1[1][3] = key_q[1][3][1];
  assign w1[2][3] = key_q[2][3][1];



  assign w2[0][0] = key_q[0][0][2];
  assign w2[1][0] = key_q[1][0][2];
  assign w2[2][0] = key_q[2][0][2];

  assign w2[0][1] = key_q[0][1][2];
  assign w2[1][1] = key_q[1][1][2];
  assign w2[2][1] = key_q[2][1][2];

  assign w2[0][2] = key_q[0][2][2];
  assign w2[1][2] = key_q[1][2][2];
  assign w2[2][2] = key_q[2][2][2];

  assign w2[0][3] = key_q[0][3][2];
  assign w2[1][3] = key_q[1][3][2];
  assign w2[2][3] = key_q[2][3][2];



  assign w3[0][0] = key_q[0][0][3];
  assign w3[1][0] = key_q[1][0][3];
  assign w3[2][0] = key_q[2][0][3];

  assign w3[0][1] = key_q[0][1][3];
  assign w3[1][1] = key_q[1][1][3];
  assign w3[2][1] = key_q[2][1][3];

  assign w3[0][2] = key_q[0][2][3];
  assign w3[1][2] = key_q[1][2][3];
  assign w3[2][2] = key_q[2][2][3];

  assign w3[0][3] = key_q[0][3][3];
  assign w3[1][3] = key_q[1][3][3];
  assign w3[2][3] = key_q[2][3][3];


  assign w3_transformed[0] = {
    key_sub_bytes_o[0][0],
    key_sub_bytes_o[0][3],
    key_sub_bytes_o[0][2],
    key_sub_bytes_o[0][1] ^ rcon_q
  };
  assign w3_transformed[1] = {
    key_sub_bytes_o[1][0], key_sub_bytes_o[1][3], key_sub_bytes_o[1][2], key_sub_bytes_o[1][1]
  };
  assign w3_transformed[2] = {
    key_sub_bytes_o[2][0], key_sub_bytes_o[2][3], key_sub_bytes_o[2][2], key_sub_bytes_o[2][1]
  };


  assign w4[0] = w0[0] ^ w3_transformed[0];
  assign w5[0] = w4[0] ^ w1[0];
  assign w6[0] = w5[0] ^ w2[0];
  assign w7[0] = w6[0] ^ w3[0];

  assign w4[1] = w0[1] ^ w3_transformed[1];
  assign w5[1] = w4[1] ^ w1[1];
  assign w6[1] = w5[1] ^ w2[1];
  assign w7[1] = w6[1] ^ w3[1];

  assign w4[2] = w0[2] ^ w3_transformed[2];
  assign w5[2] = w4[2] ^ w1[2];
  assign w6[2] = w5[2] ^ w2[2];
  assign w7[2] = w6[2] ^ w3[2];




  assign rk_o[0][0] = {w7[0][0], w6[0][0], w5[0][0], w4[0][0]};
  assign rk_o[0][1] = {w7[0][1], w6[0][1], w5[0][1], w4[0][1]};
  assign rk_o[0][2] = {w7[0][2], w6[0][2], w5[0][2], w4[0][2]};
  assign rk_o[0][3] = {w7[0][3], w6[0][3], w5[0][3], w4[0][3]};

  assign rk_o[1][0] = {w7[1][0], w6[1][0], w5[1][0], w4[1][0]};
  assign rk_o[1][1] = {w7[1][1], w6[1][1], w5[1][1], w4[1][1]};
  assign rk_o[1][2] = {w7[1][2], w6[1][2], w5[1][2], w4[1][2]};
  assign rk_o[1][3] = {w7[1][3], w6[1][3], w5[1][3], w4[1][3]};

  assign rk_o[2][0] = {w7[2][0], w6[2][0], w5[2][0], w4[2][0]};
  assign rk_o[2][1] = {w7[2][1], w6[2][1], w5[2][1], w4[2][1]};
  assign rk_o[2][2] = {w7[2][2], w6[2][2], w5[2][2], w4[2][2]};
  assign rk_o[2][3] = {w7[2][3], w6[2][3], w5[2][3], w4[2][3]};


  //-----------------------------------------------------------
  //--------------- STATE MACHINE + CONTROL LOGIC -------------
  //-----------------------------------------------------------

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cs        <= IDLE;
      round_ctr <= 0;
    end else begin
      cs <= ns;
      if (cs == ROUND_END) begin
        round_ctr <= round_ctr + 1;
      end else if (cs == INIT) round_ctr <= 0;
    end
  end

  always_comb begin
    ns        = cs;
    busy_o    = (cs != IDLE);
    case (cs)
      IDLE:            ns = start_i ? INIT_KEY : IDLE;
      INIT_KEY:        ns = INIT;
      INIT:            ns = INIT_LIN_MAP_RK;
      INIT_LIN_MAP_RK: ns = SBOX1;
      SBOX1:           ns = SBOX2;
      SBOX2:           ns = SBOX3;
      SBOX3:           ns = SBOX4;
      SBOX4:           ns = (round_ctr == 9) ? LAST_ROUND_END : ROUND_END;
      ROUND_END:       ns = SBOX1;
      LAST_ROUND_END:  ns = FINISH;
      FINISH:          ns = IDLE;
      default:         ns = ERROR;
    endcase
  end

  always_comb begin
    we_sbox[0] = (cs == SBOX1);
    we_sbox[1] = (cs == SBOX2);
    we_sbox[2] = (cs == SBOX3);
    we_sbox[3] = (cs == SBOX4);
  end

  always_comb begin
    we_key_sbox[0] = (cs == INIT_LIN_MAP_RK) || (cs == ROUND_END);
    we_key_sbox[1] = (cs == SBOX1);
    we_key_sbox[2] = (cs == SBOX2);
    we_key_sbox[3] = (cs == SBOX3);
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) rcon_q <= 8'b01;
    else if (cs == IDLE) rcon_q <= 8'b01;
    else if (cs == ROUND_END) rcon_q <= rcon_d;
  end

  always_comb begin
    rcon_d[7] = rcon_q[6];
    rcon_d[6] = rcon_q[5];
    rcon_d[5] = rcon_q[4];
    rcon_d[4] = rcon_q[3] ^ rcon_q[7];
    rcon_d[3] = rcon_q[2] ^ rcon_q[7];
    rcon_d[2] = rcon_q[1];
    rcon_d[1] = rcon_q[0] ^ rcon_q[7];
    rcon_d[0] = rcon_q[7];
  end




endmodule
