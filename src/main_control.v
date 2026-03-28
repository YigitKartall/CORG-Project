// ======================= main_control.v =======================
`timescale 1ns/1ps
`include "cpu_defs.vh"

module main_control(
  input  wire [3:0] opcode,
  input  wire [2:0] funct,

  output reg        regwrite,
  output reg        memtoreg,
  output reg        memread,
  output reg        memwrite,
  output reg        alusrc,
  output reg [3:0]  alu_ctrl,

  output reg        branch_eq,
  output reg        branch_ne,

  output reg        jump,
  output reg        jal,
  output reg        jr
);

  always @(*) begin
    // defaults
    regwrite  = 1'b0;
    memtoreg  = 1'b0;
    memread   = 1'b0;
    memwrite  = 1'b0;
    alusrc    = 1'b0;
    alu_ctrl  = `ALU_ADD;

    branch_eq = 1'b0;
    branch_ne = 1'b0;

    jump      = 1'b0;
    jal       = 1'b0;
    jr        = 1'b0;

    case (opcode)
      `OP_RTYPE: begin
        case (funct)
          `FUN_ADD: begin regwrite=1'b1; alu_ctrl=`ALU_ADD; end
          `FUN_SUB: begin regwrite=1'b1; alu_ctrl=`ALU_SUB; end
          `FUN_AND: begin regwrite=1'b1; alu_ctrl=`ALU_AND; end
          `FUN_OR : begin regwrite=1'b1; alu_ctrl=`ALU_OR;  end
          `FUN_MUL: begin regwrite=1'b1; alu_ctrl=`ALU_MUL; end
          `FUN_DIV: begin regwrite=1'b1; alu_ctrl=`ALU_DIV; end
          `FUN_JR : begin jr=1'b1; end
          `FUN_NOP: begin end
          default : begin end
        endcase
      end

      `OP_ADDI: begin
        regwrite = 1'b1;
        alusrc   = 1'b1;
        alu_ctrl = `ALU_ADD;
      end

      `OP_LW: begin
        regwrite = 1'b1;
        memtoreg = 1'b1;
        memread  = 1'b1;
        alusrc   = 1'b1;
        alu_ctrl = `ALU_ADD;
      end

      `OP_SW: begin
        memwrite = 1'b1;
        alusrc   = 1'b1;
        alu_ctrl = `ALU_ADD;
      end

      `OP_BEQ: begin
        branch_eq = 1'b1;
        alu_ctrl  = `ALU_SUB; // compare
      end

      `OP_BNE: begin
        branch_ne = 1'b1;
        alu_ctrl  = `ALU_SUB; // compare
      end

      `OP_J: begin
        jump = 1'b1;
      end

      `OP_JAL: begin
        jump     = 1'b1;
        jal      = 1'b1;
        regwrite = 1'b1; // write link
      end

      default: begin end
    endcase
  end

endmodule
