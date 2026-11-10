//----------------------------------------------------------------------
// Class: axi_lite_scoreboard
// Description: Reference model + checker. Maintains shadow RAM and
//              compares DUT read responses against expected values.
//----------------------------------------------------------------------

class axi_lite_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_lite_scoreboard)

  uvm_analysis_imp #(axi_lite_seq_item, axi_lite_scoreboard) analysis_export;

  // Reference model: shadow memory
  bit [31:0] ref_mem [bit[3:0]];

  int pass_count = 0;
  int fail_count = 0;

  function new(string name = "axi_lite_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
  endfunction

  // Called when monitor broadcasts a transaction
  function void write(axi_lite_seq_item txn);
    case (txn.txn_type)

      axi_lite_seq_item::AXI_WRITE: begin
        ref_mem[txn.addr] = txn.data;
        `uvm_info("SCB", $sformatf("WRITE recorded: addr=0x%0h data=0x%0h",
                  txn.addr, txn.data), UVM_MEDIUM)
      end

      axi_lite_seq_item::AXI_READ: begin
        if (ref_mem.exists(txn.addr)) begin
          if (txn.rdata === ref_mem[txn.addr]) begin
            `uvm_info("SCB", $sformatf("READ PASS: addr=0x%0h expected=0x%0h got=0x%0h",
                      txn.addr, ref_mem[txn.addr], txn.rdata), UVM_MEDIUM)
            pass_count++;
          end else begin
            `uvm_error("SCB", $sformatf("READ FAIL: addr=0x%0h expected=0x%0h got=0x%0h",
                       txn.addr, ref_mem[txn.addr], txn.rdata))
            fail_count++;
          end
        end else begin
          `uvm_warning("SCB", $sformatf("READ from unwritten addr=0x%0h, got=0x%0h",
                       txn.addr, txn.rdata))
        end
      end

    endcase
  endfunction

  // Report final results
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", $sformatf("\n--- Scoreboard Summary ---\n  PASS: %0d\n  FAIL: %0d",
              pass_count, fail_count), UVM_LOW)
    if (fail_count > 0)
      `uvm_error("SCB", "TEST FAILED - mismatches detected")
    else
      `uvm_info("SCB", "TEST PASSED - all reads matched", UVM_LOW)
  endfunction

endclass
