//----------------------------------------------------------------------
// Module: top
// Description: Top-level testbench module for UVM verification.
//              Instantiates the DUT, interface, generates clock/reset,
//              and kicks off UVM test execution.
//----------------------------------------------------------------------

`timescale 1ns/1ps

`include "axi_lite_pkg.sv"
`include "../tb/axi_lite_interface.sv"

module top;

  import uvm_pkg::*;
  import axi_lite_pkg::*;

  // Parameters
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 4;
  localparam DEPTH      = 16;
  localparam CLK_PERIOD = 10;

  // Clock and reset
  logic aclk;
  logic aresetn;

  //--------------------------------------------------------------------
  // Clock generation: 100 MHz (10ns period)
  //--------------------------------------------------------------------
  initial aclk = 0;
  always #(CLK_PERIOD/2) aclk = ~aclk;

  //--------------------------------------------------------------------
  // Reset generation
  //--------------------------------------------------------------------
  initial begin
    aresetn = 1'b0;
    repeat(5) @(posedge aclk);
    aresetn = 1'b1;
  end

  //--------------------------------------------------------------------
  // Interface instantiation
  //--------------------------------------------------------------------
  axi_lite_if #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) axi_if (
    .aclk    (aclk),
    .aresetn (aresetn)
  );

  //--------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------
  axi_lite_slave #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DEPTH      (DEPTH)
  ) dut (
    .aclk          (aclk),
    .aresetn       (aresetn),
    .s_axi_awaddr  (axi_if.awaddr),
    .s_axi_awvalid (axi_if.awvalid),
    .s_axi_awready (axi_if.awready),
    .s_axi_wdata   (axi_if.wdata),
    .s_axi_wvalid  (axi_if.wvalid),
    .s_axi_wready  (axi_if.wready),
    .s_axi_bresp   (axi_if.bresp),
    .s_axi_bvalid  (axi_if.bvalid),
    .s_axi_bready  (axi_if.bready),
    .s_axi_araddr  (axi_if.araddr),
    .s_axi_arvalid (axi_if.arvalid),
    .s_axi_arready (axi_if.arready),
    .s_axi_rdata   (axi_if.rdata),
    .s_axi_rresp   (axi_if.rresp),
    .s_axi_rvalid  (axi_if.rvalid),
    .s_axi_rready  (axi_if.rready)
  );

  //--------------------------------------------------------------------
  // UVM configuration and test start
  //--------------------------------------------------------------------
  initial begin
    // Pass virtual interface to all UVM components via config_db
    uvm_config_db#(virtual axi_lite_if)::set(null, "*", "vif", axi_if);

    // Start UVM test (test name passed via +UVM_TESTNAME on command line)
    run_test();
  end

  // Waveform dump (optional, simulator-dependent)
  initial begin
    $dumpfile("axi_lite_uvm.vcd");
    $dumpvars(0, top);
  end

endmodule
