/**
 * Filelist: sim.f
 */
 
+incdir+${PROJECT_LOC}/rtl
+incdir+${PROJECT_LOC}/sv/wb_agent
+incdir+${PROJECT_LOC}/env

${PROJECT_LOC}/env/wb_dma_handshake_if.sv
// ${PROJECT_LOC}/env/wb_dma_infact_env.svh
${PROJECT_LOC}/env/wb_dma_irq_if.sv

${PROJECT_LOC}/sv/wb_agent/wb_if.sv
${PROJECT_LOC}/sv/wb_agent/wb_vip_pkg.sv
${PROJECT_LOC}/env/wb_dma_tb_pkg.sv
${PROJECT_LOC}/env/wb_dma_tb_top.sv

${PROJECT_LOC}/rtl/wb_dma_top.v
