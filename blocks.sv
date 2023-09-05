`timescale 1ns / 1ns
`default_nettype none

module reg_r #(parameter WIDTH = 1) (clk, resetn, d, q);
	input  logic clk, resetn;
	input  logic [WIDTH-1:0] d;
	output logic [WIDTH-1:0] q;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            q <= 0;
        end
        else begin
            q <= d;
        end
    end
endmodule

module reg_rv #(parameter WIDTH = 1) (clk, resetn, reset_val, d, q);
	input  logic clk, resetn;
	input  logic [WIDTH-1:0] reset_val, d;
	output logic [WIDTH-1:0] q;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            q <= reset_val;
        end
        else begin
            q <= d;
        end
    end
endmodule

module reg_rc #(parameter WIDTH = 1) (clk, resetn, clear, d, q);
	input  logic clk, resetn, clear;
	input  logic [WIDTH-1:0] d;
	output logic [WIDTH-1:0] q;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            q <= 0;
        end
        else if (clear) begin
            q <= 0;
        end
        else begin
            q <= d;
        end
    end
endmodule

module reg_re #(parameter WIDTH = 1) (clk, resetn, en, d, q);
	input  logic clk, resetn, clear, en;
	input  logic [WIDTH-1:0] d;
	output logic [WIDTH-1:0] q;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            q <= 0;
        end
        else if (en) begin
            q <= d;
        end
    end
endmodule

module reg_rce #(parameter WIDTH=1) (clk, resetn, clear, en, d, q);
	input  logic clk, resetn, clear, en;
	input  logic [WIDTH-1:0] d;
	output logic [WIDTH-1:0] q;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            q <= 0;
        end
        else if (clear) begin
            q <= 0;
        end
        else if (en) begin
            q <= d;
        end
    end
endmodule

module mux2 #(parameter WIDTH=1) (in0, in1, sel, out);
	input  logic [WIDTH-1:0] in0, in1;
	input  logic sel;
	output logic [WIDTH-1:0] out;

	assign out = sel ? in1 : in0;
endmodule

module adder #(parameter WIDTH=1) (op0, op1, out);
	input  logic [WIDTH-1:0] op0, op1;
	output logic [WIDTH-1:0] out;

	assign out = op0 + op1;
endmodule