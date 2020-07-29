rm -rf work
vlib work
vlog divider.v divider_tb.v
vsim divider_tb
#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}
run 10000000ns