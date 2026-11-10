//----------------------------------------------------------------------
// Class: axi_lite_agent
// Description: UVM agent packaging driver, monitor, and sequencer.
//              Supports active (drives stimulus) and passive (monitor
//              only) modes.
//----------------------------------------------------------------------

class axi_lite_agent extends uvm_agent;

  `uvm_component_utils(axi_lite_agent)

  axi_lite_driver     drv;
  axi_lite_monitor    mon;
  uvm_sequencer #(axi_lite_seq_item) seqr;

  function new(string name = "axi_lite_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Monitor always created
    mon = axi_lite_monitor::type_id::create("mon", this);

    // Driver and sequencer only in active mode
    if (get_is_active() == UVM_ACTIVE) begin
      drv  = axi_lite_driver::type_id::create("drv", this);
      seqr = uvm_sequencer#(axi_lite_seq_item)::type_id::create("seqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass
