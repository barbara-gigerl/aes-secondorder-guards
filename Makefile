all:
	${VERILATOR_HOME_DIR}/bin/verilator --trace-max-width 10000 --trace-max-array 10000 --Mdir build/obj_dir --trace --top top --cc rtl/*.sv
	cd build/obj_dir;make -f Vtop.mk; cd ..
	g++ -g -I. -Ibuild/obj_dir -I${VERILATOR_HOME_DIR}/include -I${VERILATOR_HOME_DIR}/include/vltstd tb/tb_aes.cpp tb/aes.c build/obj_dir/Vtop__ALL.a ${VERILATOR_HOME_DIR}/include/verilated.cpp ${VERILATOR_HOME_DIR}/include/verilated_vcd_c.cpp ${VERILATOR_HOME_DIR}/include/verilated_threads.cpp ${VERILATOR_HOME_DIR}/include/verilated_dpi.cpp  -o build/top

clean:
	rm -rf build/*
