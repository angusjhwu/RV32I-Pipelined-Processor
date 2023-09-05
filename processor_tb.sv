`timescale 1ns / 1ns
`default_nettype none

module pipelined_proc_tb ();
	logic clk, resetn;
	logic temp_sel;

	initial begin : INIT_RESET
        resetn <= 0;
        #10;
        resetn <= 1;
		#100;
		resetn <= 0;
		#10;
		resetn <= 1;
    end

    initial begin : CLOCK_GEN
        clk <= 1;
        forever #5 clk = ~clk;
    end
    
	initial begin : TEMP_STIM
        temp_sel <= 0;
        #60;
		temp_sel <= 1;
		#10;
		temp_sel <= 0;
    end

	pipelined_proc proc (clk, resetn, temp_sel);

	initial begin
		#150;
		$finish;
	end

	initial begin : VCD
        $dumpfile("proc_tb.vcd");
        $dumpvars(0, pipelined_proc_tb);
    end

endmodule