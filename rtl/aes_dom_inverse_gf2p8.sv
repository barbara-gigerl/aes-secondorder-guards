module aes_dom_inverse_gf2p8 (
    input logic clk_i,
    input logic rst_ni,
    input logic [3:0] we_i,
    input logic [7:0] P0,
    input logic [7:0] P1,
    input logic [7:0] P2,
    input logic [23:0] prd_stage1,
    input logic [17:0] prd_stage2,
    input logic [9:0] prd_stage3A,
    input logic [9:0] prd_stage3B,
    input logic [19:0] prd_stage4A,
    input logic [19:0] prd_stage4B,
    output logic [7:0] P0_inv,
    output logic [7:0] P1_inv,
    output logic [7:0] P2_inv
);



  //-------------------------------------------------------------------
  //------------------- Stage 1 ---------------------------------------
  //-------------------------------------------------------------------

  logic [3:0] A0, A1, A2, B0, B1, B2;
  logic [3:0] A0_q, A1_q, A2_q, B0_q, B1_q, B2_q;
  assign A0 = P0[7:4];
  assign B0 = P0[3:0];
  assign A1 = P1[7:4];
  assign B1 = P1[3:0];
  assign A2 = P2[7:4];
  assign B2 = P2[3:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A0_q <= 0;
      A1_q <= 0;
      A2_q <= 0;
      B0_q <= 0;
      B1_q <= 0;
      B2_q <= 0;
    end else if (we_i[0]) begin
      A0_q <= A0;
      A1_q <= A1;
      A2_q <= A2;
      B0_q <= B0;
      B1_q <= B1;
      B2_q <= B2;
    end
  end

  //------------------- SQUARE SCALER Stage 1 -------------------------
  logic [3:0] SS1_P0_in;
  logic [1:0] SS1_P0_tmp0;
  logic [1:0] SS1_P0_tmp1;
  logic [3:0] SS1_P0_out;
  logic [3:0] SS1_P0_out_q;

  assign SS1_P0_in = A0 ^ B0;
  assign SS1_P0_tmp0 = SS1_P0_in[3:2] ^ SS1_P0_in[1:0];

  assign SS1_P0_tmp1[1] = SS1_P0_in[0];
  assign SS1_P0_tmp1[0] = SS1_P0_in[1];

  assign SS1_P0_out[3] = SS1_P0_tmp0[0];
  assign SS1_P0_out[2] = SS1_P0_tmp0[1];

  assign SS1_P0_out[1] = SS1_P0_tmp1[1] ^ SS1_P0_tmp1[0];
  assign SS1_P0_out[0] = SS1_P0_tmp1[1];


  logic [3:0] SS1_P1_in;
  logic [1:0] SS1_P1_tmp0;
  logic [1:0] SS1_P1_tmp1;
  logic [3:0] SS1_P1_out;
  logic [3:0] SS1_P1_out_q;

  assign SS1_P1_in      = A1 ^ B1;
  assign SS1_P1_tmp0    = SS1_P1_in[3:2] ^ SS1_P1_in[1:0];
  assign SS1_P1_tmp1[1] = SS1_P1_in[0];
  assign SS1_P1_tmp1[0] = SS1_P1_in[1];
  assign SS1_P1_out[3]  = SS1_P1_tmp0[0];
  assign SS1_P1_out[2]  = SS1_P1_tmp0[1];
  assign SS1_P1_out[1]  = SS1_P1_tmp1[1] ^ SS1_P1_tmp1[0];
  assign SS1_P1_out[0]  = SS1_P1_tmp1[1];


  logic [3:0] SS1_P2_in;
  logic [1:0] SS1_P2_tmp0;
  logic [1:0] SS1_P2_tmp1;
  logic [3:0] SS1_P2_out;

  assign SS1_P2_in      = A2 ^ B2;
  assign SS1_P2_tmp0    = SS1_P2_in[3:2] ^ SS1_P2_in[1:0];
  assign SS1_P2_tmp1[1] = SS1_P2_in[0];
  assign SS1_P2_tmp1[0] = SS1_P2_in[1];
  assign SS1_P2_out[3]  = SS1_P2_tmp0[0];
  assign SS1_P2_out[2]  = SS1_P2_tmp0[1];
  assign SS1_P2_out[1]  = SS1_P2_tmp1[1] ^ SS1_P2_tmp1[0];
  assign SS1_P2_out[0]  = SS1_P2_tmp1[1];

  //------------------- SQUARE SCALER Stage 1 end -------------------------
  //------------------- Multiplier Stage 1 -------------------------

  logic [3:0] indep1_C0, indep1_C1, indep1_C2;

  aes_dom_indep_mul_gf2pn #(
      .NPower(4)
  ) indep1 (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[0]),

      .A0(A0),
      .B0(B0),
      .A1(A1),
      .B1(B1),
      .A2(A2),
      .B2(B2),

      .SS_P0(SS1_P0_out),
      .SS_P1(SS1_P1_out),
      .SS_P2(SS1_P2_out),


      .Z0(prd_stage1[3:0]),
      .Z1(prd_stage1[7:4]),
      .Z2(prd_stage1[11:8]),
      .Z3(prd_stage1[15:12]),
      .Z4(4'b0),
      .Z5(4'b0),
      .Y0(prd_stage1[19:16]),
      .Y1(prd_stage1[23:20]),
      .Y2(4'b0),

      .C0(indep1_C0),
      .C1(indep1_C1),
      .C2(indep1_C2)
  );

  //logic [3:0] dbg_stage1 = indep1_C0 ^ indep1_C1 ^ indep1_C2;
  //------------------- Multiplier Stage 1 end -------------------------

  //-------------------------------------------------------------------
  //------------------- Stage 1 end -----------------------------------
  //-------------------------------------------------------------------
  //-------------------------------------------------------------------
  //------------------- Stage 2 ---------------------------------------
  //-------------------------------------------------------------------

  logic [3:0] A0_qq, A1_qq, A2_qq, B0_qq, B1_qq, B2_qq;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A0_qq <= 0;
      A1_qq <= 0;
      A2_qq <= 0;
      B0_qq <= 0;
      B1_qq <= 0;
      B2_qq <= 0;
    end else if (we_i[1]) begin
      A0_qq <= A0_q;
      A1_qq <= A1_q;
      A2_qq <= A2_q;
      B0_qq <= B0_q;
      B1_qq <= B1_q;
      B2_qq <= B2_q;
    end
  end


  logic [1:0]
      indep1_C0_msb, indep1_C0_lsb, indep1_C1_msb, indep1_C1_lsb, indep1_C2_msb, indep1_C2_lsb;
  logic [1:0]
      indep1_C0_msb_q,
      indep1_C0_lsb_q,
      indep1_C1_msb_q,
      indep1_C1_lsb_q,
      indep1_C2_msb_q,
      indep1_C2_lsb_q;

  assign indep1_C0_msb = indep1_C0[3:2];
  assign indep1_C0_lsb = indep1_C0[1:0];
  assign indep1_C1_msb = indep1_C1[3:2];
  assign indep1_C1_lsb = indep1_C1[1:0];
  assign indep1_C2_msb = indep1_C2[3:2];
  assign indep1_C2_lsb = indep1_C2[1:0];


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      indep1_C0_msb_q <= 0;
      indep1_C0_lsb_q <= 0;
      indep1_C1_msb_q <= 0;
      indep1_C1_lsb_q <= 0;
      indep1_C2_msb_q <= 0;
      indep1_C2_lsb_q <= 0;
    end else if (we_i[1]) begin
      indep1_C0_msb_q <= indep1_C0_msb;
      indep1_C0_lsb_q <= indep1_C0_lsb;
      indep1_C1_msb_q <= indep1_C1_msb;
      indep1_C1_lsb_q <= indep1_C1_lsb;
      indep1_C2_msb_q <= indep1_C2_msb;
      indep1_C2_lsb_q <= indep1_C2_lsb;
    end
  end
  //------------------- SQUARE SCALER Stage 2 -------------------------
  logic [1:0] SS2_P0_in;
  logic [1:0] SS2_P0_tmp0;
  logic [1:0] SS2_P0_out;
  assign SS2_P0_in      = indep1_C0_msb ^ indep1_C0_lsb;
  assign SS2_P0_tmp0[1] = SS2_P0_in[0];
  assign SS2_P0_tmp0[0] = SS2_P0_in[1];
  assign SS2_P0_out[1]  = SS2_P0_tmp0[0];
  assign SS2_P0_out[0]  = SS2_P0_tmp0[1] ^ SS2_P0_tmp0[0];

  logic [1:0] SS2_P1_in;
  logic [1:0] SS2_P1_out;
  logic [1:0] SS2_P1_tmp0;
  assign SS2_P1_in      = indep1_C1_msb ^ indep1_C1_lsb;
  assign SS2_P1_tmp0[1] = SS2_P1_in[0];
  assign SS2_P1_tmp0[0] = SS2_P1_in[1];
  assign SS2_P1_out[1]  = SS2_P1_tmp0[0];
  assign SS2_P1_out[0]  = SS2_P1_tmp0[1] ^ SS2_P1_tmp0[0];

  logic [1:0] SS2_P2_in;
  logic [1:0] SS2_P2_out;
  logic [1:0] SS2_P2_tmp0;
  assign SS2_P2_in      = indep1_C2_msb ^ indep1_C2_lsb;
  assign SS2_P2_tmp0[1] = SS2_P2_in[0];
  assign SS2_P2_tmp0[0] = SS2_P2_in[1];
  assign SS2_P2_out[1]  = SS2_P2_tmp0[0];
  assign SS2_P2_out[0]  = SS2_P2_tmp0[1] ^ SS2_P2_tmp0[0];

  //------------------- SQUARE SCALER Stage 2 end ---------------------
  //------------------- Multiplier Stage 2 -------------------------


  logic [1:0] indep2_C0, indep2_C1, indep2_C2;
  logic [1:0] alpha0, alpha1, alpha2, beta0, beta1, beta2;
  assign alpha0 = indep1_C0[3:2];
  assign alpha1 = indep1_C1[3:2];
  assign alpha2 = indep1_C2[3:2];
  assign beta0  = indep1_C0[1:0];
  assign beta1  = indep1_C1[1:0];
  assign beta2  = indep1_C2[1:0];

  aes_dom_indep_mul_gf2pn #(
      .NPower(2)
  ) indep2 (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[1]),

      .A0(alpha0),
      .B0(beta0),
      .A1(alpha1),
      .B1(beta1),
      .A2(alpha2),
      .B2(beta2),

      .SS_P0(SS2_P0_out),
      .SS_P1(SS2_P1_out),
      .SS_P2(SS2_P2_out),

      .Z0(prd_stage2[1:0]),
      .Z1(prd_stage2[3:2]),
      .Z2(prd_stage2[5:4]),
      .Z3(prd_stage2[7:6]),
      .Z4(prd_stage2[9:8]),
      .Z5(prd_stage2[11:10]),
      .Y0(prd_stage2[13:12]),
      .Y1(prd_stage2[15:14]),
      .Y2(prd_stage2[17:16]),
      .C0(indep2_C0),
      .C1(indep2_C1),
      .C2(indep2_C2)
  );

  //------------------- Multiplier Stage 2 end ------------------------
  //-------------------------------------------------------------------
  //------------------- Stage 2 end -----------------------------------
  //-------------------------------------------------------------------

  //-------------------------------------------------------------------
  //------------------- Stage 3 ---------------------------------------
  //-------------------------------------------------------------------

  logic [3:0] A0_qqq, A1_qqq, A2_qqq, B0_qqq, B1_qqq, B2_qqq;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A0_qqq <= 0;
      A1_qqq <= 0;
      A2_qqq <= 0;
      B0_qqq <= 0;
      B1_qqq <= 0;
      B2_qqq <= 0;
    end else if (we_i[2]) begin
      A0_qqq <= A0_qq;
      A1_qqq <= A1_qq;
      A2_qqq <= A2_qq;
      B0_qqq <= B0_qq;
      B1_qqq <= B1_qq;
      B2_qqq <= B2_qq;
    end
  end

  //------------------- Inverter Stage 3 -------------------------
  logic [1:0] inv_indep1_C0_in;
  logic [1:0] inv_indep1_C0_out;
  assign inv_indep1_C0_in     = indep2_C0;
  assign inv_indep1_C0_out[1] = inv_indep1_C0_in[0];
  assign inv_indep1_C0_out[0] = inv_indep1_C0_in[1];

  logic [1:0] inv_indep1_C1_in;
  logic [1:0] inv_indep1_C1_out;
  assign inv_indep1_C1_in     = indep2_C1;
  assign inv_indep1_C1_out[1] = inv_indep1_C1_in[0];
  assign inv_indep1_C1_out[0] = inv_indep1_C1_in[1];

  logic [1:0] inv_indep1_C2_in;
  logic [1:0] inv_indep1_C2_out;
  assign inv_indep1_C2_in     = indep2_C2;
  assign inv_indep1_C2_out[1] = inv_indep1_C2_in[0];
  assign inv_indep1_C2_out[0] = inv_indep1_C2_in[1];
  //------------------- Inverter Stage 3 end -------------------------
  //------------------- Multiplier Stage 3 -------------------------
  logic [3:0] indep3_C0;
  logic [3:0] indep3_C1;
  logic [3:0] indep3_C2;
  aes_dom_indep_mul_gf2pn #(
      .NPower(2)
  ) indep3A (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[2]),
      .A0    (indep1_C0_msb_q),
      .A1    (indep1_C1_msb_q),
      .A2    (indep1_C2_msb_q),
      .B0    (inv_indep1_C0_out),
      .B1    (inv_indep1_C1_out),
      .B2    (inv_indep1_C2_out),

      .SS_P0(2'b0),
      .SS_P1(2'b0),
      .SS_P2(2'b0),

      .Z0(prd_stage3A[1:0]),
      .Z1(prd_stage3A[3:2]),
      .Z2(prd_stage3A[5:4]),
      .Z3(2'b0),
      .Z4(2'b0),
      .Z5(2'b0),

      .Y0(prd_stage3A[7:6]),
      .Y1(prd_stage3A[9:8]),
      .Y2(2'b0),
      .C0(indep3_C0[1:0]),
      .C1(indep3_C1[1:0]),
      .C2(indep3_C2[1:0])
  );


  aes_dom_indep_mul_gf2pn #(
      .NPower(2)
  ) indep3B (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[2]),

      .A0(inv_indep1_C0_out),
      .A1(inv_indep1_C1_out),
      .A2(inv_indep1_C2_out),

      .B0(indep1_C0_lsb_q),
      .B1(indep1_C1_lsb_q),
      .B2(indep1_C2_lsb_q),

      .SS_P0(2'b0),
      .SS_P1(2'b0),
      .SS_P2(2'b0),

      .Z0(prd_stage3B[1:0]),
      .Z1(prd_stage3B[3:2]),
      .Z2(prd_stage3B[5:4]),
      .Z3(2'b0),
      .Z4(2'b0),
      .Z5(2'b0),
      .Y0(prd_stage3B[7:6]),
      .Y1(prd_stage3B[9:8]),
      .Y2(2'b0),

      .C0(indep3_C0[3:2]),
      .C1(indep3_C1[3:2]),
      .C2(indep3_C2[3:2])

  );


  //------------------- Multiplier Stage 3 end -------------------------
  //-------------------------------------------------------------------
  //------------------- Stage 3 end -----------------------------------
  //-------------------------------------------------------------------


  //-------------------------------------------------------------------
  //------------------- Stage 4 ---------------------------------------
  //-------------------------------------------------------------------
  //------------------- Multiplier Stage 4 -------------------------

  aes_dom_indep_mul_gf2pn #(
      .NPower(4)
  ) indep4A (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[3]),
      .A0    (A0_qqq),
      .B0    (indep3_C0),
      .A1    (A1_qqq),
      .B1    (indep3_C1),
      .A2    (A2_qqq),
      .B2    (indep3_C2),

      .SS_P0(4'b0),
      .SS_P1(4'b0),
      .SS_P2(4'b0),

      .Z0(prd_stage4A[3:0]),
      .Z1(prd_stage4A[7:4]),
      .Z2(prd_stage4A[11:8]),
      .Z3(4'b0),
      .Z4(4'b0),
      .Z5(4'b0),
      .Y0(prd_stage4A[15:12]),
      .Y1(prd_stage4A[19:16]),
      .Y2(4'b0),
      .C0(P0_inv[3:0]),
      .C1(P1_inv[3:0]),
      .C2(P2_inv[3:0])
  );

  aes_dom_indep_mul_gf2pn #(
      .NPower(4)
  ) indep4B (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .we_i  (we_i[3]),
      .A0    (indep3_C0),
      .B0    (B0_qqq),
      .A1    (indep3_C1),
      .B1    (B1_qqq),
      .A2    (indep3_C2),
      .B2    (B2_qqq),

      .SS_P0(4'b0),
      .SS_P1(4'b0),
      .SS_P2(4'b0),


      .Z0(prd_stage4B[3:0]),
      .Z1(prd_stage4B[7:4]),
      .Z2(prd_stage4B[11:8]),
      .Z3(4'b0),
      .Z4(4'b0),
      .Z5(4'b0),
      .Y0(prd_stage4B[15:12]),
      .Y1(prd_stage4B[19:16]),
      .Y2(4'b0),
      .C0(P0_inv[7:4]),
      .C1(P1_inv[7:4]),
      .C2(P2_inv[7:4])
  );

  //------------------- Multiplier Stage 4 end -------------------------
  //-------------------------------------------------------------------
  //------------------- Stage 4 end -----------------------------------
  //-------------------------------------------------------------------

endmodule
