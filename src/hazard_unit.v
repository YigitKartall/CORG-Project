// ======================= hazard_unit.v =======================
`timescale 1ns/1ps
`include "cpu_defs.vh"

module hazard_unit(
  input  wire                    idex_memread,
  input  wire [`REG_ADDR_W-1:0]   idex_rt,

  input  wire [`REG_ADDR_W-1:0]   ifid_rs,
  input  wire [`REG_ADDR_W-1:0]   ifid_rt,

  input  wire                    ifid_uses_rs,
  input  wire                    ifid_uses_rt,

  output reg                     pc_write,
  output reg                     ifid_write,
  output reg                     idex_flush
);

  always @(*) begin
    pc_write   = 1'b1;
    ifid_write = 1'b1;
    idex_flush = 1'b0;

    if (idex_memread) begin
      if ( (ifid_uses_rs && (idex_rt == ifid_rs) && (ifid_rs != {`REG_ADDR_W{1'b0}})) ||
           (ifid_uses_rt && (idex_rt == ifid_rt) && (ifid_rt != {`REG_ADDR_W{1'b0}})) ) begin
        pc_write   = 1'b0;
        ifid_write = 1'b0;
        idex_flush = 1'b1; // insert bubble
      end
    end
  end

endmodule
