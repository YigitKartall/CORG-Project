`timescale 1ns/1ps
`include "cpu_defs.vh"

module if_id_reg(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        en,
  input  wire        write_en,
  input  wire        flush,

  input  wire [15:0] pc_plus2_in,
  input  wire [15:0] instr_in,

  output reg  [15:0] pc_plus2_out,
  output reg  [15:0] instr_out
);

  always @(posedge clk) begin
    if (!rst_n) begin
      pc_plus2_out <= 16'h0000;
      instr_out    <= `INSTR_NOP;
    end else if (en) begin
      if (flush) begin
        pc_plus2_out <= 16'h0000;
        instr_out    <= `INSTR_NOP;
      end else if (write_en) begin
        pc_plus2_out <= pc_plus2_in;
        instr_out    <= instr_in;
      end
    end
  end

endmodule
