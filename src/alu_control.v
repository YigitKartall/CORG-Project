`timescale 1ns/1ps
`include "cpu_defs.vh"

// ------------------------------------------------------------
// ALU CONTROL
// - cpu_core_pipelined içinde instantiate edilen modül.
// - Hem "opcode+funct" ile decode eder,
// - Hem de istersen "alu_op" (2-bit) bağlıysa onu da destekler.
// ------------------------------------------------------------
module alu_control (
  input  wire [3:0] opcode,
  input  wire [2:0] funct,

  // Bazı tasarımlarda main_control'den gelen ALUOp vardır.
  // Eğer cpu_core_pipelined bunu bağlıyorsa compile hatası çıkmasın diye burada var.
  input  wire [1:0] alu_op,

  output reg  [3:0] alu_ctrl,
  output reg        jr
);

  always @(*) begin
    // defaultlar
    alu_ctrl = `ALU_ADD;
    jr       = 1'b0;

    // 1) Eğer alu_op kullanılıyorsa (klasik MIPS tarzı):
    // alu_op:
    // 00 -> ADD (addi/lw/sw)
    // 01 -> SUB (beq/bne)
    // 10 -> R-type funct'tan seç
    // 11 -> PASS (default)
    case (alu_op)
      2'b00: alu_ctrl = `ALU_ADD;
      2'b01: alu_ctrl = `ALU_SUB;
      2'b10: begin
        // R-type funct decode
        case (funct)
          3'b000: alu_ctrl = `ALU_ADD;
          3'b001: alu_ctrl = `ALU_SUB;
          3'b010: alu_ctrl = `ALU_AND;
          3'b011: alu_ctrl = `ALU_OR;

          // MUL/DIV varsa kullan, yoksa PASS'e düş
          3'b100: begin
            `ifdef ALU_MUL
              alu_ctrl = `ALU_MUL;
            `else
              alu_ctrl = `ALU_PASS;
            `endif
          end
          3'b101: begin
            `ifdef ALU_DIV
              alu_ctrl = `ALU_DIV;
            `else
              alu_ctrl = `ALU_PASS;
            `endif
          end

          3'b110: begin
            // JR: ALU sonucu önemli değil, PC <- rs yapılacak
            alu_ctrl = `ALU_PASS;
            jr       = 1'b1;
          end
          default: alu_ctrl = `ALU_PASS;
        endcase
      end
      default: begin
        // alu_op bağlı değilse / X ise buraya düşebilir
        // O yüzden 2) opcode bazlı decode da yapacağız (aşağıda)
        alu_ctrl = `ALU_PASS;
      end
    endcase

    // 2) opcode bazlı decode (alu_op bağlı değilse bile çalışsın diye)
    // Not: alu_op 00/01/10 ise yukarıdaki zaten doğru seçiyor,
    // burada sadece "default/PASS" durumunda tekrar anlam kazandırıyoruz.
    if (alu_op === 2'b11 || alu_op === 2'bxx) begin
      case (opcode)
        `OP_RTYPE: begin
          case (funct)
            3'b000: alu_ctrl = `ALU_ADD;
            3'b001: alu_ctrl = `ALU_SUB;
            3'b010: alu_ctrl = `ALU_AND;
            3'b011: alu_ctrl = `ALU_OR;

            3'b100: begin
              `ifdef ALU_MUL
                alu_ctrl = `ALU_MUL;
              `else
                alu_ctrl = `ALU_PASS;
              `endif
            end
            3'b101: begin
              `ifdef ALU_DIV
                alu_ctrl = `ALU_DIV;
              `else
                alu_ctrl = `ALU_PASS;
              `endif
            end

            3'b110: begin
              alu_ctrl = `ALU_PASS;
              jr       = 1'b1;
            end
            default: alu_ctrl = `ALU_PASS;
          endcase
        end

        `OP_ADDI: alu_ctrl = `ALU_ADD;
        `OP_LW:   alu_ctrl = `ALU_ADD;
        `OP_SW:   alu_ctrl = `ALU_ADD;
        `OP_BEQ:  alu_ctrl = `ALU_SUB;
        `OP_BNE:  alu_ctrl = `ALU_SUB;

        default:  alu_ctrl = `ALU_PASS;
      endcase
    end
  end

endmodule
