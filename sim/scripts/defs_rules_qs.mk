
ifneq (1,$(RULES))

else

build:
	vlib work
	vlog -F ${SIM_DIR}/scripts/rtl.f
	vlog -F ${SIM_DIR}/scripts/sim.f
	vopt -o wb_dma_tb_top_opt wb_dma_tb_top

run:
	vmap work $(BUILD_DIR)/work
	vsim -sv_seed $(SEED) -c -do "run -a; quit -f" \
	  -f sim.f wb_dma_tb_top_opt \
	  $(PLUSARGS)
	

endif

