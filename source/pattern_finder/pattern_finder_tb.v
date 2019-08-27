module pattern_finder_tb ();

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

  // inputs

  wire [MXHITB-1:0]   lyr_thresh_pretrig = 'd3;
  wire [MXHITB-1:0]   hit_thresh_pretrig = 'd3;
  wire [MXPIDB-1:0]   pid_thresh_pretrig = 'd2;
  wire [MXHITB-1:0]   dmb_thresh_pretrig = 'd3;
  wire [MXCFEB-1:0]   cfeb_en            = 'b1111111;
  wire [MXKEYB-1+1:0] adjcfeb_dist       = 'd8;
  wire                clct_blanking      = 'b1;

  wire         clct_sep_src       = 'b1; // 1==vme, 0==ram
  wire  [7:0]  clct_sep_vme       = 'd10;
  wire         clct_sep_ram_we    = 'b0;
  wire  [3:0]  clct_sep_ram_adr   = 'd0;
  wire  [15:0] clct_sep_ram_wdata = 'd0;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //--------------------------------------------------------------------------------------------------------------------

  wire  [7:0]  key_hs_expect_1st , key_hs_expect_dly_1st , key_hs_expect_mem_1st ;
  wire  [11:0] ccode_expect_1st  , ccode_expect_dly_1st  , ccode_expect_mem_1st  ;
  wire  [3:0]  pat_expect_1st    , pat_expect_dly_1st    , pat_expect_mem_1st    ;

  wire  [7:0]  key_hs_expect_2nd , key_hs_expect_dly_2nd , key_hs_expect_mem_2nd ;
  wire  [11:0] ccode_expect_2nd  , ccode_expect_dly_2nd  , ccode_expect_mem_2nd  ;
  wire  [3:0]  pat_expect_2nd    , pat_expect_dly_2nd    , pat_expect_mem_2nd    ;

  parameter MXADRB = 15;
  wire [MXADRB-1:0] mem_adr;
  wire [MXADRB-1:0] mem_adr_dly;

  srl16e_bbl #(.WIDTH(8+12+4)) srl16e_bbl_expect_1st (
    .clock (clock),
    .ce    (1'b1),
    .adr   (4'd6),
    .d     ({key_hs_expect_mem_1st, ccode_expect_mem_1st, pat_expect_mem_1st}),
    .q     ({key_hs_expect_dly_1st, ccode_expect_dly_1st, pat_expect_dly_1st})
  );

  srl16e_bbl #(.WIDTH(8+12+4)) srl16e_bbl_expect_2nd (
    .clock (clock),
    .ce    (1'b1),
    .adr   (4'd6),
    .d     ({key_hs_expect_mem_2nd, ccode_expect_mem_2nd, pat_expect_mem_2nd}),
    .q     ({key_hs_expect_dly_2nd, ccode_expect_dly_2nd, pat_expect_dly_2nd})
  );

  srl16e_bbl #(.WIDTH(MXADRB)) srl16e_bbl_adr (
    .clock (clock),
    .ce    (1'b1),
    .adr   (4'd6),
    .d     ({mem_adr}),
    .q     ({mem_adr_dly})
  );

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

  ly_oneshot #(.WIDTH(224)) ly_oneshot0 ( .persist(4'd3), .in (ly0hs_mem), .out(ly0hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.WIDTH(224)) ly_oneshot1 ( .persist(4'd3), .in (ly1hs_mem), .out(ly1hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.WIDTH(224)) ly_oneshot2 ( .persist(4'd3), .in (ly2hs_mem), .out(ly2hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.WIDTH(224)) ly_oneshot3 ( .persist(4'd3), .in (ly3hs_mem), .out(ly3hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.WIDTH(224)) ly_oneshot4 ( .persist(4'd3), .in (ly4hs_mem), .out(ly4hs_os ), .reset (reset), .clock (clock));
  ly_oneshot #(.WIDTH(224)) ly_oneshot5 ( .persist(4'd3), .in (ly5hs_mem), .out(ly5hs_os ), .reset (reset), .clock (clock));

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
    .adr   (4'd6),
    .d     ({ pat_roi_ly5_1st     , pat_roi_ly4_1st     , pat_roi_ly3_1st     , pat_roi_ly2_1st     , pat_roi_ly1_1st     , pat_roi_ly0_1st     }),
    .q     ({ pat_roi_ly5_dly_1st , pat_roi_ly4_dly_1st , pat_roi_ly3_dly_1st , pat_roi_ly2_dly_1st , pat_roi_ly1_dly_1st , pat_roi_ly0_dly_1st })
  );
  srl16e_bbl #(.WIDTH(66)) roi_dly_2nd (
    .clock (clock),
    .ce    (1'b1),
    .adr   (4'd6),
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
  wire [MXQLTB - 1   : 0] hs_qlt_1st;
  wire [MXBNDB - 1   : 0] hs_bnd_1st;
  wire [MXPATC - 1   : 0] hs_car_1st; // 1st CLCT pattern lookup comparator-code
  wire [MXSUBKEYBX-1 : 0] hs_xky_1st;

  // 2nd clct
  wire  [MXHITB-1:0]  hs_hit_2nd;
  wire  [MXPIDB-1:0]  hs_pid_2nd;
  wire  [MXKEYBX-1:0] hs_key_2nd;
  wire                hs_bsy_2nd;

  // 2nd pattern lookup results
  wire [MXQLTB - 1   : 0] hs_qlt_2nd;
  wire [MXBNDB - 1   : 0] hs_bnd_2nd;
  wire [MXPATC - 1   : 0] hs_car_2nd; // 2nd CLCT pattern lookup comparator-code
  wire [MXSUBKEYBX-1 : 0] hs_xky_2nd;

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
    // Output Checker
    //--------------------------------------------------------------------------------------------------------------------

    wire match_1st, match_2nd;

    ccode_checker ccode_checker_1st (

      .valid        (hs_pid_1st > 2),

      .check_pat    (1'b1),
      .pat_found    (hs_pid_1st),
      .pat_expect   (pat_expect_1st),

      .check_ccode  (1'b0),
      .ccode_found  (hs_car_1st),
      .ccode_expect (ccode_expect_1st),

      .check_keyhs  (1'b1),
      .keyhs_found  (hs_key_1st),
      .keyhs_expect (key_hs_expect_1st),

      .match        (match_1st)

    );

    ccode_checker ccode_checker_2nd (

      .valid        (hs_pid_2nd > 2),

      .check_pat    (1'b1),
      .pat_found    (hs_pid_2nd),
      .pat_expect   (pat_expect_2nd),

      .check_ccode  (1'b0),
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

  wire valid_match_1st    = ((pat_expect_1st > 1) &&  match_1st);
  wire valid_mismatch_1st = ((pat_expect_1st > 1) && !match_1st);

  wire valid_match_2nd    = ((pat_expect_2nd > 1) &&  match_2nd);
  wire valid_mismatch_2nd = ((pat_expect_2nd > 1) && !match_2nd);

  always @(posedge clock) begin

    if (valid_mismatch_1st) begin
      valid_unmatch_cnt_1st <= valid_unmatch_cnt_1st + 1'b1;
      $display ("FAIL: %4d 1st found:  khs=%3d, pat=%1x, ccode=%3x,  bend=%x, qlt=%x", mem_adr_dly, hs_key_1st, hs_pid_1st, hs_car_1st, hs_bnd_1st, hs_qlt_1st);
      $display ("FAIL: %4d 1st expect: khs=%3d, pat=%1x, ccode=%3x",                   mem_adr_dly, key_hs_expect_1st, pat_expect_1st, ccode_expect_1st );
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
      $display ("FAIL: %4d 2nd found:  khs=%3d, pat=%1x, ccode=%3x,  bend=%x, qlt=%x", mem_adr_dly, hs_key_2nd, hs_pid_2nd, hs_car_2nd, hs_bnd_2nd, hs_qlt_2nd);
      $display ("FAIL: %4d 2nd expect: khs=%3d, pat=%1x, ccode=%3x",                   mem_adr_dly, key_hs_expect_2nd, pat_expect_2nd, ccode_expect_2nd );
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
      $display ("PASS: 1st %4d match: khs=%3d, pat=%1x, ccode=%3x. Passed %d of %d",                            mem_adr_dly, key_hs_expect_1st, pat_expect_1st, ccode_expect_1st, valid_match_cnt_1st, valid_match_cnt_1st +valid_unmatch_cnt_1st  );
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
      $display ("PASS: 2nd %4d match: khs=%3d, pat=%1x, ccode=%3x. Passed %d of %d",                            mem_adr_dly, key_hs_expect_2nd, pat_expect_2nd, ccode_expect_2nd, valid_match_cnt_2nd, valid_match_cnt_2nd +valid_unmatch_cnt_2nd   );
    end

  end

endmodule
