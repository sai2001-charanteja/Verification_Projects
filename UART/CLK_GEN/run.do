.main clear
vlib work
vdel -all
vlib work

vlog -sv +acc\
    +incdir+C:/questasim64_2021.1/verilog_src/uvm-1.2/src \
    C:/questasim64_2021.1/verilog_src/uvm-1.2/src/uvm_pkg.sv \
    clk_gen.sv top.sv
	
vsim -sv_lib C:/questasim64_2021.1/uvm-1.2/win64/uvm_dpi \
    work.top \
    +UVM_TESTNAME=test \
    +UVM_NO_RELNOTES \
    +UVM_VERBOSITY=UVM_DEBUG"

#add wave -r /*
do wave.do
run -all