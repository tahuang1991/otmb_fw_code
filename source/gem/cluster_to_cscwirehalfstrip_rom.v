// used to translate two GEM clusters (0-1535) into flattened GEM "strip" coordinates (0-191)
// why 2 clusters? b/c we have a dualport RAM that can access 2 memory locations simultaneously. 
// why 0-191 ? can consider using csc h/s or strip or arbitrary units.. could
// just divide the chamber in thirds for example.. which would simplify this
// matching considerably but at what cost? 
// 1.gem roll+pad to wiregroup
// 2.gem pad to key HS in ME1A
// 3.gem pad to key HS in ME1B
// LUT files: 
//The most LUT files(rom_patA.mem etc) are taken from https://github.com/cms-data/L1Trigger-CSCTriggerPrimitives and the current firmware is using the version from 2021 April


module cluster_to_cscwirehalfstrip_rom (
	input                     clock,

        input                     evenchamber,   // even pair or not
        //input                     gemcsc_match_extrapolate,
        //input                     gem_match_enable,
        input      [4:0]          gem_clct_deltahs, // matching window in halfstrip direction
        input      [2:0]          gem_alct_deltawire, // matching window in wiregroup direction
        input                     gem_me1a_match_enable,
        input                     gem_me1b_match_enable,
        
        // GEM alignment correction
        input       gem_xshift_sign_eta0,
        input       gem_xshift_sign_eta1,
        input       gem_xshift_sign_eta2,
        input       gem_xshift_sign_eta3,
        input       gem_xshift_sign_eta4,
        input       gem_xshift_sign_eta5,
        input       gem_xshift_sign_eta6,
        input       gem_xshift_sign_eta7,
        input [6:0] gem_xshift_value_eta0,
        input [6:0] gem_xshift_value_eta1,
        input [6:0] gem_xshift_value_eta2,
        input [6:0] gem_xshift_value_eta3,
        input [6:0] gem_xshift_value_eta4,
        input [6:0] gem_xshift_value_eta5,
        input [6:0] gem_xshift_value_eta6,
        input [6:0] gem_xshift_value_eta7,

        input     [13:0]          cluster0,
        input                     cluster0_vpf,// valid or not
        input      [2:0]          cluster0_roll, // 0-7 
        input      [7:0]          cluster0_pad, // from 0-191
        input      [2:0]          cluster0_size, // from 0-7, 0 means 1 gem pad

        output     [WIREBITS-1:0] cluster0_cscwire_lo,
        output     [WIREBITS-1:0] cluster0_cscwire_hi,
        output     [WIREBITS-1:0] cluster0_cscwire_mi,//middle
        output     [MXXKYB-1:0]   cluster0_cscxky_lo, // from 0-127 for halfstrip, later replaced by xky resolution
        output     [MXXKYB-1:0]   cluster0_cscxky_hi, // from 0-127
        output     [MXXKYB-1:0]   cluster0_cscxky_mi, // from 128-223, middle
        output     [MXXKYB-1:0]   cluster0_cscxky_win, // strip match window
        output                    csc_cluster0_me1a,
        output     [13:0]         csc_cluster0,  
        output                    csc_cluster0_vpf,// valid or not
        //output      [2:0]         csc_cluster0_roll, // 0-7 
        //output      [7:0]         csc_cluster0_pad, // from 0-191
        //output      [2:0]         csc_cluster0_size, // from 0-7, 0 means 1 gem pad

        output  cluster_to_cscdummy
);

//parameter FALLING_EDGE = 0;

parameter MXCFEB       = 7;

parameter MXXKYB       = 10;            // Number of EightStrip key bits on 7 CFEBs
parameter WIREBITS     = 7; //wiregroup
parameter MAXWIRE      = 7'd47; //counting from0, max is 47, in total=48
parameter MINKEYHSME1B = 10'd0;
parameter MAXKEYHSME1B = 10'd511;
parameter MINKEYHSME1A = 10'd512;
parameter MAXKEYHSME1A = 10'd895;

//counter
parameter ICLST        = 0;
parameter GEMPADTOME1AES0_FILE     = "GEMCSCLUT_pad_es_ME1a_even.mem";
parameter GEMPADTOME1AES1_FILE     = "GEMCSCLUT_pad_es_ME1a_odd.mem";
parameter GEMPADTOME1BES0_FILE     = "GEMCSCLUT_pad_es_ME1b_even.mem";
parameter GEMPADTOME1BES1_FILE     = "GEMCSCLUT_pad_es_ME1b_odd.mem";
parameter GEMROLLTOMINWG0_FILE     = "GEMCSCLUT_roll_l1_min_wg_ME11_even.mem";
parameter GEMROLLTOMINWG1_FILE     = "GEMCSCLUT_roll_l1_min_wg_ME11_odd.mem";
parameter GEMROLLTOMAXWG0_FILE     = "GEMCSCLUT_roll_l1_max_wg_ME11_even.mem";
parameter GEMROLLTOMAXWG1_FILE     = "GEMCSCLUT_roll_l1_max_wg_ME11_odd.mem";

//reg [DATABITS-1:0] rom [ROMLENGTH-1:0];
//reg [MXXKYB-1:0] me1a_xky_lo, me1a_xky_hi, me1b_xky_lo, me1b_xky_hi; 
//reg [WIREBITS-1:0]  wire_lo, wire_hi;
wire [6:0] gem_clct_deltaxky = {gem_clct_deltahs, 2'b00};// convert HS level window to 1/8 strip level window


wire we = 0;
wire [7:0] w_adr1;
wire [2:0] w_adr2;
wire [MXXKYB-1:0] din1 = 0;
wire [WIREBITS-1:0] din2 = 0;

wire logic_clock;
assign logic_clock = clock;

//ME1a and ME1b seperation is at Eta2.1
wire [7:0] cluster0_pad_lo;
wire [7:0] cluster0_pad_hi;
//invalid gem pad number is 255;
assign cluster0_pad_lo    = cluster0_vpf ? cluster0_pad : 8'b0;
assign cluster0_pad_hi    = cluster0_vpf ? (cluster0_pad + cluster0_size) : 8'b0;
//assign cluster0_pad_hi    = cluster0_vpf ? (cluster0_pad + cluster0_size < 8'd192 ?  cluster0_pad + cluster0_size : 8'd191) : 8'b0;
 
wire [WIREBITS-1:0] wire_real_lo, wire_real_hi;
wire [MXXKYB-1:0] me1a_xky_real_lo, me1a_xky_real_hi, me1b_xky_real_lo, me1b_xky_real_hi;

rom_pad_es_evenodd #(
  .ROM_FILE_ME1A_ODD(GEMPADTOME1AES1_FILE),
  .ROM_FILE_ME1A_EVEN(GEMPADTOME1AES0_FILE),
  .ROM_FILE_ME1B_ODD(GEMPADTOME1BES1_FILE),
  .ROM_FILE_ME1B_EVEN(GEMPADTOME1BES0_FILE)
) romesevenodd (
  .clock(clock),
  .evenchamber(evenchamber),   // even pair or not
  .adr0(cluster0_pad_lo),
  .adr1(cluster0_pad_hi),
  .me1ard0 (me1a_xky_real_lo),
  .me1ard1 (me1a_xky_real_hi),
  .me1brd0 (me1b_xky_real_lo),
  .me1brd1 (me1b_xky_real_hi)
);


rom_roll_wg_evenodd #(
  .ROM_FILE_MIN_ODD(GEMROLLTOMINWG1_FILE),
  .ROM_FILE_MIN_EVEN(GEMROLLTOMINWG0_FILE),
  .ROM_FILE_MAX_ODD(GEMROLLTOMAXWG1_FILE),
  .ROM_FILE_MAX_EVEN(GEMROLLTOMAXWG0_FILE)
) romwgevenodd (
  .clock(clock),
  .evenchamber(evenchamber),
  .adr0(cluster0_roll),
  .rd0 (wire_real_lo),
  .rd1 (wire_real_hi)
);


reg [13:0]    reg_cluster0;
reg           reg_cluster0_vpf;// valid or not
//reg [2:0]     reg_cluster0_roll; // 0-7 
//reg [7:0]     reg_cluster0_pad; // from 0-191
//reg [2:0]     reg_cluster0_size; // from 0-7, 0 means 1 gem pad
reg           reg_cluster0_me1a;


reg       gem_xshift_sign; 
reg [6:0] gem_xshift_value; 
//1bx latency
always @(posedge logic_clock) begin
  case (cluster0_roll[2:0]) //roll number
  3'd0:  begin gem_xshift_sign = gem_xshift_sign_eta0;  gem_xshift_value[6:0] = gem_xshift_value_eta0[6:0]; end 
  3'd1:  begin gem_xshift_sign = gem_xshift_sign_eta1;  gem_xshift_value[6:0] = gem_xshift_value_eta1[6:0]; end 
  3'd2:  begin gem_xshift_sign = gem_xshift_sign_eta2;  gem_xshift_value[6:0] = gem_xshift_value_eta2[6:0]; end 
  3'd3:  begin gem_xshift_sign = gem_xshift_sign_eta3;  gem_xshift_value[6:0] = gem_xshift_value_eta3[6:0]; end 
  3'd4:  begin gem_xshift_sign = gem_xshift_sign_eta4;  gem_xshift_value[6:0] = gem_xshift_value_eta4[6:0]; end 
  3'd5:  begin gem_xshift_sign = gem_xshift_sign_eta5;  gem_xshift_value[6:0] = gem_xshift_value_eta5[6:0]; end 
  3'd6:  begin gem_xshift_sign = gem_xshift_sign_eta6;  gem_xshift_value[6:0] = gem_xshift_value_eta6[6:0]; end 
  3'd7:  begin gem_xshift_sign = gem_xshift_sign_eta7;  gem_xshift_value[6:0] = gem_xshift_value_eta7[6:0]; end 
  default: begin gem_xshift_sign = 1'b0;  gem_xshift_value[6:0] = 7'b0; end
  endcase
end



always @(posedge logic_clock) begin

    //also add cluster_pad, roll, vpf here to align them in timing!!!
    reg_cluster0           <= cluster0;
    reg_cluster0_vpf       <= cluster0_vpf && (gem_me1b_match_enable || ((cluster0_roll== 3'd7) && gem_me1a_match_enable));
    //reg_cluster0_roll      <= cluster0_roll;
    //reg_cluster0_pad       <= cluster0_pad;
    //reg_cluster0_size      <= cluster0_size;
    reg_cluster0_me1a      <= (cluster0_roll== 3'd7) && gem_me1a_match_enable;

end



//assign me1a_xky_real_lo = (me1a_xky_lo < me1a_xky_hi) ? me1a_xky_lo : me1a_xky_hi;//even or odd, CSC strip arrangement are different 
//assign me1a_xky_real_hi = (me1a_xky_lo > me1a_xky_hi) ? me1a_xky_lo : me1a_xky_hi;
//assign me1b_xky_real_lo = (me1b_xky_lo < me1b_xky_hi) ? me1b_xky_lo : me1b_xky_hi;
//assign me1b_xky_real_hi = (me1b_xky_lo > me1b_xky_hi) ? me1b_xky_lo : me1b_xky_hi;

// adding matching window
assign cluster0_cscwire_lo  = (wire_real_lo > gem_alct_deltawire)             ? (wire_real_lo-gem_alct_deltawire) : 7'd0;
assign cluster0_cscwire_hi  = ((wire_real_hi + gem_alct_deltawire) < MAXWIRE) ? (wire_real_hi+gem_alct_deltawire) : 7'd47;
assign cluster0_cscwire_mi = wire_real_lo[WIREBITS-1:1] + wire_real_hi[WIREBITS-1:1] + (wire_real_lo[0] | wire_real_hi[0]);

//wire [MXXKYB-1:0]  cluster0_me1axky_lo  = (me1a_xky_real_lo > (MINKEYHSME1A+gem_clct_deltaxky)) ? (me1a_xky_real_lo-gem_clct_deltaxky) : MINKEYHSME1A; 
//wire [MXXKYB-1:0]  cluster0_me1bxky_lo  = (me1b_xky_real_lo > (MINKEYHSME1B+gem_clct_deltaxky)) ? (me1b_xky_real_lo-gem_clct_deltaxky) : MINKEYHSME1B;
//
//wire [MXXKYB-1:0]  cluster0_me1axky_hi  = ((me1a_xky_real_hi+gem_clct_deltaxky) > MAXKEYHSME1A) ? MAXKEYHSME1A : (me1a_xky_real_hi+gem_clct_deltaxky);
//wire [MXXKYB-1:0]  cluster0_me1bxky_hi  = ((me1b_xky_real_hi+gem_clct_deltaxky) > MAXKEYHSME1B) ? MAXKEYHSME1B : (me1b_xky_real_hi+gem_clct_deltaxky);
//wire [MXXKYB-1:0]  cluster0_me1axky_lo  = gem_xshift_sign ? me1a_xky_real_lo-gem_clct_deltaxky+gem_xshift_value : me1a_xky_real_lo-gem_clct_deltaxky-gem_xshift_value; 
//wire [MXXKYB-1:0]  cluster0_me1bxky_lo  = gem_xshift_sign ? me1b_xky_real_lo-gem_clct_deltaxky+gem_xshift_value : me1b_xky_real_lo-gem_clct_deltaxky-gem_xshift_value;
//
//wire [MXXKYB-1:0]  cluster0_me1axky_hi  = gem_xshift_sign ? me1a_xky_real_hi+gem_clct_deltaxky+gem_xshift_value : me1a_xky_real_hi+gem_clct_deltaxky-gem_xshift_value;
//wire [MXXKYB-1:0]  cluster0_me1bxky_hi  = gem_xshift_sign ? me1b_xky_real_hi+gem_clct_deltaxky+gem_xshift_value : me1a_xky_real_hi+gem_clct_deltaxky-gem_xshift_value;
//
wire [MXXKYB-1:0]  cluster0_me1axky_lo  = me1a_xky_real_lo-gem_clct_deltaxky; 
wire [MXXKYB-1:0]  cluster0_me1bxky_lo  = me1b_xky_real_lo-gem_clct_deltaxky;

wire [MXXKYB-1:0]  cluster0_me1axky_hi  = me1a_xky_real_hi+gem_clct_deltaxky;
wire [MXXKYB-1:0]  cluster0_me1bxky_hi  = me1b_xky_real_hi+gem_clct_deltaxky;

wire [MXXKYB-1:0]  cluster0_me1axky_mi  = me1a_xky_real_lo[MXXKYB-1:1]+me1a_xky_real_hi[MXXKYB-1:1]+(me1a_xky_real_lo[0] | me1a_xky_real_hi[0]);
wire [MXXKYB-1:0]  cluster0_me1bxky_mi  = me1b_xky_real_lo[MXXKYB-1:1]+me1b_xky_real_hi[MXXKYB-1:1]+(me1b_xky_real_lo[0] | me1b_xky_real_hi[0]);

wire [MXXKYB-1:0]  cluster0_me1axky_win = me1a_xky_real_hi[MXXKYB-1:1]-me1a_xky_real_lo[MXXKYB-1:1]+gem_clct_deltaxky;
wire [MXXKYB-1:0]  cluster0_me1bxky_win = me1b_xky_real_hi[MXXKYB-1:1]-me1b_xky_real_lo[MXXKYB-1:1]+gem_clct_deltaxky;

//assign cluster0_cscxky_lo = (csc_cluster0_me1a) ? cluster0_me1axky_lo : cluster0_me1bxky_lo;
//assign cluster0_cscxky_hi = (csc_cluster0_me1a) ? cluster0_me1axky_hi : cluster0_me1bxky_hi;
//assign cluster0_cscxky_mi = (csc_cluster0_me1a) ? cluster0_me1axky_mi : cluster0_me1bxky_mi;
wire[MXXKYB-1:0] cluster0_cscxky_tmp_lo = (csc_cluster0_me1a) ? cluster0_me1axky_lo : cluster0_me1bxky_lo;
wire[MXXKYB-1:0] cluster0_cscxky_tmp_hi = (csc_cluster0_me1a) ? cluster0_me1axky_hi : cluster0_me1bxky_hi;
wire[MXXKYB-1:0] cluster0_cscxky_tmp_mi = (csc_cluster0_me1a) ? cluster0_me1axky_mi : cluster0_me1bxky_mi;
assign cluster0_cscxky_lo = gem_xshift_sign ? cluster0_cscxky_tmp_lo+gem_xshift_value : cluster0_cscxky_tmp_lo-gem_xshift_value; 
assign cluster0_cscxky_hi = gem_xshift_sign ? cluster0_cscxky_tmp_hi+gem_xshift_value : cluster0_cscxky_tmp_hi-gem_xshift_value; 
assign cluster0_cscxky_mi = gem_xshift_sign ? cluster0_cscxky_tmp_mi+gem_xshift_value : cluster0_cscxky_tmp_mi-gem_xshift_value; 
assign cluster0_cscxky_win = (csc_cluster0_me1a) ? cluster0_me1axky_win : cluster0_me1bxky_win;


//assign cluster0_cscxky_lo = (csc_cluster0_me1a) ? ((me1a_xky_real_lo > MINKEYHSME1A+gem_clct_deltaxky) ? me1a_xky_real_lo-gem_clct_deltaxky : MINKEYHSME1A) : ((me1b_xky_real_lo > MINKEYHSME1B+gem_clct_deltaxky) ? me1b_xky_real_lo-gem_clct_deltaxky : MINKEYHSME1B);
//assign cluster0_cscxky_hi = (csc_cluster0_me1a) ? ((me1a_xky_real_hi+gem_clct_deltaxky > MAXKEYHSME1A) ? MAXKEYHSME1A : me1a_xky_real_hi+gem_clct_deltaxky) : ((me1b_xky_real_hi+gem_clct_deltaxky > MAXKEYHSME1B) ? MAXKEYHSME1B : me1b_xky_real_hi+gem_clct_deltaxky);
//assign cluster0_cscxky_mi = (csc_cluster0_me1a) ? (me1a_xky_real_lo[MXXKYB-1:1]+me1a_xky_real_hi[MXXKYB-1:1]+(me1a_xky_real_lo[0] | me1a_xky_real_hi[0])) : (me1b_xky_real_lo[MXXKYB-1:1]+me1b_xky_real_hi[MXXKYB-1:1]+(me1b_xky_real_lo[0] | me1b_xky_real_hi[0]));

assign csc_cluster0       = reg_cluster0;
assign csc_cluster0_vpf   = reg_cluster0_vpf;// valid or not
//assign csc_cluster0_roll  = reg_cluster0_roll; // 0-7 
//assign csc_cluster0_pad   = reg_cluster0_pad; // from 0-191
//assign csc_cluster0_size  = reg_cluster0_size; // from 0-7, 0 means 1 gem pad
assign csc_cluster0_me1a  = reg_cluster0_me1a; // only roll7 is matchd to ME1a, 1 for ME1a, 0 for ME1b

assign cluster_to_cscdummy = 1'b0;

endmodule
