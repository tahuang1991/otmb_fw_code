
module mem_reader (

  input clock,

  input increment,

  output [223:0] ly0,
  output [223:0] ly1,
  output [223:0] ly2,
  output [223:0] ly3,
  output [223:0] ly4,
  output [223:0] ly5,

  output  [7:0]  key_hs_expect,
  output  [11:0] ccode_expect,
  output  [3:0]  pat_expect

);

parameter MXADRB       = 12;
parameter MXDATB       = 9;
parameter ROMLENGTH    = 1 << MXADRB;
parameter ADR_MAX      = 1 << MXADRB;
parameter ROM_FILE     = "../source/pattern_finder/default.dat";

reg [MXADRB-1:0] adr;



reg [223:0] ly0_rom [ROMLENGTH-1:0];
reg [223:0] ly1_rom [ROMLENGTH-1:0];
reg [223:0] ly2_rom [ROMLENGTH-1:0];
reg [223:0] ly3_rom [ROMLENGTH-1:0];
reg [223:0] ly4_rom [ROMLENGTH-1:0];
reg [223:0] ly5_rom [ROMLENGTH-1:0];

reg [223:0] expect_rom [ROMLENGTH-1:0];


initial begin
  $readmemh("../source/pattern_finder/ly0.mem",    ly0_rom);
  $readmemh("../source/pattern_finder/ly1.mem",    ly1_rom);
  $readmemh("../source/pattern_finder/ly2.mem",    ly2_rom);
  $readmemh("../source/pattern_finder/ly3.mem",    ly3_rom);
  $readmemh("../source/pattern_finder/ly4.mem",    ly4_rom);
  $readmemh("../source/pattern_finder/ly5.mem",    ly5_rom);
  $readmemh("../source/pattern_finder/expect.mem", expect_rom);
end

always @(posedge clock) begin
  if (increment) begin
    if (adr==ADR_MAX) adr <= 0;
    else              adr <= adr + 1'b1;
  end
end

assign ly0 = ly0_rom[adr];
assign ly1 = ly1_rom[adr];
assign ly2 = ly2_rom[adr];
assign ly3 = ly3_rom[adr];
assign ly4 = ly4_rom[adr];
assign ly5 = ly5_rom[adr];

assign key_hs_expect = expect_rom[adr][7:0];
assign ccode_expect  = expect_rom[adr][11:0];
assign pat_expect    = expect_rom[adr][3:0];

endmodule
