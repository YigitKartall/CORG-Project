// ======================= forwarding_unit.v =======================
`timescale 1ns/1ps
`include "cpu_defs.vh"

module forwarding_unit(
  input  wire                    exmem_regwrite,
  input  wire [`REG_ADDR_W-1:0]   exmem_rd,

  input  wire                    memwb_regwrite,
  input  wire [`REG_ADDR_W-1:0]   memwb_rd,

  input  wire [`REG_ADDR_W-1:0]   idex_rs,
  input  wire [`REG_ADDR_W-1:0]   idex_rt,

  output reg  [1:0]              forward_a,
  output reg  [1:0]              forward_b
);

  always @(*) begin
    forward_a = 2'b00;
    forward_b = 2'b00;

    // EX hazard
    if (exmem_regwrite && (exmem_rd != {`REG_ADDR_W{1'b0}}) && (exmem_rd == idex_rs))
      forward_a = 2'b10;
    if (exmem_regwrite && (exmem_rd != {`REG_ADDR_W{1'b0}}) && (exmem_rd == idex_rt))
      forward_b = 2'b10;

    // MEM hazard
    if (memwb_regwrite && (memwb_rd != {`REG_ADDR_W{1'b0}}) &&
        !(exmem_regwrite && (exmem_rd != {`REG_ADDR_W{1'b0}}) && (exmem_rd == idex_rs)) &&
        (memwb_rd == idex_rs))
      forward_a = 2'b01;

    if (memwb_regwrite && (memwb_rd != {`REG_ADDR_W{1'b0}}) &&
        !(exmem_regwrite && (exmem_rd != {`REG_ADDR_W{1'b0}}) && (exmem_rd == idex_rt)) &&
        (memwb_rd == idex_rt))
      forward_b = 2'b01;
  end

endmodule
