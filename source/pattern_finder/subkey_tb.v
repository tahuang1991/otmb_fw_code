`include "pattern_params.v"

module subkey_tb ();

reg clock = 0;
always @*
  clock <= #12.5 ~clock;

reg signed [MXOFFSB   -1:0] best_offs;
reg  [MXKEYBX   -1:0] best_key;
wire [MXSUBKEYBX-1:0] best_subkey;
reg  [MXSUBKEYBX-1:0] expect;

initial begin
  #25 best_offs <= -1; best_key <= 0; expect <= 0; // negative edge
  #25 best_offs <=  0; best_key <= 0; expect <= 0; //
  #25 best_offs <=  1; best_key <= 0; expect <= 1; //

  #25 best_offs <= -4; best_key <= 1; expect <= 0; //
  #25 best_offs <= -3; best_key <= 1; expect <= 1; //

  #25 best_offs <=  0; best_key <= 1; expect <= 4; //
  #25 best_offs <=  1; best_key <= 1; expect <= 5; //

  #25 best_offs <=  3 ; best_key <= 127; expect <= 511; //
  #25 best_offs <=  7 ; best_key <= 126; expect <= 511; //

  #25 best_offs <=  6  ; best_key <= 126; expect <= 510; //

  #25 best_offs <=  0  ; best_key <= 128; expect <= 512; //
  #25 best_offs <= -4  ; best_key <= 129; expect <= 512; //

  #25 best_offs <=  1  ; best_key <= 128; expect <= 513; //
  #25 best_offs <=  -3  ; best_key <= 129; expect <= 513; //

  #25 best_offs <=  3  ; best_key <= 223; expect <= 895; //
  #25 best_offs <=  7 ;  best_key <= 222; expect <= 895; //

  #25 best_offs <=  2 ;  best_key <= 223; expect <= 894; //
  #25 best_offs <=  6 ;  best_key <= 222; expect <= 894; //

  #25 best_offs <= -4 ;  best_key <= 1; expect <= 0; //
  #25 best_offs <= -3 ;  best_key <= 1; expect <= 1; //
  #25 best_offs <= -2 ;  best_key <= 1; expect <= 2; //
  #25 best_offs <= -1 ;  best_key <= 1; expect <= 3; //
  #25 best_offs <=  0 ;  best_key <= 1; expect <= 4; //
  #25 best_offs <=  1 ;  best_key <= 1; expect <= 5; //
  #25 best_offs <=  2 ;  best_key <= 1; expect <= 6; //
  #25 best_offs <=  3 ;  best_key <= 1; expect <= 7; //

  #25 best_offs <= -4 ;  best_key <= 2; expect <= 4; //
  #25 best_offs <= -3 ;  best_key <= 2; expect <= 5; //
  #25 best_offs <= -2 ;  best_key <= 2; expect <= 6; //
  #25 best_offs <= -1 ;  best_key <= 2; expect <= 7; //
  #25 best_offs <=  0 ;  best_key <= 2; expect <= 8; //
  #25 best_offs <=  1 ;  best_key <= 2; expect <= 9; //
  #25 best_offs <=  2 ;  best_key <= 2; expect <= 10; //
  #25 best_offs <=  3 ;  best_key <= 2; expect <= 11; //

  #25 best_offs <= -4 ;  best_key <= 3; expect <= 8; //
  #25 best_offs <= -3 ;  best_key <= 3; expect <= 9; //
  #25 best_offs <= -2 ;  best_key <= 3; expect <= 10; //
  #25 best_offs <= -1 ;  best_key <= 3; expect <= 11; //
  #25 best_offs <=  0 ;  best_key <= 3; expect <= 12; //
  #25 best_offs <=  1 ;  best_key <= 3; expect <= 13; //
  #25 best_offs <=  2 ;  best_key <= 3; expect <= 14; //
  #25 best_offs <=  3 ;  best_key <= 3; expect <= 15; //

  #25 best_offs <= -4 ;  best_key <= 4; expect <= 12; //
  #25 best_offs <= -3 ;  best_key <= 4; expect <= 13; //
  #25 best_offs <= -2 ;  best_key <= 4; expect <= 14; //
  #25 best_offs <= -1 ;  best_key <= 4; expect <= 15; //
  #25 best_offs <=  0 ;  best_key <= 4; expect <= 16; //
  #25 best_offs <=  1 ;  best_key <= 4; expect <= 17; //
  #25 best_offs <=  2 ;  best_key <= 4; expect <= 18; //
  #25 best_offs <=  3 ;  best_key <= 4; expect <= 19; //

  #25 best_offs <= -4 ;  best_key <= 5; expect <= 16; //
  #25 best_offs <= -3 ;  best_key <= 5; expect <= 17; //
  #25 best_offs <= -2 ;  best_key <= 5; expect <= 18; //
  #25 best_offs <= -1 ;  best_key <= 5; expect <= 19; //
  #25 best_offs <=  0 ;  best_key <= 5; expect <= 20; //
  #25 best_offs <=  1 ;  best_key <= 5; expect <= 21; //
  #25 best_offs <=  2 ;  best_key <= 5; expect <= 22; //
  #25 best_offs <=  3 ;  best_key <= 5; expect <= 23; //

  #25 best_offs <= -4 ;  best_key <= 6; expect <= 20; //
  #25 best_offs <= -3 ;  best_key <= 6; expect <= 21; //
  #25 best_offs <= -2 ;  best_key <= 6; expect <= 22; //
  #25 best_offs <= -1 ;  best_key <= 6; expect <= 23; //
  #25 best_offs <=  0 ;  best_key <= 6; expect <= 24; //
  #25 best_offs <=  1 ;  best_key <= 6; expect <= 25; //
  #25 best_offs <=  2 ;  best_key <= 6; expect <= 26; //
  #25 best_offs <=  3 ;  best_key <= 6; expect <= 27; //

  #25 best_offs <= -4 ;  best_key <= 7; expect <= 24; //
  #25 best_offs <= -3 ;  best_key <= 7; expect <= 25; //
  #25 best_offs <= -2 ;  best_key <= 7; expect <= 26; //
  #25 best_offs <= -1 ;  best_key <= 7; expect <= 27; //
  #25 best_offs <=  0 ;  best_key <= 7; expect <= 28; //
  #25 best_offs <=  1 ;  best_key <= 7; expect <= 29; //
  #25 best_offs <=  2 ;  best_key <= 7; expect <= 30; //
  #25 best_offs <=  3 ;  best_key <= 7; expect <= 31; //

  #25 best_offs <= -4 ;  best_key <= 8; expect <= 28; //
  #25 best_offs <= -3 ;  best_key <= 8; expect <= 29; //
  #25 best_offs <= -2 ;  best_key <= 8; expect <= 30; //
  #25 best_offs <= -1 ;  best_key <= 8; expect <= 31; //
  #25 best_offs <=  0 ;  best_key <= 8; expect <= 32; //
  #25 best_offs <=  1 ;  best_key <= 8; expect <= 33; //
  #25 best_offs <=  2 ;  best_key <= 8; expect <= 34; //
  #25 best_offs <=  3 ;  best_key <= 8; expect <= 35; //

  #25 best_offs <= -4 ;  best_key <= 9; expect <= 32; //
  #25 best_offs <= -3 ;  best_key <= 9; expect <= 33; //
  #25 best_offs <= -2 ;  best_key <= 9; expect <= 34; //
  #25 best_offs <= -1 ;  best_key <= 9; expect <= 35; //
  #25 best_offs <=  0 ;  best_key <= 9; expect <= 36; //
  #25 best_offs <=  1 ;  best_key <= 9; expect <= 37; //
  #25 best_offs <=  2 ;  best_key <= 9; expect <= 38; //
  #25 best_offs <=  3 ;  best_key <= 9; expect <= 39; //

  #25 best_offs <= -4 ;  best_key <= 10; expect <= 36; //
  #25 best_offs <= -3 ;  best_key <= 10; expect <= 37; //
  #25 best_offs <= -2 ;  best_key <= 10; expect <= 38; //
  #25 best_offs <= -1 ;  best_key <= 10; expect <= 39; //
  #25 best_offs <=  0 ;  best_key <= 10; expect <= 40; //
  #25 best_offs <=  1 ;  best_key <= 10; expect <= 41; //
  #25 best_offs <=  2 ;  best_key <= 10; expect <= 42; //
  #25 best_offs <=  3 ;  best_key <= 10; expect <= 43; //

  #25 best_offs <= -4 ;  best_key <= 11; expect <= 40; //
  #25 best_offs <= -3 ;  best_key <= 11; expect <= 41; //
  #25 best_offs <= -2 ;  best_key <= 11; expect <= 42; //
  #25 best_offs <= -1 ;  best_key <= 11; expect <= 43; //
  #25 best_offs <=  0 ;  best_key <= 11; expect <= 44; //
  #25 best_offs <=  1 ;  best_key <= 11; expect <= 45; //
  #25 best_offs <=  2 ;  best_key <= 11; expect <= 46; //
  #25 best_offs <=  3 ;  best_key <= 11; expect <= 47; //

  #25 best_offs <= -4 ;  best_key <= 12; expect <= 44; //
  #25 best_offs <= -3 ;  best_key <= 12; expect <= 45; //
  #25 best_offs <= -2 ;  best_key <= 12; expect <= 46; //
  #25 best_offs <= -1 ;  best_key <= 12; expect <= 47; //
  #25 best_offs <=  0 ;  best_key <= 12; expect <= 48; //
  #25 best_offs <=  1 ;  best_key <= 12; expect <= 49; //
  #25 best_offs <=  2 ;  best_key <= 12; expect <= 50; //
  #25 best_offs <=  3 ;  best_key <= 12; expect <= 51; //

  #25 best_offs <= -4 ;  best_key <= 13; expect <= 48; //
  #25 best_offs <= -3 ;  best_key <= 13; expect <= 49; //
  #25 best_offs <= -2 ;  best_key <= 13; expect <= 50; //
  #25 best_offs <= -1 ;  best_key <= 13; expect <= 51; //
  #25 best_offs <=  0 ;  best_key <= 13; expect <= 52; //
  #25 best_offs <=  1 ;  best_key <= 13; expect <= 53; //
  #25 best_offs <=  2 ;  best_key <= 13; expect <= 54; //
  #25 best_offs <=  3 ;  best_key <= 13; expect <= 55; //

  #25 best_offs <= -4 ;  best_key <= 14; expect <= 52; //
  #25 best_offs <= -3 ;  best_key <= 14; expect <= 53; //
  #25 best_offs <= -2 ;  best_key <= 14; expect <= 54; //
  #25 best_offs <= -1 ;  best_key <= 14; expect <= 55; //
  #25 best_offs <=  0 ;  best_key <= 14; expect <= 56; //
  #25 best_offs <=  1 ;  best_key <= 14; expect <= 57; //
  #25 best_offs <=  2 ;  best_key <= 14; expect <= 58; //
  #25 best_offs <=  3 ;  best_key <= 14; expect <= 59; //

  #25 best_offs <= -4 ;  best_key <= 15; expect <= 56; //
  #25 best_offs <= -3 ;  best_key <= 15; expect <= 57; //
  #25 best_offs <= -2 ;  best_key <= 15; expect <= 58; //
  #25 best_offs <= -1 ;  best_key <= 15; expect <= 59; //
  #25 best_offs <=  0 ;  best_key <= 15; expect <= 60; //
  #25 best_offs <=  1 ;  best_key <= 15; expect <= 61; //
  #25 best_offs <=  2 ;  best_key <= 15; expect <= 62; //
  #25 best_offs <=  3 ;  best_key <= 15; expect <= 63; //

  #25 best_offs <= -4 ;  best_key <= 16; expect <= 60; //
  #25 best_offs <= -3 ;  best_key <= 16; expect <= 61; //
  #25 best_offs <= -2 ;  best_key <= 16; expect <= 62; //
  #25 best_offs <= -1 ;  best_key <= 16; expect <= 63; //
  #25 best_offs <=  0 ;  best_key <= 16; expect <= 64; //
  #25 best_offs <=  1 ;  best_key <= 16; expect <= 65; //
  #25 best_offs <=  2 ;  best_key <= 16; expect <= 66; //
  #25 best_offs <=  3 ;  best_key <= 16; expect <= 67; //

  #25 best_offs <= -4 ;  best_key <= 17; expect <= 64; //
  #25 best_offs <= -3 ;  best_key <= 17; expect <= 65; //
  #25 best_offs <= -2 ;  best_key <= 17; expect <= 66; //
  #25 best_offs <= -1 ;  best_key <= 17; expect <= 67; //
  #25 best_offs <=  0 ;  best_key <= 17; expect <= 68; //
  #25 best_offs <=  1 ;  best_key <= 17; expect <= 69; //
  #25 best_offs <=  2 ;  best_key <= 17; expect <= 70; //
  #25 best_offs <=  3 ;  best_key <= 17; expect <= 71; //

  #25 best_offs <= -4 ;  best_key <= 18; expect <= 68; //
  #25 best_offs <= -3 ;  best_key <= 18; expect <= 69; //
  #25 best_offs <= -2 ;  best_key <= 18; expect <= 70; //
  #25 best_offs <= -1 ;  best_key <= 18; expect <= 71; //
  #25 best_offs <=  0 ;  best_key <= 18; expect <= 72; //
  #25 best_offs <=  1 ;  best_key <= 18; expect <= 73; //
  #25 best_offs <=  2 ;  best_key <= 18; expect <= 74; //
  #25 best_offs <=  3 ;  best_key <= 18; expect <= 75; //

  #25 best_offs <= -4 ;  best_key <= 19; expect <= 72; //
  #25 best_offs <= -3 ;  best_key <= 19; expect <= 73; //
  #25 best_offs <= -2 ;  best_key <= 19; expect <= 74; //
  #25 best_offs <= -1 ;  best_key <= 19; expect <= 75; //
  #25 best_offs <=  0 ;  best_key <= 19; expect <= 76; //
  #25 best_offs <=  1 ;  best_key <= 19; expect <= 77; //
  #25 best_offs <=  2 ;  best_key <= 19; expect <= 78; //
  #25 best_offs <=  3 ;  best_key <= 19; expect <= 79; //

  #25 best_offs <= -4 ;  best_key <= 20; expect <= 76; //
  #25 best_offs <= -3 ;  best_key <= 20; expect <= 77; //
  #25 best_offs <= -2 ;  best_key <= 20; expect <= 78; //
  #25 best_offs <= -1 ;  best_key <= 20; expect <= 79; //
  #25 best_offs <=  0 ;  best_key <= 20; expect <= 80; //
  #25 best_offs <=  1 ;  best_key <= 20; expect <= 81; //
  #25 best_offs <=  2 ;  best_key <= 20; expect <= 82; //
  #25 best_offs <=  3 ;  best_key <= 20; expect <= 83; //

  #25 best_offs <= -4 ;  best_key <= 21; expect <= 80; //
  #25 best_offs <= -3 ;  best_key <= 21; expect <= 81; //
  #25 best_offs <= -2 ;  best_key <= 21; expect <= 82; //
  #25 best_offs <= -1 ;  best_key <= 21; expect <= 83; //
  #25 best_offs <=  0 ;  best_key <= 21; expect <= 84; //
  #25 best_offs <=  1 ;  best_key <= 21; expect <= 85; //
  #25 best_offs <=  2 ;  best_key <= 21; expect <= 86; //
  #25 best_offs <=  3 ;  best_key <= 21; expect <= 87; //

  #25 best_offs <= -4 ;  best_key <= 22; expect <= 84; //
  #25 best_offs <= -3 ;  best_key <= 22; expect <= 85; //
  #25 best_offs <= -2 ;  best_key <= 22; expect <= 86; //
  #25 best_offs <= -1 ;  best_key <= 22; expect <= 87; //
  #25 best_offs <=  0 ;  best_key <= 22; expect <= 88; //
  #25 best_offs <=  1 ;  best_key <= 22; expect <= 89; //
  #25 best_offs <=  2 ;  best_key <= 22; expect <= 90; //
  #25 best_offs <=  3 ;  best_key <= 22; expect <= 91; //

  #25 best_offs <= -4 ;  best_key <= 23; expect <= 88; //
  #25 best_offs <= -3 ;  best_key <= 23; expect <= 89; //
  #25 best_offs <= -2 ;  best_key <= 23; expect <= 90; //
  #25 best_offs <= -1 ;  best_key <= 23; expect <= 91; //
  #25 best_offs <=  0 ;  best_key <= 23; expect <= 92; //
  #25 best_offs <=  1 ;  best_key <= 23; expect <= 93; //
  #25 best_offs <=  2 ;  best_key <= 23; expect <= 94; //
  #25 best_offs <=  3 ;  best_key <= 23; expect <= 95; //
end

calculate calculate (
  .best_offs   (best_offs),
  .best_key    (best_key),
  .best_subkey (best_subkey)
);

wire difference = (best_subkey != expect);


endmodule

module calculate (
  input      [MXOFFSB   -1:0] best_offs,
  input      [MXKEYBX   -1:0] best_key,
  output reg [MXSUBKEYBX-1:0] best_subkey
);

  reg case0;
  reg case1;
  reg case2;
  reg case3;
  reg casedefault;

  wire signed [MXOFFSB   -1:0] best_offs_signed   = best_offs;
  wire signed [MXKEYBX   -1:0] best_key_signed    = best_key;
  wire        [MXSUBKEYBX-1:0] best_subkey_signed = 4*best_key_signed + best_offs_signed;

  always @(*) begin

    case0=0;
    case1=0;
    case2=0;
    case3=0;
    casedefault=0;

    if      ((best_key==0   && best_offs_signed<=0) || (best_key==1   && best_offs_signed<=-4)) begin
      case0=1;
      best_subkey <= 0;
    end
    else if ((best_key==127 && best_offs_signed>=3) || (best_key==126 && best_offs_signed>= 7)) begin
      case1=1;
      best_subkey <= 127*4+3;
    end
    else if ((best_key==128 && best_offs_signed<=0) || (best_key==129 && best_offs_signed<=-4)) begin
      case2=1;
      best_subkey <= 128*4;
    end
    else if ((best_key==223 && best_offs_signed>=3) || (best_key==222 && best_offs_signed>= 7)) begin
      case3=1;
      best_subkey <= 223*4+3;
    end
    else begin
      casedefault=1;
      best_subkey <= best_subkey_signed;
    end
  end

endmodule
