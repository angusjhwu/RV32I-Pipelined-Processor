export DISPLAY=:0
iverilog -g2012 -Wall -o proc.out *.sv
vvp proc.out
gtkwave proc_tb.gtkw