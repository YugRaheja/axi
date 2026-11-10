#----------------------------------------------------------------------
# Makefile for AXI-Lite Slave Simulation
# Supports: Xilinx Vivado Simulator (xvlog/xelab/xsim)
#           Icarus Verilog (iverilog)
#           Synopsys VCS
#           Cadence Xcelium
#
# Usage:
#   make directed       - Run directed testbench (simple TB)
#   make uvm TEST=<test> - Run UVM test
#   make clean           - Remove generated files
#----------------------------------------------------------------------

# Default UVM test
TEST ?= axi_lite_write_read_test

# Source files
RTL_SRCS = ../rtl/ram_design.sv ../rtl/axi_lite_slave.sv
TB_SRCS  = ../tb/axi_lite_interface.sv ../tb/tb_axi_lite_slave.sv
UVM_TOP  = ../uvm_tb/top.sv

#----------------------------------------------------------------------
# Icarus Verilog (free, open source)
#----------------------------------------------------------------------
directed_iverilog:
	iverilog -g2012 -o sim_directed $(RTL_SRCS) $(TB_SRCS)
	vvp sim_directed

#----------------------------------------------------------------------
# Xilinx Vivado Simulator
#----------------------------------------------------------------------
directed:
	xvlog -sv $(RTL_SRCS) $(TB_SRCS)
	xelab tb_axi_lite_slave -s sim_directed
	xsim sim_directed -R

uvm:
	xvlog -sv -L uvm $(RTL_SRCS) ../tb/axi_lite_interface.sv $(UVM_TOP)
	xelab top -s sim_uvm -L uvm
	xsim sim_uvm -R -testplusarg "UVM_TESTNAME=$(TEST)"

#----------------------------------------------------------------------
# Synopsys VCS
#----------------------------------------------------------------------
directed_vcs:
	vcs -sverilog -full64 $(RTL_SRCS) $(TB_SRCS) -o simv_directed
	./simv_directed

uvm_vcs:
	vcs -sverilog -full64 -ntb_opts uvm-1.2 \
	    $(RTL_SRCS) ../tb/axi_lite_interface.sv $(UVM_TOP) \
	    +UVM_TESTNAME=$(TEST) -o simv_uvm
	./simv_uvm +UVM_TESTNAME=$(TEST)

#----------------------------------------------------------------------
# Cadence Xcelium
#----------------------------------------------------------------------
directed_xcelium:
	xrun -sv $(RTL_SRCS) $(TB_SRCS)

uvm_xcelium:
	xrun -sv -uvm $(RTL_SRCS) ../tb/axi_lite_interface.sv $(UVM_TOP) \
	     +UVM_TESTNAME=$(TEST)

#----------------------------------------------------------------------
# Clean
#----------------------------------------------------------------------
clean:
	rm -rf work/ xcelium.d/ simv* csrc/ DVEfiles/ *.log *.vcd *.wlf
	rm -rf .Xil/ xsim.dir/ webtalk* xvlog* xelab* *.jou *.pb *.wdb
	rm -f sim_directed ucli.key inter.vpd

.PHONY: directed uvm clean directed_vcs uvm_vcs directed_xcelium uvm_xcelium directed_iverilog
