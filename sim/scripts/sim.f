/**
 * Filelist: sim.f
 */
 
+incdir+${PROJECT_LOC}/rtl
+incdir+${PROJECT_LOC}/sv/wb_agent
+incdir+${PROJECT_LOC}/env

${PROJECT_LOC}/env/wb_dma_handshake_if.sv
// ${PROJECT_LOC}/env/wb_dma_infact_env.svh
${PROJECT_LOC}/env/wb_dma_irq_if.sv

-f ${PROJECT_LOC}/sv/wb_agent/wb_agent.f
-f ${PROJECT_LOC}/sv/timer/timer.f
-f ${PROJECT_LOC}/sv/memory_mgr/memory_mgr.f
-f ${PROJECT_LOC}/sv/dma_reg/dma_reg.f
-f ${PROJECT_LOC}/sv/dma_channel_agent/dma_channel_agent.f
-f ${PROJECT_LOC}/sv/dma_config/dma_config.f

-f ${PROJECT_LOC}/stim/stim.f

${PROJECT_LOC}/sv/wb_agent/wb_if.sv
${PROJECT_LOC}/env/wb_dma_tb_pkg.sv
-f ${PROJECT_LOC}/tests/tests.f
${PROJECT_LOC}/rtl/wb_dma_top.v
${PROJECT_LOC}/env/wb_dma_tb_top.sv



