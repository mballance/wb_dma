#!/bin/sh

pwd=`pwd`
export PROJECT_LOC=`dirname $pwd`

vlib work

vlog -f rtl.f
if test $? -ne 0; then
	exit
fi

vlog -sv -suppress 2283 -f sim.f
if test $? -ne 0; then
	exit
fi

vopt +cover=sbcef+/wb_dma_tb_top/u0. -o wb_dma_tb_top_opt wb_dma_tb_top
# vopt +cover -o wb_dma_tb_top_opt wb_dma_tb_top

