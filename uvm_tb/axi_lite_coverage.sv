//----------------------------------------------------------------------
// Class: axi_lite_coverage
// Description: Functional coverage collector for AXI-Lite transactions.
//              Tracks which addresses, data patterns, and transaction
//              types have been exercised. Receives transactions from
//              the monitor via analysis port.
//
// Status: WIP - basic covergroups implemented, more bins to be added
//----------------------------------------------------------------------

class axi_lite_coverage extends uvm_subscriber #(axi_lite_seq_item);

  `uvm_component_utils(axi_lite_coverage)

  // Transaction being sampled
  axi_lite_seq_item txn;

  // Covergroup: transaction type and address coverage
  covergroup axi_lite_cg;

    // Cover read vs write transactions
    cp_txn_type: coverpoint txn.txn_type {
      bins write_txn = {axi_lite_seq_item::AXI_WRITE};
      bins read_txn  = {axi_lite_seq_item::AXI_READ};
    }

    // Cover all address locations accessed
    cp_addr: coverpoint txn.addr {
      bins low_addr  = {[0:3]};
      bins mid_addr  = {[4:11]};
      bins high_addr = {[12:15]};
    }

    // Cover response codes
    cp_resp: coverpoint txn.resp {
      bins okay    = {2'b00};
      bins slv_err = {2'b10};
    }

    // Cross coverage: type x address
    cx_type_addr: cross cp_txn_type, cp_addr;

  endgroup

  function new(string name = "axi_lite_coverage", uvm_component parent);
    super.new(name, parent);
    axi_lite_cg = new();
  endfunction

  // Called when monitor broadcasts a transaction
  function void write(axi_lite_seq_item t);
    txn = t;
    axi_lite_cg.sample();
    `uvm_info("COV", $sformatf("Sampled: %s", t.convert2string()), UVM_HIGH)
  endfunction

  // Report coverage at end
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV", $sformatf("Functional Coverage = %.2f%%",
              axi_lite_cg.get_coverage()), UVM_LOW)
  endfunction

endclass

