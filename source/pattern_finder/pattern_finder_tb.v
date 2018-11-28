module pattern_finder_tb (

output [MXCFEB-1:0]   cfeb_hit,
output [MXCFEB-1:0]   cfeb_active,
output                cfeb_layer_trig,
output [MXLY-1:0]     cfeb_layer_or,
output [MXHITB-1:0]   cfeb_nlayers_hit,
output [15:0]         clct_sep_ram_rdata,

output [MXHITB-1:0]  hs_hit_1st, // Out  1st CLCT pattern hits
output [MXPIDB-1:0]  hs_pid_1st, // Out  1st CLCT pattern ID
output [MXKEYBX-1:0] hs_key_1st, // Out  1st CLCT key 1/2-strip

output [MXHITB-1:0]  hs_hit_2nd, // Out  2nd CLCT pattern hits
output [MXPIDB-1:0]  hs_pid_2nd, // Out  2nd CLCT pattern ID
output [MXKEYBX-1:0] hs_key_2nd, // Out  2nd CLCT key 1/2-strip
output               hs_bsy_2nd, // Out  2nd CLCT busy, logic error indicator

output              hs_layer_trig,  // Out  Layer triggered
output [MXHITB-1:0] hs_nlayers_hit, // Out  Number of layers hit
output [MXLY-1:0]   hs_layer_or,    // Out  Layer ORs

output [MXQLTB     - 1:0] hs_qlt_1st,
output [MXBNDB     - 1:0] hs_bnd_1st,
output [MXPATC     - 1:0] hs_car_1st,
output [MXSUBKEYBX - 1:0] hs_xky_1st,

output [MXQLTB     - 1:0] hs_qlt_2nd,
output [MXBNDB     - 1:0] hs_bnd_2nd,
output [MXPATC     - 1:0] hs_car_2nd,
output [MXSUBKEYBX - 1:0] hs_xky_2nd
);

`include "pattern_params.v"

  wire [3: 0] csc_type;        // Firmware compile type
  wire        csc_me1ab;       // 1=ME1A or ME1B CSC type
  wire        stagger_hs_csc;  // 1=Staggered CSC non-me1, 0=non-staggered me1
  wire        reverse_hs_csc;  // 1=Reverse staggered CSC, non-me1
  wire        reverse_hs_me1a; // 1=reverse me1a hstrips prior to pattern sorting
  wire        reverse_hs_me1b; // 1=reverse me1b hstrips prior to pattern sorting


wire global_reset = 0;

reg clock = 1;
always @(*)
  clock <= #12.5 ~clock;

reg [31:0] iclk = 32'd0;

always @(posedge clock)
  iclk <= iclk + 1'b1;


wire layer_trig_en = 0;

// inputs

wire [MXHITB-1:0]   lyr_thresh_pretrig = 'd3;
wire [MXHITB-1:0]   hit_thresh_pretrig = 'd3;
wire [MXPIDB-1:0]   pid_thresh_pretrig = 'd2;
wire [MXHITB-1:0]   dmb_thresh_pretrig = 'd3;
wire [MXCFEB-1:0]   cfeb_en            = 'b1111111;
wire [MXKEYB-1+1:0] adjcfeb_dist       = 'd8;
wire                clct_blanking      = 'b1;

wire         clct_sep_src       = 'b1; // 1==vme, 0==ram
wire  [7:0]  clct_sep_vme       = 'd12;
wire         clct_sep_ram_we    = 'b0;
wire  [3:0]  clct_sep_ram_adr   = 'd0;
wire  [15:0] clct_sep_ram_wdata = 'd0;

wire [10:0] pat_ly0;
wire [10:0] pat_ly1;
wire [10:0] pat_ly2;
wire [10:0] pat_ly3;
wire [10:0] pat_ly4;
wire [10:0] pat_ly5;

reg [10:0] pat_ly0_expect_injector;
reg [10:0] pat_ly1_expect_injector;
reg [10:0] pat_ly2_expect_injector;
reg [10:0] pat_ly3_expect_injector;
reg [10:0] pat_ly4_expect_injector;
reg [10:0] pat_ly5_expect_injector;

wire [10:0] pat_ly0_expect, pat_ly0_expect_mem;
wire [10:0] pat_ly1_expect, pat_ly1_expect_mem;
wire [10:0] pat_ly2_expect, pat_ly2_expect_mem;
wire [10:0] pat_ly3_expect, pat_ly3_expect_mem;
wire [10:0] pat_ly4_expect, pat_ly4_expect_mem;
wire [10:0] pat_ly5_expect, pat_ly5_expect_mem;


  assign pat_ly0_expect = use_injector ? pat_ly0_expect_injector : pat_ly0_expect_mem;
  assign pat_ly1_expect = use_injector ? pat_ly1_expect_injector : pat_ly1_expect_mem;
  assign pat_ly2_expect = use_injector ? pat_ly2_expect_injector : pat_ly2_expect_mem;
  assign pat_ly3_expect = use_injector ? pat_ly3_expect_injector : pat_ly3_expect_mem;
  assign pat_ly4_expect = use_injector ? pat_ly4_expect_injector : pat_ly4_expect_mem;
  assign pat_ly5_expect = use_injector ? pat_ly5_expect_injector : pat_ly5_expect_mem;

wire [223:0] cfeb_ly0;
wire [223:0] cfeb_ly1;
wire [223:0] cfeb_ly2;
wire [223:0] cfeb_ly3;
wire [223:0] cfeb_ly4;
wire [223:0] cfeb_ly5;


wire [MXHS - 1: 0] cfeb0_ly0hs, cfeb0_ly1hs, cfeb0_ly2hs, cfeb0_ly3hs, cfeb0_ly4hs, cfeb0_ly5hs;
wire [MXHS - 1: 0] cfeb1_ly0hs, cfeb1_ly1hs, cfeb1_ly2hs, cfeb1_ly3hs, cfeb1_ly4hs, cfeb1_ly5hs;
wire [MXHS - 1: 0] cfeb2_ly0hs, cfeb2_ly1hs, cfeb2_ly2hs, cfeb2_ly3hs, cfeb2_ly4hs, cfeb2_ly5hs;
wire [MXHS - 1: 0] cfeb3_ly0hs, cfeb3_ly1hs, cfeb3_ly2hs, cfeb3_ly3hs, cfeb3_ly4hs, cfeb3_ly5hs;
wire [MXHS - 1: 0] cfeb4_ly0hs, cfeb4_ly1hs, cfeb4_ly2hs, cfeb4_ly3hs, cfeb4_ly4hs, cfeb4_ly5hs;
wire [MXHS - 1: 0] cfeb5_ly0hs, cfeb5_ly1hs, cfeb5_ly2hs, cfeb5_ly3hs, cfeb5_ly4hs, cfeb5_ly5hs;
wire [MXHS - 1: 0] cfeb6_ly0hs, cfeb6_ly1hs, cfeb6_ly2hs, cfeb6_ly3hs, cfeb6_ly4hs, cfeb6_ly5hs;

reg [3:0] pulse_wait_cnt = 0;
always @(posedge clock)
  pulse_wait_cnt <= pulse_wait_cnt + 1'b1;

wire pulse = (pulse_wait_cnt == 'd15);

assign {cfeb6_ly0hs, cfeb5_ly0hs, cfeb4_ly0hs, cfeb3_ly0hs, cfeb2_ly0hs, cfeb1_ly0hs, cfeb0_ly0hs} = {224{pulse}} & cfeb_ly0;
assign {cfeb6_ly1hs, cfeb5_ly1hs, cfeb4_ly1hs, cfeb3_ly1hs, cfeb2_ly1hs, cfeb1_ly1hs, cfeb0_ly1hs} = {224{pulse}} & cfeb_ly1;
assign {cfeb6_ly2hs, cfeb5_ly2hs, cfeb4_ly2hs, cfeb3_ly2hs, cfeb2_ly2hs, cfeb1_ly2hs, cfeb0_ly2hs} = {224{pulse}} & cfeb_ly2;
assign {cfeb6_ly3hs, cfeb5_ly3hs, cfeb4_ly3hs, cfeb3_ly3hs, cfeb2_ly3hs, cfeb1_ly3hs, cfeb0_ly3hs} = {224{pulse}} & cfeb_ly3;
assign {cfeb6_ly4hs, cfeb5_ly4hs, cfeb4_ly4hs, cfeb3_ly4hs, cfeb2_ly4hs, cfeb1_ly4hs, cfeb0_ly4hs} = {224{pulse}} & cfeb_ly4;
assign {cfeb6_ly5hs, cfeb5_ly5hs, cfeb4_ly5hs, cfeb3_ly5hs, cfeb2_ly5hs, cfeb1_ly5hs, cfeb0_ly5hs} = {224{pulse}} & cfeb_ly5;

reg  [7:0]  key_hs_to_pulse = 'd0; // $unsigned ($random) % 223;
reg  [11:0] ccode_to_pulse  = 'hAAA;
reg  [3:0]  pat_to_pulse    = 'hA; // ($unsigned($random) % 4) + 6;
reg  ccode_over_threshold;

parameter use_injector = 1;

wire  [7:0]  key_hs_expect , key_hs_expect_mem ;
wire  [11:0] ccode_expect  , ccode_expect_mem  ;
wire  [3:0]  pat_expect    , pat_expect_mem    ;

reg  [7:0]  key_hs_expect_injector ;
reg  [11:0] ccode_expect_injector  ;
reg  [3:0]  pat_expect_injector    ;

  assign key_hs_expect = use_injector ? key_hs_expect_injector : key_hs_expect_mem;
  assign ccode_expect  = use_injector ? ccode_expect_injector  : ccode_expect_mem ;
  assign pat_expect    = use_injector ? pat_expect_injector    : pat_expect_mem   ;

always @(*) begin
    ccode_over_threshold <=(( ccode_to_pulse[11:10] + |ccode_to_pulse[9:8] + |ccode_to_pulse[7:6] + |ccode_to_pulse[5:4] + |ccode_to_pulse[3:2] + |ccode_to_pulse[1:0]) >= hit_thresh_pretrig)
                         && ((|cfeb_ly0 + |cfeb_ly1 + |cfeb_ly2 + |cfeb_ly3 + |cfeb_ly4 + |cfeb_ly5) >= hit_thresh_pretrig);
end

always @(posedge clock) begin
  if (pulse) begin
    if      (key_hs_to_pulse==224 )  key_hs_to_pulse <= 0;
    else if (ccode_over_threshold)   key_hs_to_pulse <= key_hs_to_pulse + 1'b1;

    ccode_to_pulse   <= $unsigned($random) % 4095;
    //pat_to_pulse     <= ($unsigned($random) % 4) + 6;

    key_hs_expect_injector   <= key_hs_to_pulse;
    ccode_expect_injector    <= ccode_to_pulse;
    pat_expect_injector      <= pat_to_pulse;

    pat_ly0_expect_injector <=pat_ly0;
    pat_ly1_expect_injector <=pat_ly1;
    pat_ly2_expect_injector <=pat_ly2;
    pat_ly3_expect_injector <=pat_ly3;
    pat_ly4_expect_injector <=pat_ly4;
    pat_ly5_expect_injector <=pat_ly5;
  end
end

always @(posedge pulse) begin
  $display ("%d pulsing hs=%d, pat=%x, ccode=%x", iclk, key_hs_to_pulse, pat_to_pulse, ccode_to_pulse );
end

`ifdef CSC_TYPE_C

  wire [MXHS * 3 - 1: 0] me1a_ly0hs;
  wire [MXHS * 3 - 1: 0] me1a_ly1hs;
  wire [MXHS * 3 - 1: 0] me1a_ly2hs;
  wire [MXHS * 3 - 1: 0] me1a_ly3hs;
  wire [MXHS * 3 - 1: 0] me1a_ly4hs;
  wire [MXHS * 3 - 1: 0] me1a_ly5hs;

  wire [MXHS * 4 - 1: 0] me1b_ly0hs;
  wire [MXHS * 4 - 1: 0] me1b_ly1hs;
  wire [MXHS * 4 - 1: 0] me1b_ly2hs;
  wire [MXHS * 4 - 1: 0] me1b_ly3hs;
  wire [MXHS * 4 - 1: 0] me1b_ly4hs;
  wire [MXHS * 4 - 1: 0] me1b_ly5hs;

  assign csc_type        = 4'hC; // Firmware compile type
  assign csc_me1ab       = 1;    // 1 = ME1A or ME1B CSC
  assign stagger_hs_csc  = 0;    // 1 = Staggered CSC non-ME1
  assign reverse_hs_csc  = 0;    // 1 = Reversed  CSC non-ME1
  assign reverse_hs_me1a = 1;    // 1 = Reverse ME1A HalfStrips prior to pattern sorting
  assign reverse_hs_me1b = 0;    // 1 = Reverse ME1B HalfStrips prior to pattern sorting
  initial $display ("CSC_TYPE_C instantiated");

  // Generate hs reversal map for ME1A
  wire [MXHS - 1: 0] cfeb4_ly0hsr, cfeb4_ly1hsr, cfeb4_ly2hsr, cfeb4_ly3hsr, cfeb4_ly4hsr, cfeb4_ly5hsr;
  wire [MXHS - 1: 0] cfeb5_ly0hsr, cfeb5_ly1hsr, cfeb5_ly2hsr, cfeb5_ly3hsr, cfeb5_ly4hsr, cfeb5_ly5hsr;
  wire [MXHS - 1: 0] cfeb6_ly0hsr, cfeb6_ly1hsr, cfeb6_ly2hsr, cfeb6_ly3hsr, cfeb6_ly4hsr, cfeb6_ly5hsr;

  genvar ihs;
  generate
    for (ihs = 0; ihs <= MXHS - 1; ihs = ihs + 1) begin: hsrev
      assign cfeb4_ly0hsr[ihs] = cfeb4_ly0hs[(MXHS - 1) - ihs];
      assign cfeb4_ly1hsr[ihs] = cfeb4_ly1hs[(MXHS - 1) - ihs];
      assign cfeb4_ly2hsr[ihs] = cfeb4_ly2hs[(MXHS - 1) - ihs];
      assign cfeb4_ly3hsr[ihs] = cfeb4_ly3hs[(MXHS - 1) - ihs];
      assign cfeb4_ly4hsr[ihs] = cfeb4_ly4hs[(MXHS - 1) - ihs];
      assign cfeb4_ly5hsr[ihs] = cfeb4_ly5hs[(MXHS - 1) - ihs];

      assign cfeb5_ly0hsr[ihs] = cfeb5_ly0hs[(MXHS - 1) - ihs];
      assign cfeb5_ly1hsr[ihs] = cfeb5_ly1hs[(MXHS - 1) - ihs];
      assign cfeb5_ly2hsr[ihs] = cfeb5_ly2hs[(MXHS - 1) - ihs];
      assign cfeb5_ly3hsr[ihs] = cfeb5_ly3hs[(MXHS - 1) - ihs];
      assign cfeb5_ly4hsr[ihs] = cfeb5_ly4hs[(MXHS - 1) - ihs];
      assign cfeb5_ly5hsr[ihs] = cfeb5_ly5hs[(MXHS - 1) - ihs];

      assign cfeb6_ly0hsr[ihs] = cfeb6_ly0hs[(MXHS - 1) - ihs];
      assign cfeb6_ly1hsr[ihs] = cfeb6_ly1hs[(MXHS - 1) - ihs];
      assign cfeb6_ly2hsr[ihs] = cfeb6_ly2hs[(MXHS - 1) - ihs];
      assign cfeb6_ly3hsr[ihs] = cfeb6_ly3hs[(MXHS - 1) - ihs];
      assign cfeb6_ly4hsr[ihs] = cfeb6_ly4hs[(MXHS - 1) - ihs];
      assign cfeb6_ly5hsr[ihs] = cfeb6_ly5hs[(MXHS - 1) - ihs];
    end
  endgenerate

  // Reversed ME1A CFEBs: 4, 5, 6
  assign me1a_ly0hs = {cfeb4_ly0hsr, cfeb5_ly0hsr, cfeb6_ly0hsr};
  assign me1a_ly1hs = {cfeb4_ly1hsr, cfeb5_ly1hsr, cfeb6_ly1hsr};
  assign me1a_ly2hs = {cfeb4_ly2hsr, cfeb5_ly2hsr, cfeb6_ly2hsr};
  assign me1a_ly3hs = {cfeb4_ly3hsr, cfeb5_ly3hsr, cfeb6_ly3hsr};
  assign me1a_ly4hs = {cfeb4_ly4hsr, cfeb5_ly4hsr, cfeb6_ly4hsr};
  assign me1a_ly5hs = {cfeb4_ly5hsr, cfeb5_ly5hsr, cfeb6_ly5hsr};

  // Normal ME1B CFEBs: 3, 2, 1, 0
  assign me1b_ly0hs = {cfeb3_ly0hs, cfeb2_ly0hs, cfeb1_ly0hs, cfeb0_ly0hs};
  assign me1b_ly1hs = {cfeb3_ly1hs, cfeb2_ly1hs, cfeb1_ly1hs, cfeb0_ly1hs};
  assign me1b_ly2hs = {cfeb3_ly2hs, cfeb2_ly2hs, cfeb1_ly2hs, cfeb0_ly2hs};
  assign me1b_ly3hs = {cfeb3_ly3hs, cfeb2_ly3hs, cfeb1_ly3hs, cfeb0_ly3hs};
  assign me1b_ly4hs = {cfeb3_ly4hs, cfeb2_ly4hs, cfeb1_ly4hs, cfeb0_ly4hs};
  assign me1b_ly5hs = {cfeb3_ly5hs, cfeb2_ly5hs, cfeb1_ly5hs, cfeb0_ly5hs};

`elsif CSC_TYPE_D

  wire [MXHS * 3 - 1: 0] me1a_ly0hs;
  wire [MXHS * 3 - 1: 0] me1a_ly1hs;
  wire [MXHS * 3 - 1: 0] me1a_ly2hs;
  wire [MXHS * 3 - 1: 0] me1a_ly3hs;
  wire [MXHS * 3 - 1: 0] me1a_ly4hs;
  wire [MXHS * 3 - 1: 0] me1a_ly5hs;

  wire [MXHS * 4 - 1: 0] me1b_ly0hs;
  wire [MXHS * 4 - 1: 0] me1b_ly1hs;
  wire [MXHS * 4 - 1: 0] me1b_ly2hs;
  wire [MXHS * 4 - 1: 0] me1b_ly3hs;
  wire [MXHS * 4 - 1: 0] me1b_ly4hs;
  wire [MXHS * 4 - 1: 0] me1b_ly5hs;

  assign csc_type        = 4'hD; // Firmware compile type
  assign csc_me1ab       = 1;    // 1 = ME1A or ME1B CSC
  assign stagger_hs_csc  = 0;    // 1 = Staggered CSC non-ME1
  assign reverse_hs_csc  = 0;    // 1 = Reversed  CSC non-ME1
  assign reverse_hs_me1a = 0;    // 1 = Reverse ME1A HalfStrips prior to pattern sorting
  assign reverse_hs_me1b = 1;    // 1 = Reverse ME1B HalfStrips prior to pattern sorting
  initial $display ("CSC_TYPE_D instantiated");

  // Generate hs reversal map for ME1B
  wire [MXHS - 1: 0] cfeb0_ly0hsr, cfeb0_ly1hsr, cfeb0_ly2hsr, cfeb0_ly3hsr, cfeb0_ly4hsr, cfeb0_ly5hsr;
  wire [MXHS - 1: 0] cfeb1_ly0hsr, cfeb1_ly1hsr, cfeb1_ly2hsr, cfeb1_ly3hsr, cfeb1_ly4hsr, cfeb1_ly5hsr;
  wire [MXHS - 1: 0] cfeb2_ly0hsr, cfeb2_ly1hsr, cfeb2_ly2hsr, cfeb2_ly3hsr, cfeb2_ly4hsr, cfeb2_ly5hsr;
  wire [MXHS - 1: 0] cfeb3_ly0hsr, cfeb3_ly1hsr, cfeb3_ly2hsr, cfeb3_ly3hsr, cfeb3_ly4hsr, cfeb3_ly5hsr;

  genvar ihs;
  generate
    for (ihs = 0; ihs <= MXHS - 1; ihs = ihs + 1) begin: hsrev
      assign cfeb0_ly0hsr[ihs] = cfeb0_ly0hs[(MXHS - 1) - ihs];
      assign cfeb0_ly1hsr[ihs] = cfeb0_ly1hs[(MXHS - 1) - ihs];
      assign cfeb0_ly2hsr[ihs] = cfeb0_ly2hs[(MXHS - 1) - ihs];
      assign cfeb0_ly3hsr[ihs] = cfeb0_ly3hs[(MXHS - 1) - ihs];
      assign cfeb0_ly4hsr[ihs] = cfeb0_ly4hs[(MXHS - 1) - ihs];
      assign cfeb0_ly5hsr[ihs] = cfeb0_ly5hs[(MXHS - 1) - ihs];

      assign cfeb1_ly0hsr[ihs] = cfeb1_ly0hs[(MXHS - 1) - ihs];
      assign cfeb1_ly1hsr[ihs] = cfeb1_ly1hs[(MXHS - 1) - ihs];
      assign cfeb1_ly2hsr[ihs] = cfeb1_ly2hs[(MXHS - 1) - ihs];
      assign cfeb1_ly3hsr[ihs] = cfeb1_ly3hs[(MXHS - 1) - ihs];
      assign cfeb1_ly4hsr[ihs] = cfeb1_ly4hs[(MXHS - 1) - ihs];
      assign cfeb1_ly5hsr[ihs] = cfeb1_ly5hs[(MXHS - 1) - ihs];

      assign cfeb2_ly0hsr[ihs] = cfeb2_ly0hs[(MXHS - 1) - ihs];
      assign cfeb2_ly1hsr[ihs] = cfeb2_ly1hs[(MXHS - 1) - ihs];
      assign cfeb2_ly2hsr[ihs] = cfeb2_ly2hs[(MXHS - 1) - ihs];
      assign cfeb2_ly3hsr[ihs] = cfeb2_ly3hs[(MXHS - 1) - ihs];
      assign cfeb2_ly4hsr[ihs] = cfeb2_ly4hs[(MXHS - 1) - ihs];
      assign cfeb2_ly5hsr[ihs] = cfeb2_ly5hs[(MXHS - 1) - ihs];

      assign cfeb3_ly0hsr[ihs] = cfeb3_ly0hs[(MXHS - 1) - ihs];
      assign cfeb3_ly1hsr[ihs] = cfeb3_ly1hs[(MXHS - 1) - ihs];
      assign cfeb3_ly2hsr[ihs] = cfeb3_ly2hs[(MXHS - 1) - ihs];
      assign cfeb3_ly3hsr[ihs] = cfeb3_ly3hs[(MXHS - 1) - ihs];
      assign cfeb3_ly4hsr[ihs] = cfeb3_ly4hs[(MXHS - 1) - ihs];
      assign cfeb3_ly5hsr[ihs] = cfeb3_ly5hs[(MXHS - 1) - ihs];
    end
  endgenerate

  // Normal ME1A CFEBs: 6, 5, 4
  assign me1a_ly0hs = {cfeb6_ly0hs, cfeb5_ly0hs, cfeb4_ly0hs};
  assign me1a_ly1hs = {cfeb6_ly1hs, cfeb5_ly1hs, cfeb4_ly1hs};
  assign me1a_ly2hs = {cfeb6_ly2hs, cfeb5_ly2hs, cfeb4_ly2hs};
  assign me1a_ly3hs = {cfeb6_ly3hs, cfeb5_ly3hs, cfeb4_ly3hs};
  assign me1a_ly4hs = {cfeb6_ly4hs, cfeb5_ly4hs, cfeb4_ly4hs};
  assign me1a_ly5hs = {cfeb6_ly5hs, cfeb5_ly5hs, cfeb4_ly5hs};

  // Reversed ME1B CFEBs: 0, 1, 2, 3
  assign me1b_ly0hs = {cfeb0_ly0hsr, cfeb1_ly0hsr, cfeb2_ly0hsr, cfeb3_ly0hsr};
  assign me1b_ly1hs = {cfeb0_ly1hsr, cfeb1_ly1hsr, cfeb2_ly1hsr, cfeb3_ly1hsr};
  assign me1b_ly2hs = {cfeb0_ly2hsr, cfeb1_ly2hsr, cfeb2_ly2hsr, cfeb3_ly2hsr};
  assign me1b_ly3hs = {cfeb0_ly3hsr, cfeb1_ly3hsr, cfeb2_ly3hsr, cfeb3_ly3hsr};
  assign me1b_ly4hs = {cfeb0_ly4hsr, cfeb1_ly4hsr, cfeb2_ly4hsr, cfeb3_ly4hsr};
  assign me1b_ly5hs = {cfeb0_ly5hsr, cfeb1_ly5hsr, cfeb2_ly5hsr, cfeb3_ly5hsr};
`endif

wire [MXHSX - 1: 0] ly0hs, ly0hs_mem;
wire [MXHSX - 1: 0] ly1hs, ly1hs_mem;
wire [MXHSX - 1: 0] ly2hs, ly2hs_mem;      // key layer 2
wire [MXHSX - 1: 0] ly3hs, ly3hs_mem;
wire [MXHSX - 1: 0] ly4hs, ly4hs_mem;
wire [MXHSX - 1: 0] ly5hs, ly5hs_mem;

assign ly0hs = {me1a_ly0hs, me1b_ly0hs}; // No stagger correction
assign ly1hs = {me1a_ly1hs, me1b_ly1hs};
assign ly2hs = {me1a_ly2hs, me1b_ly2hs};
assign ly3hs = {me1a_ly3hs, me1b_ly3hs};
assign ly4hs = {me1a_ly4hs, me1b_ly4hs};
assign ly5hs = {me1a_ly5hs, me1b_ly5hs};

wire [MXHS - 1: 0] cfeb0_ly0hst, cfeb0_ly1hst, cfeb0_ly2hst, cfeb0_ly3hst, cfeb0_ly4hst, cfeb0_ly5hst;
wire [MXHS - 1: 0] cfeb1_ly0hst, cfeb1_ly1hst, cfeb1_ly2hst, cfeb1_ly3hst, cfeb1_ly4hst, cfeb1_ly5hst;
wire [MXHS - 1: 0] cfeb2_ly0hst, cfeb2_ly1hst, cfeb2_ly2hst, cfeb2_ly3hst, cfeb2_ly4hst, cfeb2_ly5hst;
wire [MXHS - 1: 0] cfeb3_ly0hst, cfeb3_ly1hst, cfeb3_ly2hst, cfeb3_ly3hst, cfeb3_ly4hst, cfeb3_ly5hst;
wire [MXHS - 1: 0] cfeb4_ly0hst, cfeb4_ly1hst, cfeb4_ly2hst, cfeb4_ly3hst, cfeb4_ly4hst, cfeb4_ly5hst;
wire [MXHS - 1: 0] cfeb5_ly0hst, cfeb5_ly1hst, cfeb5_ly2hst, cfeb5_ly3hst, cfeb5_ly4hst, cfeb5_ly5hst;
wire [MXHS - 1: 0] cfeb6_ly0hst, cfeb6_ly1hst, cfeb6_ly2hst, cfeb6_ly3hst, cfeb6_ly4hst, cfeb6_ly5hst;

//always @(posedge pulse) begin
//  $display ("        %b", ly0hs);
//  $display ("        %b", ly1hs);
//  $display ("        %b", ly2hs);
//  $display ("        %b", ly3hs);
//  $display ("        %b", ly4hs);
//  $display ("        %b", ly5hs);
//end

comparator_generator ucomparator_generator (
  .reset   (global_reset),
  .key_hs  (key_hs_to_pulse),
  .ccode   (ccode_to_pulse),
  .pattern (pat_to_pulse),
  .pat_ly0 (pat_ly0),
  .pat_ly1 (pat_ly1),
  .pat_ly2 (pat_ly2),
  .pat_ly3 (pat_ly3),
  .pat_ly4 (pat_ly4),
  .pat_ly5 (pat_ly5),
  .cfeb_ly0 (cfeb_ly0),
  .cfeb_ly1 (cfeb_ly1),
  .cfeb_ly2 (cfeb_ly2),
  .cfeb_ly3 (cfeb_ly3),
  .cfeb_ly4 (cfeb_ly4),
  .cfeb_ly5 (cfeb_ly5)
);

mem_reader umem_reader (
  .clock          (clock),
  .increment      (pulse),
  .ly0            (ly0hs_mem),
  .ly1            (ly0hs_mem),
  .ly2            (ly0hs_mem),
  .ly3            (ly0hs_mem),
  .ly4            (ly0hs_mem),
  .ly5            (ly0hs_mem),
  .key_hs_expect  (key_hs_expect_mem),
  .ccode_expect   (ccode_expect_mem),
  .pat_expect     (pat_expect_mem)
);

assign {cfeb6_ly0hst, cfeb5_ly0hst, cfeb4_ly0hst, cfeb3_ly0hst, cfeb2_ly0hst, cfeb1_ly0hst, cfeb0_ly0hst} = use_injector ? ly0hs : ly0hs_mem;
assign {cfeb6_ly1hst, cfeb5_ly1hst, cfeb4_ly1hst, cfeb3_ly1hst, cfeb2_ly1hst, cfeb1_ly1hst, cfeb0_ly1hst} = use_injector ? ly1hs : ly0hs_mem;
assign {cfeb6_ly2hst, cfeb5_ly2hst, cfeb4_ly2hst, cfeb3_ly2hst, cfeb2_ly2hst, cfeb1_ly2hst, cfeb0_ly2hst} = use_injector ? ly2hs : ly0hs_mem;
assign {cfeb6_ly3hst, cfeb5_ly3hst, cfeb4_ly3hst, cfeb3_ly3hst, cfeb2_ly3hst, cfeb1_ly3hst, cfeb0_ly3hst} = use_injector ? ly3hs : ly0hs_mem;
assign {cfeb6_ly4hst, cfeb5_ly4hst, cfeb4_ly4hst, cfeb3_ly4hst, cfeb2_ly4hst, cfeb1_ly4hst, cfeb0_ly4hst} = use_injector ? ly4hs : ly0hs_mem;
assign {cfeb6_ly5hst, cfeb5_ly5hst, cfeb4_ly5hst, cfeb3_ly5hst, cfeb2_ly5hst, cfeb1_ly5hst, cfeb0_ly5hst} = use_injector ? ly5hs : ly0hs_mem;

pattern_finder upattern_finder (
// Ports
  .clock        (clock),                  // In  40MHz TMB main clock
  .global_reset (global_reset),           // In  1=Reset everything

// CFEB Ports
  .cfeb0_ly0hs (cfeb0_ly0hst), // In  1/2-strip pulses
  .cfeb0_ly1hs (cfeb0_ly1hst), // In  1/2-strip pulses
  .cfeb0_ly2hs (cfeb0_ly2hst), // In  1/2-strip pulses
  .cfeb0_ly3hs (cfeb0_ly3hst), // In  1/2-strip pulses
  .cfeb0_ly4hs (cfeb0_ly4hst), // In  1/2-strip pulses
  .cfeb0_ly5hs (cfeb0_ly5hst), // In  1/2-strip pulses

  .cfeb1_ly0hs (cfeb1_ly0hst), // In  1/2-strip pulses
  .cfeb1_ly1hs (cfeb1_ly1hst), // In  1/2-strip pulses
  .cfeb1_ly2hs (cfeb1_ly2hst), // In  1/2-strip pulses
  .cfeb1_ly3hs (cfeb1_ly3hst), // In  1/2-strip pulses
  .cfeb1_ly4hs (cfeb1_ly4hst), // In  1/2-strip pulses
  .cfeb1_ly5hs (cfeb1_ly5hst), // In  1/2-strip pulses

  .cfeb2_ly0hs (cfeb2_ly0hst), // In  1/2-strip pulses
  .cfeb2_ly1hs (cfeb2_ly1hst), // In  1/2-strip pulses
  .cfeb2_ly2hs (cfeb2_ly2hst), // In  1/2-strip pulses
  .cfeb2_ly3hs (cfeb2_ly3hst), // In  1/2-strip pulses
  .cfeb2_ly4hs (cfeb2_ly4hst), // In  1/2-strip pulses
  .cfeb2_ly5hs (cfeb2_ly5hst), // In  1/2-strip pulses

  .cfeb3_ly0hs (cfeb3_ly0hst), // In  1/2-strip pulses
  .cfeb3_ly1hs (cfeb3_ly1hst), // In  1/2-strip pulses
  .cfeb3_ly2hs (cfeb3_ly2hst), // In  1/2-strip pulses
  .cfeb3_ly3hs (cfeb3_ly3hst), // In  1/2-strip pulses
  .cfeb3_ly4hs (cfeb3_ly4hst), // In  1/2-strip pulses
  .cfeb3_ly5hs (cfeb3_ly5hst), // In  1/2-strip pulses

  .cfeb4_ly0hs (cfeb4_ly0hst), // In  1/2-strip pulses
  .cfeb4_ly1hs (cfeb4_ly1hst), // In  1/2-strip pulses
  .cfeb4_ly2hs (cfeb4_ly2hst), // In  1/2-strip pulses
  .cfeb4_ly3hs (cfeb4_ly3hst), // In  1/2-strip pulses
  .cfeb4_ly4hs (cfeb4_ly4hst), // In  1/2-strip pulses
  .cfeb4_ly5hs (cfeb4_ly5hst), // In  1/2-strip pulses

  .cfeb5_ly0hs (cfeb5_ly0hst), // In  1/2-strip pulses
  .cfeb5_ly1hs (cfeb5_ly1hst), // In  1/2-strip pulses
  .cfeb5_ly2hs (cfeb5_ly2hst), // In  1/2-strip pulses
  .cfeb5_ly3hs (cfeb5_ly3hst), // In  1/2-strip pulses
  .cfeb5_ly4hs (cfeb5_ly4hst), // In  1/2-strip pulses
  .cfeb5_ly5hs (cfeb5_ly5hst), // In  1/2-strip pulses

  .cfeb6_ly0hs (cfeb6_ly0hst), // In  1/2-strip pulses
  .cfeb6_ly1hs (cfeb6_ly1hst), // In  1/2-strip pulses
  .cfeb6_ly2hs (cfeb6_ly2hst), // In  1/2-strip pulses
  .cfeb6_ly3hs (cfeb6_ly3hst), // In  1/2-strip pulses
  .cfeb6_ly4hs (cfeb6_ly4hst), // In  1/2-strip pulses
  .cfeb6_ly5hs (cfeb6_ly5hst), // In  1/2-strip pulses

// CSC Orientation Ports
  .csc_type        (),   // Out  Firmware compile type
  .csc_me1ab       (),       // Out  1=ME1A or ME1B CSC type
  .stagger_hs_csc  (),  // Out  1=Staggered CSC, 0=non-staggered
  .reverse_hs_csc  (),  // Out  1=Reverse staggered CSC, non-me1
  .reverse_hs_me1a (), // Out  1=reverse me1a hstrips prior to pattern sorting
  .reverse_hs_me1b (), // Out  1=reverse me1b hstrips prior to pattern sorting

// PreTrigger Ports
  .layer_trig_en      (layer_trig_en),                  // In  1=Enable layer trigger mode
  .lyr_thresh_pretrig (lyr_thresh_pretrig[MXHITB-1:0]), // In  Layers hit pre-trigger threshold
  .hit_thresh_pretrig (hit_thresh_pretrig[MXHITB-1:0]), // In  Hits on pattern template pre-trigger threshold
  .pid_thresh_pretrig (pid_thresh_pretrig[MXPIDB-1:0]), // In  Pattern shape ID pre-trigger threshold
  .dmb_thresh_pretrig (dmb_thresh_pretrig[MXHITB-1:0]), // In  Hits on pattern template DMB active-feb threshold
  .cfeb_en            (cfeb_en[MXCFEB-1:0]),            // In  1=Enable cfeb for pre-triggering
  .adjcfeb_dist       (adjcfeb_dist[MXKEYB-1+1:0]),     // In  Distance from key to cfeb boundary for marking adjacent cfeb as hit
  .clct_blanking      (clct_blanking),                  // In  clct_blanking=1 clears clcts with 0 hits

  .cfeb_hit    (cfeb_hit[MXCFEB-1:0]),    // Out  This CFEB has a pattern over pre-trigger threshold
  .cfeb_active (cfeb_active[MXCFEB-1:0]), // Out  CFEBs marked active for DMB readout

  .cfeb_layer_trig  (cfeb_layer_trig),              // Out  Layer pretrigger
  .cfeb_layer_or    (cfeb_layer_or[MXLY-1:0]),      // Out  OR of hstrips on each layer
  .cfeb_nlayers_hit (cfeb_nlayers_hit[MXHITB-1:0]), // Out  Number of CSC layers hit

// 2nd CLCT separation RAM Ports
  .clct_sep_src       (clct_sep_src),             // In  CLCT separation source 1=vme, 0=ram
  .clct_sep_vme       (clct_sep_vme[7:0]),        // In  CLCT separation from vme
  .clct_sep_ram_we    (clct_sep_ram_we),          // In  CLCT separation RAM write enable
  .clct_sep_ram_adr   (clct_sep_ram_adr[3:0]),    // In  CLCT separation RAM rw address VME
  .clct_sep_ram_wdata (clct_sep_ram_wdata[15:0]), // In  CLCT separation RAM write data VME
  .clct_sep_ram_rdata (clct_sep_ram_rdata[15:0]), // Out  CLCT separation RAM read  data VME

// CLCT Pattern-finder results
  .hs_hit_1st (hs_hit_1st), // Out  1st CLCT pattern hits
  .hs_pid_1st (hs_pid_1st), // Out  1st CLCT pattern ID
  .hs_key_1st (hs_key_1st), // Out  1st CLCT key 1/2-strip

  .hs_qlt_1st (hs_qlt_1st),
  .hs_bnd_1st (hs_bnd_1st),
  .hs_car_1st (hs_car_1st),
  .hs_xky_1st (hs_xky_1st),

  .hs_hit_2nd (hs_hit_2nd), // Out  2nd CLCT pattern hits
  .hs_pid_2nd (hs_pid_2nd), // Out  2nd CLCT pattern ID
  .hs_key_2nd (hs_key_2nd), // Out  2nd CLCT key 1/2-strip
  .hs_bsy_2nd (hs_bsy_2nd), // Out  2nd CLCT busy, logic error indicator

  .hs_qlt_2nd (hs_qlt_2nd),
  .hs_bnd_2nd (hs_bnd_2nd),
  .hs_car_2nd (hs_car_2nd),
  .hs_xky_2nd (hs_xky_2nd),

  .hs_layer_trig  (hs_layer_trig),  // Out  Layer triggered
  .hs_nlayers_hit (hs_nlayers_hit), // Out  Number of layers hit
  .hs_layer_or    (hs_layer_or)     // Out  Layer ORs
  );

  wire match_1st, match_2nd;

  ccode_checker ccode_checker_1st (
    .valid (hs_pid_1st > 2),
    .pat_expect (pat_expect),
    .pat_found (hs_pid_1st),
    .ccode_expect (ccode_expect),
    .keyhs_expect (key_hs_expect),
    .ccode_found  (hs_car_1st),
    .keyhs_found (hs_key_1st),
    .match (match_1st)
  );

  ccode_checker ccode_checker_2nd (
    .valid (hs_pid_2nd > 2),
    .pat_expect (pat_expect),
    .pat_found (hs_pid_2nd),
    .ccode_expect (ccode_expect),
    .keyhs_expect (key_hs_expect),
    .ccode_found  (hs_car_2nd),
    .keyhs_found (hs_key_2nd),
    .match (match_2nd)
  );

wire valid_clct_found = (hs_pid_1st > 2 && ccode_over_threshold);

reg [31:0] valid_match_cnt;
reg [31:0] valid_unmatch_cnt;

wire mismatch = (valid_clct_found & !match_1st);

always @(posedge clock) begin
  if (mismatch) begin
    //$display ("%d expect: hs=%d, pat=%x, ccode=%x", iclk, key_hs_expect, pat_expect, ccode_expect );
    $display ("%d found:  hs=%d, pat=%x, ccode=%x, bend=%x, qlt=%x, MATCH=%x", iclk, hs_key_1st, hs_pid_1st, hs_car_1st, hs_bnd_1st, hs_qlt_1st, match_1st);

    $display ("        %b", pat_ly0_expect);
    $display ("        %b", pat_ly1_expect);
    $display ("        %b", pat_ly2_expect);
    $display ("        %b", pat_ly3_expect);
    $display ("        %b", pat_ly4_expect);
    $display ("        %b", pat_ly5_expect);
  end
end


endmodule
