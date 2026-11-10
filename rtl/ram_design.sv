//----------------------------------------------------------------------
// Module: ram_design
// Description: Simple synchronous single-port RAM for AXI-Lite slave
//              backend storage. Supports parameterizable width and depth.
//----------------------------------------------------------------------

module ram_design #(
  parameter ADDR_WIDTH = 4,
  parameter DATA_WIDTH = 32,
  parameter DEPTH      = 16
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    wr_enb,
  input  logic [ADDR_WIDTH-1:0]   addr,
  input  logic [DATA_WIDTH-1:0]   wdata,
  output logic [DATA_WIDTH-1:0]   rdata
);

  // Memory array
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rdata <= '0;
    end
    else begin
      if (wr_enb) begin
        mem[addr] <= wdata;
      end
      else begin
        rdata <= mem[addr];
      end
    end
  end

endmodule
