
module ly_oneshot (
  input [3:0] persist,
  input [WIDTH-1:0] in,
  output [WIDTH-1:0] out,
  input clock,
  input reset
);
parameter WIDTH = 224;
parameter BYPASS = 0;

reg  [3:0] width_cnt [WIDTH-1:0];
wire [WIDTH-1:0] busy;

genvar ibit;
generate
  for (ibit=0; ibit<WIDTH; ibit=ibit+1) begin : bitloop

    initial width_cnt[ibit] = 0;

    assign busy[ibit] = width_cnt[ibit]!=0;

    always @(posedge clock) begin
        if      (reset)      width_cnt[ibit] <= 0;                    // clear on reset
        else if (in[ibit])   width_cnt[ibit] <= persist[3:0];         // load persistence count
        else if (busy[ibit]) width_cnt[ibit] <= width_cnt[ibit]-1'b1; // decrement count down to 0
    end

    if (BYPASS)
      assign out[ibit] = in[ibit];
    else
      assign out[ibit] = busy[ibit] || in[ibit];

  end
endgenerate



endmodule
