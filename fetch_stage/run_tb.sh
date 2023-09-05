export DISPLAY=:0
iverilog -g2012 -Wall -o tb.out *.sv ../*.sv ../utils/*.sv
vvp tb.out
gtkwave tb.gtkw