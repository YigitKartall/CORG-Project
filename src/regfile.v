// ======================= regfile.v =======================
`timescale 1ns/1ps
`include "cpu_defs.vh"

module regfile(
  input  wire                  clk,
  input  wire                  rst_n,

  input  wire [`REG_ADDR_W-1:0] raddr1,
  input  wire [`REG_ADDR_W-1:0] raddr2,
  output wire [`XLEN-1:0]       rdata1,
  output wire [`XLEN-1:0]       rdata2,

  input  wire                  we,
  input  wire [`REG_ADDR_W-1:0] waddr,
  input  wire [`XLEN-1:0]       wdata
);

  reg [`XLEN-1:0] regs [0:(1<<`REG_ADDR_W)-1];
  integer i;

  always @(posedge clk) begin
    if (!rst_n) begin
      for (i=0;i<(1<<`REG_ADDR_W);i=i+1) regs[i] <= {`XLEN{1'b0}};
    end else begin
      if (we && (waddr != {`REG_ADDR_W{1'b0}})) begin
        regs[waddr] <= wdata;
      end
      regs[0] <= {`XLEN{1'b0}}; // R0 always zero
    end
  end

  assign rdata1 = (raddr1 == {`REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} : regs[raddr1];
  assign rdata2 = (raddr2 == {`REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} : regs[raddr2];

endmodule
