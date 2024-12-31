module async_fifo(
  wr_clk,
  rd_clk,
  rst,
  wr,
  rd,
  wdata,
  rdata,
  valid,
  empty,
  full,
  overflow,
  underflow  
);

input wr_clk;
input rd_clk;
input rst;
input [7:0]wdata;
input wr,rd;

output reg[7:0]rdata;
output full;
output empty;
output reg valid;
output reg overflow;
output reg underflow;

parameter fifo_depth = 8;
parameter address_size = 4;

  reg [address_size-1:0]wr_pointer,wr_pointer_g_s1,wr_pointer_g_s2;
  reg [address_size-1:0]rd_pointer,rd_pointer_g_s1,rd_pointer_g_s2;
  
wire [address_size-1:0]wr_pointer_g;
wire [address_size-1:0]rd_pointer_g;

//FIFO Memory Block
reg [7:0] fifo_mem [fifo_depth-1:0];

//Writing to the FIFO
always @(posedge wr_clk)begin
  if (rst) wr_pointer <= 0;
  else begin
    if(wr && !full) begin
      wr_pointer <= wr_pointer+1;
      fifo_mem[wr_pointer] <= wdata;
    end
  end
end

//Reading from the FIFO
always @(posedge rd_clk)begin
  if (rst) rd_pointer <= 0;
  else begin
    if(rd && !empty) begin
      rd_pointer <= rd_pointer+1;
      rdata <= fifo_mem[rd_pointer];
    end
  end
end
  
//rd_pointer and wr_pointer gray conversion
  assign wr_pointer_g = wr_pointer ^ (wr_pointer >> 1'b1);
  assign rd_pointer_g = rd_pointer ^ (rd_pointer >> 1'b1);

//Synchronizer for wr_pointer wrt rd_clk
always @(posedge rd_clk)begin
  if (rst) begin
    wr_pointer_g_s1 <= 0;
    wr_pointer_g_s2 <= 0;
  end
  else begin
    wr_pointer_g_s1 <= wr_pointer_g;
    wr_pointer_g_s2 <= wr_pointer_g_s1;
  end
end

//Synchronizer for rd_pointer wrt wr_clk
always @(posedge wr_clk)begin
  if (rst) begin
    rd_pointer_g_s1 <= 0;
    rd_pointer_g_s2 <= 0;
  end
  else begin
    rd_pointer_g_s1 <= rd_pointer_g;
    rd_pointer_g_s2 <= rd_pointer_g_s1;
  end
end

//Empty and Full conditions
assign empty = (rd_pointer_g == wr_pointer_g_s2);
  assign full = (wr_pointer_g[address_size-1] != rd_pointer_g_s2[address_size-1] && wr_pointer_g[address_size-2] == rd_pointer_g_s2[address_size-2] && wr_pointer_g[address_size-3] == rd_pointer_g_s2[address_size-3]);

//Overflow and Underflow conditions

always @(posedge wr_clk)begin
  overflow = full && wr;
end

always @(posedge rd_clk)begin
  underflow = empty && rd;
  valid = (rd && !empty);
end

endmodule
