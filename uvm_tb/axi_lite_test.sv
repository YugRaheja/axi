//----------------------------------------------------------------------
// UVM Tests for AXI-Lite Slave
// Description: Test classes that configure the environment and start
//              specific sequences to verify the DUT.
//----------------------------------------------------------------------

//======================================================================
// Base test - sets up the environment
//======================================================================
class axi_lite_base_test extends uvm_test;

  `uvm_component_utils(axi_lite_base_test)

  axi_lite_env env;

  function new(string name = "axi_lite_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_lite_env::type_id::create("env", this);
  endfunction

  // Report pass/fail at end
  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_ERROR) > 0)
      `uvm_info("TEST", "*** TEST FAILED ***", UVM_NONE)
    else
      `uvm_info("TEST", "*** TEST PASSED ***", UVM_NONE)
  endfunction

endclass

//======================================================================
// Test: Write-Read test
// Writes to several addresses and reads back to verify
//======================================================================
class axi_lite_write_read_test extends axi_lite_base_test;

  `uvm_component_utils(axi_lite_write_read_test)

  function new(string name = "axi_lite_write_read_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_write_read_seq seq;

    phase.raise_objection(this, "write_read_test running");

    // Run write-read sequence multiple times with different addresses
    repeat (5) begin
      seq = axi_lite_write_read_seq::type_id::create("seq");
      if (!seq.randomize())
        `uvm_error("TEST", "Sequence randomization failed")
      seq.start(env.agent.seqr);
    end

    #100;
    phase.drop_objection(this, "write_read_test done");
  endtask

endclass

//======================================================================
// Test: All-address sweep test
//======================================================================
class axi_lite_all_addr_test extends axi_lite_base_test;

  `uvm_component_utils(axi_lite_all_addr_test)

  function new(string name = "axi_lite_all_addr_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_all_addr_seq seq;

    phase.raise_objection(this, "all_addr_test running");

    seq = axi_lite_all_addr_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #100;
    phase.drop_objection(this, "all_addr_test done");
  endtask

endclass

//======================================================================
// Test: Random stress test
// TODO: Add more targeted tests as verification plan expands
//======================================================================
class axi_lite_random_test extends axi_lite_base_test;

  `uvm_component_utils(axi_lite_random_test)

  function new(string name = "axi_lite_random_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_random_seq seq;

    phase.raise_objection(this, "random_test running");

    seq = axi_lite_random_seq::type_id::create("seq");
    seq.randomize() with { num_txns == 30; };
    seq.start(env.agent.seqr);

    #200;
    phase.drop_objection(this, "random_test done");
  endtask

endclass

