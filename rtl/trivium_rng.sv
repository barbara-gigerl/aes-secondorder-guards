module trivium_rng #(
    parameter NBITS = 64
) (
    input clk_i,
    input rst_ni,
    input reseed_i,
    input [79:0] key_i,
    input [79:0] iv_i,
    input req_i,
    output valid_o,
    output [63:0] prd_o
);

  logic valid_q;
  logic [4:0] valid_wait_q;
  logic [287:0] state_init;
  logic [287:0] state_q;
  logic [63:0] prd_q;
  logic [63:0] t1;
  logic [63:0] t2;
  logic [63:0] t3;

  logic [63:0] t1_upd;
  logic [63:0] t2_upd;
  logic [63:0] t3_upd;

  integer m;
  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin
      valid_q <= 0;
      valid_wait_q <= 0;
      state_q <= state_init;
    end else begin

      if (valid_wait_q == 18) valid_q <= 1;

      if (valid_q == 0) valid_wait_q <= (valid_wait_q + 1);

      if (reseed_i) begin
        state_q <= state_init;
        valid_wait_q <= 0;
        valid_q <= 0;
      end else if (req_i || !valid_q) begin

        for (m = 0; m < 64; m++) begin
          prd_q[64-1-m] <= t1[m] ^ t2[m] ^ t3[m];
        end
        state_q[92:0] <= {state_q[93-1-NBITS:0], t3_upd};
        state_q[176:93] <= {state_q[177-1-NBITS : 94-1], t1_upd};
        state_q[287:177] <= {state_q[288-1-NBITS : 178-1], t2_upd};
      end
    end
  end

  assign prd_o   = prd_q;
  assign valid_o = valid_q;





  always @(*) begin
    t1 = state_q[66-1 : 66-NBITS] ^ state_q[93-1 : 93-NBITS];
    t2 = state_q[162-1 : 162-NBITS] ^ state_q[177-1 : 177-NBITS];
    t3 = state_q[243-1 : 243-NBITS] ^ state_q[288-1 : 288-NBITS];

    t1_upd = t1 ^ (state_q[91-1 : 91-NBITS]   &   state_q[92-1 : 92-NBITS]) ^ state_q[171-1 : 171-NBITS];
    t2_upd = t2 ^ (state_q[175-1 : 175-NBITS] & state_q[176-1 : 176-NBITS]) ^ state_q[264-1 : 264-NBITS];
    t3_upd = t3 ^ (state_q[286-1 : 286-NBITS] & state_q[287-1 : 287-NBITS]) ^  state_q[69-1 : 69-NBITS];
  end


  integer k;
  always @(*) begin
    state_init = 0;
    for (k = 0; k < 80; k++) begin
      state_init[79-k] = key_i[k];
      state_init[93+79-k] = iv_i[k];
    end
    state_init[287:285] = 3'b111;
  end

endmodule
