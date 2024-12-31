`timescale 1ns/1ps

module async_fifo_tb;

  // Parameters
  parameter FIFO_DEPTH = 8;
  parameter ADDR_SIZE = 4;

  // Clock and Reset
  reg wr_clk;
  reg rd_clk;
  reg rst;

  // Inputs and Outputs
  reg wr;
  reg rd;
  reg [7:0] wdata;
  wire [7:0] rdata;
  wire valid;
  wire empty;
  wire full;
  wire overflow;
  wire underflow;

  // DUT instantiation
  async_fifo #(
    .fifo_depth(FIFO_DEPTH),
    .address_size(ADDR_SIZE)
  ) fifo (
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst(rst),
    .wr(wr),
    .rd(rd),
    .wdata(wdata),
    .rdata(rdata),
    .valid(valid),
    .empty(empty),
    .full(full),
    .overflow(overflow),
    .underflow(underflow)
  );

  // Clock Generation
  always #5 wr_clk = ~wr_clk; // 100 MHz write clock
  always #7 rd_clk = ~rd_clk; // ~71.4 MHz read clock
  
  initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars;
  end

  // Stimulus
  initial begin
    // Initialize
    wr_clk = 0;
    rd_clk = 0;
    rst = 1;
    wr = 0;
    rd = 0;
    wdata = 8'b0;
    // Reset
    #20;
    rst = 0;

    // Write stimulus
    $display("Writing data to FIFO");
    repeat (FIFO_DEPTH + 2) begin
      @(posedge wr_clk);
      if (!full) begin
        wr = 1;
        wdata = wdata + 1;
      end else begin
        wr = 0;
        $display("FIFO is full. Writing halted at wdata=%d", wdata);
      end
    end
    wr = 0;

    // Read stimulus
    $display("Reading data from FIFO");
    repeat (FIFO_DEPTH + 2) begin
      @(posedge rd_clk);
      if (!empty) begin
        rd = 1;
      end else begin
        rd = 0;
        $display("FIFO is empty. Reading halted.");
      end
    end
    rd = 0;

    // Overflow and Underflow Checks
    $display("Testing overflow condition");
    @(posedge wr_clk);
    if (full) wr = 1;
    else wr = 0;
    
    $display("Testing underflow condition");
    @(posedge rd_clk);
    if (empty) rd = 1;
    else rd = 0;

    // End of simulation
    #100;
    $stop;
  end

endmodule
