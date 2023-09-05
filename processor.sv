`timescale 1ns / 1ns
`default_nettype none

/*
=== Register Conventions ===
	32 registers each 32b
		REG		ABI		DESCRIPTION					SAVER
		x0		zero	hard-wired zero				-
		x1		ra		return address				caller
		x2		sp		stack pointer				callee
		x3		gp		global pointer				-
		x4		tp		thread pointer				-
		x5		t0		temp / alt link reg			caller
		x6-7	t1-2	temps						caller
		x8		s0/fp	saved reg / frame pointer	callee
		x9		s1		saved reg					callee
		x10-11	a0-1	func args / return values	caller
		x12-17	a2-7	func args					caller
		x18-27	s2-11	saved regs					callee
		x28-31	t3-6	temps						caller
	separate pc 32b
*/

/*
=== Instruction Formats ===
	R-Type (register)
	> 	funct7 [31:25],		rs2 [24:20],	rs1 [19:15],	funct3 [14:12],	rd [11:7],			opcode [6:0]

	I-Type (immediate)
	> 	imm[11:0] [31:20],					rs1 [19:15], 	funct3 [14:12],	rd [11:7], 			opcode [6:0]

	S-Type (store)
	> 	imm[11:5] [31:25], 	rs2 [24:20], 	rs1 [19:15], 	funct3 [14:12],	imm[4:0] [11:7],	opcode [6:0]

	B-Type (branch, variation on S)
	> 	imm[12][10:5] [31:25], rs2 [24:20], rs1 [19:15], 	funct3 [14:12],	imm[4:1][11] [11:7],opcode [6:0]

	U-Type (upper immediate)
	> 	imm[31:12] [31:12],													rd [11:7],			opcode [6:0]

	J-Type (jump, variation on U)
	> 	imm[20][10:1][11] [31:20], 			imm[19:12] [19:12],				rd [11:7],			opcode [6:0]

	Sources      : rs1, rs2
	Desination   : rd

	- Immediates always sign extended (MSB is always the sign bit)
	- In RV32I, lowest two bits (of opcode) is always 11 (can be effectively ignored, but it's illegal)
	- All zero/one bits is not legal
	- Little Endian 0x0A0B0C0D is stored in memory in order n+3, n+2, n+1, n

=== Immediates Produced ===
	I-immediate
	> 	{{25{inst[31]}}, inst[30:25], inst[24:21], inst[20]}

	S-immediate
	> 	{{25{inst[31]}}, inst[30:25], inst[11:8], inst[7]}

	B-immediate
	> 	{{24{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}

	U-immediate
	>	{inst[31], inst[30:20], inst[19:12], 12'b0}

	J-immediate
	>	{{12{inst[31]}}, inst[19:12}, inst[20], inst{30:25}, inst[24:21], 1'b0}
*/

/*
47 Total Instructions (+ assembler pseudo-instructions ch20)
(^) May reduce instruction count to 38 with these simplifications

=== Register-Immediate Instructions (11) ===
	ADDI rd, rs1, imm
		MV rd, rs1		implemented as ADDI rd, rs1, 0 in assembler
		NOP				as ADDI x0, x0, 0 (only advances pc)
	SLTI, SLITU (set less than immediate)
		SEQZ rd, rs 	implemented as SLTIU rd, rs1, 1
	ANDI, ORI, XORI
		NOT rd, rs		implemented as XORI rd, rs1, -1
	SLLI, SRLI, SRAI (shift left logical, right logical, right arithmetic)
	LUI (load upper immediate)
	AUIPC (add upper immediate to pc)

=== Register-Register Instructions (10) ===
	ADD, SUB
	SLT, SLTU (SNEZ)
	AND, OR, XOR
	SLL, SRL, SRA

=== Control Transfer Instrucitons (pc relative) (8) ===
	JAL (jump and link,  uses J type)
		J	(unconditional jump no link) has rd = x0
	JALR (jump and link register, uses I type)
	# JAL and JALR can generate a misaligned instruction fetch exception when not alined to four-byte boundary

	B (branch, uses B type)
		B{EQ, NE}, {LT, LTU, GE, GEU} and {GT, GTU, LE, LEU} by reversing operands

=== Load Store Instructions (8) ===
	Loads (I type)
		L{W, H, HU, B, BU} (word 32b, halfword 16b signed, hw unsigned, byte 8b signed, byte unsigned)
	Stores (S type)
		S{W, H, B}
	# Loads with rd = x0 must raise exception

=== Memory Model (2) ===
	FENCE (skip, too complex, not necessary for simple processor)
	FENCE.I (same as above)
	^ Might be able to implement both as just NOP (ch2)

=== Control and Status Register Instructions (6) ===
	CSR{RW, RS, RC, RWI, RSI, RCI} (read write, read and set bits, read and clear bits, + unsigned variants)
		Timer (64b): RDCYCLE{-, H}, RDTIME{-, H}, RDINSTRET{-, H} (H stands for high 32b)
		# MUST IMPLEMENT ACCORDING TO MANUAL, FOR PERF ANALYSIS AND OPTIMAZATION
	^ Might be able to cover these instructions with a single SYSTEM instruction

=== Environment Call and Breakpoints (2) ===
	ECALL
	EBREAK
	^ Might be able to cover these instructions with a single SYSTEM instruction

*/

/*
Software Optimization
- Sequential code path should be the most common path, less-frequent paths place out of line
- Software should assume backward branches are predicted taken, forward branches not taken
*/

module pipelined_proc (clk, resetn, temp_sel);
    input logic clk, resetn;
    input logic temp_sel;

	parameter
		LUI 	= 7'b0110111,
		AUIPC 	= 7'b0010111,
		JAL 	= 7'b1101111,
		JALR	= 7'b1100111,
		BEQ		= 7'b1100011,
		BNE		= 7'b1100011,
		BLT		= 7'b1100011,
		BGE		= 7'b1100011,
		BLTU	= 7'b1100011,
		BGEU	= 7'b1100011,
		LB		= 7'b0000011,
		LH		= 7'b0000011,
		LW		= 7'b0000011,
		LBU		= 7'b0000011,
		LBH		= 7'b0000011,
		SB		= 7'b0100011,
		SH		= 7'b0100011,
		SW		= 7'b0100011,
		ADDI	= 7'b0010011,
		SLTI	= 7'b0010011,
		SLTIU	= 7'b0010011,
		XORI	= 7'b0010011,
		ORI		= 7'b0010011,
		ANDI	= 7'b0010011,
		SLLI	= 7'b0010011,
		SRLI	= 7'b0010011,
		SRAI	= 7'b0010011,
		ADD		= 7'b0110011,
		SUB		= 7'b0110011,
		SLL		= 7'b0110011,
		SLT		= 7'b0110011,
		SLTU	= 7'b0110011,
		XOR		= 7'b0110011,
		SRL		= 7'b0110011,
		SRA		= 7'b0110011,
		OR		= 7'b0110011,
		AND		= 7'b0110011;
		// FENCE	= 7'b0001111,
		// FENCE.I	= 7'b0001111,
		// ECALL	= 7'b1110011,
		// EBREAK	= 7'b1110011,
		// CSRRW	= 7'b1110011,
		// CSRRS	= 7'b1110011,
		// CSRRC	= 7'b1110011,
		// CSRRWI	= 7'b1110011,
		// CSRRSI 	= 7'b1110011,
		// CSRRCI 	= 7'b1110011;

    logic [31:0] instr;

	logic [6:0] funct7, opcode;
	logic [4:0] rd, rs1, rs2;
	logic [2:0] funct3;
	assign {funct7, rs2, rs1, funct3, rd, opcode} = instr[31:0];

	logic [31:0] immI, immS, immB, immU, immJ;
	assign immI = {{25{instr[31]}}, instr[30:25], instr[24:21], instr[20]};
	assign immS = {{25{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
	assign immB = {{24{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
	assign immU = {instr[31], instr[30:20], instr[19:12], 12'b0};
	assign immJ = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};

    // Fetch
    fetch fetch_stage (.clk(clk),
                       .resetn(resetn),
                       .pcSel(temp_sel),
                       .pcTarget(32'h00000080),
                       .instr(instr));
	
	// // Decode
	// always_ff @(posedge clk) begin
		
	// end

	// // Execute
	// always_ff @(posedge clk) begin
		
	// end

	// // Memory
	// always_ff @(posedge clk) begin
		
	// end

	// // Writeback
	// always_ff @(posedge clk) begin
		
	// end

endmodule


module fetch (clk, resetn, pcSel, pcTarget, instr);
    input  logic clk, resetn, pcSel;
    input  logic [31:0] pcTarget;
    output logic [31:0] instr;

    logic [31:0] pc, pcNext, pcPlus4;

    adder #(.WIDTH(32)) pcIncr (.op0(pc),
                                .op1(32'h4),
                                .out(pcPlus4));

    mux2 #(.WIDTH(32)) pcSelect (.in0(pcPlus4),
                                 .in1(pcTarget),
                                 .sel(pcSel),
                                 .out(pcNext));

    reg_r #(.WIDTH(32)) getPC (.clk(clk),
                               .resetn(resetn),
                               .d(pcNext),
                               .q(pc));

    mem mem1MB (.addr(pc[7:0]),
                .val(instr));
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