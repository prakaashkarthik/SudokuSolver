FLAGS= --cc --exe --build -j 0 --timing --trace # -Wall
TOP= --top-module tb_top
WAVES=sudoku.vcd

build:
	verilator $(FLAGS) sim_main.cpp values2onehot.sv sudoku.sv tb_top.sv $(TOP)

run: obj_dir/Vtb_top
	./obj_dir/Vtb_top

waves: obj_dir/Vtb_top
	gtkwave $(WAVES)

all: build run waves


