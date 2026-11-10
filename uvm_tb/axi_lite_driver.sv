//----------------------------------------------------------------------
// Class: axi_lite_driver
// Description: UVM driver that converts axi_lite_seq_item transactions
//              into pin-level AXI-Lite bus activity.
//----------------------------------------------------------------------

class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);

  `uvm_component_utils(axi_lite_driver)

  // Virtual interface handle
  virtual axi_lite_if vif;

  function new(string name = "axi_lite_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase: get the virtual interface from config_db
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Could not get virtual interface from config_db")
  endfunction

  // Run phase: main driver loop
  task run_phase(uvm_phase phase);
    // Initialize all master outputs
    vif.awaddr  <= '0;
    vif.awvalid <= 1'b0;
    vif.wdata   <= '0;
    vif.wvalid  <= 1'b0;
    vif.bready  <= 1'b0;
    vif.araddr  <= '0;
    vif.arvalid <= 1'b0;
    vif.rready  <= 1'b0;

    // Wait for reset to deassert
    @(posedge vif.aresetn);
    @(posedge vif.aclk);

    forever begin
      // Get next transaction from sequencer
      seq_item_port.get_next_item(req);

      `uvm_info("DRV", $sformatf("Driving: %s", req.convert2string()), UVM_MEDIUM)

      case (req.txn_type)
        axi_lite_seq_item::AXI_WRITE: drive_write(req);
        axi_lite_seq_item::AXI_READ:  drive_read(req);
      endcase

      // Signal sequencer that we're done with this item
      seq_item_port.item_done();
    end
  endtask

  // Drive a complete write transaction (AW + W + B channels)
  task drive_write(axi_lite_seq_item item);
    @(posedge vif.aclk);
    vif.awaddr  <= item.addr;
    vif.awvalid <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.awready);
    vif.awvalid <= 1'b0;

    vif.wdata  <= item.data;
    vif.wvalid <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.wready);
    vif.wvalid <= 1'b0;

    vif.bready <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.bvalid);
    item.resp = vif.bresp;
    vif.bready <= 1'b0;

    @(posedge vif.aclk);
  endtask

  // Drive a complete read transaction (AR + R channels)
  task drive_read(axi_lite_seq_item item);
    @(posedge vif.aclk);
    vif.araddr  <= item.addr;
    vif.arvalid <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.arready);
    vif.arvalid <= 1'b0;

    vif.rready <= 1'b1;

    do @(posedge vif.aclk);
    while (!vif.rvalid);
    item.rdata = vif.rdata;
    item.resp  = vif.rresp;
    vif.rready <= 1'b0;

    @(posedge vif.aclk);
  endtask

endclass
