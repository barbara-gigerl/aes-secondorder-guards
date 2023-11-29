`ifdef YOSYS
`include "aes_pkg_verilog.sv"
`endif
module aes_dom_indep_mul_gf2pn #(
    parameter int unsigned NPower = 2
) (
    input logic clk_i,
    input logic rst_ni,
    input logic we_i,

    input logic [NPower-1:0] A0,
    input logic [NPower-1:0] B0,
    input logic [NPower-1:0] A1,
    input logic [NPower-1:0] B1,
    input logic [NPower-1:0] A2,
    input logic [NPower-1:0] B2,

    input logic [NPower-1:0] Z0,
    input logic [NPower-1:0] Z1,
    input logic [NPower-1:0] Z2,
    input logic [NPower-1:0] Z3,
    input logic [NPower-1:0] Z4,
    input logic [NPower-1:0] Z5,

    input logic [NPower-1:0] Y0,
    input logic [NPower-1:0] Y1,
    input logic [NPower-1:0] Y2,

    input logic [NPower-1:0] SS_P0,
    input logic [NPower-1:0] SS_P1,
    input logic [NPower-1:0] SS_P2,

    output logic [NPower-1:0] C0,
    output logic [NPower-1:0] C1,
    output logic [NPower-1:0] C2
);

  //-----------------------------------------------------------------------------

  // DOMAIN 0
  logic [NPower-1:0] A0_B0_d, A0_B0_q;
  logic [NPower-1:0] A0_B1_d, A0_B1_q;
  logic [NPower-1:0] A0_B2_d, A0_B2_q;
  logic [NPower-1:0] A0_x_B0, A0_x_B1, A0_x_B2;

  if (NPower == 4) begin
    assign A0_x_B0 = aes_mul_gf2p4(A0, B0);
    assign A0_x_B1 = aes_mul_gf2p4(A0, B1);
    assign A0_x_B2 = aes_mul_gf2p4(A0, B2);
  end else begin
    assign A0_x_B0 = aes_mul_gf2p2(A0, B0);
    assign A0_x_B1 = aes_mul_gf2p2(A0, B1);
    assign A0_x_B2 = aes_mul_gf2p2(A0, B2);
  end

  assign A0_B0_d = A0_x_B0 ^ Y0 ^ Y1 ^ SS_P0;
  assign A0_B1_d = A0_x_B1 ^ Z0 ^ Z3;
  assign A0_B2_d = A0_x_B2 ^ Z1 ^ Z5;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A0_B0_q <= {NPower{1'b0}};
      A0_B1_q <= {NPower{1'b0}};
      A0_B2_q <= {NPower{1'b0}};
    end else begin
      A0_B0_q <= (A0_B0_d & {NPower{we_i}}) | (A0_B0_q & {NPower{~we_i}});
      A0_B1_q <= (A0_B1_d & {NPower{we_i}}) | (A0_B1_q & {NPower{~we_i}});
      A0_B2_q <= (A0_B2_d & {NPower{we_i}}) | (A0_B2_q & {NPower{~we_i}});
    end
  end

  //-----------------------------------------------------------------------------

  // DOMAIN 1
  logic [NPower-1:0] A1_B0_d, A1_B0_q;
  logic [NPower-1:0] A1_B1_d, A1_B1_q;
  logic [NPower-1:0] A1_B2_d, A1_B2_q;
  logic [NPower-1:0] A1_x_B0, A1_x_B1, A1_x_B2;

  if (NPower == 4) begin
    assign A1_x_B0 = aes_mul_gf2p4(A1, B0);
    assign A1_x_B1 = aes_mul_gf2p4(A1, B1);
    assign A1_x_B2 = aes_mul_gf2p4(A1, B2);
  end else begin
    assign A1_x_B0 = aes_mul_gf2p2(B0, A1);
    assign A1_x_B1 = aes_mul_gf2p2(A1, B1);
    assign A1_x_B2 = aes_mul_gf2p2(A1, B2);
  end

  assign A1_B0_d = A1_x_B0 ^ Z0 ^ Z4;
  assign A1_B1_d = A1_x_B1 ^ Y1 ^ Y2 ^ SS_P1;
  assign A1_B2_d = A1_x_B2 ^ Z2 ^ Z5;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A1_B0_q <= {NPower{1'b0}};
      A1_B1_q <= {NPower{1'b0}};
      A1_B2_q <= {NPower{1'b0}};
    end else begin
      A1_B0_q <= (A1_B0_d & {NPower{we_i}}) | (A1_B0_q & {NPower{~we_i}});
      A1_B1_q <= (A1_B1_d & {NPower{we_i}}) | (A1_B1_q & {NPower{~we_i}});
      A1_B2_q <= (A1_B2_d & {NPower{we_i}}) | (A1_B2_q & {NPower{~we_i}});
    end
  end


  //-----------------------------------------------------------------------------

  // DOMAIN 2
  logic [NPower-1:0] A2_B0_d, A2_B0_q;
  logic [NPower-1:0] A2_B1_d, A2_B1_q;
  logic [NPower-1:0] A2_B2_d, A2_B2_q;

  logic [NPower-1:0] A2_x_B0, A2_x_B1, A2_x_B2;

  if (NPower == 4) begin
    assign A2_x_B0 = aes_mul_gf2p4(A2, B0);
    assign A2_x_B1 = aes_mul_gf2p4(A2, B1);
    assign A2_x_B2 = aes_mul_gf2p4(A2, B2);
  end else begin
    assign A2_x_B0 = aes_mul_gf2p2(B0, A2);
    assign A2_x_B1 = aes_mul_gf2p2(B1, A2);
    assign A2_x_B2 = aes_mul_gf2p2(A2, B2);
  end

  assign A2_B0_d = A2_x_B0 ^ Z1 ^ Z3;
  assign A2_B1_d = A2_x_B1 ^ Z2 ^ Z4;
  assign A2_B2_d = A2_x_B2 ^ Y0 ^ Y2 ^ SS_P2;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      A2_B0_q <= {NPower{1'b0}};
      A2_B1_q <= {NPower{1'b0}};
      A2_B2_q <= {NPower{1'b0}};
    end else begin
      A2_B2_q <= (A2_B2_d & {NPower{we_i}}) | (A2_B2_q & {NPower{~we_i}});
      A2_B0_q <= (A2_B0_d & {NPower{we_i}}) | (A2_B0_q & {NPower{~we_i}});
      A2_B1_q <= (A2_B1_d & {NPower{we_i}}) | (A2_B1_q & {NPower{~we_i}});
    end
  end

  /////////////////
  // Integration //
  /////////////////
  assign C0 = A0_B0_q ^ A0_B1_q ^ A0_B2_q;
  assign C1 = A1_B1_q ^ A1_B0_q ^ A1_B2_q;
  assign C2 = A2_B2_q ^ A2_B0_q ^ A2_B1_q;


endmodule
