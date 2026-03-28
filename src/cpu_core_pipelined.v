`timescale 1ns/1ps
`include "cpu_defs.vh"

module cpu_core_pipelined(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        en,

  output wire        dbg_we,
  output wire [3:0]  dbg_waddr,
  output wire [15:0] dbg_wdata,

  output wire        halted,
  output wire        dbg_bubble,
  output wire        dbg_stall,
  output wire        dbg_flush,
  output wire [3:0]  dbg_opcode_ifid,

  output wire [15:0] dbg_ifid_instr,
  output wire [15:0] dbg_pc
);

  // ============================================================
  // PC / IF  (BYTE PC: 0x0000,0x0002,0x0004,...)
  // ============================================================
  reg [15:0] pc;

  wire [15:0] if_instr;
  wire [15:0] pc_plus2_if = pc + 16'd2;   // <<< FIX: +2 bytes

  instrmem U_IMEM(
    .addr(pc),
    .instr(if_instr)
  );

  // IF/ID regs
  wire [15:0] ifid_pc_plus2;
  wire [15:0] ifid_instr;

  // decode fields (ID)
  wire [3:0]  op_id   = ifid_instr[15:12];
  wire [2:0]  rs_id   = ifid_instr[11:9];
  wire [2:0]  rt_id   = ifid_instr[8:6];
  wire [2:0]  rd_id   = ifid_instr[5:3];
  wire [2:0]  fun_id  = ifid_instr[2:0];
  wire [5:0]  imm6_id = ifid_instr[5:0];
  wire [11:0] tgt_id  = ifid_instr[11:0];

  assign dbg_opcode_ifid = op_id;
  assign dbg_ifid_instr  = ifid_instr;
  assign dbg_pc          = pc;

  wire is_halt_ifid = (ifid_instr == `INSTR_HALT);
  wire is_nop_ifid  = (ifid_instr == `INSTR_NOP);

  // sign-extend imm6
  wire [15:0] imm_id = {{10{imm6_id[5]}}, imm6_id};

  // ============================================================
  // Control (ID)
  // ============================================================
  wire       id_regwrite, id_memtoreg, id_memread, id_memwrite, id_alusrc;
  wire [3:0] id_aluctrl;
  wire       id_beq, id_bne, id_jump, id_jal, id_jr;

  main_control U_CTRL(
    .opcode(op_id),
    .funct(fun_id),
    .regwrite(id_regwrite),
    .memtoreg(id_memtoreg),
    .memread(id_memread),
    .memwrite(id_memwrite),
    .alusrc(id_alusrc),
    .alu_ctrl(id_aluctrl),
    .branch_eq(id_beq),
    .branch_ne(id_bne),
    .jump(id_jump),
    .jal(id_jal),
    .jr(id_jr)
  );

  // ============================================================
  // Register file (WB write)
  // ============================================================
  wire       wb_regwrite;
  wire [2:0] wb_rd;
  wire [15:0] wb_wdata;

  wire [15:0] rs_val_id, rt_val_id;
  regfile U_RF(
    .clk(clk),
    .rst_n(rst_n),
    .raddr1(rs_id),
    .raddr2(rt_id),
    .rdata1(rs_val_id),
    .rdata2(rt_val_id),
    .we(wb_regwrite),
    .waddr(wb_rd),
    .wdata(wb_wdata)
  );

  // ID dest select
  wire is_rtype_id = (op_id == `OP_RTYPE);
  wire [2:0] id_dest = id_jal ? 3'b111 : (is_rtype_id ? rd_id : rt_id);

  // IFID uses rs/rt (for hazard)  <<< FIX: HALT/NOP uses none
  wire ifid_uses_rs = !is_halt_ifid && !is_nop_ifid &&
                      (op_id != `OP_J) && (op_id != `OP_JAL);

  wire ifid_uses_rt = !is_halt_ifid && !is_nop_ifid &&
                      ((op_id == `OP_RTYPE) || (op_id == `OP_SW) || (op_id == `OP_BEQ) || (op_id == `OP_BNE));

  // ============================================================
  // Hazard detect (load-use)
  // ============================================================
  wire pc_write_hz, ifid_write_hz, idex_flush_hz;
  wire idex_memread;
  wire [2:0] idex_rt_for_hz;

  hazard_unit U_HZ(
    .idex_memread(idex_memread),
    .idex_rt(idex_rt_for_hz),
    .ifid_rs(rs_id),
    .ifid_rt(rt_id),
    .ifid_uses_rs(ifid_uses_rs),
    .ifid_uses_rt(ifid_uses_rt),
    .pc_write(pc_write_hz),
    .ifid_write(ifid_write_hz),
    .idex_flush(idex_flush_hz)
  );

  // ============================================================
  // ID/EX
  // ============================================================
  wire       ex_regwrite, ex_memtoreg, ex_memwrite, ex_alusrc;
  wire [3:0] ex_aluctrl;
  wire       ex_beq, ex_bne, ex_jump, ex_jr, ex_jal;
  wire [15:0] ex_rs_val, ex_rt_val, ex_imm, ex_pc_plus2;
  wire [11:0] ex_target;
  wire [2:0]  ex_rs, ex_rt, ex_rd;

  wire control_taken_ex;  // defined later
  wire ifid_flush;        // defined later

  wire idex_flush_final = idex_flush_hz | control_taken_ex;

  // HALT sticky (core-level)
  reg halted_r;
  assign halted = halted_r;

  wire run_en = en & ~halted_r;   // stop pipeline advancing after HALT

  id_ex_reg U_IDEX(
    .clk(clk),
    .rst_n(rst_n),
    .en(run_en),
    .flush(idex_flush_final),

    .regwrite_in(id_regwrite),
    .memtoreg_in(id_memtoreg),
    .memread_in(id_memread),
    .memwrite_in(id_memwrite),
    .alusrc_in(id_alusrc),
    .alu_ctrl_in(id_aluctrl),

    .branch_eq_in(id_beq),
    .branch_ne_in(id_bne),
    .jump_in(id_jump),
    .jr_in(id_jr),
    .jal_in(id_jal),

    .rs_val_in(rs_val_id),
    .rt_val_in(rt_val_id),
    .imm_in(imm_id),
    .pc_plus2_in(ifid_pc_plus2),
    .target_in(tgt_id),
    .rs_in(rs_id),
    .rt_in(rt_id),
    .rd_in(id_dest),

    .regwrite_out(ex_regwrite),
    .memtoreg_out(ex_memtoreg),
    .memread_out(idex_memread),
    .memwrite_out(ex_memwrite),
    .alusrc_out(ex_alusrc),
    .alu_ctrl_out(ex_aluctrl),

    .branch_eq_out(ex_beq),
    .branch_ne_out(ex_bne),
    .jump_out(ex_jump),
    .jr_out(ex_jr),
    .jal_out(ex_jal),

    .rs_val_out(ex_rs_val),
    .rt_val_out(ex_rt_val),
    .imm_out(ex_imm),
    .pc_plus2_out(ex_pc_plus2),
    .target_out(ex_target),
    .rs_out(ex_rs),
    .rt_out(ex_rt),
    .rd_out(ex_rd)
  );

  assign idex_rt_for_hz = ex_rt;

  // ============================================================
  // Forwarding (EX)
  // ============================================================
  wire exmem_regwrite;
  wire [2:0] exmem_rd;

  wire memwb_regwrite_i;
  wire [2:0] memwb_rd_i;

  wire [1:0] fwdA, fwdB;
  forwarding_unit U_FWD(
    .exmem_regwrite(exmem_regwrite),
    .exmem_rd(exmem_rd),
    .memwb_regwrite(memwb_regwrite_i),
    .memwb_rd(memwb_rd_i),
    .idex_rs(ex_rs),
    .idex_rt(ex_rt),
    .forward_a(fwdA),
    .forward_b(fwdB)
  );

  wire [15:0] exmem_alu_res;
  wire [15:0] memwb_alu_res;
  wire [15:0] memwb_mem_data;
  wire        memwb_memtoreg;
  wire        memwb_jal;
  wire [15:0] memwb_pc_plus2;

  wire [15:0] wb_value = memwb_jal ? memwb_pc_plus2 :
                         (memwb_memtoreg ? memwb_mem_data : memwb_alu_res);

  reg [15:0] opA_ex, opB_ex;
  always @(*) begin
    case (fwdA)
      2'b00: opA_ex = ex_rs_val;
      2'b10: opA_ex = exmem_alu_res;
      2'b01: opA_ex = wb_value;
      default: opA_ex = ex_rs_val;
    endcase
    case (fwdB)
      2'b00: opB_ex = ex_rt_val;
      2'b10: opB_ex = exmem_alu_res;
      2'b01: opB_ex = wb_value;
      default: opB_ex = ex_rt_val;
    endcase
  end

  wire [15:0] aluB_ex = ex_alusrc ? ex_imm : opB_ex;

  wire [15:0] alu_y;
  wire alu_zero;
  alu16 U_ALU(
    .a(opA_ex),
    .b(aluB_ex),
    .alu_ctrl(ex_aluctrl),
    .y(alu_y),
    .zero(alu_zero)
  );

  // branch decision in EX
  wire eq_ex = (opA_ex == opB_ex);
  wire take_branch = (ex_beq && eq_ex) || (ex_bne && !eq_ex);

  // jump target in EX (target is WORD index -> shift left 1 -> BYTE PC)
  wire [15:0] jump_abs = {3'b000, ex_target, 1'b0};

  // next PC computed in EX
  wire [15:0] pc_target_ex =
      ex_jr         ? opA_ex :
      ex_jump       ? jump_abs :
      take_branch   ? (ex_pc_plus2 + (ex_imm << 1)) :  // <<< FIX base = PC+2
                      pc_plus2_if;

  assign control_taken_ex = ex_jr | ex_jump | take_branch;

  // ============================================================
  // EX/MEM
  // ============================================================
  wire exmem_memtoreg, exmem_memread, exmem_memwrite, exmem_jal;
  wire [15:0] exmem_rt_val;
  wire [15:0] exmem_pc_plus2;

  ex_mem_reg U_EXMEM(
    .clk(clk),
    .rst_n(rst_n),
    .en(run_en),

    .regwrite_in(ex_regwrite),
    .memtoreg_in(ex_memtoreg),
    .memread_in(idex_memread),
    .memwrite_in(ex_memwrite),
    .jal_in(ex_jal),

    .alu_res_in(alu_y),
    .rt_val_in(opB_ex),
    .pc_plus2_in(ex_pc_plus2),
    .rd_in(ex_rd),

    .regwrite_out(exmem_regwrite),
    .memtoreg_out(exmem_memtoreg),
    .memread_out(exmem_memread),
    .memwrite_out(exmem_memwrite),
    .jal_out(exmem_jal),

    .alu_res_out(exmem_alu_res),
    .rt_val_out(exmem_rt_val),
    .pc_plus2_out(exmem_pc_plus2),
    .rd_out(exmem_rd)
  );

  // ============================================================
  // MEM
  // ============================================================
  wire [15:0] mem_rdata;
  datamem U_DMEM(
    .clk(clk),
    .addr(exmem_alu_res),
    .wdata(exmem_rt_val),
    .we(exmem_memwrite),
    .re(exmem_memread),
    .rdata(mem_rdata)
  );

  // ============================================================
  // MEM/WB
  // ============================================================
  mem_wb_reg U_MEMWB(
    .clk(clk),
    .rst_n(rst_n),
    .en(run_en),

    .regwrite_in(exmem_regwrite),
    .memtoreg_in(exmem_memtoreg),
    .jal_in(exmem_jal),

    .mem_data_in(mem_rdata),
    .alu_res_in(exmem_alu_res),
    .pc_plus2_in(exmem_pc_plus2),
    .rd_in(exmem_rd),

    .regwrite_out(memwb_regwrite_i),
    .memtoreg_out(memwb_memtoreg),
    .jal_out(memwb_jal),

    .mem_data_out(memwb_mem_data),
    .alu_res_out(memwb_alu_res),
    .pc_plus2_out(memwb_pc_plus2),
    .rd_out(memwb_rd_i)
  );

  // WB
  assign wb_regwrite = memwb_regwrite_i;
  assign wb_rd       = memwb_rd_i;
  assign wb_wdata    = wb_value;

  // ============================================================
  // PC + IF/ID update control
  // ============================================================
  wire pc_we_final   = run_en & (pc_write_hz | control_taken_ex);
  wire ifid_we_final = run_en & (ifid_write_hz & ~control_taken_ex);

  assign ifid_flush  = control_taken_ex;

  // PC reg
  always @(posedge clk) begin
    if (!rst_n) begin
      pc <= 16'h0000;
    end else if (pc_we_final) begin
      pc <= pc_target_ex;
    end
  end

  if_id_reg U_IFID(
    .clk(clk),
    .rst_n(rst_n),
    .en(run_en),
    .write_en(ifid_we_final),
    .flush(ifid_flush),

    .pc_plus2_in(pc_plus2_if),
    .instr_in(if_instr),

    .pc_plus2_out(ifid_pc_plus2),
    .instr_out(ifid_instr)
  );

  // ============================================================
  // HALT sticky detect (ID stage instruction)
  // - flush varsa (control redirect) HALT sayılmaz
  // ============================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      halted_r <= 1'b0;
    end else if (en) begin
      if (!halted_r && !ifid_flush && (ifid_instr == `INSTR_HALT)) begin
        halted_r <= 1'b1;
      end
    end
  end

  // ============================================================
  // Debug outputs
  // ============================================================
  assign dbg_we    = wb_regwrite;
  assign dbg_waddr = {1'b0, wb_rd};
  assign dbg_wdata = wb_wdata;

  assign dbg_stall  = ~pc_write_hz;      // load-use stall
  assign dbg_flush  = ifid_flush;        // control flush
  assign dbg_bubble = idex_flush_final;  // load-use bubble + control flush bubble
     

endmodule
