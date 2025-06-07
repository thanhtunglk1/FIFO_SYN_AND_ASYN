module bin_2_gray #(
  parameter WIDTH = 4
)(
  input  logic [WIDTH - 1:0] i_bin,
  output logic [WIDTH - 1:0] o_gray
);

  assign o_gray = i_bin ^ {1'b0, i_bin[WIDTH - 1:1]};

endmodule