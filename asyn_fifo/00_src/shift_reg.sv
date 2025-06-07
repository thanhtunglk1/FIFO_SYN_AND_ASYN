module shift_reg #(
  parameter WIDTH = 8,
  parameter DEPTH = 2
)(
  input  logic i_clk,
  input  logic i_rst_n,
  input  logic [WIDTH - 1:0] i_data_in,
  output logic [WIDTH - 1:0] o_data_out
);

  logic [WIDTH - 1:0] shift_reg [DEPTH - 1:0];

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if(~i_rst_n) begin
      for(int i = 0; i < DEPTH; i++) shift_reg[i] <= '0;
    end

    else begin
      shift_reg[0] <= i_data_in;
      for(int i = 1; i < DEPTH; i++) shift_reg[i] <= shift_reg[i - 1];
    end
  end

  assign o_data_out = shift_reg[DEPTH - 1];

endmodule