//----------------------------------------------------------------------
// Interface: axi_lite_if
// Description: AXI4-Lite interface bundle. Used by both the simple
//              directed testbench and the UVM verification environment
//              to connect to the DUT.
//----------------------------------------------------------------------

interface axi_lite_if #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 4
)(
  input logic aclk,
  input logic aresetn
);

  // Write Address Channel
  logic [ADDR_WIDTH-1:0] awaddr;
  logic                  awvalid;
  logic                  awready;

  // Write Data Channel
  logic [DATA_WIDTH-1:0] wdata;
  logic                  wvalid;
  logic                  wready;

  // Write Response Channel
  logic [1:0]            bresp;
  logic                  bvalid;
  logic                  bready;

  // Read Address Channel
  logic [ADDR_WIDTH-1:0] araddr;
  logic                  arvalid;
  logic                  arready;

  // Read Data Channel
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0]            rresp;
  logic                  rvalid;
  logic                  rready;

  //--------------------------------------------------------------------
  // Clocking blocks for testbench timing
  //--------------------------------------------------------------------

  clocking master_cb @(posedge aclk);
    default input #1 output #1;
    // Master drives these
    output awaddr, awvalid;
    output wdata, wvalid;
    output bready;
    output araddr, arvalid;
    output rready;
    // Master samples these
    input  awready;
    input  wready;
    input  bresp, bvalid;
    input  arready;
    input  rdata, rresp, rvalid;
  endclocking

  clocking monitor_cb @(posedge aclk);
    default input #1;
    input awaddr, awvalid, awready;
    input wdata, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arvalid, arready;
    input rdata, rresp, rvalid, rready;
  endclocking

  // Modport for master (testbench) side
  modport master (clocking master_cb, input aclk, aresetn);

  // Modport for monitor (passive observation)
  modport monitor (clocking monitor_cb, input aclk, aresetn);

  //====================================================================
  //  SVA Protocol Assertions
  //  Based on AXI4-Lite specification rules (ARM IHI 0022E)
  //  These check that the DUT follows AXI protocol at the signal level.
  //====================================================================

  // Rule: Once VALID is asserted, it must stay HIGH until READY handshake
  // (AXI spec: A source is not permitted to wait for VALID before READY,
  //  but once VALID is asserted it must remain asserted until handshake)

  // Write address: awvalid must stay high until awready
  property p_awvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (awvalid && !awready) |=> awvalid;
  endproperty
  assert_awvalid_stable: assert property (p_awvalid_stable)
    else $error("PROTOCOL VIOLATION: awvalid deasserted before awready handshake");

  // Write data: wvalid must stay high until wready
  property p_wvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (wvalid && !wready) |=> wvalid;
  endproperty
  assert_wvalid_stable: assert property (p_wvalid_stable)
    else $error("PROTOCOL VIOLATION: wvalid deasserted before wready handshake");

  // Write response: bvalid must stay high until bready
  property p_bvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (bvalid && !bready) |=> bvalid;
  endproperty
  assert_bvalid_stable: assert property (p_bvalid_stable)
    else $error("PROTOCOL VIOLATION: bvalid deasserted before bready handshake");

  // Read address: arvalid must stay high until arready
  property p_arvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (arvalid && !arready) |=> arvalid;
  endproperty
  assert_arvalid_stable: assert property (p_arvalid_stable)
    else $error("PROTOCOL VIOLATION: arvalid deasserted before arready handshake");

  // Read data: rvalid must stay high until rready
  property p_rvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (rvalid && !rready) |=> rvalid;
  endproperty
  assert_rvalid_stable: assert property (p_rvalid_stable)
    else $error("PROTOCOL VIOLATION: rvalid deasserted before rready handshake");

  // Rule: Signals must not be X/unknown during valid transactions
  property p_awaddr_not_x;
    @(posedge aclk) disable iff (!aresetn)
      awvalid |-> !$isunknown(awaddr);
  endproperty
  assert_awaddr_not_x: assert property (p_awaddr_not_x)
    else $error("PROTOCOL VIOLATION: awaddr is X while awvalid is asserted");

  property p_wdata_not_x;
    @(posedge aclk) disable iff (!aresetn)
      wvalid |-> !$isunknown(wdata);
  endproperty
  assert_wdata_not_x: assert property (p_wdata_not_x)
    else $error("PROTOCOL VIOLATION: wdata is X while wvalid is asserted");

  property p_rdata_not_x;
    @(posedge aclk) disable iff (!aresetn)
      rvalid |-> !$isunknown(rdata);
  endproperty
  assert_rdata_not_x: assert property (p_rdata_not_x)
    else $error("PROTOCOL VIOLATION: rdata is X while rvalid is asserted");

  // Rule: After reset deasserts, all valid/ready signals should be known
  property p_no_x_after_reset;
    @(posedge aclk)
      $rose(aresetn) |=> !$isunknown({awvalid, wvalid, bvalid, arvalid, rvalid});
  endproperty
  assert_no_x_after_reset: assert property (p_no_x_after_reset)
    else $error("PROTOCOL VIOLATION: Valid signals are X after reset deasserted");

endinterface
