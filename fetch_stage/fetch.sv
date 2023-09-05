`timescale 1ns / 1ns
`default_nettype none

module fetch (clk, resetn, pcSel, pcTarget, pc);
    input  logic clk, resetn, pcSel;
    input  logic [31:0] pcTarget;
    output logic [31:0] pc;

    logic [31:0] pcNext, pcPlus4;

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

endmodule