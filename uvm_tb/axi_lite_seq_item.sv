//----------------------------------------------------------------------
// UVM Components: axi_lite_seq_item
//----------------------------------------------------------------------

class axi_lite_seq_item extends uvm_sequence_item;

  // Transaction type
  typedef enum bit {AXI_WRITE = 0, AXI_READ = 1} txn_type_t;

  // Randomizable fields
  rand txn_type_t                txn_type;
  rand bit [3:0]                 addr;      // 4-bit address
  rand bit [31:0]                data;      // 32-bit data

  // Response fields (filled by driver/monitor after transaction)
  bit [31:0]                     rdata;     // Read data returned
  bit [1:0]                      resp;      // Response code (OKAY=00)

  // UVM utility macro - registers this class with the UVM factory
  `uvm_object_utils_begin(axi_lite_seq_item)
    `uvm_field_enum(txn_type_t, txn_type, UVM_ALL_ON)
    `uvm_field_int(addr,  UVM_ALL_ON)
    `uvm_field_int(data,  UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(resp,  UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "axi_lite_seq_item");
    super.new(name);
  endfunction

  // Constraint: keep address within RAM range
  constraint addr_range_c {
    addr inside {[0:15]};
  }

  // Convert transaction to readable string
  function string convert2string();
    return $sformatf("type=%s addr=0x%0h data=0x%0h rdata=0x%0h resp=%0b",
                     txn_type.name(), addr, data, rdata, resp);
  endfunction

endclass
