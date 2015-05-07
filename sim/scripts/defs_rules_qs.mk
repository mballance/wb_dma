
ifneq (1,$(RULES))

else

build:
	vlib work
	vlog -F ${SIM_DIR}/scripts/rtl.f
	vlog -F ${SIM_DIR}/scripts/sim.f
	vopt +acc -o wb_dma_tb_top_dbg wb_dma_tb_top
	vopt -o wb_dma_tb_top_opt wb_dma_tb_top

run:
	vmap work $(BUILD_DIR)/work
	echo "" > run.do
	if test "$(DEBUG)" = "true"; then \
		echo "log -r /*" >> run.do; \
	fi
	echo "coverage save -onexit cov.ucdb" >> run.do
	echo "run -a; quit -f" >> run.do
	if test "$(DEBUG)" = "true"; then \
		vsim -sv_seed $(SEED) -c -do run.do \
		  -f sim.f wb_dma_tb_top_dbg \
		  $(PLUSARGS); \
	else \
		vsim -sv_seed $(SEED) -c -do run.do \
		  -f sim.f wb_dma_tb_top_opt \
		  $(PLUSARGS); \
	fi
	

endif

