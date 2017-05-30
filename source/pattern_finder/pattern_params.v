parameter MXCFEB  = 7;             // Number of CFEBs on CSC
parameter MXLY    = 6;             // Number of layers in CSC
parameter MXDS    = 8;             // Number of DiStrips per layer on 1 CFEB
parameter MXDSX   = MXCFEB * MXDS; // Number of DiStrips per layer on 7 CFEBs
parameter MXHS    = 32;            // Number of HalfStrips per layer on 1 CFEB
parameter MXHSX   = MXCFEB * MXHS; // Number of HalfStrips per layer on 7 CFEBs
parameter MXKEY   = MXHS;          // Number of key HalfSrips on 1 CFEB
parameter MXKEYB  = 5;             // Number of HalfSrip key bits on 1 CFEB
parameter MXKEYX  = MXCFEB * MXHS; // Number of key HalfSrips on 7 CFEBs
parameter MXKEYBX = 8;             // Number of HalfSrip key bits on 7 CFEBs

parameter MXPIDB  = 4;             // Pattern ID bits
parameter MXHITB  = 3;             // Hits on pattern bits
parameter MXPATB  = 3 + 4;         // Pattern bits

parameter MXPATC  = 12; // Pattern Carry Bits

parameter MXQSB   = 3;   // Quarter-strip bits
parameter MXQLTB  = 2;   // Fit quality bits
parameter MXBNDB  = 4;   // Bend bits

parameter MXPID   = 11; // Number of patterns

parameter PATLUT = 1;

parameter A=10;

parameter PRETRIG_SOURCE = 0; // 0=pretrig, 1=post-fit

parameter [MXPID-1:2] pat_en = { 1'b1, // A
                                 1'b1, // 9
                                 1'b1, // 8
                                 1'b1, // 7
                                 1'b1, // 6
                                 1'b1, // 5
                                 1'b1, // 4
                                 1'b1, // 3
                                 1'b1  // 2
                               };
