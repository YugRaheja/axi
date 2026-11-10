//----------------------------------------------------------------------
// Module: axi_lite_slave
// Description: AXI4-Lite Slave interface with RAM backend.
//              Supports single-beat read/write transactions with
//              protocol-compliant handshaking on all 5 AXI channels.
//
// Parameters:
//   DATA_WIDTH - Width of data bus (default 32)
//   ADDR_WIDTH - Width of address bus (default 4)
//   DEPTH      - Depth of backend RAM (default 16)
//
// Notes:
//   - Write and read channels operate with independent FSMs
//   - BRESP/RRESP always returns OKAY for valid address range
//   - No burst support (AXI-Lite is single-beat only)
//----------------------------------------------------------------------

module axi_lite_slave #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 4,
  parameter DEPTH      = 16
)(
  input  logic                    aclk,
  input  logic                    aresetn,

  // ---- Write Address Channel ----
  input  logic [ADDR_WIDTH-1:0]   s_axi_awaddr,
  input  logic                    s_axi_awvalid,
  output logic                    s_axi_awready,

  // ---- Write Data Channel ----
  input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
  input  logic                    s_axi_wvalid,
  output logic                    s_axi_wready,

  // ---- Write Response Channel ----
  output logic [1:0]              s_axi_bresp,
  output logic                    s_axi_bvalid,
  input  logic                    s_axi_bready,

  // ---- Read Address Channel ----
  input  logic [ADDR_WIDTH-1:0]   s_axi_araddr,
  input  logic                    s_axi_arvalid,
  output logic                    s_axi_arready,

  // ---- Read Data Channel ----
  output logic [DATA_WIDTH-1:0]   s_axi_rdata,
  output logic [1:0]              s_axi_rresp,
  output logic                    s_axi_rvalid,
  input  logic                    s_axi_rready
);

  // ----- Response Codes -----
  localparam logic [1:0] RESP_OKAY    = 2'b00;
  localparam logic [1:0] RESP_SLV_ERR = 2'b10;

  // ----- FSM States -----
  typedef enum logic [1:0] {
    S_IDLE  = 2'b00,
    S_WRITE = 2'b01,
    S_READ  = 2'b10,
    S_RESP  = 2'b11
  } state_t;

  state_t write_state, read_state;

  // ----- Internal Registers -----
  logic [ADDR_WIDTH-1:0] write_addr_reg;
  logic [ADDR_WIDTH-1:0] read_addr_reg;

  // ----- RAM Interface Signals -----
  logic                    ram_wr_en;
  logic [ADDR_WIDTH-1:0]   ram_addr;
  logic [DATA_WIDTH-1:0]   ram_wdata;
  logic [DATA_WIDTH-1:0]   ram_rdata;

  // ----- RAM Instantiation -----
  ram_design #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
  ) u_ram (
    .clk    (aclk),
    .rst_n  (aresetn),
    .wr_enb (ram_wr_en),
    .addr   (ram_addr),
    .wdata  (ram_wdata),
    .rdata  (ram_rdata)
  );

  //=====================================================================
  //  WRITE PATH FSM
  //=====================================================================

  // Write Address + Data + Response handling
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      write_state    <= S_IDLE;
      s_axi_awready  <= 1'b0;
      s_axi_wready   <= 1'b0;
      s_axi_bvalid   <= 1'b0;
      s_axi_bresp    <= RESP_OKAY;
      write_addr_reg <= '0;
      ram_wr_en      <= 1'b0;
      ram_wdata      <= '0;
    end
    else begin
      case (write_state)

        S_IDLE: begin
          // Ready to accept write address
          s_axi_awready <= 1'b1;
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b0;
          ram_wr_en     <= 1'b0;

          // Address handshake complete
          if (s_axi_awvalid && s_axi_awready) begin
            write_addr_reg <= s_axi_awaddr;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b1;  // ready for data next
            write_state    <= S_WRITE;
          end
        end

        S_WRITE: begin
          // Data handshake complete - write to RAM
          if (s_axi_wvalid && s_axi_wready) begin
            ram_wr_en    <= 1'b1;
            ram_wdata    <= s_axi_wdata;
            ram_addr     <= write_addr_reg;
            s_axi_wready <= 1'b0;
            write_state  <= S_RESP;
          end
        end

        S_RESP: begin
          // Deassert write enable after one cycle
          ram_wr_en    <= 1'b0;
          // Present response
          s_axi_bvalid <= 1'b1;
          s_axi_bresp  <= RESP_OKAY;

          // Response handshake complete
          if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            write_state  <= S_IDLE;
          end
        end

        default: begin
          write_state <= S_IDLE;
        end

      endcase
    end
  end

  //=====================================================================
  //  READ PATH FSM
  //=====================================================================

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      read_state    <= S_IDLE;
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rdata   <= '0;
      s_axi_rresp   <= RESP_OKAY;
      read_addr_reg <= '0;
    end
    else begin
      case (read_state)

        S_IDLE: begin
          // Ready to accept read address
          s_axi_arready <= 1'b1;
          s_axi_rvalid  <= 1'b0;

          // Address handshake complete
          if (s_axi_arvalid && s_axi_arready) begin
            read_addr_reg <= s_axi_araddr;
            s_axi_arready <= 1'b0;
            // Point RAM to read address
            ram_addr      <= s_axi_araddr;
            read_state    <= S_READ;
          end
        end

        S_READ: begin
          // Wait one cycle for RAM read latency
          // RAM output (ram_rdata) will be valid next cycle
          read_state <= S_RESP;
        end

        S_RESP: begin
          // Present read data
          s_axi_rvalid <= 1'b1;
          s_axi_rdata  <= ram_rdata;
          s_axi_rresp  <= RESP_OKAY;

          // Data handshake complete
          if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            read_state   <= S_IDLE;
          end
        end

        default: begin
          read_state <= S_IDLE;
        end

      endcase
    end
  end

endmodule
