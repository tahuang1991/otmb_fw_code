//GEM roll to CSC wiregroup
//GEM roll: 0-7;    CSC wiregroup: 0-48 for ME11

module rom_roll_wg (
  input clock,
  input evenchamber,
  input  [MXADRB-1:0] adr0,
  output [MXDATB-1:0] rd0,  
  output [MXDATB-1:0] rd1   
);

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------

parameter FALLING_EDGE = 0;
parameter MXADRB       = 3;
parameter MXDATB       = 7;//
parameter ROMLENGTH    = 8;
parameter ROM_FILE_MIN_ODD     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_MAX_ODD     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_MIN_EVEN     = "../source/pattern_finder/default.dat";
parameter ROM_FILE_MAX_EVEN     = "../source/pattern_finder/default.dat";

//----------------------------------------------------------------------------------------------------------------------
// Signals
//----------------------------------------------------------------------------------------------------------------------

reg [MXDATB-1:0] rom_min_odd [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_max_odd [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_min_even [ROMLENGTH-1:0];
reg [MXDATB-1:0] rom_max_even [ROMLENGTH-1:0];
reg [MXDATB-1:0] rd_data_min; //min
reg [MXDATB-1:0] rd_data_max; //max
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

initial begin
  $readmemh(ROM_FILE_MIN_ODD, rom_min_odd);
  $readmemh(ROM_FILE_MAX_ODD, rom_max_odd);
  $readmemh(ROM_FILE_MIN_EVEN, rom_min_even);
  $readmemh(ROM_FILE_MAX_EVEN, rom_max_even);
end

//----------------------------------------------------------------------------------------------------------------------
// ROM
//----------------------------------------------------------------------------------------------------------------------

always @(posedge logic_clock) begin
  if (we)  begin
    rom_min_odd[adr0[MXADRB-1:0]] <=din;  // dummy write to help Xilinx infer a dual port block RAM
    rom_max_odd[adr0[MXADRB-1:0]] <=din;  // dummy write to help Xilinx infer a dual port block RAM
    rom_min_even[adr0[MXADRB-1:0]]<=din;  // dummy write to help Xilinx infer a dual port block RAM
    rom_max_even[adr0[MXADRB-1:0]]<=din;  // dummy write to help Xilinx infer a dual port block RAM
  end

  rd_data_min <= evenchamber ? rom_min_even[adr0[MXADRB-1:0]] : rom_min_even[adr0[MXADRB-1:0]];
  rd_data_max <= evenchamber ? rom_max_even[adr0[MXADRB-1:0]] : rom_max_even[adr0[MXADRB-1:0]];
end

assign rd0 = rd_data_min[MXDATB-1:0];
assign rd1 = rd_data_max[MXDATB-1:0];

endmodule
