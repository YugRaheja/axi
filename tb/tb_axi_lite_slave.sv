//----------------------------------------------------------------------
// Testbench: tb_axi_lite_slave
// Description: Simple directed testbench for axi_lite_slave module.
//              Performs basic write and read transactions to verify
//              correct handshaking and data integrity.
//
// Test Plan:
//   1. Reset the DUT
//   2. Write known data to multiple addresses
//   3. Read back and verify data matches
//   4. Test back-to-back transactions
//----------------------------------------------------------------------

`timescale 1ns/1ps

module tb_axi_lite_slave;

  // Parameters
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 4;
  localparam DEPTH      = 16;
  localparam CLK_PERIOD = 10;

  // Clock and reset
  logic aclk;
  logic aresetn;

  // Transaction counters
  int write_pass = 0;
  int write_fail = 0;
  int read_pass  = 0;
  int read_fail  = 0;

  //--------------------------------------------------------------------
  // Interface instantiation
  //--------------------------------------------------------------------
  axi_lite_if #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) axi_if (
    .aclk    (aclk),
    .aresetn (aresetn)
  );

  //--------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------
  axi_lite_slave #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DEPTH      (DEPTH)
  ) dut (
    .aclk          (aclk),
    .aresetn       (aresetn),
    // Write Address
    .s_axi_awaddr  (axi_if.awaddr),
    .s_axi_awvalid (axi_if.awvalid),
    .s_axi_awready (axi_if.awready),
    // Write Data
    .s_axi_wdata   (axi_if.wdata),
    .s_axi_wvalid  (axi_if.wvalid),
    .s_axi_wready  (axi_if.wready),
    // Write Response
    .s_axi_bresp   (axi_if.bresp),
    .s_axi_bvalid  (axi_if.bvalid),
    .s_axi_bready  (axi_if.bready),
    // Read Address
    .s_axi_araddr  (axi_if.araddr),
    .s_axi_arvalid (axi_if.arvalid),
    .s_axi_arready (axi_if.arready),
    // Read Data
    .s_axi_rdata   (axi_if.rdata),
    .s_axi_rresp   (axi_if.rresp),
    .s_axi_rvalid  (axi_if.rvalid),
    .s_axi_rready  (axi_if.rready)
  );

  //--------------------------------------------------------------------
  // Clock generation
  //--------------------------------------------------------------------
  initial aclk = 0;
  always #(CLK_PERIOD/2) aclk = ~aclk;

  //--------------------------------------------------------------------
  // Task: apply_reset
  //--------------------------------------------------------------------
  task automatic apply_reset();
    aresetn = 1'b0;
    // Initialize all master signals to 0
    axi_if.awaddr  = '0;
    axi_if.awvalid = 1'b0;
    axi_if.wdata   = '0;
    axi_if.wvalid  = 1'b0;
    axi_if.bready  = 1'b0;
    axi_if.araddr  = '0;
    axi_if.arvalid = 1'b0;
    axi_if.rready  = 1'b0;
    repeat(5) @(posedge aclk);
    aresetn = 1'b1;
    repeat(2) @(posedge aclk);
    $display("[%0t] Reset complete", $time);
  endtask

  //--------------------------------------------------------------------
  // Task: axi_write
  // Performs a complete AXI-Lite write transaction
  //--------------------------------------------------------------------
  task automatic axi_write(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
  );
    // Phase 1: Write Address handshake
    @(posedge aclk);
    axi_if.awaddr  <= addr;
    axi_if.awvalid <= 1'b1;

    // Wait for awready
    do @(posedge aclk);
    while (!axi_if.awready);

    axi_if.awvalid <= 1'b0;

    // Phase 2: Write Data handshake
    axi_if.wdata  <= data;
    axi_if.wvalid <= 1'b1;

    // Wait for wready
    do @(posedge aclk);
    while (!axi_if.wready);

    axi_if.wvalid <= 1'b0;

    // Phase 3: Write Response handshake
    axi_if.bready <= 1'b1;

    // Wait for bvalid
    do @(posedge aclk);
    while (!axi_if.bvalid);

    if (axi_if.bresp == 2'b00) begin
      $display("[%0t] WRITE OK: addr=0x%0h, data=0x%0h", $time, addr, data);
      write_pass++;
    end else begin
      $display("[%0t] WRITE ERR: addr=0x%0h, bresp=%0b", $time, addr, axi_if.bresp);
      write_fail++;
    end

    axi_if.bready <= 1'b0;
    @(posedge aclk);
  endtask

  //--------------------------------------------------------------------
  // Task: axi_read
  // Performs a complete AXI-Lite read transaction
  //--------------------------------------------------------------------
  task automatic axi_read(
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
  );
    // Phase 1: Read Address handshake
    @(posedge aclk);
    axi_if.araddr  <= addr;
    axi_if.arvalid <= 1'b1;

    // Wait for arready
    do @(posedge aclk);
    while (!axi_if.arready);

    axi_if.arvalid <= 1'b0;

    // Phase 2: Read Data handshake
    axi_if.rready <= 1'b1;

    // Wait for rvalid
    do @(posedge aclk);
    while (!axi_if.rvalid);

    data = axi_if.rdata;

    if (axi_if.rresp == 2'b00) begin
      $display("[%0t] READ OK: addr=0x%0h, data=0x%0h", $time, addr, data);
    end else begin
      $display("[%0t] READ ERR: addr=0x%0h, rresp=%0b", $time, addr, axi_if.rresp);
    end

    axi_if.rready <= 1'b0;
    @(posedge aclk);
  endtask

  //--------------------------------------------------------------------
  // Task: write_then_read_check
  // Write data, read it back, and verify match
  //--------------------------------------------------------------------
  task automatic write_then_read_check(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
  );
    logic [DATA_WIDTH-1:0] read_data;

    axi_write(addr, data);
    axi_read(addr, read_data);

    if (read_data === data) begin
      $display("[%0t] VERIFY PASS: addr=0x%0h, expected=0x%0h, got=0x%0h",
               $time, addr, data, read_data);
      read_pass++;
    end else begin
      $display("[%0t] VERIFY FAIL: addr=0x%0h, expected=0x%0h, got=0x%0h",
               $time, addr, data, read_data);
      read_fail++;
    end
  endtask

  //--------------------------------------------------------------------
  // Main test sequence
  //--------------------------------------------------------------------
  initial begin
    $display("=========================================");
    $display("  AXI-Lite Slave Directed Testbench");
    $display("=========================================");

    apply_reset();

    // Test 1: Single write + read at address 0
    $display("\n--- Test 1: Single Write/Read ---");
    write_then_read_check(4'h0, 32'hDEAD_BEEF);

    // Test 2: Write to multiple addresses
    $display("\n--- Test 2: Multiple Address Write/Read ---");
    write_then_read_check(4'h1, 32'hCAFE_BABE);
    write_then_read_check(4'h2, 32'h1234_5678);
    write_then_read_check(4'h3, 32'hA5A5_A5A5);

    // Test 3: Overwrite and verify
    $display("\n--- Test 3: Overwrite Test ---");
    axi_write(4'h0, 32'h0000_1111);
    write_then_read_check(4'h0, 32'h0000_1111);

    // Test 4: Boundary addresses
    $display("\n--- Test 4: Boundary Addresses ---");
    write_then_read_check(4'h0, 32'h0000_0001);  // First address
    write_then_read_check(4'hF, 32'hFFFF_FFFF);  // Last address

    // Test 5: Back-to-back writes then reads
    $display("\n--- Test 5: Back-to-Back Transactions ---");
    axi_write(4'h4, 32'hAAAA_AAAA);
    axi_write(4'h5, 32'hBBBB_BBBB);
    axi_write(4'h6, 32'hCCCC_CCCC);

    begin
      logic [DATA_WIDTH-1:0] rd;
      axi_read(4'h4, rd);
      if (rd === 32'hAAAA_AAAA) read_pass++; else read_fail++;
      axi_read(4'h5, rd);
      if (rd === 32'hBBBB_BBBB) read_pass++; else read_fail++;
      axi_read(4'h6, rd);
      if (rd === 32'hCCCC_CCCC) read_pass++; else read_fail++;
    end

    // Summary
    $display("\n=========================================");
    $display("           TEST SUMMARY");
    $display("=========================================");
    $display("  Writes  : %0d passed, %0d failed", write_pass, write_fail);
    $display("  Reads   : %0d passed, %0d failed", read_pass, read_fail);
    if (write_fail == 0 && read_fail == 0)
      $display("  RESULT  : ALL TESTS PASSED");
    else
      $display("  RESULT  : SOME TESTS FAILED");
    $display("=========================================\n");

    #100;
    $finish;
  end

  // Timeout watchdog
  initial begin
    #50000;
    $display("ERROR: Simulation timeout!");
    $finish;
  end

  // Optional waveform dump
  initial begin
    $dumpfile("axi_lite_slave.vcd");
    $dumpvars(0, tb_axi_lite_slave);
  end

endmodule
