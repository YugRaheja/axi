//----------------------------------------------------------------------
// Class: axi_lite_monitor
// Description: Passive UVM monitor that observes AXI-Lite bus activity
//              and broadcasts observed transactions via analysis port.
//----------------------------------------------------------------------

class axi_lite_monitor extends uvm_monitor;

  `uvm_component_utils(axi_lite_monitor)

  virtual axi_lite_if vif;

  // Analysis port - broadcasts to scoreboard and coverage
  uvm_analysis_port #(axi_lite_seq_item) ap;

  function new(string name = "axi_lite_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get virtual interface from config_db")
  endfunction

  // Run phase: fork write and read monitors
  task run_phase(uvm_phase phase);
    @(posedge vif.aresetn);

    fork
      monitor_write_channel();
      monitor_read_channel();
    join
  endtask

  // Watch for completed write transactions
  task monitor_write_channel();
    axi_lite_seq_item txn;
    logic [3:0]  captured_addr;
    logic [31:0] captured_data;

    forever begin
      @(posedge vif.aclk);
      if (vif.awvalid && vif.awready) begin
        captured_addr = vif.awaddr;

        do @(posedge vif.aclk);
        while (!(vif.wvalid && vif.wready));
        captured_data = vif.wdata;

        do @(posedge vif.aclk);
        while (!(vif.bvalid && vif.bready));

        txn = axi_lite_seq_item::type_id::create("write_txn");
        txn.txn_type = axi_lite_seq_item::AXI_WRITE;
        txn.addr     = captured_addr;
        txn.data     = captured_data;
        txn.resp     = vif.bresp;

        `uvm_info("MON", $sformatf("Write observed: %s", txn.convert2string()), UVM_HIGH)
        ap.write(txn);
      end
    end
  endtask

  // Watch for completed read transactions
  task monitor_read_channel();
    axi_lite_seq_item txn;
    logic [3:0] captured_addr;

    forever begin
      @(posedge vif.aclk);
      if (vif.arvalid && vif.arready) begin
        captured_addr = vif.araddr;

        do @(posedge vif.aclk);
        while (!(vif.rvalid && vif.rready));

        txn = axi_lite_seq_item::type_id::create("read_txn");
        txn.txn_type = axi_lite_seq_item::AXI_READ;
        txn.addr     = captured_addr;
        txn.rdata    = vif.rdata;
        txn.resp     = vif.rresp;

        `uvm_info("MON", $sformatf("Read observed: %s", txn.convert2string()), UVM_HIGH)
        ap.write(txn);
      end
    end
  endtask

endclass
