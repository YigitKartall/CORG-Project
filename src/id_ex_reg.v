`timescale 1ns/1ps
`include "cpu_defs.vh"

module id_ex_reg(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        en,
  input  wire        flush,

  // control in
  input  wire        regwrite_in,
  input  wire        memtoreg_in,
  input  wire        memread_in,
  input  wire        memwrite_in,
  input  wire        alusrc_in,
  input  wire [3:0]  alu_ctrl_in,

  input  wire        branch_eq_in,
  input  wire        branch_ne_in,
  input  wire        jump_in,
  input  wire        jr_in,
  input  wire        jal_in,

  // NEW
  input  wire        halt_in,

  // data in
  input  wire [15:0] rs_val_in,
  input  wire [15:0] rt_val_in,
  input  wire [15:0] imm_in,
  input  wire [15:0] pc_plus2_in,
  input  wire [11:0] target_in,
  input  wire [2:0]  rs_in,
  input  wire [2:0]  rt_in,
  input  wire [2:0]  rd_in,

  // control out
  output reg         regwrite_out,
  output reg         memtoreg_out,
  output reg         memread_out,
  output reg         memwrite_out,
  output reg         alusrc_out,
  output reg  [3:0]  alu_ctrl_out,

  output reg         branch_eq_out,
  output reg         branch_ne_out,
  output reg         jump_out,
  output reg         jr_out,
  output reg         jal_out,

  // NEW
  output reg         halt_out,

  // data out
  output reg  [15:0] rs_val_out,
  output reg  [15:0] rt_val_out,
  output reg  [15:0] imm_out,
  output reg  [15:0] pc_plus2_out,
  output reg  [11:0] target_out,
  output reg  [2:0]  rs_out,
  output reg  [2:0]  rt_out,
  output reg  [2:0]  rd_out
);

  always @(posedge clk) begin
    if (!rst_n) begin
      regwrite_out  <= 1'b0;
      memtoreg_out  <= 1'b0;
      memread_out   <= 1'b0;
      memwrite_out  <= 1'b0;
      alusrc_out    <= 1'b0;
      alu_ctrl_out  <= 4'h0;

      branch_eq_out <= 1'b0;
      branch_ne_out <= 1'b0;
      jump_out      <= 1'b0;
      jr_out        <= 1'b0;
      jal_out       <= 1'b0;

      halt_out      <= 1'b0;

      rs_val_out    <= 16'h0;
      rt_val_out    <= 16'h0;
      imm_out       <= 16'h0;
      pc_plus2_out  <= 16'h0;
      target_out    <= 12'h0;
      rs_out        <= 3'h0;
      rt_out        <= 3'h0;
      rd_out        <= 3'h0;

    end else if (en) begin
      if (flush) begin
        regwrite_out  <= 1'b0;
        memtoreg_out  <= 1'b0;
        memread_out   <= 1'b0;
        memwrite_out  <= 1'b0;
        alusrc_out    <= 1'b0;
        alu_ctrl_out  <= 4'h0;

        branch_eq_out <= 1'b0;
        branch_ne_out <= 1'b0;
        jump_out      <= 1'b0;
        jr_out        <= 1'b0;
        jal_out       <= 1'b0;

        halt_out      <= 1'b0;

        rs_val_out    <= 16'h0;
        rt_val_out    <= 16'h0;
        imm_out       <= 16'h0;
        pc_plus2_out  <= 16'h0;
        target_out    <= 12'h0;
        rs_out        <= 3'h0;
        rt_out        <= 3'h0;
        rd_out        <= 3'h0;
      end else begin
        regwrite_out  <= regwrite_in;
        memtoreg_out  <= memtoreg_in;
        memread_out   <= memread_in;
        memwrite_out  <= memwrite_in;
        alusrc_out    <= alusrc_in;
        alu_ctrl_out  <= alu_ctrl_in;

        branch_eq_out <= branch_eq_in;
        branch_ne_out <= branch_ne_in;
        jump_out      <= jump_in;
        jr_out        <= jr_in;
        jal_out       <= jal_in;

        halt_out      <= halt_in;

        rs_val_out    <= rs_val_in;
        rt_val_out    <= rt_val_in;
        imm_out       <= imm_in;
        pc_plus2_out  <= pc_plus2_in;
        target_out    <= target_in;
        rs_out        <= rs_in;
        rt_out        <= rt_in;
        rd_out        <= rd_in;
      end
    end
  end

endmodule
