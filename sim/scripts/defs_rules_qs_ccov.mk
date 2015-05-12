
ifneq (1,$(RULES))

else

build:
	vlib work
	vlog -F ${SIM_DIR}/scripts/rtl.f
	vlog -F ${SIM_DIR}/scripts/sim.f
	vopt +cover +acc -o wb_dma_tb_top_dbg wb_dma_tb_top
	vopt +cover -o wb_dma_tb_top_opt wb_dma_tb_top

run:
	vmap work $(BUILD_DIR)/work
	echo "" > run.do
	if test "$(DEBUG)" = "true"; then \
		echo "log -r /*" >> run.do; \
	fi
	echo "coverage save -onexit cov.ucdb" >> run.do
	echo "run 100ms; quit -f" >> run.do
	if test "$(DEBUG)" = "true"; then \
		vsim -sv_seed $(SEED) -c -do run.do -coverage -solvefaildebug \
		  -f sim.f wb_dma_tb_top_dbg \
		  $(PLUSARGS); \
	else \
		vsim -sv_seed $(SEED) -c -do run.do -coverage \
		  -f sim.f wb_dma_tb_top_opt \
		  $(PLUSARGS); \
	fi
	

endif

