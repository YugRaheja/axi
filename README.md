# AXI-Lite Slave Interface Design and UVM Verification

> **Status: 🚧 Ongoing (7th Semester Minor Project)**

## Overview

This project implements a **synthesizable AXI4-Lite slave interface** in SystemVerilog with a simple RAM backend, along with a **UVM-based verification environment** to validate protocol compliance and data integrity.

### Key Features
- AXI4-Lite compliant read/write handshaking on all 5 channels
- Parameterizable data width, address width, and memory depth
- Independent write and read FSMs for concurrent handling
- UVM testbench with driver, monitor, scoreboard, and functional coverage

## Project Structure

```
AXI/
├── rtl/                          # Synthesizable RTL
│   ├── axi_lite_slave.sv        # AXI-Lite slave top module with FSMs
│   └── ram_design.sv            # Single-port synchronous RAM
│
├── tb/                           # Testbench files
│   ├── axi_lite_interface.sv    # SystemVerilog interface definition
│   └── tb_axi_lite_slave.sv    # Directed testbench (non-UVM)
│
├── uvm_tb/                       # UVM Verification Environment
│   ├── axi_lite_pkg.sv         # UVM package (imports all components)
│   ├── axi_lite_seq_item.sv    # Transaction object
│   ├── axi_lite_driver.sv      # Drives AXI-Lite bus signals
│   ├── axi_lite_monitor.sv     # Passive bus observer
│   ├── axi_lite_agent.sv       # Packages driver + monitor + sequencer
│   ├── axi_lite_scoreboard.sv  # Reference model + checker
│   ├── axi_lite_coverage.sv    # Functional coverage collector
│   ├── axi_lite_sequence.sv    # Stimulus sequences
│   ├── axi_lite_env.sv         # Top-level UVM environment
│   ├── axi_lite_test.sv        # Test classes
│   └── top.sv                  # Top-level TB module for UVM
│
├── sim/                          # Simulation scripts
│   └── Makefile                 # Build & run targets
│
└── docs/                         # Documentation
    └── architecture.md          # Design architecture notes
```

## Architecture

### RTL Design

The AXI-Lite slave uses two independent FSMs:

```
Write FSM:  IDLE → WRITE → RESP → IDLE
Read FSM:   IDLE → READ  → RESP → IDLE
```

- **Write Path**: Accepts address (AW channel) → accepts data (W channel) → writes to RAM → sends OKAY response (B channel)
- **Read Path**: Accepts address (AR channel) → reads from RAM (1-cycle latency) → returns data with OKAY response (R channel)

### UVM Verification Environment

```
┌─────────────────────────────────────────────┐
│                 UVM Test                     │
│  ┌────────────────────────────────────────┐  │
│  │            Environment                 │  │
│  │  ┌──────────────────────┐              │  │
│  │  │       Agent          │  ┌─────────┐ │  │
│  │  │  ┌────────┐ ┌─────┐ │  │Scoreboard│ │  │
│  │  │  │Sequencer│ │Drvr │──→│(Ref Model)│ │  │
│  │  │  └────────┘ └─────┘ │  └─────────┘ │  │
│  │  │  ┌─────────────────┐│  ┌─────────┐ │  │
│  │  │  │    Monitor      │├─→│Coverage  │ │  │
│  │  │  └─────────────────┘│  └─────────┘ │  │
│  │  └──────────────────────┘              │  │
│  └────────────────────────────────────────┘  │
│                    ↕ (virtual interface)      │
│              ┌──────────┐                    │
│              │   DUT    │                    │
│              └──────────┘                    │
└─────────────────────────────────────────────┘
```

## How to Run

### Prerequisites
- A SystemVerilog simulator (Vivado, VCS, Xcelium, or Icarus Verilog for directed TB)
- UVM library (bundled with VCS/Xcelium/Vivado)

### Directed Testbench (Simple)
```bash
cd sim/

# Using Vivado
make directed

# Using Icarus Verilog (directed TB only, no UVM)
make directed_iverilog
```

### UVM Testbench
```bash
cd sim/

# Run write-read test (default)
make uvm

# Run specific test
make uvm TEST=axi_lite_all_addr_test
make uvm TEST=axi_lite_random_test
```

### Available UVM Tests
| Test Name | Description |
|-----------|-------------|
| `axi_lite_write_read_test` | Write-then-read verification at random addresses |
| `axi_lite_all_addr_test` | Writes to all 16 addresses, reads back all |
| `axi_lite_random_test` | Constrained-random transaction mix |

## Current Status & Roadmap

### ✅ Completed
- [x] AXI-Lite slave RTL with write and read FSMs
- [x] RAM backend module
- [x] SystemVerilog interface with clocking blocks
- [x] Directed testbench with write/read verification
- [x] UVM sequence item with constraints
- [x] UVM driver (write and read transactions)
- [x] UVM monitor (passive observation, analysis port)
- [x] UVM agent (active/passive modes)
- [x] UVM scoreboard with reference model
- [x] Basic functional coverage
- [x] Write-read and all-address sequences

### 🔄 In Progress
- [ ] Expand functional coverage (data patterns, corner cases)
- [ ] Add protocol assertion checks (SVA)
- [ ] Error injection sequences
- [ ] Write strobe (`wstrb`) support in RTL

### 📋 Planned
- [ ] AXI4-Lite protocol checker (assertion-based)
- [ ] Register abstraction layer (UVM RAL)
- [ ] Burst-to-single-beat bridge (AXI4 to AXI4-Lite)
- [ ] FPGA synthesis and resource reports
- [ ] Integration with SoC bus fabric

## References
- [AMBA AXI4-Lite Specification (ARM IHI 0022E)](https://developer.arm.com/documentation/ihi0022/latest)
- [UVM 1.2 Reference Manual](https://www.accellera.org/downloads/standards/uvm)

## License
This project is developed for academic purposes as part of a 7th semester minor project.
