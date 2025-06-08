module shift_reg #(
  parameter WIDTH = 8
)(
  input  logic i_clk,
  input  logic i_rst_n,
  input  logic i_en,
  input  logic i_data_in,
  output logic o_data_out
);

  logic [WIDTH - 1:0] shift_reg;

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if(~i_rst_n) shift_reg <= '0;

    else if (i_en) begin

      shift_reg <= {shift_reg[WIDTH - 2:0], i_data_in};

    end
  end

  assign o_data_out = shift_reg[WIDTH - 1];

endmodule