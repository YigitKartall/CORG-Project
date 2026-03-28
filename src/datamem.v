`timescale 1ns/1ps
`include "cpu_defs.vh"

module datamem(
  input  wire              clk,
  input  wire [15:0]        addr,   // BYTE address
  input  wire [15:0]        wdata,
  input  wire              we,
  input  wire              re,
  output reg  [15:0]        rdata
);

  // 512B = 256 x 16-bit word
  (* ram_style = "distributed" *) reg [15:0] mem [0:255];

  integer i;
  initial begin
    for (i=0; i<256; i=i+1)
      mem[i] = 16'h0000;
  end

  wire [7:0] idx      = addr[8:1];     // word index
  wire       aligned  = (addr[0] == 1'b0);

  always @(posedge clk) begin
    // write
    if (we && aligned) begin
      mem[idx] <= wdata;
    end

    // sync read (LW)
    if (re && aligned) begin
      rdata <= mem[idx];
    end else begin
      rdata <= 16'h0000;
    end
  end

endmodule
