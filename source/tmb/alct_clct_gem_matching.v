`timescale 1ns / 1ps
// the module is to check ALCT, CLCT, GEM position matching

module  alct_clct_gem_matching(
    
  input alct0_vpf,
  input alct1_vpf,

  input [6:0] alct0_wg,
  input [6:0] alct1_wg,

  input clct0_vpf,
  input clct1_vpf,
  input [9:0] clct0_xky,
  input [9:0] clct1_xky,

  input [7:0] gemA_vpf,
  input [7:0] gemB_vpf,

  input [6:0] gemA_cluster0_wg_lo,
  input [6:0] gemA_cluster1_wg_lo,
  input [6:0] gemA_cluster2_wg_lo,
  input [6:0] gemA_cluster3_wg_lo,
  input [6:0] gemA_cluster4_wg_lo,
  input [6:0] gemA_cluster5_wg_lo,
  input [6:0] gemA_cluster6_wg_lo,
  input [6:0] gemA_cluster7_wg_lo,

  input [6:0] gemA_cluster0_wg_hi,
  input [6:0] gemA_cluster1_wg_hi,
  input [6:0] gemA_cluster2_wg_hi,
  input [6:0] gemA_cluster3_wg_hi,
  input [6:0] gemA_cluster4_wg_hi,
  input [6:0] gemA_cluster5_wg_hi,
  input [6:0] gemA_cluster6_wg_hi,
  input [6:0] gemA_cluster7_wg_hi,

  input [9:0] gemA_cluster0_xky_lo,
  input [9:0] gemA_cluster1_xky_lo,
  input [9:0] gemA_cluster2_xky_lo,
  input [9:0] gemA_cluster3_xky_lo,
  input [9:0] gemA_cluster4_xky_lo,
  input [9:0] gemA_cluster5_xky_lo,
  input [9:0] gemA_cluster6_xky_lo,
  input [9:0] gemA_cluster7_xky_lo,

  input [9:0] gemA_cluster0_xky_hi,
  input [9:0] gemA_cluster1_xky_hi,
  input [9:0] gemA_cluster2_xky_hi,
  input [9:0] gemA_cluster3_xky_hi,
  input [9:0] gemA_cluster4_xky_hi,
  input [9:0] gemA_cluster5_xky_hi,
  input [9:0] gemA_cluster6_xky_hi,
  input [9:0] gemA_cluster7_xky_hi,

  input [9:0] gemA_cluster0_xky_mi,
  input [9:0] gemA_cluster1_xky_mi,
  input [9:0] gemA_cluster2_xky_mi,
  input [9:0] gemA_cluster3_xky_mi,
  input [9:0] gemA_cluster4_xky_mi,
  input [9:0] gemA_cluster5_xky_mi,
  input [9:0] gemA_cluster6_xky_mi,
  input [9:0] gemA_cluster7_xky_mi,

  input [6:0] gemB_cluster0_wg_lo,
  input [6:0] gemB_cluster1_wg_lo,
  input [6:0] gemB_cluster2_wg_lo,
  input [6:0] gemB_cluster3_wg_lo,
  input [6:0] gemB_cluster4_wg_lo,
  input [6:0] gemB_cluster5_wg_lo,
  input [6:0] gemB_cluster6_wg_lo,
  input [6:0] gemB_cluster7_wg_lo,

  input [6:0] gemB_cluster0_wg_hi,
  input [6:0] gemB_cluster1_wg_hi,
  input [6:0] gemB_cluster2_wg_hi,
  input [6:0] gemB_cluster3_wg_hi,
  input [6:0] gemB_cluster4_wg_hi,
  input [6:0] gemB_cluster5_wg_hi,
  input [6:0] gemB_cluster6_wg_hi,
  input [6:0] gemB_cluster7_wg_hi,

  input [9:0] gemB_cluster0_xky_lo,
  input [9:0] gemB_cluster1_xky_lo,
  input [9:0] gemB_cluster2_xky_lo,
  input [9:0] gemB_cluster3_xky_lo,
  input [9:0] gemB_cluster4_xky_lo,
  input [9:0] gemB_cluster5_xky_lo,
  input [9:0] gemB_cluster6_xky_lo,
  input [9:0] gemB_cluster7_xky_lo,

  input [9:0] gemB_cluster0_xky_hi,
  input [9:0] gemB_cluster1_xky_hi,
  input [9:0] gemB_cluster2_xky_hi,
  input [9:0] gemB_cluster3_xky_hi,
  input [9:0] gemB_cluster4_xky_hi,
  input [9:0] gemB_cluster5_xky_hi,
  input [9:0] gemB_cluster6_xky_hi,
  input [9:0] gemB_cluster7_xky_hi,

  input [9:0] gemB_cluster0_xky_mi,
  input [9:0] gemB_cluster1_xky_mi,
  input [9:0] gemB_cluster2_xky_mi,
  input [9:0] gemB_cluster3_xky_mi,
  input [9:0] gemB_cluster4_xky_mi,
  input [9:0] gemB_cluster5_xky_mi,
  input [9:0] gemB_cluster6_xky_mi,
  input [9:0] gemB_cluster7_xky_mi,

  input [7:0] copad_match, // copad 

  output  alct0_gemA_match_pos,
  output  alct0_gemB_match_pos,
  output  alct0_copad_match_pos,
  output  alct1_gemA_match_pos,
  output  alct1_gemB_match_pos,
  output  alct1_copad_match_pos,
  output  clct0_gemA_match_pos,
  output  clct0_gemB_match_pos,
  output  clct0_copad_match_pos,
  output  clct1_gemA_match_pos,
  output  clct1_gemB_match_pos,
  output  clct1_copad_match_pos,

  output  clct0_gem_bending,
  output  clct1_gem_bending,
  output [3:0] pri_best

  );

  parameter MXCLUSTER_CHAMBER       = 8; // Num GEM clusters  per Chamber
  parameter MXCLUSTER_SUPERCHAMBER  = 16; //Num GEM cluster  per superchamber

  wire [6:0] gemA_cluster_cscwg_lo[MXCLUSTER_CHAMBER-1:0] = {
      gemA_cluster0_wg_lo,
      gemA_cluster1_wg_lo,
      gemA_cluster2_wg_lo,
      gemA_cluster3_wg_lo,
      gemA_cluster4_wg_lo,
      gemA_cluster5_wg_lo,
      gemA_cluster6_wg_lo,
      gemA_cluster7_wg_lo
      };

  wire [6:0] gemA_cluster_cscwg_hi[MXCLUSTER_CHAMBER-1:0] = {
      gemA_cluster0_wg_hi,
      gemA_cluster1_wg_hi,
      gemA_cluster2_wg_hi,
      gemA_cluster3_wg_hi,
      gemA_cluster4_wg_hi,
      gemA_cluster5_wg_hi,
      gemA_cluster6_wg_hi,
      gemA_cluster7_wg_hi
      };

  wire [9:0] gemA_cluster_cscxky_lo[MXCLUSTER_CHAMBER-1:0] = {
      gemA_cluster0_xky_lo,
      gemA_cluster1_xky_lo,
      gemA_cluster2_xky_lo,
      gemA_cluster3_xky_lo,
      gemA_cluster4_xky_lo,
      gemA_cluster5_xky_lo,
      gemA_cluster6_xky_lo,
      gemA_cluster7_xky_lo
      };

  wire [9:0] gemA_cluster_cscxky_mi[MXCLUSTER_CHAMBER-1:0] = {
      gemA_cluster0_xky_mi,
      gemA_cluster1_xky_mi,
      gemA_cluster2_xky_mi,
      gemA_cluster3_xky_mi,
      gemA_cluster4_xky_mi,
      gemA_cluster5_xky_mi,
      gemA_cluster6_xky_mi,
      gemA_cluster7_xky_mi
      };

  wire [9:0] gemA_cluster_cscxky_hi[MXCLUSTER_CHAMBER-1:0] = {
      gemA_cluster0_xky_hi,
      gemA_cluster1_xky_hi,
      gemA_cluster2_xky_hi,
      gemA_cluster3_xky_hi,
      gemA_cluster4_xky_hi,
      gemA_cluster5_xky_hi,
      gemA_cluster6_xky_hi,
      gemA_cluster7_xky_hi
      };

  wire [6:0] gemB_cluster_cscwg_lo[MXCLUSTER_CHAMBER-1:0] = {
      gemB_cluster0_wg_lo,
      gemB_cluster1_wg_lo,
      gemB_cluster2_wg_lo,
      gemB_cluster3_wg_lo,
      gemB_cluster4_wg_lo,
      gemB_cluster5_wg_lo,
      gemB_cluster6_wg_lo,
      gemB_cluster7_wg_lo
      };

  wire [6:0] gemB_cluster_cscwg_hi[MXCLUSTER_CHAMBER-1:0] = {
      gemB_cluster0_wg_hi,
      gemB_cluster1_wg_hi,
      gemB_cluster2_wg_hi,
      gemB_cluster3_wg_hi,
      gemB_cluster4_wg_hi,
      gemB_cluster5_wg_hi,
      gemB_cluster6_wg_hi,
      gemB_cluster7_wg_hi
      };

  wire [9:0] gemB_cluster_cscxky_lo[MXCLUSTER_CHAMBER-1:0] = {
      gemB_cluster0_xky_lo,
      gemB_cluster1_xky_lo,
      gemB_cluster2_xky_lo,
      gemB_cluster3_xky_lo,
      gemB_cluster4_xky_lo,
      gemB_cluster5_xky_lo,
      gemB_cluster6_xky_lo,
      gemB_cluster7_xky_lo
      };

  wire [9:0] gemB_cluster_cscxky_mi[MXCLUSTER_CHAMBER-1:0] = {
      gemB_cluster0_xky_mi,
      gemB_cluster1_xky_mi,
      gemB_cluster2_xky_mi,
      gemB_cluster3_xky_mi,
      gemB_cluster4_xky_mi,
      gemB_cluster5_xky_mi,
      gemB_cluster6_xky_mi,
      gemB_cluster7_xky_mi
      };

  wire [9:0] gemB_cluster_cscxky_hi[MXCLUSTER_CHAMBER-1:0] = {
      gemB_cluster0_xky_hi,
      gemB_cluster1_xky_hi,
      gemB_cluster2_xky_hi,
      gemB_cluster3_xky_hi,
      gemB_cluster4_xky_hi,
      gemB_cluster5_xky_hi,
      gemB_cluster6_xky_hi,
      gemB_cluster7_xky_hi
      };

  wire [MXCLUSTER_CHAMBER-1:0] alct0_gemA_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_gemA_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_gemA_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_gemA_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_gemA_match_ok; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_gemA_match_ok; 

  wire [MXCLUSTER_CHAMBER-1:0] alct0_gemB_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_gemB_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_gemB_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_gemB_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_gemB_match_ok; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_gemB_match_ok; 

  wire [MXCLUSTER_CHAMBER-1:0] alct0_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] clct0_copad_match_ok; 
  wire [MXCLUSTER_CHAMBER-1:0] clct1_copad_match_ok; 

  wire [MXCLUSTER_CHAMBER-1:0] alct0_clct0_gem_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct0_clct1_gem_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_clct0_gem_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_clct1_gem_match; 

  wire [MXCLUSTER_CHAMBER-1:0] alct0_clct0_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct0_clct1_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_clct0_copad_match; 
  wire [MXCLUSTER_CHAMBER-1:0] alct1_clct1_copad_match; 

  wire [0]  clct0_gemA_bend [MXCLUSTER_CHAMBER-1:0];
  wire [0]  clct1_gemA_bend [MXCLUSTER_CHAMBER-1:0];
  wire [0]  clct0_gemB_bend [MXCLUSTER_CHAMBER-1:0];
  wire [0]  clct1_gemB_bend [MXCLUSTER_CHAMBER-1:0];
  wire [9:0]  clct0_gemA_angle [MXCLUSTER_CHAMBER-1:0];
  wire [9:0]  clct1_gemA_angle [MXCLUSTER_CHAMBER-1:0];
  wire [9:0]  clct0_gemB_angle [MXCLUSTER_CHAMBER-1:0];
  wire [9:0]  clct1_gemB_angle [MXCLUSTER_CHAMBER-1:0];

  wire [9:0]  alct0_copad_angle [MXCLUSTER_CHAMBER-1:0];
  wire [9:0]  alct1_copad_angle [MXCLUSTER_CHAMBER-1:0];

  parameter smallbending = 10'd16; // ignore the sign check for small bending angle
  parameter MAXGEMCSCBND = 10'd1024;// invalid bending 

  genvar i;
  generate
  for (i=0; i<MXCLUSTER_CHAMBER; i=i+1) begin: gem_csc_match
      alct0_gemA_match[i] = alct0_vpf && gemA_vpf[i] && alct0_wg  >= gemA_cluster_cscwg_lo[i]  && alct0_wg  <= gemA_cluster_cscwg_hi[i]; 
      alct1_gemA_match[i] = alct1_vpf && gemA_vpf[i] && alct1_wg  >= gemA_cluster_cscwg_lo[i]  && alct1_wg  <= gemA_cluster_cscwg_hi[i]; 
      clct0_gemA_match[i] = clct0_vpf && gemA_vpf[i] && clct0_xky >= gemA_cluster_cscxky_lo[i] && clct0_xky <= gemA_cluster_cscxky_hi[i]; 
      clct1_gemA_match[i] = clct1_vpf && gemA_vpf[i] && clct1_xky >= gemA_cluster_cscxky_lo[i] && clct1_xky <= gemA_cluster_cscxky_hi[i]; 
      alct0_gemB_match[i] = alct0_vpf && gemB_vpf[i] && alct0_wg  >= gemB_cluster_cscwg_lo[i]  && alct0_wg  <= gemB_cluster_cscwg_hi[i]; 
      alct1_gemB_match[i] = alct1_vpf && gemB_vpf[i] && alct1_wg  >= gemB_cluster_cscwg_lo[i]  && alct1_wg  <= gemB_cluster_cscwg_hi[i]; 
      clct0_gemB_match[i] = clct0_vpf && gemB_vpf[i] && clct0_xky >= gemB_cluster_cscxky_lo[i] && clct0_xky <= gemB_cluster_cscxky_hi[i]; 
      clct1_gemB_match[i] = clct1_vpf && gemB_vpf[i] && clct1_xky >= gemB_cluster_cscxky_lo[i] && clct1_xky <= gemB_cluster_cscxky_hi[i]; 

      clct0_gemA_bend[i]   = clct0_xky > gemA_cluster_cscxky_mi[i];
      clct0_gemB_bend[i]   = clct0_xky > gemB_cluster_cscxky_mi[i];
      clct1_gemA_bend[i]   = clct1_xky > gemA_cluster_cscxky_mi[i];
      clct1_gemB_bend[i]   = clct1_xky > gemB_cluster_cscxky_mi[i];

      clct0_gemA_match_ok[i] = clct0_gemA_match[i] && (clct0_gemA_bend[i] == clct0_bend);
      clct0_gemB_match_ok[i] = clct0_gemB_match[i] && (clct0_gemB_bend[i] == clct0_bend);
      clct1_gemA_match_ok[i] = clct1_gemA_match[i] && (clct0_gemA_bend[i] == clct1_bend);
      clct1_gemB_match_ok[i] = clct1_gemB_match[i] && (clct0_gemB_bend[i] == clct1_bend);

      clct0_gemA_angle[i] = clct0_gemA_match_ok[i] ? (clct0_gemA_bend[i] ? clct0_xky-gemA_cluster_cscxky_mi[i] : gemA_cluster_cscxky_mi[i]-clct0_xky) : MAXGEMCSCBND; 
      clct0_gemB_angle[i] = clct0_gemB_match_ok[i] ? (clct0_gemB_bend[i] ? clct0_xky-gemB_cluster_cscxky_mi[i] : gemB_cluster_cscxky_mi[i]-clct0_xky) : MAXGEMCSCBND; 
      clct1_gemA_angle[i] = clct1_gemA_match_ok[i] ? (clct1_gemA_bend[i] ? clct1_xky-gemA_cluster_cscxky_mi[i] : gemA_cluster_cscxky_mi[i]-clct1_xky) : MAXGEMCSCBND; 
      clct1_gemB_angle[i] = clct1_gemB_match_ok[i] ? (clct1_gemB_bend[i] ? clct1_xky-gemB_cluster_cscxky_mi[i] : gemB_cluster_cscxky_mi[i]-clct1_xky) : MAXGEMCSCBND; 

      alct0_copad_match[i] = alct0_gemA_match[i] && copad_match[i];
      alct1_copad_match[i] = alct1_gemA_match[i] && copad_match[i];
      clct0_copad_match[i] = clct0_gemA_match[i] && copad_match[i];
      clct1_copad_match[i] = clct1_gemA_match[i] && copad_match[i];

      clct0_copad_bend[i]  = clct0_xky > copad_cscxky_mi[i];
      clct1_copad_bend[i]  = clct1_xky > copad_cscxky_mi[i];

      clct0_copad_match_ok[i] = clct0_copad_match[i] && (clct0_copad_bend[i] == clct0_bend);
      clct1_copad_match_ok[i] = clct1_copad_match[i] && (clct1_copad_bend[i] == clct1_bend);

      clct0_copad_angle[i] = clct0_copad_match_ok[i] ? (clct0_copad_bend[i] ? clct0_xky-copad_cscxky_mi[i] : copad_cscxky_mi[i]-clct0_xky) : MAXGEMCSCBND;
      clct1_copad_angle[i] = clct1_copad_match_ok[i] ? (clct1_copad_bend[i] ? clct1_xky-copad_cscxky_mi[i] : copad_cscxky_mi[i]-clct1_xky) : MAXGEMCSCBND;
      
      alct0_copad_angle[i] = alct0_copad_match[i] ? 0 : MAXGEMCSCBND;
      alct1_copad_angle[i] = alct1_copad_match[i] ? 0 : MAXGEMCSCBND;

      alct0_clct0_gemA_match[i] = (alct0_gemA_match[i] && clct0_gemA_match_ok[i]);
      alct0_clct1_gemA_match[i] = (alct0_gemA_match[i] && clct1_gemA_match_ok[i]);
      alct1_clct0_gemA_match[i] = (alct1_gemA_match[i] && clct0_gemA_match_ok[i]);
      alct1_clct1_gemA_match[i] = (alct1_gemA_match[i] && clct1_gemA_match_ok[i]);
      alct0_clct0_gemB_match[i] = (alct0_gemB_match[i] && clct0_gemB_match_ok[i]);
      alct0_clct1_gemB_match[i] = (alct0_gemB_match[i] && clct1_gemB_match_ok[i]);
      alct1_clct0_gemB_match[i] = (alct1_gemB_match[i] && clct0_gemB_match_ok[i]);
      alct1_clct1_gemB_match[i] = (alct1_gemB_match[i] && clct1_gemB_match_ok[i]);

      alct0_clct0_gem_match[i] = (alct0_gemA_match[i] && clct0_gemA_match_ok[i]) || (alct0_gemB_match[i] && clct0_gemB_match_ok[i]);
      alct0_clct1_gem_match[i] = (alct0_gemA_match[i] && clct1_gemA_match_ok[i]) || (alct0_gemB_match[i] && clct1_gemB_match_ok[i]);
      alct1_clct0_gem_match[i] = (alct1_gemA_match[i] && clct0_gemA_match_ok[i]) || (alct1_gemB_match[i] && clct0_gemB_match_ok[i]);
      alct1_clct1_gem_match[i] = (alct1_gemA_match[i] && clct1_gemA_match_ok[i]) || (alct1_gemB_match[i] && clct1_gemB_match_ok[i]);

      alct0_clct0_copad_match[i] = alct0_copad_match[i] && clct0_copad_match_ok[i];
      alct0_clct1_copad_match[i] = alct0_copad_match[i] && clct1_copad_match_ok[i];
      alct1_clct0_copad_match[i] = alct1_copad_match[i] && clct0_copad_match_ok[i];
      alct1_clct1_copad_match[i] = alct1_copad_match[i] && clct1_copad_match_ok[i];

    end
  endgenerate 

  wire [2:0] clct0_gemA_best_icluster;
  wire [9:0] clct0_gemA_best_angle;
  wire [9:0] clct0_gemA_best_cscxky;
  tree_encoder_gemclct uclct0_gemA_match{
      
      clct0_gemA_angle[0],
      clct0_gemA_angle[1],
      clct0_gemA_angle[2],
      clct0_gemA_angle[3],
      clct0_gemA_angle[4],
      clct0_gemA_angle[5],
      clct0_gemA_angle[6],
      clct0_gemA_angle[7],

      gemA_cluster_cscxky_mi[0],
      gemA_cluster_cscxky_mi[1],
      gemA_cluster_cscxky_mi[2],
      gemA_cluster_cscxky_mi[3],
      gemA_cluster_cscxky_mi[4],
      gemA_cluster_cscxky_mi[5],
      gemA_cluster_cscxky_mi[6],
      gemA_cluster_cscxky_mi[7],

      clct0_gemA_best_cscxky,
      clct0_gemA_best_angle,
      clct0_gemA_best_icluster
      };


  wire [2:0] clct0_gemB_best_icluster;
  wire [9:0] clct0_gemB_best_angle;
  wire [9:0] clct0_gemB_best_cscxky;
  tree_encoder_gemclct uclct0_gemB_match{
      clct0_gemB_angle[0],
      clct0_gemB_angle[1],
      clct0_gemB_angle[2],
      clct0_gemB_angle[3],
      clct0_gemB_angle[4],
      clct0_gemB_angle[5],
      clct0_gemB_angle[6],
      clct0_gemB_angle[7],

      gemB_cluster_cscxky_mi[0],
      gemB_cluster_cscxky_mi[1],
      gemB_cluster_cscxky_mi[2],
      gemB_cluster_cscxky_mi[3],
      gemB_cluster_cscxky_mi[4],
      gemB_cluster_cscxky_mi[5],
      gemB_cluster_cscxky_mi[6],
      gemB_cluster_cscxky_mi[7],

      clct0_gemB_best_cscxky,
      clct0_gemB_best_angle,
      clct0_gemB_best_icluster
      };

  wire [2:0] clct1_gemA_best_icluster;
  wire [9:0] clct1_gemA_best_angle;
  wire [9:0] clct1_gemA_best_cscxky;
  tree_encoder_gemclct uclct1_gemA_match{
      clct1_gemA_angle[0],
      clct1_gemA_angle[1],
      clct1_gemA_angle[2],
      clct1_gemA_angle[3],
      clct1_gemA_angle[4],
      clct1_gemA_angle[5],
      clct1_gemA_angle[6],
      clct1_gemA_angle[7],

      gemA_cluster_cscxky_mi[0],
      gemA_cluster_cscxky_mi[1],
      gemA_cluster_cscxky_mi[2],
      gemA_cluster_cscxky_mi[3],
      gemA_cluster_cscxky_mi[4],
      gemA_cluster_cscxky_mi[5],
      gemA_cluster_cscxky_mi[6],
      gemA_cluster_cscxky_mi[7],

      clct1_gemA_best_cscxky,
      clct1_gemA_best_angle,
      clct1_gemA_best_icluster
      };

  wire [2:0] clct1_gemB_best_icluster;
  wire [9:0] clct1_gemB_best_angle;
  wire [9:0] clct1_gemB_best_cscxky;
  tree_encoder_gemclct uclct1_gemB_match{
      clct1_gemB_angle[0],
      clct1_gemB_angle[1],
      clct1_gemB_angle[2],
      clct1_gemB_angle[3],
      clct1_gemB_angle[4],
      clct1_gemB_angle[5],
      clct1_gemB_angle[6],
      clct1_gemB_angle[7],

      gemB_cluster_cscxky_mi[0],
      gemB_cluster_cscxky_mi[1],
      gemB_cluster_cscxky_mi[2],
      gemB_cluster_cscxky_mi[3],
      gemB_cluster_cscxky_mi[4],
      gemB_cluster_cscxky_mi[5],
      gemB_cluster_cscxky_mi[6],
      gemB_cluster_cscxky_mi[7],

      clct1_gemA_best_cscxky,
      clct1_gemA_best_angle,
      clct1_gemA_best_icluster
      };


  wire [2:0] clct0_copad_best_icluster;
  wire [9:0] clct0_copad_best_angle;
  wire [9:0] clct0_copad_best_cscxky;
  tree_encoder_gemclct uclct0_copad_match{
      clct0_copad_angle[0],
      clct0_copad_angle[1],
      clct0_copad_angle[2],
      clct0_copad_angle[3],
      clct0_copad_angle[4],
      clct0_copad_angle[5],
      clct0_copad_angle[6],
      clct0_copad_angle[7],

      copad_cluster_cscxky_mi[0],
      copad_cluster_cscxky_mi[1],
      copad_cluster_cscxky_mi[2],
      copad_cluster_cscxky_mi[3],
      copad_cluster_cscxky_mi[4],
      copad_cluster_cscxky_mi[5],
      copad_cluster_cscxky_mi[6],
      copad_cluster_cscxky_mi[7],

      clct0_copad_best_cscxky,
      clct0_copad_best_angle,
      clct0_copad_best_icluster
      };

  wire [2:0] clct1_copad_best_icluster;
  wire [9:0] clct1_copad_best_angle;
  wire [9:0] clct1_copad_best_cscxky;
  tree_encoder_gemclct uclct1_copad_match{
      clct1_copad_angle[0],
      clct1_copad_angle[1],
      clct1_copad_angle[2],
      clct1_copad_angle[3],
      clct1_copad_angle[4],
      clct1_copad_angle[5],
      clct1_copad_angle[6],
      clct1_copad_angle[7],

      copad_cluster_cscxky_mi[0],
      copad_cluster_cscxky_mi[1],
      copad_cluster_cscxky_mi[2],
      copad_cluster_cscxky_mi[3],
      copad_cluster_cscxky_mi[4],
      copad_cluster_cscxky_mi[5],
      copad_cluster_cscxky_mi[6],
      copad_cluster_cscxky_mi[7],

      clct1_copad_best_cscxky,
      clct1_copad_best_angle,
      clct1_copad_best_icluster
      };


  wire alct0_clct0_copad_match_any = |alct0_clct0_copad_match && clct0_copad_best_angle != MAXGEMCSCBND;
  wire alct0_clct1_copad_match_any = |alct0_clct1_copad_match && clct1_copad_best_angle != MAXGEMCSCBND;
  wire alct1_clct0_copad_match_any = |alct1_clct0_copad_match && clct0_copad_best_angle != MAXGEMCSCBND;
  wire alct1_clct1_copad_match_any = |alct1_clct1_copad_match && clct1_copad_best_angle != MAXGEMCSCBND;

  wire alct0_clct0_gemA_match_any  = |alct0_clct0_gemA_match && clct0_gemA_best_angle != MAXGEMCSCBND;
  wire alct0_clct1_gemA_match_any  = |alct0_clct1_gemA_match && clct1_gemA_best_angle != MAXGEMCSCBND;
  wire alct1_clct0_gemA_match_any  = |alct1_clct0_gemA_match && clct0_gemA_best_angle != MAXGEMCSCBND;
  wire alct1_clct1_gemA_match_any  = |alct1_clct1_gemA_match && clct1_gemA_best_angle != MAXGEMCSCBND;

  wire alct0_clct0_gemB_match_any  = |alct0_clct0_gemB_match && clct0_gemB_best_angle != MAXGEMCSCBND;
  wire alct0_clct1_gemB_match_any  = |alct0_clct1_gemB_match && clct1_gemB_best_angle != MAXGEMCSCBND;
  wire alct1_clct0_gemB_match_any  = |alct1_clct0_gemB_match && clct0_gemB_best_angle != MAXGEMCSCBND;
  wire alct1_clct1_gemB_match_any  = |alct1_clct1_gemB_match && clct1_gemB_best_angle != MAXGEMCSCBND;

  wire alct0_gemA_match_any        = |alct0_gemA_match_any;
  wire alct1_gemA_match_any        = |alct1_gemA_match_any;
  wire alct0_gemB_match_any        = |alct0_gemB_match_any;
  wire alct1_gemB_match_any        = |alct1_gemB_match_any;

  wire clct0_gemA_match_any        = |clct0_gemA_match_any && clct0_gemA_best_angle != MAXGEMCSCBND;
  wire clct1_gemA_match_any        = |clct1_gemA_match_any && clct1_gemA_best_angle != MAXGEMCSCBND;
  wire clct0_gemB_match_any        = |clct0_gemB_match_any && clct0_gemB_best_angle != MAXGEMCSCBND;
  wire clct1_gemB_match_any        = |clct1_gemB_match_any && clct1_gemB_best_angle != MAXGEMCSCBND;

  //wire alct0_clct0_gem_match_any   = |alct0_clct0_gem_match;
  //wire alct0_clct1_gem_match_any   = |alct0_clct1_gem_match;
  //wire alct1_clct0_gem_match_any   = |alct1_clct0_gem_match;
  //wire alct1_clct1_gem_match_any   = |alct1_clct1_gem_match;

  wire alct0_clct0_copad_match_found = alct0_clct0_copad_match_any || alct0_clct1_copad_match_any || alct1_clct0_copad_match_any || alct1_clct1_copad_match_any;
  wire alct1_clct1_copad_match_found = alct0_clct0_copad_match_any && alct0_clct1_copad_match_any && alct1_clct0_copad_match_any && alct1_clct1_copad_match_any;
  wire swapclct_copad_match = alct0_clct0_copad_match_found && (clct0_copad_best_angle > clct1_copad_best_angle);
  wire swapalct_copad_match = !alct0_clct0_copad_match_any && !alct0_clct1_copad_match_any && (alct1_clct0_copad_match_any || alct1_clct1_copad_match_any);

  wire alct_clct_copad_nomatch = !alct0_clct0_copad_match_found;

  //-------------------------------------------------------------------------------------------------------------------
  //ALCT-CLCT+singleGEM match, very challenging part!, lot of combinations!
  //-------------------------------------------------------------------------------------------------------------------
  wire alct0_clct0_gem_match_found = (
      alct0_clct0_gemA_match_any || alct0_clct1_gemA_match_any || alct1_clct0_gemA_match_any || alct1_clct1_gemA_match_any ||
      alct0_clct0_gemB_match_any || alct0_clct1_gemB_match_any || alct1_clct0_gemB_match_any || alct1_clct1_gemB_match_any 
  );

  //always @(*) begin
  //    if (clct0_gemA_best_angle < clct0_gemB_best_angle && clct0_gemA_best_angle < clct1_gemA_best_angle && clct0_gemA_best_angle < clct1_gemB_best_angle) begin

  //    end
  //end 

  wire alct_clct_gem_nomatch = !alct0_clct0_gem_match_found;
  //-------------------------------------------------------------------------------------------------------------------


  //alct-clct match in tmb.v

  //still need to find out wire group of GEM pad
  wire clct0_copad_match_found  = (clct0_copad_best_angle != MAXGEMCSCBND) || (clct1_copad_best_angle != MAXGEMCSCBND);
  wire swapclct_clctcopad_match = clct0_copad_match_found && (clct0_copad_best_angle > clct1_copad_best_angle);
  wire clct1_copad_match_found  = (clct0_copad_best_angle != MAXGEMCSCBND) && (clct1_copad_best_angle != MAXGEMCSCBND);
  wire clct0_copad_nomatch      = !clct0_copad_match_found;


  wire [2:0] alct0_copad_best_icluster;
  wire [9:0] alct0_copad_best_angle;
  wire [9:0] alct0_copad_best_cscxky;
  tree_encoder_gemclct ualct0_copad_match{
      alct0_copad_angle[0],
      alct0_copad_angle[1],
      alct0_copad_angle[2],
      alct0_copad_angle[3],
      alct0_copad_angle[4],
      alct0_copad_angle[5],
      alct0_copad_angle[6],
      alct0_copad_angle[7],

      copad_cluster_cscxky_mi[0],
      copad_cluster_cscxky_mi[1],
      copad_cluster_cscxky_mi[2],
      copad_cluster_cscxky_mi[3],
      copad_cluster_cscxky_mi[4],
      copad_cluster_cscxky_mi[5],
      copad_cluster_cscxky_mi[6],
      copad_cluster_cscxky_mi[7],

      alct0_copad_best_cscxky,
      alct0_copad_best_angle,
      alct0_copad_best_icluster
      };

  wire [2:0] alct1_copad_best_icluster;
  wire [9:0] alct1_copad_best_angle;
  wire [9:0] alct1_copad_best_cscxky;
  tree_encoder_gemclct ualct1_copad_match{
      alct1_copad_angle[0],
      alct1_copad_angle[1],
      alct1_copad_angle[2],
      alct1_copad_angle[3],
      alct1_copad_angle[4],
      alct1_copad_angle[5],
      alct1_copad_angle[6],
      alct1_copad_angle[7],

      copad_cluster_cscxky_mi[0],
      copad_cluster_cscxky_mi[1],
      copad_cluster_cscxky_mi[2],
      copad_cluster_cscxky_mi[3],
      copad_cluster_cscxky_mi[4],
      copad_cluster_cscxky_mi[5],
      copad_cluster_cscxky_mi[6],
      copad_cluster_cscxky_mi[7],

      alct1_copad_best_cscxky,
      alct1_copad_best_angle,
      alct1_copad_best_icluster
      };

  wire alct0_copad_match_found  = (alct1_copad_best_angle != MAXGEMCSCBND) || (alct1_copad_best_angle != MAXGEMCSCBND);
  wire alct1_copad_match_found  = (alct0_copad_best_angle != MAXGEMCSCBND) && (alct1_copad_best_angle != MAXGEMCSCBND);
  wire alct0_copad_nomatch      = !alct0_copad_match_found;
  wire swapalct_alctcopad_match = alct0_copad_match_found && (alct0_copad_best_angle > alct1_copad_best_angle);



//-------------------------------------------------------------------------------------------------------------------
  endmodule
//-------------------------------------------------------------------------------------------------------------------

