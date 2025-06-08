module gray_2_bin #(
  parameter WIDTH = 4
)(
  input  logic [WIDTH -1:0] i_gray,
  output logic [WIDTH -1:0] o_bin
);

  always_comb begin : proc_gray_2_bin
    o_bin[WIDTH - 1] = i_gray[WIDTH - 1];

    for(int i = (WIDTH - 2); i >= 0; i--) begin 
      o_bin[i] = o_bin[i + 1] ^ i_gray[i];
    end
  end

endmodule