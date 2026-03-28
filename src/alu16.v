// ======================= alu16.v =======================
`timescale 1ns/1ps
`include "cpu_defs.vh"

module alu16(
  input  wire [`XLEN-1:0] a,
  input  wire [`XLEN-1:0] b,
  input  wire [3:0]       alu_ctrl,
  output reg  [`XLEN-1:0] y,
  output wire             zero
);

  always @(*) begin
    case (alu_ctrl)
      `ALU_ADD:  y = a + b;
      `ALU_SUB:  y = a - b;
      `ALU_AND:  y = a & b;
      `ALU_OR:   y = a | b;
      `ALU_MUL:  y = a * b;
      `ALU_DIV:  y = (b == 0) ? {`XLEN{1'b0}} : (a / b);
      `ALU_SLT:  y = ($signed(a) < $signed(b)) ? {{(`XLEN-1){1'b0}},1'b1} : {`XLEN{1'b0}};
      `ALU_PASS: y = b;
      default:   y = {`XLEN{1'b0}};
    endcase
  end

  assign zero = (y == {`XLEN{1'b0}});

endmodule
