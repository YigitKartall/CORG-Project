`timescale 1ns/1ps
`include "cpu_defs.vh"

module ex_mem_reg(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        en,

  // control in
  input  wire        regwrite_in,
  input  wire        memtoreg_in,
  input  wire        memread_in,
  input  wire        memwrite_in,
  input  wire        jal_in,
  input  wire        halt_in,     // NEW

  // data in
  input  wire [15:0] alu_res_in,
  input  wire [15:0] rt_val_in,
  input  wire [15:0] pc_plus2_in,
  input  wire [2:0]  rd_in,

  // control out
  output reg         regwrite_out,
  output reg         memtoreg_out,
  output reg         memread_out,
  output reg         memwrite_out,
  output reg         jal_out,
  output reg         halt_out,    // NEW

  // data out
  output reg  [15:0] alu_res_out,
  output reg  [15:0] rt_val_out,
  output reg  [15:0] pc_plus2_out,
  output reg  [2:0]  rd_out
);

  always @(posedge clk) begin
    if (!rst_n) begin
      regwrite_out <= 1'b0;
      memtoreg_out <= 1'b0;
      memread_out  <= 1'b0;
      memwrite_out <= 1'b0;
      jal_out      <= 1'b0;
      halt_out     <= 1'b0;

      alu_res_out  <= 16'h0;
      rt_val_out   <= 16'h0;
      pc_plus2_out <= 16'h0;
      rd_out       <= 3'h0;
    end else if (en) begin
      regwrite_out <= regwrite_in;
      memtoreg_out <= memtoreg_in;
      memread_out  <= memread_in;
      memwrite_out <= memwrite_in;
      jal_out      <= jal_in;
      halt_out     <= halt_in;

      alu_res_out  <= alu_res_in;
      rt_val_out   <= rt_val_in;
      pc_plus2_out <= pc_plus2_in;
      rd_out       <= rd_in;
    end
  end

endmodule
