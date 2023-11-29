
// Transpose state matrix
function automatic logic [127:0] aes_transpose;
  input logic [127:0] in;
  logic [127:0] transpose;
  transpose = 0;
  transpose[((0 *4) + 0) * 8+:8] = in[((0 * 4) + 0) * 8+:8];
  transpose[((0* 4) + 1) * 8+:8] = in[((1 * 4) + 0) * 8+:8];
  transpose[((0* 4) + 2) * 8+:8] = in[((2 * 4) + 0) * 8+:8];
  transpose[((0* 4) + 3) * 8+:8] = in[((3 * 4) + 0) * 8+:8];

  transpose[((1* 4) + 0) * 8+:8] = in[((0 * 4) + 1) * 8+:8];
  transpose[((1* 4) + 1) * 8+:8] = in[((1 * 4) + 1) * 8+:8];
  transpose[((1* 4) + 2) * 8+:8] = in[((2 * 4) + 1) * 8+:8];
  transpose[((1* 4) + 3) * 8+:8] = in[((3 * 4) + 1) * 8+:8];

  transpose[((2* 4) + 0) * 8+:8] = in[((0 * 4) + 2) * 8+:8];
  transpose[((2* 4) + 1) * 8+:8] = in[((1 * 4) + 2) * 8+:8];
  transpose[((2* 4) + 2) * 8+:8] = in[((2 * 4) + 2) * 8+:8];
  transpose[((2* 4) + 3) * 8+:8] = in[((3 * 4) + 2) * 8+:8];

  transpose[((3* 4) + 0) * 8+:8] = in[((0 * 4) + 3) * 8+:8];
  transpose[((3* 4) + 1) * 8+:8] = in[((1 * 4) + 3) * 8+:8];
  transpose[((3* 4) + 2) * 8+:8] = in[((2 * 4) + 3) * 8+:8];
  transpose[((3* 4) + 3) * 8+:8] = in[((3 * 4) + 3) * 8+:8];

  
  aes_transpose = transpose;
endfunction


function automatic logic [7:0] aes_mul2;
input logic [7:0] in;
  logic [7:0] out;
  out[7] = in[6];
  out[6] = in[5];
  out[5] = in[4];
  out[4] = in[3] ^ in[7];
  out[3] = in[2] ^ in[7];
  out[2] = in[1];
  out[1] = in[0] ^ in[7];
  out[0] = in[7];
  aes_mul2 = out;
endfunction



  // Multiplication in GF(2^2), using normal basis [Omega^2, Omega]
  // (see Figure 14 in the technical report)
  function automatic logic [1:0] aes_mul_gf2p2;
  input logic [1:0] g;
  input logic [1:0] d;
  logic [1:0] f;
    f[1] = (g[1] & d[1]) ^ ((g[0]^g[1]) & (d[0]^d[1]));
    f[0] = (g[0] & d[0]) ^ ((g[0]^g[1]) & (d[0]^d[1]));
    aes_mul_gf2p2 = f;
  endfunction

 // Multiplication in GF(2^4), using normal basis [alpha^8, alpha^2]
  // (see Figure 13 in the technical report)
  function automatic logic [3:0] aes_mul_gf2p4;
    input logic [3:0] gamma;
    input logic [3:0] delta;
    logic [3:0] theta;
    logic [1:0] tmp0;
    logic [1:0] a, b, c;
    a          = aes_mul_gf2p2(gamma[3:2], delta[3:2]);
    /*a[1] = (gamma[3] & delta[3]) ^ ((gamma[3]^gamma[2]) & (delta[3]^delta[2]));
    a[0] = (gamma[2] & delta[2]) ^ ((gamma[3]^gamma[2]) & (delta[3]^delta[2]));
*/

    b          = aes_mul_gf2p2(gamma[3:2] ^ gamma[1:0], delta[3:2] ^ delta[1:0]);
    /*b[1] = ((gamma[3]^gamma[1]) & (delta[3] ^ delta[1])) ^ ((gamma[3] ^ gamma[2] ^ gamma[1] ^ gamma[0]) & (delta[3]^delta[2]^delta[1]^delta[0]));
    b[0] = ((gamma[2] ^ gamma[0]) & (delta[2] ^ delta[0])) ^ ((gamma[3] ^ gamma[2] ^ gamma[1] ^ gamma[0]) & (delta[3]^delta[2]^delta[1]^delta[0]));
*/

    c          = aes_mul_gf2p2(gamma[1:0], delta[1:0]);
    /*c[1] = (gamma[1] & delta[1]) ^ ((gamma[1]^gamma[0]) & (delta[1]^delta[0]));
    c[0] = (gamma[0] & delta[0]) ^ ((gamma[1]^gamma[0]) & (delta[1]^delta[0]));
*/

    tmp0[1] = b[0];
    tmp0[0] = b[1] ^ b[0];
    theta[3:2] = a ^ tmp0;
    theta[1:0] = c ^ tmp0;
    aes_mul_gf2p4 = theta;
  endfunction


parameter [3:0] IDLE         = 4'd0;
parameter [3:0] INIT         = 4'd1;
parameter [3:0] INIT_KEY     = 4'd11;
parameter [3:0] INIT_LIN_MAP_RK = 4'd2;
parameter [3:0] SBOX1        = 4'd3;
parameter [3:0] SBOX2        = 4'd4;
parameter [3:0] SBOX3        = 4'd5;
parameter [3:0] SBOX4        = 4'd6;
parameter [3:0] ROUND_END    = 4'd7;
parameter [3:0] LAST_ROUND_END    = 4'd8;
parameter [3:0] FINISH       = 4'd9;
parameter [3:0] ERROR       = 4'd10;


parameter [2:0] OUTER_IDLE = 3'd0;
parameter [2:0] OUTER_INIT = 3'd1;
parameter [2:0] OUTER_HEATUP_RNG = 3'd2;
parameter [2:0] OUTER_FILL_RNG = 3'd3;
parameter [2:0] OUTER_WAIT_AES = 3'd4;
parameter [2:0] OUTER_AES_ROUND = 3'd5;
parameter [2:0] OUTER_AES_FINISH = 3'd6;
parameter [2:0] OUTER_INIT_TRIVIUM = 3'd7;
