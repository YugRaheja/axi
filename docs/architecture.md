# AXI-Lite Slave - Design Architecture

## AXI4-Lite Protocol Summary

AXI4-Lite is a simplified version of the full AXI4 protocol, designed for simple register-mapped peripherals. Key characteristics:

- **Single-beat transactions only** (no bursts)
- **5 independent channels**: Write Address (AW), Write Data (W), Write Response (B), Read Address (AR), Read Data (R)
- **Handshake mechanism**: Every channel uses VALID/READY handshaking — transfer occurs when both VALID and READY are HIGH on the same clock edge

## Channel Handshaking

```
        ┌───┐   ┌───┐   ┌───┐   ┌───┐
 CLK    │   │   │   │   │   │   │   │
     ───┘   └───┘   └───┘   └───┘   └───

            ┌───────────────┐
 VALID ─────┘               └────────────
                    ┌───────┐
 READY ─────────────┘       └────────────
                    ↑
               Transfer happens here
               (VALID=1 && READY=1)
```

## Write Transaction Flow

```
  Master                          Slave
    │                               │
    │──── AWADDR + AWVALID ────────→│
    │←──── AWREADY ────────────────│  (Address accepted)
    │                               │
    │──── WDATA + WVALID ─────────→│
    │←──── WREADY ────────────────│  (Data accepted, written to RAM)
    │                               │
    │←──── BRESP + BVALID ────────│  (Write OK response)
    │──── BREADY ─────────────────→│
    │                               │
```

## Read Transaction Flow

```
  Master                          Slave
    │                               │
    │──── ARADDR + ARVALID ────────→│
    │←──── ARREADY ────────────────│  (Address accepted)
    │                               │
    │         (RAM read latency)    │
    │                               │
    │←──── RDATA + RRESP + RVALID ─│  (Read data returned)
    │──── RREADY ─────────────────→│
    │                               │
```

## FSM Design

### Write FSM States

| State | Description |
|-------|-------------|
| `S_IDLE` | Assert `awready`, wait for address handshake |
| `S_WRITE` | Assert `wready`, wait for data handshake, write to RAM |
| `S_RESP` | Assert `bvalid` with `OKAY` response, wait for `bready` |

### Read FSM States

| State | Description |
|-------|-------------|
| `S_IDLE` | Assert `arready`, wait for address handshake |
| `S_READ` | RAM read latency cycle (1 clock) |
| `S_RESP` | Assert `rvalid` with read data, wait for `rready` |

## RAM Backend

- Simple single-port synchronous RAM
- Parameterizable width and depth
- Write: `wr_enb=1` → `mem[addr] <= wdata`
- Read: `wr_enb=0` → `rdata <= mem[addr]` (1-cycle latency)

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 32 | Data bus width in bits |
| `ADDR_WIDTH` | 4 | Address bus width in bits |
| `DEPTH` | 16 | Number of memory locations |
