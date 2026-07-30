onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/clk
add wave -noupdate /top/bif/clk
add wave -noupdate /top/bif/reset
add wave -noupdate -radix unsigned /top/bif/baud
add wave -noupdate -radix unsigned /top/bif/tx_clk
add wave -noupdate -radix unsigned /top/c_gen/clk
add wave -noupdate -radix unsigned /top/c_gen/rst
add wave -noupdate -radix unsigned /top/c_gen/baud
add wave -noupdate -radix unsigned /top/c_gen/tx_clk
add wave -noupdate -radix unsigned /top/c_gen/t_clk
add wave -noupdate -radix unsigned /top/c_gen/tx_max
add wave -noupdate -radix unsigned /top/c_gen/tx_count
add wave -noupdate -radix unsigned /uvm_pkg::uvm_oneway_hash/msb
add wave -noupdate -radix unsigned /uvm_pkg::uvm_oneway_hash/current_byte
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7831 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {7800 ns} {7854 ns}
