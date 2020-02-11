
module mem_reader (

  input clock,

  input increment,

  output [223:0] ly0,
  output [223:0] ly1,
  output [223:0] ly2,
  output [223:0] ly3,
  output [223:0] ly4,
  output [223:0] ly5,

  output  [7:0]  key_hs_expect_1st,
  output  [11:0] ccode_expect_1st,
  output  [3:0]  pat_expect_1st,

  output  [7:0]  key_hs_expect_2nd,
  output  [11:0] ccode_expect_2nd,
  output  [3:0]  pat_expect_2nd,

  output [1:0] state_expect,

  output [MXADRB-1:0] adr_out,

  output done

);

parameter MXADRB       = 10;
parameter ADR_MAX      = 1 << MXADRB;
parameter ROM_FILE     = "../source/pattern_finder/default.dat";

reg [51:0] expect_rom_1st [ADR_MAX-1:0];
reg [51:0] expect_rom_2nd [ADR_MAX-1:0];

reg [32*6-1:0] cfeb0_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb1_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb2_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb3_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb4_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb5_rom [ADR_MAX-1:0];
reg [32*6-1:0] cfeb6_rom [ADR_MAX-1:0];

wire [32*6-1:0] cfeb0;
wire [32*6-1:0] cfeb1;
wire [32*6-1:0] cfeb2;
wire [32*6-1:0] cfeb3;
wire [32*6-1:0] cfeb4;
wire [32*6-1:0] cfeb5;
wire [32*6-1:0] cfeb6;

initial begin
  //$readmemh("../source/pattern_finder/cfeb0.mem",  cfeb0_rom);
  //$readmemh("../source/pattern_finder/cfeb1.mem",  cfeb1_rom);
  //$readmemh("../source/pattern_finder/cfeb2.mem",  cfeb2_rom);
  //$readmemh("../source/pattern_finder/cfeb3.mem",  cfeb3_rom);
  //$readmemh("../source/pattern_finder/cfeb4.mem",  cfeb4_rom);
  //$readmemh("../source/pattern_finder/cfeb5.mem",  cfeb5_rom);
  //$readmemh("../source/pattern_finder/cfeb6.mem",  cfeb6_rom);

  //$readmemh("../source/pattern_finder/expected0.mem", expect_rom_1st);
  //$readmemh("../source/pattern_finder/expected1.mem", expect_rom_2nd);
  $readmemh("cfeb0.mem",  cfeb0_rom);
  $readmemh("cfeb1.mem",  cfeb1_rom);
  $readmemh("cfeb2.mem",  cfeb2_rom);
  $readmemh("cfeb3.mem",  cfeb3_rom);
  $readmemh("cfeb4.mem",  cfeb4_rom);
  $readmemh("cfeb5.mem",  cfeb5_rom);
  $readmemh("cfeb6.mem",  cfeb6_rom);

  $readmemh("expected_1st.mem", expect_rom_1st);
  $readmemh("expected_2nd.mem", expect_rom_2nd);
end

reg stop=1'b0;
assign done = stop;

reg [MXADRB-1:0] adr='h0;

always @(posedge clock) begin
  if (!stop && increment) begin
    if (adr==ADR_MAX-1) adr <= 0;
    else                adr <= adr + 1'b1;

    if (adr==ADR_MAX-1) stop <= 1'b1;
  end
end

assign adr_out = adr;

assign cfeb0 = cfeb0_rom[adr];
assign cfeb1 = cfeb1_rom[adr];
assign cfeb2 = cfeb2_rom[adr];
assign cfeb3 = cfeb3_rom[adr];
assign cfeb4 = cfeb4_rom[adr];
assign cfeb5 = cfeb5_rom[adr];
assign cfeb6 = cfeb6_rom[adr];

assign ly0 = {cfeb6[32*6-1:32*5], cfeb5[32*6-1:32*5], cfeb4[32*6-1:32*5], cfeb3[32*6-1:32*5], cfeb2[32*6-1:32*5], cfeb1[32*6-1:32*5], cfeb0[32*6-1:32*5]} ;
assign ly1 = {cfeb6[32*5-1:32*4], cfeb5[32*5-1:32*4], cfeb4[32*5-1:32*4], cfeb3[32*5-1:32*4], cfeb2[32*5-1:32*4], cfeb1[32*5-1:32*4], cfeb0[32*5-1:32*4]} ;
assign ly2 = {cfeb6[32*4-1:32*3], cfeb5[32*4-1:32*3], cfeb4[32*4-1:32*3], cfeb3[32*4-1:32*3], cfeb2[32*4-1:32*3], cfeb1[32*4-1:32*3], cfeb0[32*4-1:32*3]} ;
assign ly3 = {cfeb6[32*3-1:32*2], cfeb5[32*3-1:32*2], cfeb4[32*3-1:32*2], cfeb3[32*3-1:32*2], cfeb2[32*3-1:32*2], cfeb1[32*3-1:32*2], cfeb0[32*3-1:32*2]} ;
assign ly4 = {cfeb6[32*2-1:32*1], cfeb5[32*2-1:32*1], cfeb4[32*2-1:32*1], cfeb3[32*2-1:32*1], cfeb2[32*2-1:32*1], cfeb1[32*2-1:32*1], cfeb0[32*2-1:32*1]} ;
assign ly5 = {cfeb6[32*1-1:32*0], cfeb5[32*1-1:32*0], cfeb4[32*1-1:32*0], cfeb3[32*1-1:32*0], cfeb2[32*1-1:32*0], cfeb1[32*1-1:32*0], cfeb0[32*1-1:32*0]} ;

assign key_hs_expect_1st = expect_rom_1st[adr][39:32];
assign ccode_expect_1st  = expect_rom_1st[adr][11:0];
assign pat_expect_1st    = expect_rom_1st[adr][19:16];


assign key_hs_expect_2nd = expect_rom_2nd[adr][39:32];
assign ccode_expect_2nd  = expect_rom_2nd[adr][11:0];
assign pat_expect_2nd    = expect_rom_2nd[adr][19:16];

// 0x1 = idle, 0x2 = flush, 0x3 = pretrigger
assign state_expect      = expect_rom_1st[adr][49:48];

endmodule
