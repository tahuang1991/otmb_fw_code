module pattern_finder_tb ();

 `define pretrig
 `include "pattern_params.v"
 `include "../otmb_virtex6_fw_version.v"

  wire [3: 0] csc_type;        // Firmware compile type
  wire        csc_me1ab;       // 1=ME1A or ME1B CSC type
  wire        stagger_hs_csc;  // 1=Staggered CSC non-me1, 0=non-staggered me1
  wire        reverse_hs_csc;  // 1=Reverse staggered CSC, non-me1
  wire        reverse_hs_me1a; // 1=reverse me1a hstrips prior to pattern sorting
  wire        reverse_hs_me1b; // 1=reverse me1b hstrips prior to pattern sorting

  //----------------------------------------------------------------------------------------------------------------------
  // System clock
  //----------------------------------------------------------------------------------------------------------------------

  reg clock = 0;
  always @(*)
    clock <= #12.5 ~clock;

  reg [31:0] iclk = 32'd0;

  always @(posedge clock)
    iclk <= iclk + 1'b1;

  reg [5:0] reset_cnt='h1f;
  reg reset=1;
  always @(posedge clock) begin
    if (reset_cnt>0) reset_cnt <= reset_cnt - 1'b1;

    reset <= ~(reset_cnt==0);

  end


  //----------------------------------------------------------------------------------------------------------------------
  // Firmware settings
  //----------------------------------------------------------------------------------------------------------------------

  wire layer_trig_en = 0;

  // wire

  wire [MXHITB-1:0]   lyr_thresh_pretrig = 'd3;
  wire [MXHITB-1:0]   hit_thresh_pretrig = 'd3;
  wire [MXPIDB-1:0]   pid_thresh_pretrig = 'd2;

  wire [MXHITB-1:0]   hit_thresh_postdrift = 'd3;
  wire [MXPIDB-1:0]   pid_thresh_postdrift = 'd2;

  wire [MXHITB-1:0]   dmb_thresh_pretrig = 'd3;
  wire [MXCFEB-1:0]   cfeb_en            = 'b1111111;
  wire [MXKEYB-1+1:0] adjcfeb_dist       = 'd8;
  wire                clct_blanking      = 'b1;

  wire         clct_sep_src       = 'b1; // Input: 1==vme, 0==ram
  wire  [7:0]  clct_sep_vme       = 'd10;
  wire         clct_sep_ram_we    = 'b0;
  wire  [3:0]  clct_sep_ram_adr   = 'd0;
  wire  [15:0] clct_sep_ram_wdata = 'd0;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //--------------------------------------------------------------------------------------------------------------------

  wire [1:0] state_expect;
  wire [1:0] state_expect_dly;

  wire  [7:0]  key_hs_expect_1st , key_hs_expect_dly_1st , key_hs_expect_mem_1st ;
  wire  [11:0] ccode_expect_1st  , ccode_expect_dly_1st  , ccode_expect_mem_1st  ;
  wire  [3:0]  pat_expect_1st    , pat_expect_dly_1st    , pat_expect_mem_1st    ;

  wire  [7:0]  key_hs_expect_2nd , key_hs_expect_dly_2nd , key_hs_expect_mem_2nd ;
  wire  [11:0] ccode_expect_2nd  , ccode_expect_dly_2nd  , ccode_expect_mem_2nd  ;
  wire  [3:0]  pat_expect_2nd    , pat_expect_dly_2nd    , pat_expect_mem_2nd    ;

  parameter MXADRB = 17;
  wire [MXADRB-1:0] mem_adr;
  wire [MXADRB-1:0] mem_adr_dly;

  parameter [3:0] expect_dly = 5;

  srl16e_bbl #(.WIDTH(2)) srl16e_bbl_sm (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly-4),
    .d     (state_expect),
    .q     (state_expect_dly)
  );

  srl16e_bbl #(.WIDTH(8+12+4)) srl16e_bbl_expect_1st (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly),
    .d     ({key_hs_expect_mem_1st, ccode_expect_mem_1st, pat_expect_mem_1st}),
    .q     ({key_hs_expect_dly_1st, ccode_expect_dly_1st, pat_expect_dly_1st})
  );

  srl16e_bbl #(.WIDTH(8+12+4)) srl16e_bbl_expect_2nd (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly),
    .d     ({key_hs_expect_mem_2nd, ccode_expect_mem_2nd, pat_expect_mem_2nd}),
    .q     ({key_hs_expect_dly_2nd, ccode_expect_dly_2nd, pat_expect_dly_2nd})
  );

  srl16e_bbl #(.WIDTH(MXADRB)) srl16e_bbl_adr (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly),
    .d     ({mem_adr}),
    .q     ({mem_adr_dly})
  );

// CLCT Sequencer State Declarations
  reg[63:0] state_expect_sm_dsp;

  always @* begin
    case (state_expect_dly)
      'h1:       state_expect_sm_dsp <= "idle    ";
      'h2:       state_expect_sm_dsp <= "flush   ";
      'h3:       state_expect_sm_dsp <= "pretrig ";
       default   state_expect_sm_dsp <= "default ";
    endcase
  end

  assign key_hs_expect_1st = key_hs_expect_dly_1st;
  assign ccode_expect_1st  = ccode_expect_dly_1st;
  assign pat_expect_1st    = pat_expect_dly_1st;

  assign key_hs_expect_2nd = key_hs_expect_dly_2nd;
  assign ccode_expect_2nd  = ccode_expect_dly_2nd;
  assign pat_expect_2nd    = pat_expect_dly_2nd;

  wire [MXHSX - 1: 0] ly0hs_os, ly0hs_mem;
  wire [MXHSX - 1: 0] ly1hs_os, ly1hs_mem;
  wire [MXHSX - 1: 0] ly2hs_os, ly2hs_mem;
  wire [MXHSX - 1: 0] ly3hs_os, ly3hs_mem;
  wire [MXHSX - 1: 0] ly4hs_os, ly4hs_mem;
  wire [MXHSX - 1: 0] ly5hs_os, ly5hs_mem;


  mem_reader #(.MXADRB(MXADRB)) umem_reader (

    .clock             (clock),
    .increment         (~reset),
    .ly0               (ly0hs_mem),
    .ly1               (ly1hs_mem),
    .ly2               (ly2hs_mem),
    .ly3               (ly3hs_mem),
    .ly4               (ly4hs_mem),
    .ly5               (ly5hs_mem),

    .state_expect      (state_expect),

    .key_hs_expect_1st (key_hs_expect_mem_1st),
    .ccode_expect_1st  (ccode_expect_mem_1st),
    .pat_expect_1st    (pat_expect_mem_1st),

    .key_hs_expect_2nd (key_hs_expect_mem_2nd),
    .ccode_expect_2nd  (ccode_expect_mem_2nd),
    .pat_expect_2nd    (pat_expect_mem_2nd),

    .done              (done_reading),

    .adr_out           (mem_adr)

  );

  //--------------------------------------------------------------------------------------------------------------------
  // Fire oneshots to extend pulses
  //--------------------------------------------------------------------------------------------------------------------

  `ifdef pretrig
  parameter BYPASS_OS = 0;
  `else
  parameter BYPASS_OS = 1;
  `endif

  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot0 ( .persist(4'd3), .in (ly0hs_mem), .out(ly0hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot1 ( .persist(4'd3), .in (ly1hs_mem), .out(ly1hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot2 ( .persist(4'd3), .in (ly2hs_mem), .out(ly2hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot3 ( .persist(4'd3), .in (ly3hs_mem), .out(ly3hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot4 ( .persist(4'd3), .in (ly4hs_mem), .out(ly4hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.BYPASS(BYPASS_OS), .WIDTH(224)) ly_oneshot5 ( .persist(4'd3), .in (ly5hs_mem), .out(ly5hs_os ), .reset (reset), .clock (clock));

  //--------------------------------------------------------------------------------------------------------------------
  // Remap layers to CFEBs for reversal
  //--------------------------------------------------------------------------------------------------------------------

  wire [MXHS - 1: 0] cfeb0_ly0hs, cfeb0_ly1hs, cfeb0_ly2hs, cfeb0_ly3hs, cfeb0_ly4hs, cfeb0_ly5hs;
  wire [MXHS - 1: 0] cfeb1_ly0hs, cfeb1_ly1hs, cfeb1_ly2hs, cfeb1_ly3hs, cfeb1_ly4hs, cfeb1_ly5hs;
  wire [MXHS - 1: 0] cfeb2_ly0hs, cfeb2_ly1hs, cfeb2_ly2hs, cfeb2_ly3hs, cfeb2_ly4hs, cfeb2_ly5hs;
  wire [MXHS - 1: 0] cfeb3_ly0hs, cfeb3_ly1hs, cfeb3_ly2hs, cfeb3_ly3hs, cfeb3_ly4hs, cfeb3_ly5hs;
  wire [MXHS - 1: 0] cfeb4_ly0hs, cfeb4_ly1hs, cfeb4_ly2hs, cfeb4_ly3hs, cfeb4_ly4hs, cfeb4_ly5hs;
  wire [MXHS - 1: 0] cfeb5_ly0hs, cfeb5_ly1hs, cfeb5_ly2hs, cfeb5_ly3hs, cfeb5_ly4hs, cfeb5_ly5hs;
  wire [MXHS - 1: 0] cfeb6_ly0hs, cfeb6_ly1hs, cfeb6_ly2hs, cfeb6_ly3hs, cfeb6_ly4hs, cfeb6_ly5hs;

  assign {cfeb6_ly0hs, cfeb5_ly0hs, cfeb4_ly0hs, cfeb3_ly0hs, cfeb2_ly0hs, cfeb1_ly0hs, cfeb0_ly0hs} = ly0hs_os;
  assign {cfeb6_ly1hs, cfeb5_ly1hs, cfeb4_ly1hs, cfeb3_ly1hs, cfeb2_ly1hs, cfeb1_ly1hs, cfeb0_ly1hs} = ly1hs_os;
  assign {cfeb6_ly2hs, cfeb5_ly2hs, cfeb4_ly2hs, cfeb3_ly2hs, cfeb2_ly2hs, cfeb1_ly2hs, cfeb0_ly2hs} = ly2hs_os;
  assign {cfeb6_ly3hs, cfeb5_ly3hs, cfeb4_ly3hs, cfeb3_ly3hs, cfeb2_ly3hs, cfeb1_ly3hs, cfeb0_ly3hs} = ly3hs_os;
  assign {cfeb6_ly4hs, cfeb5_ly4hs, cfeb4_ly4hs, cfeb3_ly4hs, cfeb2_ly4hs, cfeb1_ly4hs, cfeb0_ly4hs} = ly4hs_os;
  assign {cfeb6_ly5hs, cfeb5_ly5hs, cfeb4_ly5hs, cfeb3_ly5hs, cfeb2_ly5hs, cfeb1_ly5hs, cfeb0_ly5hs} = ly5hs_os;

  //--------------------------------------------------------------------------------------------------------------------
  // CSC Type Reversal
  //--------------------------------------------------------------------------------------------------------------------

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

  // Orientation flags
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

  // Orientation flags
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

  //-------------------------------------------------------------------------------------------------------------------
  // Stage 4A5: CSC_TYPE_X Undefined
  //-------------------------------------------------------------------------------------------------------------------
  `else
    initial $display ("CSC_TYPE Undefined. Halting.");
    $finish
  `endif

  wire [MXHSX- 1: 0] ly0hs = {me1a_ly0hs, me1b_ly0hs};
  wire [MXHSX- 1: 0] ly1hs = {me1a_ly1hs, me1b_ly1hs};
  wire [MXHSX- 1: 0] ly2hs = {me1a_ly2hs, me1b_ly2hs};
  wire [MXHSX- 1: 0] ly3hs = {me1a_ly3hs, me1b_ly3hs};
  wire [MXHSX- 1: 0] ly4hs = {me1a_ly4hs, me1b_ly4hs};
  wire [MXHSX- 1: 0] ly5hs = {me1a_ly5hs, me1b_ly5hs};


  wire [MXHS - 1: 0] cfeb0_ly0hs_flip, cfeb0_ly1hs_flip, cfeb0_ly2hs_flip, cfeb0_ly3hs_flip, cfeb0_ly4hs_flip, cfeb0_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb1_ly0hs_flip, cfeb1_ly1hs_flip, cfeb1_ly2hs_flip, cfeb1_ly3hs_flip, cfeb1_ly4hs_flip, cfeb1_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb2_ly0hs_flip, cfeb2_ly1hs_flip, cfeb2_ly2hs_flip, cfeb2_ly3hs_flip, cfeb2_ly4hs_flip, cfeb2_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb3_ly0hs_flip, cfeb3_ly1hs_flip, cfeb3_ly2hs_flip, cfeb3_ly3hs_flip, cfeb3_ly4hs_flip, cfeb3_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb4_ly0hs_flip, cfeb4_ly1hs_flip, cfeb4_ly2hs_flip, cfeb4_ly3hs_flip, cfeb4_ly4hs_flip, cfeb4_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb5_ly0hs_flip, cfeb5_ly1hs_flip, cfeb5_ly2hs_flip, cfeb5_ly3hs_flip, cfeb5_ly4hs_flip, cfeb5_ly5hs_flip;
  wire [MXHS - 1: 0] cfeb6_ly0hs_flip, cfeb6_ly1hs_flip, cfeb6_ly2hs_flip, cfeb6_ly3hs_flip, cfeb6_ly4hs_flip, cfeb6_ly5hs_flip;

  assign {cfeb6_ly0hs_flip, cfeb5_ly0hs_flip, cfeb4_ly0hs_flip, cfeb3_ly0hs_flip, cfeb2_ly0hs_flip, cfeb1_ly0hs_flip, cfeb0_ly0hs_flip} = ly0hs;
  assign {cfeb6_ly1hs_flip, cfeb5_ly1hs_flip, cfeb4_ly1hs_flip, cfeb3_ly1hs_flip, cfeb2_ly1hs_flip, cfeb1_ly1hs_flip, cfeb0_ly1hs_flip} = ly1hs;
  assign {cfeb6_ly2hs_flip, cfeb5_ly2hs_flip, cfeb4_ly2hs_flip, cfeb3_ly2hs_flip, cfeb2_ly2hs_flip, cfeb1_ly2hs_flip, cfeb0_ly2hs_flip} = ly2hs;
  assign {cfeb6_ly3hs_flip, cfeb5_ly3hs_flip, cfeb4_ly3hs_flip, cfeb3_ly3hs_flip, cfeb2_ly3hs_flip, cfeb1_ly3hs_flip, cfeb0_ly3hs_flip} = ly3hs;
  assign {cfeb6_ly4hs_flip, cfeb5_ly4hs_flip, cfeb4_ly4hs_flip, cfeb3_ly4hs_flip, cfeb2_ly4hs_flip, cfeb1_ly4hs_flip, cfeb0_ly4hs_flip} = ly4hs;
  assign {cfeb6_ly5hs_flip, cfeb5_ly5hs_flip, cfeb4_ly5hs_flip, cfeb3_ly5hs_flip, cfeb2_ly5hs_flip, cfeb1_ly5hs_flip, cfeb0_ly5hs_flip} = ly5hs;

  // copy a region of interest around the pattern for diagnostic printout later
  // need to add in handling of me1a me1b split
  wire [10:0] pat_roi_ly0_1st = {ly0hs,5'b00000} >> (key_hs_expect_mem_1st);
  wire [10:0] pat_roi_ly1_1st = {ly1hs,5'b00000} >> (key_hs_expect_mem_1st);
  wire [10:0] pat_roi_ly2_1st = {ly2hs,5'b00000} >> (key_hs_expect_mem_1st);
  wire [10:0] pat_roi_ly3_1st = {ly3hs,5'b00000} >> (key_hs_expect_mem_1st);
  wire [10:0] pat_roi_ly4_1st = {ly4hs,5'b00000} >> (key_hs_expect_mem_1st);
  wire [10:0] pat_roi_ly5_1st = {ly5hs,5'b00000} >> (key_hs_expect_mem_1st);

  wire [10:0] pat_roi_ly0_2nd = {ly0hs,5'b00000} >> (key_hs_expect_mem_2nd);
  wire [10:0] pat_roi_ly1_2nd = {ly1hs,5'b00000} >> (key_hs_expect_mem_2nd);
  wire [10:0] pat_roi_ly2_2nd = {ly2hs,5'b00000} >> (key_hs_expect_mem_2nd);
  wire [10:0] pat_roi_ly3_2nd = {ly3hs,5'b00000} >> (key_hs_expect_mem_2nd);
  wire [10:0] pat_roi_ly4_2nd = {ly4hs,5'b00000} >> (key_hs_expect_mem_2nd);
  wire [10:0] pat_roi_ly5_2nd = {ly5hs,5'b00000} >> (key_hs_expect_mem_2nd);

  wire [10:0] pat_roi_ly0_dly_1st, pat_roi_ly0_dly_2nd;
  wire [10:0] pat_roi_ly1_dly_1st, pat_roi_ly1_dly_2nd;
  wire [10:0] pat_roi_ly2_dly_1st, pat_roi_ly2_dly_2nd;
  wire [10:0] pat_roi_ly3_dly_1st, pat_roi_ly3_dly_2nd;
  wire [10:0] pat_roi_ly4_dly_1st, pat_roi_ly4_dly_2nd;
  wire [10:0] pat_roi_ly5_dly_1st, pat_roi_ly5_dly_2nd;

  // take a look at the region around the pattern for diagnostic printout
  srl16e_bbl #(.WIDTH(66)) roi_dly_1st (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly),
    .d     ({ pat_roi_ly5_1st     , pat_roi_ly4_1st     , pat_roi_ly3_1st     , pat_roi_ly2_1st     , pat_roi_ly1_1st     , pat_roi_ly0_1st     }),
    .q     ({ pat_roi_ly5_dly_1st , pat_roi_ly4_dly_1st , pat_roi_ly3_dly_1st , pat_roi_ly2_dly_1st , pat_roi_ly1_dly_1st , pat_roi_ly0_dly_1st })
  );
  srl16e_bbl #(.WIDTH(66)) roi_dly_2nd (
    .clock (clock),
    .ce    (1'b1),
    .adr   (expect_dly),
    .d     ({ pat_roi_ly5_2nd     , pat_roi_ly4_2nd     , pat_roi_ly3_2nd     , pat_roi_ly2_2nd     , pat_roi_ly1_2nd     , pat_roi_ly0_2nd     }),
    .q     ({ pat_roi_ly5_dly_2nd , pat_roi_ly4_dly_2nd , pat_roi_ly3_dly_2nd , pat_roi_ly2_dly_2nd , pat_roi_ly1_dly_2nd , pat_roi_ly0_dly_2nd })
  );

//-------------------------------------------------------------------------------------------------------------------
// Pattern Finder declarations, common to ME1A+ME1B+ME234
//-------------------------------------------------------------------------------------------------------------------
  wire  [15:0] clct_sep_ram_rdata; // CLCT separation RAM read  data VME

//-------------------------------------------------------------------------------------------------------------------
// Pattern Finder instantiation
//-------------------------------------------------------------------------------------------------------------------
  wire  [MXCFEB-1:0]  cfeb_hit;         // This CFEB has a pattern over pre-trigger threshold
  wire  [MXCFEB-1:0]  cfeb_active;      // CFEBs marked for DMB readout
  wire  [MXLY-1:0]    cfeb_layer_or;    // OR of hstrips on each layer
  wire  [MXHITB-1:0]  cfeb_nlayers_hit; // Number of CSC layers hit

  // 1st clct
  wire  [MXHITB-1:0]  hs_hit_1st;
  wire  [MXPIDB-1:0]  hs_pid_1st;
  wire  [MXKEYBX-1:0] hs_key_1st;

  // 1st pattern lookup results
  wire [MXQLTB - 1 : 0] hs_qlt_1st;
  wire [MXBNDB - 1 : 0] hs_bnd_1st;
  wire [MXPATC - 1 : 0] hs_car_1st; // 1st CLCT pattern lookup comparator-code
  wire [MXXKYB - 1 : 0] hs_xky_1st;

  // 2nd clct
  wire  [MXHITB-1:0]  hs_hit_2nd;
  wire  [MXPIDB-1:0]  hs_pid_2nd;
  wire  [MXKEYBX-1:0] hs_key_2nd;
  wire                hs_bsy_2nd;

  // 2nd pattern lookup results
  wire [MXQLTB - 1 : 0] hs_qlt_2nd;
  wire [MXBNDB - 1 : 0] hs_bnd_2nd;
  wire [MXPATC - 1 : 0] hs_car_2nd; // 2nd CLCT pattern lookup comparator-code
  wire [MXXKYB - 1 : 0] hs_xky_2nd;

  wire                hs_layer_trig;  // Layer triggered
  wire  [MXHITB-1:0]  hs_nlayers_hit; // Number of layers hit
  wire  [MXLY-1:0]    hs_layer_or;    // Layer ORs

  pattern_finder upattern_finder (
  // Ports
    .clock        (clock), // In  40MHz TMB main clock
    .global_reset (reset), // In  1=Reset everything

  // CFEB Ports
    .cfeb0_ly0hs (cfeb0_ly0hs_flip), // In  1/2-strip pulses
    .cfeb0_ly1hs (cfeb0_ly1hs_flip), // In  1/2-strip pulses
    .cfeb0_ly2hs (cfeb0_ly2hs_flip), // In  1/2-strip pulses
    .cfeb0_ly3hs (cfeb0_ly3hs_flip), // In  1/2-strip pulses
    .cfeb0_ly4hs (cfeb0_ly4hs_flip), // In  1/2-strip pulses
    .cfeb0_ly5hs (cfeb0_ly5hs_flip), // In  1/2-strip pulses

    .cfeb1_ly0hs (cfeb1_ly0hs_flip), // In  1/2-strip pulses
    .cfeb1_ly1hs (cfeb1_ly1hs_flip), // In  1/2-strip pulses
    .cfeb1_ly2hs (cfeb1_ly2hs_flip), // In  1/2-strip pulses
    .cfeb1_ly3hs (cfeb1_ly3hs_flip), // In  1/2-strip pulses
    .cfeb1_ly4hs (cfeb1_ly4hs_flip), // In  1/2-strip pulses
    .cfeb1_ly5hs (cfeb1_ly5hs_flip), // In  1/2-strip pulses

    .cfeb2_ly0hs (cfeb2_ly0hs_flip), // In  1/2-strip pulses
    .cfeb2_ly1hs (cfeb2_ly1hs_flip), // In  1/2-strip pulses
    .cfeb2_ly2hs (cfeb2_ly2hs_flip), // In  1/2-strip pulses
    .cfeb2_ly3hs (cfeb2_ly3hs_flip), // In  1/2-strip pulses
    .cfeb2_ly4hs (cfeb2_ly4hs_flip), // In  1/2-strip pulses
    .cfeb2_ly5hs (cfeb2_ly5hs_flip), // In  1/2-strip pulses

    .cfeb3_ly0hs (cfeb3_ly0hs_flip), // In  1/2-strip pulses
    .cfeb3_ly1hs (cfeb3_ly1hs_flip), // In  1/2-strip pulses
    .cfeb3_ly2hs (cfeb3_ly2hs_flip), // In  1/2-strip pulses
    .cfeb3_ly3hs (cfeb3_ly3hs_flip), // In  1/2-strip pulses
    .cfeb3_ly4hs (cfeb3_ly4hs_flip), // In  1/2-strip pulses
    .cfeb3_ly5hs (cfeb3_ly5hs_flip), // In  1/2-strip pulses

    .cfeb4_ly0hs (cfeb4_ly0hs_flip), // In  1/2-strip pulses
    .cfeb4_ly1hs (cfeb4_ly1hs_flip), // In  1/2-strip pulses
    .cfeb4_ly2hs (cfeb4_ly2hs_flip), // In  1/2-strip pulses
    .cfeb4_ly3hs (cfeb4_ly3hs_flip), // In  1/2-strip pulses
    .cfeb4_ly4hs (cfeb4_ly4hs_flip), // In  1/2-strip pulses
    .cfeb4_ly5hs (cfeb4_ly5hs_flip), // In  1/2-strip pulses

    .cfeb5_ly0hs (cfeb5_ly0hs_flip), // In  1/2-strip pulses
    .cfeb5_ly1hs (cfeb5_ly1hs_flip), // In  1/2-strip pulses
    .cfeb5_ly2hs (cfeb5_ly2hs_flip), // In  1/2-strip pulses
    .cfeb5_ly3hs (cfeb5_ly3hs_flip), // In  1/2-strip pulses
    .cfeb5_ly4hs (cfeb5_ly4hs_flip), // In  1/2-strip pulses
    .cfeb5_ly5hs (cfeb5_ly5hs_flip), // In  1/2-strip pulses

    .cfeb6_ly0hs (cfeb6_ly0hs_flip), // In  1/2-strip pulses
    .cfeb6_ly1hs (cfeb6_ly1hs_flip), // In  1/2-strip pulses
    .cfeb6_ly2hs (cfeb6_ly2hs_flip), // In  1/2-strip pulses
    .cfeb6_ly3hs (cfeb6_ly3hs_flip), // In  1/2-strip pulses
    .cfeb6_ly4hs (cfeb6_ly4hs_flip), // In  1/2-strip pulses
    .cfeb6_ly5hs (cfeb6_ly5hs_flip), // In  1/2-strip pulses

    // CSC Orientation Ports
    .csc_type        (), // Out  Firmware compile type
    .csc_me1ab       (), // Out  1=ME1A or ME1B CSC type
    .stagger_hs_csc  (), // Out  1=Staggered CSC, 0=non-staggered
    .reverse_hs_csc  (), // Out  1=Reverse staggered CSC, non-me1
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

    //--------------------------------------------------------------------------------------------------------------------
    // wire Checker
    //--------------------------------------------------------------------------------------------------------------------

    wire match_1st, match_2nd;

    // delay 2 bx to wait for drift delay
    wire valid_1st, valid_2nd;

    assign valid_1st = (pat_expect_1st >= pid_thresh_pretrig) || (hs_pid_1st >= pid_thresh_pretrig && hs_hit_1st >= hit_thresh_pretrig);
    assign valid_2nd = (pat_expect_2nd >= pid_thresh_pretrig) || (hs_pid_2nd >= pid_thresh_pretrig && hs_hit_2nd >= hit_thresh_pretrig);

    ccode_checker ccode_checker_1st (

      .valid        (1'b1),

      .check_pat    (1'b1),
      .pat_found    ({MXPIDB{valid_1st}} & hs_pid_1st),
      .pat_expect   (pat_expect_1st),

      .check_ccode  (1'b1),
      .ccode_found  ({MXPATC{valid_1st}} & hs_car_1st),
      .ccode_expect (ccode_expect_1st),

      .check_keyhs  (1'b1),
      .keyhs_found  ({MXKEYBX{valid_1st}} & hs_key_1st),
      .keyhs_expect (key_hs_expect_1st),

      .match        (match_1st)

    );

    ccode_checker ccode_checker_2nd (

      .valid        (1'b1),

      .check_pat    (1'b1),
      .pat_found    (hs_pid_2nd),
      .pat_expect   (pat_expect_2nd),

      .check_ccode  (1'b1),
      .ccode_found  (hs_car_2nd),
      .ccode_expect (ccode_expect_2nd),

      .check_keyhs  (1'b1),
      .keyhs_found  (hs_key_2nd),
      .keyhs_expect (key_hs_expect_2nd),

      .match        (match_2nd)

    );

  reg [31:0] valid_match_cnt_1st=0;
  reg [31:0] valid_unmatch_cnt_1st=0;
  reg [31:0] valid_match_cnt_2nd=0;
  reg [31:0] valid_unmatch_cnt_2nd=0;
  `ifdef pretrig
    wire valid_pretrig_1st;
    wire valid_pretrig_2nd;
  `else
    wire valid_pretrig_1st=1'b1;
    wire valid_pretrig_2nd=1'b1;
  `endif

  // dly vpf flags from sequencer sublogic by 100ns to align with pattern finder outputs

  wire clct0_vpf;
  wire clct1_vpf;

  reg err_vec_reg;
  always @(posedge clock) begin
    err_vec_reg <= valid_mismatch_1st || valid_mismatch_2nd;
  end

  wire valid_match_1st    = (clct0_vpf && valid_1st &&  match_1st);
  wire valid_mismatch_1st = (clct0_vpf && valid_1st && !match_1st);

  wire valid_match_2nd    = (clct1_vpf && valid_2nd &&  match_2nd);
  wire valid_mismatch_2nd = (clct1_vpf && valid_2nd && !match_2nd);

  always @(posedge clock) begin

    if (valid_mismatch_1st) begin
      valid_unmatch_cnt_1st <= valid_unmatch_cnt_1st + 1'b1;
      $display ("FAIL: %4d 1st found:  khs=%3d, pat=%1x, ccode=%3x,  bend=%x, qlt=%x", mem_adr_dly+1, hs_key_1st, hs_pid_1st, hs_car_1st, hs_bnd_1st, hs_qlt_1st);
      $display ("FAIL: %4d 1st expect: khs=%3d, pat=%1x, ccode=%3x",                   mem_adr_dly+1, key_hs_expect_1st, pat_expect_1st, ccode_expect_1st );
      $display ("\tA9876543210");
      $display ("\t%b", pat_roi_ly0_dly_1st);
      $display ("\t%b", pat_roi_ly1_dly_1st);
      $display ("\t%b", pat_roi_ly2_dly_1st);
      $display ("\t%b", pat_roi_ly3_dly_1st);
      $display ("\t%b", pat_roi_ly4_dly_1st);
      $display ("\t%b", pat_roi_ly5_dly_1st);
    end

    if (valid_mismatch_2nd) begin
      valid_unmatch_cnt_2nd <= valid_unmatch_cnt_2nd + 1'b1;
      $display ("FAIL: %4d 2nd found:  khs=%3d, pat=%1x, ccode=%3x,  bend=%x, qlt=%x", mem_adr_dly+1, hs_key_2nd, hs_pid_2nd, hs_car_2nd, hs_bnd_2nd, hs_qlt_2nd);
      $display ("FAIL: %4d 2nd expect: khs=%3d, pat=%1x, ccode=%3x",                   mem_adr_dly+1, key_hs_expect_2nd, pat_expect_2nd, ccode_expect_2nd );
      $display ("\tA9876543210");
      $display ("\t%b", pat_roi_ly0_dly_2nd);
      $display ("\t%b", pat_roi_ly1_dly_2nd);
      $display ("\t%b", pat_roi_ly2_dly_2nd);
      $display ("\t%b", pat_roi_ly3_dly_2nd);
      $display ("\t%b", pat_roi_ly4_dly_2nd);
      $display ("\t%b", pat_roi_ly5_dly_2nd);
    end

    if (valid_match_1st) begin
      valid_match_cnt_1st <= valid_match_cnt_1st + 1'b1;
      $display ("PASS: 1st %4d match: khs=%3d, pat=%1x, ccode=%3x. Passed %d of %d",                            mem_adr_dly+1, key_hs_expect_1st, pat_expect_1st, ccode_expect_1st, valid_match_cnt_1st, valid_match_cnt_1st +valid_unmatch_cnt_1st  );
//    $display ("\tA9876543210");
//    $display ("\t%b", pat_roi_ly0_dly_1st);
//    $display ("\t%b", pat_roi_ly1_dly_1st);
//    $display ("\t%b", pat_roi_ly2_dly_1st);
//    $display ("\t%b", pat_roi_ly3_dly_1st);
//    $display ("\t%b", pat_roi_ly4_dly_1st);
//    $display ("\t%b", pat_roi_ly5_dly_1st);
    end

    if (valid_match_2nd) begin
      valid_match_cnt_2nd <= valid_match_cnt_2nd + 1'b1;
      $display ("PASS: 2nd %4d match: khs=%3d, pat=%1x, ccode=%3x. Passed %d of %d",                            mem_adr_dly+1, key_hs_expect_2nd, pat_expect_2nd, ccode_expect_2nd, valid_match_cnt_2nd, valid_match_cnt_2nd +valid_unmatch_cnt_2nd   );
    end

  end


parameter MXTHROTTLE = 8;
parameter MXDRIFT    = 4;
parameter MXFLUSH    = 4;         // Number bits needed for flush counter

wire tmb_non_trig_keep      = 0;
wire tmb_trig_keep          = 0;
wire ext_trig_inject        = 0;
wire sync_err_stops_pretrig = 0;
wire wr_buf_avail           = 1;
wire ttc_resync             = 0;
wire startup_done           = ~reset;
wire pretrig_halt           = 0;
wire all_cfebs_active       = 0;
wire tmb_trig_pulse         = 0;
wire active_feb_src         = 0;

wire [MXTHROTTLE-1:0] clct_throttle = 0;
wire [MXFLUSH-1:0] clct_flush_delay = 1;
wire [MXCFEB-1:0]  tmb_aff_list=0;      // Active CFEBs for CLCT used in TMB match

parameter RAM_ADRB     = 11;        // Address width=log2(ram_depth)
parameter MXBADR       = RAM_ADRB;  // Header buffer data address bits

`ifdef pretrig

  wire  [MXDRIFT-1:0]  drift_delay='d2;      // CSC Drift delay clocks
//----------------------------------------------------------------------------------------------------------------------
// Pretrigger
//----------------------------------------------------------------------------------------------------------------------
  wire              clct_pat_trig_en=1;   // Allow CLCT Pattern triggers
  wire              alct_pat_trig_en=0;   // Allow ALCT Pattern trigger
  wire              alct_match_trig_en=0; // Allow ALCT*CLCT Pattern trigger
  wire              adb_ext_trig_en=0;    // Allow ADB Test pulse trigger
  wire              dmb_ext_trig_en=0;    // Allow DMB Calibration trigger
  wire              clct_ext_trig_en=0;   // Allow CLCT External trigger from CCB
  wire              alct_ext_trig_en=0;   // Allow ALCT External trigger from CCB
  wire              vme_ext_trig=0;

// Pre-trigger Source Multiplexer
  wire [8:0] trig_source;
  wire any_cfeb_hit = (|cfeb_hit[MXCFEB-1:0]);                               // Any CFEB has a hit

  assign trig_source[0] = any_cfeb_hit     && clct_pat_trig_en;                     // CLCT pattern pretrigger
  assign trig_source[1] = 0 && alct_pat_trig_en;                     // ALCT pattern trigger
  assign trig_source[2] = 0     && alct_match_trig_en;                   // ALCT*CLCT match pattern pretrigger, success presumed
  assign trig_source[3] = 0  && adb_ext_trig_en;                      // ADB external trigger
  assign trig_source[4] = 0  && dmb_ext_trig_en;                      // DMB external trigger
  assign trig_source[5] = 0 && clct_ext_trig_en && !ext_trig_inject; // CLCT external trigger from CCB
  assign trig_source[6] = 0 && alct_ext_trig_en;                     // ALCT external trigger from CCB
  assign trig_source[7] = 0;                                             // VME  external trigger from backplane
  assign trig_source[8] = 0  && layer_trig_en;                        // Layer-wide trigger

// Pre-trigger
  reg  noflush    = 0;
  reg  nothrottle = 0;
  wire flush_done;
  wire throttle_done;

  wire clct_pretrig_rqst= (| trig_source[7:0]) && !sync_err_stops_pretrig; // CLCT pretrigger requested, dont trig on [8]

// CLCT Sequencer State Declarations
  reg [5:0] clct_sm;      // synthesis attribute safe_implementation of clct_sm is "yes";

  parameter startup  = 0; // Startup waiting for initial debris to clear
  parameter idle     = 1; // Idling, waiting for pretrig
  parameter pretrig  = 2; // Pretriggered, pushed event into pretrigger pipeline
  parameter throttle = 3; // Reduce trigger rate
  parameter flush    = 4; // Flushing event, throttling trigger rate
  parameter halt     = 5; // Halted, waiting for un-halt from VME

  wire clct_pretrig   = (clct_sm == pretrig);                    // CLCT pre-triggered
  wire clct_pat_trig  = any_cfeb_hit && clct_pat_trig_en;        // Trigger source is a CLCT pattern
  wire clct_retrigger = clct_pat_trig && noflush && nothrottle;  // Immediate re-trigger
  wire clct_notbusy   = !clct_pretrig_rqst;                      // Ready for next pretrig
  wire clct_deadtime  = (clct_sm==flush) || (clct_sm==throttle); // CLCT Bx pretrig machine waited for triads to dissipate before rearm

  assign clct_pretrig = (clct_sm == pretrig);                        // CLCT pre-triggered

// Pre-trigger keep or discard
  wire discard_nowrbuf = clct_pretrig && !wr_buf_avail;     // Discard pretrig because wr_buf was not ready
  wire discard_noalct  = 0;                                 // Discard pretrig because alct was not in window
  wire discard_pretrig = discard_nowrbuf || discard_noalct; // Discard this pretrig

  wire clct_push_pretrig = clct_pretrig && !discard_pretrig; // Keep this pretrig, push it into pipeline

  wire fmm_trig_stop = 1'b0;

  wire sm_reset = reset;

// CLCT pre-trigger State Machine
  always @(posedge clock or posedge sm_reset) begin
    if      (sm_reset  ) clct_sm = startup; // async reset
    else if (ttc_resync) clct_sm = halt;    // sync  reset
    else begin

      case (clct_sm)

        startup:            // Delay for active feb bits to clear
          if (startup_done) // Startup countdown timer
           clct_sm = halt;  // Start up halted, wait for FMM trigger start

        idle:                         // Idling, waiting for next pre-trigger request
          if (fmm_trig_stop)          // TTC stop trigger command
           clct_sm = halt;
          else if (clct_pretrig_rqst) // Pre-trigger requested
           clct_sm = pretrig;

        pretrig:                    // Pre-triggered, send Active FEB bits to DMB
          if (!nothrottle)          // Throttle trigger rate before re-arming
           clct_sm = throttle;
          else if (!noflush)        // Flush triads before re-arming
           clct_sm = flush;
          else if (!clct_retrigger) // Stay in pre-trig for immediate re-trigger
           clct_sm = idle;

        throttle:                // Decrease pre-trigger rate
          if (throttle_done)     // Countdown timer
            if (!noflush)
             clct_sm = flush;      // Flush if required
            else if (pretrig_halt)
             clct_sm = halt;       // Halt if required
            else
             clct_sm = idle;       // Otherwise go directly from throttle to idle

        flush:                   // Wait fixed time for 1/2-strip one-shots to dissipate
          if (flush_done) begin  // Countdown timer
            if (pretrig_halt)    // Pretrigger and halt mode
             clct_sm = halt;
            else                 // Ready for next trigger
             clct_sm =idle;
          end

        halt:                    // Halted, wait for resume from VME or FMM
          if (!fmm_trig_stop && !pretrig_halt) begin
            if (!noflush)
              clct_sm = flush;      // Flush if required
            else
              clct_sm = idle;       // Otherwise go directly from halt to idle
          end

        default
          clct_sm = idle;

      endcase
    end
  end

// Throttle state timer, reduce trigger rate
  reg   [MXTHROTTLE-1:0] throttle_cnt=0;

  always @(posedge clock) begin
    if      (clct_sm != throttle) throttle_cnt = clct_throttle - 1'b1; // Sync load
    else if (clct_sm == throttle) throttle_cnt = throttle_cnt  - 1'b1; // Only count during throttle
  end

  assign throttle_done = (throttle_cnt == 0) || nothrottle;

  always @(posedge clock) begin
    nothrottle <= (clct_throttle == 0);
  end

// Trigger flush state timer. Wait for 1/2-strip one-shots and raw hits fifo to clear
  reg   [MXFLUSH-1:0] flush_cnt=0;

  wire flush_cnt_clr = (clct_sm != flush) || !clct_notbusy;  // Flush timer resets if triad debris remains
  wire flush_cnt_ena = (clct_sm == flush);

  always @(posedge clock) begin
    if    (flush_cnt_clr) flush_cnt = clct_flush_delay-1'b1; // sync load before entering flush state
    else if (flush_cnt_ena) flush_cnt = flush_cnt-1'b1;      // only count during flush
  end

  assign flush_done = ((flush_cnt == 0) || noflush) && clct_notbusy;

  always @(posedge clock) begin
    noflush  <= (clct_flush_delay == 0);
  end

// Delay trigger source and cfeb active feb list 1bx for clct_sm to go to pretrig state
  reg [MXCFEB-1:0] active_feb_s0  = 0;
  reg [MXCFEB-1:0] cfeb_hit_s0    = 0;
  reg [2:0]        nlayers_hit_s0 = 0;
  reg [8:0]        trig_source_s0 = 0;

  wire [MXCFEB-1:0] active_feb = cfeb_active[MXCFEB-1:0] | {MXCFEB{all_cfebs_active}};  // Active list includes boundary overlaps

  always @(posedge clock) begin
    active_feb_s0  <= active_feb;    // CFEBs active, including overlaps
    cfeb_hit_s0    <= cfeb_hit;      // CFEBs hit, not including overlaps
    nlayers_hit_s0 <= cfeb_nlayers_hit;
    trig_source_s0 <= trig_source;
  end

  wire trig_source_ext = (|trig_source_s0[7:3]) | trig_source_s0[1];          // Trigger source was not CLCT pattern
  wire trig_clct_flash = clct_pretrig & (trig_source_s0[0] || trig_source_s0[7:2]);  // Trigger source flashes CLCT light

// Record which CFEBs were hit at pretrigger
  reg [MXCFEB-1:0] cfeb_hit_at_pretrig = 0;

  always @(posedge clock) begin
    cfeb_hit_at_pretrig <= cfeb_hit_s0 & {MXCFEB{clct_pretrig}};
  end

// On Pretrigger send Active FEB word to DMB, persist 1 cycle per event
  wire [MXCFEB-1:0] active_feb_list_pre; // Active FEB list to DMB at pretrig time
  wire [MXCFEB-1:0] active_feb_list_tmb; // Active FEB list to DMB at tmb match time
  wire [MXCFEB-1:0] active_feb_list;     // Active FEB list selection

  wire              active_feb_flag_pre; // Active FEB flag to DMB at pretrig time
  wire              active_feb_flag_tmb; // Active FEB flag to DMB at tmb match time
  wire              active_feb_flag;     // Active FEB flag selection

  assign active_feb_flag_pre = clct_push_pretrig;
  assign active_feb_list_pre = active_feb_s0[MXCFEB-1:0] & {MXCFEB{active_feb_flag_pre}};

  wire tmb_trig_write = tmb_trig_pulse && (tmb_trig_keep || tmb_non_trig_keep);

  assign active_feb_flag_tmb = tmb_trig_write;
  assign active_feb_list_tmb = tmb_aff_list & {MXCFEB{active_feb_flag_tmb}};

  assign active_feb_flag = (active_feb_src) ? active_feb_flag_tmb : active_feb_flag_pre;
  assign active_feb_list = (active_feb_src) ? active_feb_list_tmb : active_feb_list_pre;

// Delay TMB active feb list 1bx so it can share tmb+1bx RAM
  reg [MXCFEB-1:0] tmb_aff_list_ff = 0;

  always @(posedge clock) begin
    tmb_aff_list_ff <= tmb_aff_list;
  end

//------------------------------------------------------------------------------------------------------------------
// Pre-trigger Pipeline
// Pushes CLCT pretrigger data into pipeline to wait for pattern finder and drift delay
//------------------------------------------------------------------------------------------------------------------
// On pretrigger push buffer address and bxn into the pre-trigger pipeline
  parameter PATTERN_FINDER_LATENCY = 2;  // Tuned 4/22/08
  parameter MXPTRID = 23;

  wire [3:0]         postdrift_adr;
  wire [MXPTRID-1:0] pretrig_data;
  wire [MXPTRID-1:0] postdrift_data;

  assign pretrig_data[0]     = clct_push_pretrig;        // Pre-trigger flag alias active_feb_flag
  assign pretrig_data[11:1]  = 0;                        // Buffer address at pre-trigger
  assign pretrig_data[12]    = 1'b1;                     // Buffer address was valid at pre-trigger
  assign pretrig_data[14:13] = 0;                        // BXN at pre-trigger, only lsbs are needed for clct
  assign pretrig_data[15]    = 0;                        // Trigger source was not CLCT pattern
  assign pretrig_data[22:16] = active_feb_list_pre[6:0]; // Active feb list at pre-trig

  assign postdrift_adr = PATTERN_FINDER_LATENCY + drift_delay;

  srl16e_bbl #(MXPTRID) usrldrift (.clock(clock),.ce(1'b1),.adr(postdrift_adr),.d(pretrig_data),.q(postdrift_data));

  wire valid_clct_required = 1'b1;

// Extract pre-trigger data after drift delay, compensated for pattern-finder latency + programmable drift delay
  wire              clct_pop_xtmb        = postdrift_data[0];     // CLCT postdrift flag aka active_feb_flag
  wire [MXBADR-1:0] clct_wr_adr_xtmb     = postdrift_data[11:1];  // Buffer address at pre-trigger
  wire              clct_wr_avail_xtmb   = postdrift_data[12];    // Buffer address was valid at pre-trigger
  wire [1:0]        bxn_counter_xtmb     = postdrift_data[14:13]; // BXN at pre-trigger, only lsbs are needed for clct
  wire              trig_source_ext_xtmb = postdrift_data[15];    // Trigger source was not CLCT pattern
  wire [MXCFEB-1:0] aff_list_xtmb        = postdrift_data[22:16]; // Active feb list

// After drift, send CLCT words to TMB, persist 1 cycle only, blank invalid CLCTs unless override
  wire clct0_hit_valid = (hs_hit_1st >= hit_thresh_postdrift);    // CLCT is over hit thresh
  wire clct0_pid_valid = (hs_pid_1st >= pid_thresh_postdrift);    // CLCT is over pid thresh

  wire clct1_hit_valid = (hs_hit_2nd >= hit_thresh_postdrift);    // CLCT is over hit thresh
  wire clct1_pid_valid = (hs_pid_2nd >= pid_thresh_postdrift);    // CLCT is over pid thresh

  wire clct0_really_valid = (clct0_hit_valid && clct0_pid_valid);    // CLCT is over thresh and not external
  wire clct1_really_valid = (clct1_hit_valid && clct1_pid_valid);    // CLCT is over thresh and not external

  wire clct0_valid = clct0_really_valid || trig_source_ext_xtmb || !valid_clct_required;
  wire clct1_valid = clct1_really_valid || trig_source_ext_xtmb || !valid_clct_required;

  assign clct0_vpf = clct0_valid && clct_pop_xtmb;
  assign clct1_vpf = clct1_valid && clct_pop_xtmb;

// CLCT Sequencer State Declarations
  reg[63:0] clct_sm_dsp;

  always @* begin
    case (clct_sm)
      startup:  clct_sm_dsp <= "startup ";
      idle:     clct_sm_dsp <= "idle    ";
      pretrig:  clct_sm_dsp <= "pretrig ";
      throttle: clct_sm_dsp <= "throttle";
      flush:    clct_sm_dsp <= "flush   ";
      halt:     clct_sm_dsp <= "halt    ";
      default   clct_sm_dsp <= "default ";
    endcase
  end

`endif

endmodule
