//----------------------------------------------------------------------
// Class: axi_lite_env
// Description: Top-level UVM environment that instantiates and connects
//              the agent, scoreboard, and coverage collector.
//----------------------------------------------------------------------

class axi_lite_env extends uvm_env;

  `uvm_component_utils(axi_lite_env)

  // Components
  axi_lite_agent       agent;
  axi_lite_scoreboard  scoreboard;
  axi_lite_coverage    coverage;

  function new(string name = "axi_lite_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase: create all components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent      = axi_lite_agent::type_id::create("agent", this);
    scoreboard = axi_lite_scoreboard::type_id::create("scoreboard", this);
    coverage   = axi_lite_coverage::type_id::create("coverage", this);
  endfunction

  // Connect phase: wire monitor analysis port to scoreboard and coverage
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Monitor broadcasts to both scoreboard and coverage
    agent.mon.ap.connect(scoreboard.analysis_export);
    agent.mon.ap.connect(coverage.analysis_export);
  endfunction

endclass

