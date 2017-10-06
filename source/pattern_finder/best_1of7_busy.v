`timescale 1ns / 1ps
//-------------------------------------------------------------------------------------------------------------------
// Finds best 1 of 7 1/2-strip patterns comparing all patterns simultaneously
//
//  11/08/2006  Initial
//  12/13/2006  Non-busy version
//  12/20/2006  Replace envelope hits with pattern ids
//  12/22/2006  Sort based on 6-bit patterns instead of just number of hits
//  01/10/2007  Increase pattern bits to 3 hits + 4 bends
//  01/25/2007  Add busy logic to best_1of5.v
//  05/08/2007  Change pattern numbers 1-9 to 0-8 so lsb now implies bend direction, ignore lsb during sort
//  08/11/2010   Port to ISE 12
//  02/19/2013  Expand to best 1 of 7
//-------------------------------------------------------------------------------------------------------------------
  module best_1of7_busy
  (
  input  [MXPATB-1:0]  pat0  , pat1  , pat2  , pat3  , pat4  , pat5  , pat6  ,
  input  [MXKEYB-1:0]  key0  , key1  , key2  , key3  , key4  , key5  , key6  ,
  input  [MXQSB -1:0]  qs0   , qs1   , qs2   , qs3   , qs4   , qs5   , qs6   ,
  input  [MXQLTB-1:0]  qlt0  , qlt1  , qlt2  , qlt3  , qlt4  , qlt5  , qlt6  ,
  input  [MXBNDB-1:0]  bend0 , bend1 , bend2 , bend3 , bend4 , bend5 , bend6 ,

  input                bsy0  , bsy1  , bsy2  , bsy3  , bsy4  , bsy5  , bsy6  ,

  output reg [MXPATB -1:0] best_pat,
  output reg [MXKEYBX-1:0] best_key,
  output reg [MXBNDB -1:0] best_bend,
  output reg [MXKEYBX  :0] best_qkey,
  output reg [MXQLTB -1:0] best_qlt,
  output reg               best_bsy
  );

// Constants

`include "pattern_params.v"

reg [MXQSB-1:0] best_qs;

// Choose bits to sort on, either sortable pattern or post-fit quality

  wire [5:0] sort_key0 = (PATLUT) ? qlt0 : pat0[6:1];
  wire [5:0] sort_key1 = (PATLUT) ? qlt1 : pat1[6:1];
  wire [5:0] sort_key2 = (PATLUT) ? qlt2 : pat2[6:1];
  wire [5:0] sort_key3 = (PATLUT) ? qlt3 : pat3[6:1];
  wire [5:0] sort_key4 = (PATLUT) ? qlt4 : pat4[6:1];
  wire [5:0] sort_key5 = (PATLUT) ? qlt5 : pat5[6:1];
  wire [5:0] sort_key6 = (PATLUT) ? qlt6 : pat6[6:1];

// Stage 3: Best 1 of 7

  always @* begin
  if     ((sort_key6 > sort_key5) &&
          (sort_key6 > sort_key4) &&
          (sort_key6 > sort_key3) &&
          (sort_key6 > sort_key2) &&
          (sort_key6 > sort_key1) &&
          (sort_key6 > sort_key0) && !bsy6)
      begin
      best_pat  = pat6;
      best_key  = {3'd6,key6};
      best_qlt  = qlt6;
      best_bend = bend6;
      best_qs   = qs6;
      best_bsy  = 0;
      end

  else if((pat5 > pat4) &&
          (pat5 > pat3) &&
          (pat5 > pat2) &&
          (pat5 > pat1) &&
          (pat5 > pat0) && !bsy5)
      begin
      best_pat  = pat5;
      best_key  = {3'd5,key5};
      best_qlt  = qlt5;
      best_bend = bend5;
      best_qs   = qs5;
      best_bsy  = 0;
      end

  else if((sort_key4 > sort_key3) &&
          (sort_key4 > sort_key2) &&
          (sort_key4 > sort_key1) &&
          (sort_key4 > sort_key0) && !bsy4)
      begin
      best_pat  = pat4;
      best_key  = {3'd4,key4};
      best_qlt  = qlt4;
      best_bend = bend4;
      best_qs   = qs4;
      best_bsy  = 0;
      end

  else if((pat3 > pat2) &&
          (pat3 > pat1) &&
          (pat3 > pat0) && !bsy3)
      begin
      best_pat  = pat3;
      best_qlt  = qlt3;
      best_bend = bend3;
      best_qs   = qs3;
      best_key  = {3'd3,key3};
      best_bsy  = 0;
      end

  else if((sort_key2 > sort_key1) &&
          (sort_key2 > sort_key0) && !bsy2)
      begin
      best_pat  = pat2;
      best_qlt  = qlt2;
      best_bend = bend2;
      best_qs   = qs2;
      best_key  = {3'd2,key2};
      best_bsy  = 0;
      end

  else if((sort_key1 > sort_key0) && !bsy1)
      begin
      best_pat  = pat1;
      best_qlt  = qlt1;
      best_bend = bend1;
      best_qs   = qs1;
      best_key  = {3'd1,key1};
      best_bsy  = 0;
      end

  else if (!bsy0)
      begin
      best_pat  = pat0;
      best_qlt  = qlt0;
      best_bend = bend0;
      best_qs   = qs0;
      best_key  = {3'd0,key0};
      best_bsy  = 0;
      end

  else  begin
      best_pat  = 0;
      best_key  = 0;
      best_qlt  = 0;
      best_bend = 0;
      best_qs   = 0;
      best_bsy  = 1;
      end
  end

  //always @(*) begin
  //  case (best_key)
  //    0:       best_qkey = best_qs-2;
  //    1:       best_qkey = best_qs;
  //    2:       best_qkey = best_qs+2;
  //    3:       best_qkey = best_qs+4;
  //    4:       best_qkey = best_qs+4;
  //    default: best_qkey = best_qs+best_key*2;
  //    MXHS:    best_qkey = best_qs+MXHS*2-2;
  //  endcase
  //end

  always @(*) begin
  best_qkey = best_qs+best_key*2;
  end

//-------------------------------------------------------------------------------------------------------------------
  endmodule
//-------------------------------------------------------------------------------------------------------------------
