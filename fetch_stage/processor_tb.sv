`timescale 1ns / 1ns
`default_nettype none

module pipelined_proc_tb ();
	logic clk, resetn;
	logic [31:0] pc, instr;

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
    
	// Current Testbench Watch =======================
	logic temp_sel;
	logic [31:0] temp_target;

	initial begin : TB_STIMULUS
        temp_sel <= 0;
		temp_target <= 32'h00000080;
        #60;
		temp_sel <= 1;
		#10;
		temp_sel <= 0;
    end

	pipelined_proc proc (.clk(clk),
	                     .resetn(resetn),
						 .pc(pc),
						 .temp_sel(temp_sel),
						 .temp_target(temp_target));

	mem mem1MiB (.addr(pc[7:0]),
                .val(instr));

	// Debug Setup ======================================
	initial begin : TB_LENGTH
		#150;
		$finish;
	end

	initial begin : VCD
        $dumpfile("tb.vcd");
        $dumpvars(0, pipelined_proc_tb);
    end

endmodule


// 1MiB instr memory
module mem (addr, val);
    input  logic [7:0]  addr;
    output logic [31:0] val;

    logic [31:0] memArray [0:255];

    initial begin
        $readmemh("program.mem", memArray);
    end

    assign val = memArray[addr];
endmodule