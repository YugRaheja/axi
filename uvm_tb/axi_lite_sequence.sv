//----------------------------------------------------------------------
// Sequences for AXI-Lite verification
// Description: Contains stimulus sequences that generate AXI-Lite
//              transactions. Sequences are started on the agent's
//              sequencer during test execution.
//----------------------------------------------------------------------

//======================================================================
// Sequence: Write-then-Read to a single address
//======================================================================
class axi_lite_write_read_seq extends uvm_sequence #(axi_lite_seq_item);

  `uvm_object_utils(axi_lite_write_read_seq)

  rand bit [3:0]  target_addr;
  rand bit [31:0] write_data;

  function new(string name = "axi_lite_write_read_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_seq_item txn;

    // Write transaction
    txn = axi_lite_seq_item::type_id::create("write_txn");
    start_item(txn);
    txn.txn_type = axi_lite_seq_item::AXI_WRITE;
    txn.addr     = target_addr;
    txn.data     = write_data;
    finish_item(txn);

    // Small delay between write and read
    #20;

    // Read back from same address
    txn = axi_lite_seq_item::type_id::create("read_txn");
    start_item(txn);
    txn.txn_type = axi_lite_seq_item::AXI_READ;
    txn.addr     = target_addr;
    finish_item(txn);
  endtask

endclass

//======================================================================
// Sequence: Write to all addresses then read back all
//======================================================================
class axi_lite_all_addr_seq extends uvm_sequence #(axi_lite_seq_item);

  `uvm_object_utils(axi_lite_all_addr_seq)

  function new(string name = "axi_lite_all_addr_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_seq_item txn;

    `uvm_info("SEQ", "Starting all-address write sequence", UVM_MEDIUM)

    // Write incrementing data to all 16 addresses
    for (int i = 0; i < 16; i++) begin
      txn = axi_lite_seq_item::type_id::create($sformatf("write_%0d", i));
      start_item(txn);
      txn.txn_type = axi_lite_seq_item::AXI_WRITE;
      txn.addr     = i[3:0];
      txn.data     = (i + 1) * 32'h1111_1111;
      finish_item(txn);
    end

    `uvm_info("SEQ", "Starting all-address read-back sequence", UVM_MEDIUM)

    // Read back from all 16 addresses
    for (int i = 0; i < 16; i++) begin
      txn = axi_lite_seq_item::type_id::create($sformatf("read_%0d", i));
      start_item(txn);
      txn.txn_type = axi_lite_seq_item::AXI_READ;
      txn.addr     = i[3:0];
      finish_item(txn);
    end
  endtask

endclass

//======================================================================
// Sequence: Randomized transactions
// TODO: Add more constrained-random sequences as coverage improves
//======================================================================
class axi_lite_random_seq extends uvm_sequence #(axi_lite_seq_item);

  `uvm_object_utils(axi_lite_random_seq)

  rand int unsigned num_txns;

  constraint txn_count_c {
    num_txns inside {[10:50]};
  }

  function new(string name = "axi_lite_random_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_seq_item txn;

    `uvm_info("SEQ", $sformatf("Running %0d random transactions", num_txns), UVM_MEDIUM)

    repeat (num_txns) begin
      txn = axi_lite_seq_item::type_id::create("rand_txn");
      start_item(txn);
      if (!txn.randomize())
        `uvm_error("SEQ", "Randomization failed!")
      finish_item(txn);
    end
  endtask

endclass

