//----------------------------------------------------------------------
// Package: axi_lite_pkg
// Description: UVM package that imports all UVM components for the
//              AXI-Lite verification environment. Centralizes all
//              class includes in the correct dependency order.
//----------------------------------------------------------------------

package axi_lite_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Transaction
  `include "axi_lite_seq_item.sv"

  // Agent components
  `include "axi_lite_driver.sv"
  `include "axi_lite_monitor.sv"
  `include "axi_lite_agent.sv"

  // Analysis components
  `include "axi_lite_scoreboard.sv"
  `include "axi_lite_coverage.sv"

  // Sequences
  `include "axi_lite_sequence.sv"

  // Environment
  `include "axi_lite_env.sv"

  // Tests
  `include "axi_lite_test.sv"

endpackage
