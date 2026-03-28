`timescale 1ns/1ps
`include "cpu_defs.vh"

module instrmem(
  input  wire [15:0] addr,   // BYTE PC
  output wire [15:0] instr
);

  reg [15:0] imem [0:255];

  initial begin
    $readmemh("machinecode2.hex.txt", imem);
  end

  // 0x0000->0, 0x0002->1, 0x000E->7 ...
  assign instr = imem[addr[8:1]];

endmodule
