module afifo #(
  parameter DEPTH = 16,
  parameter WIDTH = 8
)(
//GLOBAL
  input  logic i_clk_wr,
  input  logic i_clk_rd,
  input  logic i_rst_n ,

//CONTROL SIGNAL
  input  logic i_wr_en,
  input  logic i_rd_en,

//IN_OUT DATA
  input  logic [WIDTH - 1:0] i_data_in,
  output logic [WIDTH - 1:0] o_data_out,

//STATUS
  output logic o_full,
  output logic o_empty
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  //POINTER
  logic [ADDR_WIDTH:0] p_rd_ptr, n_rd_ptr;
  logic [ADDR_WIDTH:0] p_wr_ptr, n_wr_ptr;
  logic [ADDR_WIDTH:0] gray_rd_ptr, gray_wr_ptr;
  logic [ADDR_WIDTH:0] gray_rd_ptr_wr_clk, gray_wr_ptr_rd_clk;
  logic [ADDR_WIDTH:0] rd_ptr_wr_clk, wr_ptr_rd_clk;

  logic update_wr_ptr, update_rd_ptr;
  assign update_wr_ptr = ~o_full  & i_wr_en;
  assign update_rd_ptr = ~o_empty & i_rd_en;

  always_ff @(posedge i_clk_wr, negedge i_rst_n) begin : proc_update_wr_ptr
    if(~i_rst_n) p_wr_ptr <= '0;
    else         p_wr_ptr <= n_wr_ptr;
  end

  always_ff @(posedge i_clk_rd, negedge i_rst_n) begin : proc_update_rd_ptr
    if(~i_rst_n) p_rd_ptr <= '0;
    else         p_rd_ptr <= n_rd_ptr;
  end

  assign o_full  = (p_wr_ptr[ADDR_WIDTH] == ~rd_ptr_wr_clk[ADDR_WIDTH]) & (p_wr_ptr[ADDR_WIDTH - 1:0] == rd_ptr_wr_clk[ADDR_WIDTH - 1:0]);
  assign o_empty = (p_rd_ptr == wr_ptr_rd_clk);

  assign n_rd_ptr = update_rd_ptr ? (p_rd_ptr + 1'b1) : p_rd_ptr;
  assign n_wr_ptr = update_wr_ptr ? (p_wr_ptr + 1'b1) : p_wr_ptr;

  logic [WIDTH - 1:0] ram_data_out;
  assign o_data_out = (i_rd_en & ~o_empty) ? ram_data_out : '0;

  bin_2_gray #(.WIDTH(ADDR_WIDTH)) change_wr_ptr_gray (
  .i_bin(p_wr_ptr)    ,
  .o_gray(gray_wr_ptr)
  );

  bin_2_gray #(.WIDTH(ADDR_WIDTH)) change_rd_ptr_gray (
  .i_bin(p_rd_ptr)    ,
  .o_gray(gray_rd_ptr)
  );

  shift_reg #(
    .WIDTH(ADDR_WIDTH),
    .DEPTH(2)
  ) meta_gray_wr_ptr (
    .i_clk(i_clk_rd)               ,
    .i_rst_n(i_rst_n)              ,
    .i_data_in(gray_wr_ptr)        ,
	  .o_data_out(gray_wr_ptr_rd_clk)
  );
  
  shift_reg #(
    .WIDTH(ADDR_WIDTH),
    .DEPTH(2)
    ) meta_gray_rd_ptr (
    .i_clk(i_clk_wr)               ,
    .i_rst_n(i_rst_n)              ,
    .i_data_in(gray_rd_ptr)        ,
	  .o_data_out(gray_rd_ptr_wr_clk)
  );

  gray_2_bin #(.WIDTH(ADDR_WIDTH)) change_wr_ptr_bin (
    .i_gray(gray_wr_ptr_rd_clk),
    .o_bin(wr_ptr_rd_clk)
  );
  
  gray_2_bin #(.WIDTH(ADDR_WIDTH)) change_rd_ptr_bin (
    .i_gray(gray_rd_ptr_wr_clk),
    .o_bin(rd_ptr_wr_clk)
  );
  
  duo_port_RAM_duo_clk #(.DATA_WIDTH(WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) RAM (
    .i_clk_a    (i_clk_wr)                  ,
    .i_clk_b    (i_clk_rd)                  ,
    .i_addr_a   (p_wr_ptr[ADDR_WIDTH - 1:0]),
    .i_data_a   (i_data_in)                 ,    
    .i_addr_b   (n_rd_ptr[ADDR_WIDTH - 1:0]),
    .i_data_b   (i_data_in)                 ,
    .i_wr_a     (update_wr_ptr)             , 
    .i_wr_b     (1'b0)                      ,
    .o_data_a   ()                          ,
    .o_data_b   (ram_data_out)
  );

endmodule