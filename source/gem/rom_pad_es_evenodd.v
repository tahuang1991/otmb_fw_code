//GEM pad to CSC halfstrip, up to 1/8 strip bits
//GEM pad: 0-191;    CSC es: 0-128*4 for ME1b  and 128*4-224*4 for ME1a

module rom_pad_es_evenodd (
  input clock,
  input evenchamber,
  input  [MXADRB-1:0] adr0, adr1,
  output [MXDATB-1:0] me1ard0, me1ard1,
  output [MXDATB-1:0] me1brd0, me1brd1
);

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------

parameter FALLING_EDGE = 0;
parameter MXADRB       = 8;
parameter MXDATB       = 10;
parameter ROMLENGTH    = 192;
parameter ROM_FILE_ME1A_EVEN     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_ME1A_ODD     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_ME1B_EVEN     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_ME1B_ODD     = "../source/pattern_finder/default.dat";

//----------------------------------------------------------------------------------------------------------------------
// Signals
//----------------------------------------------------------------------------------------------------------------------

reg [MXDATB-1:0] rom_me1a_even [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_me1a_odd [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_me1b_even [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_me1b_odd [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_me1a [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_me1b [ROMLENGTH-1:0];
reg [MXDATB-1:0] rd_me1a_data0, rd_me1a_data1;
reg [MXDATB-1:0] rd_me1b_data0, rd_me1b_data1;
wire [MXDATB-1:0] din = 0;
wire we = 0;
wire logic_clock;

generate
if (FALLING_EDGE) assign logic_clock = ~clock;
else              assign logic_clock =  clock;
endgenerate

//----------------------------------------------------------------------------------------------------------------------
// Read in ROM File
//----------------------------------------------------------------------------------------------------------------------

integer i;
initial begin
  $readmemh(ROM_FILE_ME1A_EVEN, rom_me1a_even);
  $readmemh(ROM_FILE_ME1A_ODD,  rom_me1a_odd);
  $readmemh(ROM_FILE_ME1B_EVEN, rom_me1b_even);
  $readmemh(ROM_FILE_ME1B_ODD,  rom_me1b_odd);
  for (i=0;  i<ROMLENGTH; i=i+1) begin
    rom_me1a[i] = 10'b0;
    rom_me1b[i] = 10'b0;
  end
end

//----------------------------------------------------------------------------------------------------------------------
// ROM
//----------------------------------------------------------------------------------------------------------------------

//always @(posedge logic_clock) begin
//  if (we) begin
//    rom_me1a_odd[adr0[MXADRB-1:0]] <=din;  // dummy write to help Xilinx infer a dual port block RAM
//    rom_me1a_even[adr0[MXADRB-1:0]]<=din; 
//    rom_me1b_odd[adr0[MXADRB-1:0]] <=din; 
//    rom_me1b_even[adr0[MXADRB-1:0]]<=din; 
//  end
//end

genvar iadr;
generate
for (iadr=0; iadr<ROMLENGTH; iadr=iadr+1) begin: gemcsclut
  always @* begin
    rom_me1a[iadr] <= evenchamber ? rom_me1a_even[iadr] : rom_me1a_odd[iadr];
    rom_me1b[iadr] <= evenchamber ? rom_me1b_even[iadr] : rom_me1b_odd[iadr];
  end
end
endgenerate

always @(posedge logic_clock) begin
  //adr0: low end pad, adr1: high end pad
  //ME1A LUT: even is increasing and odd is decreasing 
  //ME1B LUT: even is increasing and odd is decreasing
  //rd_me1a_data0 <= evenchamber ?  rom_me1a_even[adr0[MXADRB-1:0]] : rom_me1a_odd[adr1[MXADRB-1:0]];
  //rd_me1a_data1 <= evenchamber ?  rom_me1a_even[adr1[MXADRB-1:0]] : rom_me1a_odd[adr0[MXADRB-1:0]];
  //rd_me1b_data0 <= evenchamber ?  rom_me1b_even[adr0[MXADRB-1:0]] : rom_me1b_odd[adr1[MXADRB-1:0]];
  //rd_me1b_data1 <= evenchamber ?  rom_me1b_even[adr1[MXADRB-1:0]] : rom_me1b_odd[adr0[MXADRB-1:0]];
  rd_me1a_data0 <= rom_me1a[adr0[MXADRB-1:0]];
  rd_me1a_data1 <= rom_me1a[adr1[MXADRB-1:0]];
  rd_me1b_data0 <= rom_me1b[adr0[MXADRB-1:0]];
  rd_me1b_data1 <= rom_me1b[adr1[MXADRB-1:0]];
end

assign me1ard0 = (evenchamber) ? rd_me1a_data0[MXDATB-1:0] : rd_me1a_data1[MXDATB-1:0]; //low end
assign me1ard1 = (evenchamber) ? rd_me1a_data1[MXDATB-1:0] : rd_me1a_data0[MXDATB-1:0]; //high end
assign me1brd0 = (evenchamber) ? rd_me1b_data0[MXDATB-1:0] : rd_me1b_data1[MXDATB-1:0]; //low end
assign me1brd1 = (evenchamber) ? rd_me1b_data1[MXDATB-1:0] : rd_me1b_data0[MXDATB-1:0]; //high end

//assign me1ard0 = rd_me1a_data0[MXDATB-1:0]; //low end
//assign me1ard1 = rd_me1a_data1[MXDATB-1:0]; //high end
//assign me1brd0 = rd_me1b_data0[MXDATB-1:0]; //low end
//assign me1brd1 = rd_me1b_data1[MXDATB-1:0]; //high end

endmodule
