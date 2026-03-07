# sim/run.do
transcript on
if {![file exists build]} { file mkdir build }

vlib build/work
vmap work build/work

vlog -sv -work work rtl/alu.sv tb/tb_alu.sv
vsim -c work.tb_alu

run -all
quit -f