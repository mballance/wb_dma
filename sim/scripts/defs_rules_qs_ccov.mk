
ifneq (1,$(RULES))

else

build:
	vlib work
	vlog -F ${SIM_DIR}/scripts/rtl.f
	vlog -F ${SIM_DIR}/scripts/sim.f
	vopt +cover=sbcef+/wb_dma_tb_top/u0. -o wb_dma_tb_top_opt wb_dma_tb_top

run:
	

endif

