`ifdef YOSYS
`include "aes_pkg_verilog.sv"
`endif
module top #(
    parameter int unsigned NumShares = 3
) (
    input clk_i,
    input rst_ni,
    input start_i,
    input trivium_reseed_i,
    output logic busy_o,

    input  logic [3:0][3:0][7:0] aes_key_i  [NumShares],
    input  logic [3:0][3:0][7:0] aes_plain_i[NumShares],
    output logic [3:0][3:0][7:0] aes_ct_o   [NumShares],

    input logic [79:0] trivium_key_i,
    input logic [79:0] trivium_iv_i

);

  logic [63:0]           trivium_prd;
  logic                  trivium_reseed;
  logic                  trivium_req;
  logic                  trivium_valid;

  logic                  aes_start;
  logic                  aes_busy;

  logic [ 2:0]           cs;
  logic [ 2:0]           ns;



  logic [ 3:0][3:0][7:0] aes_key_q      [NumShares];
  logic [ 3:0][3:0][7:0] aes_plain_q    [NumShares];
  logic [ 3:0][3:0][7:0] aes_ct_q       [NumShares];
  logic [ 3:0][3:0][7:0] aes_ct_d       [NumShares];


  trivium_rng rng (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .reseed_i(trivium_reseed),
      .key_i(trivium_key_i),
      .iv_i(trivium_iv_i),
      .req_i(trivium_req),
      .valid_o(trivium_valid),
      .prd_o(trivium_prd)
  );



  assign aes_start = (cs == OUTER_WAIT_AES);
  aes_top aes (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .start_i(aes_start),
      .busy_o(aes_busy),
      .key_i(aes_key_q),
      .plain_i(aes_plain_q),
      .ct_o(aes_ct_d),
      .trivium_prd_i(trivium_prd)
  );







  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cs <= OUTER_IDLE;
    end else begin
      cs <= ns;
    end
  end


  always_comb begin
    ns = cs;
    busy_o = (cs != OUTER_IDLE);

    case (cs)
      OUTER_IDLE: ns = trivium_reseed_i ? OUTER_INIT_TRIVIUM : start_i ? OUTER_INIT : OUTER_IDLE;
      OUTER_INIT_TRIVIUM: ns = OUTER_HEATUP_RNG;
      OUTER_INIT: ns = OUTER_WAIT_AES;
      OUTER_HEATUP_RNG: ns = trivium_valid ? OUTER_IDLE : OUTER_HEATUP_RNG;
      OUTER_WAIT_AES: ns = OUTER_AES_ROUND;
      OUTER_AES_ROUND: ns = (!aes_busy) ? OUTER_AES_FINISH : OUTER_AES_ROUND;
      OUTER_AES_FINISH: ns = OUTER_IDLE;
      default: ns = OUTER_IDLE;
    endcase
  end

  always_comb begin
    trivium_reseed = 0;
    trivium_req = 0;
    if (cs == OUTER_INIT_TRIVIUM) begin
      trivium_reseed = 1;
      trivium_req = 1;
    end else if (cs == OUTER_HEATUP_RNG || cs == OUTER_WAIT_AES || cs == OUTER_AES_ROUND) begin
      trivium_req = 1;
    end
  end



  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      aes_key_q <= '{default: 0};
      aes_plain_q <= '{default: 0};
      aes_ct_q <= '{default: 0};
    end else if (cs == OUTER_AES_FINISH) begin
      aes_key_q   <= '{default: 0};
      aes_plain_q <= '{default: 0};
      aes_ct_q <= aes_ct_d;
    end else if (cs == OUTER_INIT) begin
      aes_key_q   <= aes_key_i;
      aes_plain_q <= aes_plain_i;
    end
  end

  assign aes_ct_o = aes_ct_q;


endmodule
