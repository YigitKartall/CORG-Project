`timescale 1ns/1ps

module top_tangnano9k(
  input  wire        clk_in,   // 27MHz
  input  wire        btn1_n,    // reset (active-low)
  input  wire        btn2_n,    // short=step, long=hb toggle (active-low)
  output wire [5:0]  led_n
);

  // ============================================================
  // Sync reset/button (metastability filter)
  // ============================================================
  reg [2:0] rst_sync;
  reg [2:0] b2_sync;

  always @(posedge clk_in) begin
    rst_sync <= {rst_sync[1:0], btn1_n};
    b2_sync  <= {b2_sync[1:0], btn2_n};
  end

  wire rst_n = rst_sync[2];

  // ============================================================
  // RESET READY: rst_n 1 olduktan sonra kısa süre bekle
  // ============================================================
  reg [7:0] rst_cnt;
  reg       rst_ready;

  always @(posedge clk_in) begin
    if (!rst_n) begin
      rst_cnt   <= 8'd0;
      rst_ready <= 1'b0;
    end else if (!rst_ready) begin
      rst_cnt <= rst_cnt + 8'd1;
      if (rst_cnt == 8'hFF)
        rst_ready <= 1'b1; // ~9.5us @27MHz
    end
  end

  // ============================================================
  // BTN2 DEBOUNCE
  // ============================================================
  localparam integer CLK_HZ      = 27_000_000;
  localparam integer DEBOUNCE_MS = 5;
  localparam integer DB_LIMIT    = (CLK_HZ/1000)*DEBOUNCE_MS;

  reg        b2_db;
  reg [31:0] db_cnt;

  always @(posedge clk_in) begin
    if (!rst_n) begin
      b2_db  <= 1'b1;
      db_cnt <= 32'd0;
    end else begin
      if (b2_sync[2] == b2_db) begin
        db_cnt <= 32'd0;
      end else begin
        if (db_cnt >= DB_LIMIT) begin
          b2_db  <= b2_sync[2];
          db_cnt <= 32'd0;
        end else begin
          db_cnt <= db_cnt + 32'd1;
        end
      end
    end
  end

  // ============================================================
  // LONG PRESS LOGIC (short=step pulse, long=hb toggle)
  // ============================================================
  localparam integer LONG_MS    = 500;
  localparam integer LONG_LIMIT = (CLK_HZ/1000)*LONG_MS;

  reg [31:0] hold_cnt;

  localparam S_IDLE     = 2'd0;
  localparam S_PRESSING = 2'd1;
  localparam S_LONG     = 2'd2;

  reg [1:0] st;

  reg step_pulse_r;
  reg hb_toggle_pulse_r;

  always @(posedge clk_in) begin
    if (!rst_n) begin
      st                <= S_IDLE;
      hold_cnt          <= 32'd0;
      step_pulse_r      <= 1'b0;
      hb_toggle_pulse_r <= 1'b0;
    end else begin
      step_pulse_r      <= 1'b0;
      hb_toggle_pulse_r <= 1'b0;

      case (st)
        S_IDLE: begin
          hold_cnt <= 32'd0;
          if (b2_db == 1'b0) begin
            st       <= S_PRESSING;
            hold_cnt <= 32'd0;
          end
        end

        S_PRESSING: begin
          if (b2_db == 1'b0) begin
            if (hold_cnt >= LONG_LIMIT) begin
              hb_toggle_pulse_r <= 1'b1;
              st                <= S_LONG;
            end else begin
              hold_cnt <= hold_cnt + 32'd1;
            end
          end else begin
            // kısa basış -> 1 clk pulse (buton bırakınca)
            step_pulse_r <= 1'b1;
            st           <= S_IDLE;
          end
        end

        S_LONG: begin
          if (b2_db == 1'b1) begin
            st <= S_IDLE;
          end
        end

        default: st <= S_IDLE;
      endcase
    end
  end

  // ============================================================
  // HB toggle
  // ============================================================
  reg hb;
  always @(posedge clk_in) begin
    if (!rst_n) hb <= 1'b0;
    else if (hb_toggle_pulse_r) hb <= ~hb;
  end

  // ============================================================
  // Blink generators
  // ============================================================
  reg [23:0] blink_div;
  always @(posedge clk_in) begin
    if (!rst_n) blink_div <= 24'd0;
    else        blink_div <= blink_div + 24'd1;
  end

  wire blink_slow = blink_div[23];
  wire blink_mid  = blink_div[22];
  wire blink_fast = blink_div[21];

  // ============================================================
  // CPU + DEBUG WIRES (KEEP)
  // ============================================================
  (* keep = "true" *) wire        dbg_we;
  (* keep = "true" *) wire [3:0]  dbg_waddr;
  (* keep = "true" *) wire [15:0] dbg_wdata;

  (* keep = "true" *) wire        halted;
  (* keep = "true" *) wire        dbg_stall;
  (* keep = "true" *) wire        dbg_flush;
  (* keep = "true" *) wire        dbg_bubble;
  (* keep = "true" *) wire [3:0]  dbg_op;

  (* keep = "true" *) wire [15:0] dbg_ifid_instr;
  (* keep = "true" *) wire [15:0] dbg_pc;

  // ============================================================
  // STEP kaybolmasın: rst_ready gelmeden step gelirse sakla
  // ============================================================
  reg pending_step;

  always @(posedge clk_in) begin
    if (!rst_n) begin
      pending_step <= 1'b0;
    end else begin
      // rst_ready gelmeden step gelirse sakla
      if (step_pulse_r && !rst_ready) begin
        pending_step <= 1'b1;
      end
      // rst_ready olduktan sonra pending'i bir kere kullanınca temizle
      else if (rst_ready && pending_step && !halted) begin
        pending_step <= 1'b0;
      end
    end
  end

  // ============================================================
  // CPU enable (STEP)  + reset-ready gate + pending support
  // ============================================================
  (* keep = "true" *) wire cpu_en;
  assign cpu_en = (~halted) &
                  ( (rst_ready & step_pulse_r) |
                    (rst_ready & pending_step) );

  // ============================================================
  // CPU instance
  // ============================================================
  cpu_core_pipelined U_CPU(
    .clk(clk_in),
    .rst_n(rst_n),
    .en(cpu_en),

    .dbg_we(dbg_we),
    .dbg_waddr(dbg_waddr),
    .dbg_wdata(dbg_wdata),

    .halted(halted),
    .dbg_bubble(dbg_bubble),
    .dbg_stall(dbg_stall),
    .dbg_flush(dbg_flush),
    .dbg_opcode_ifid(dbg_op),

    .dbg_ifid_instr(dbg_ifid_instr),
    .dbg_pc(dbg_pc)
  );

  // ============================================================
  // latch last WB data
  // ============================================================
  reg [15:0] last_wdata;
  always @(posedge clk_in) begin
    if (!rst_n) last_wdata <= 16'h0000;
    else if (cpu_en && dbg_we) last_wdata <= dbg_wdata;
  end

  // ============================================================
  // latch hazards
  // ============================================================
  reg last_stall, last_flush, last_bubble;
  always @(posedge clk_in) begin
    if (!rst_n) begin
      last_stall  <= 1'b0;
      last_flush  <= 1'b0;
      last_bubble <= 1'b0;
    end else if (cpu_en) begin
      last_stall  <= dbg_stall;
      last_flush  <= dbg_flush;
      last_bubble <= dbg_bubble;
    end
  end

  // ============================================================
  // STATUS LED
  // ============================================================
  wire status_led =
      halted      ? 1'b1 :
      last_flush  ? blink_fast :
      last_stall  ? blink_slow :
      last_bubble ? blink_mid  :
                    1'b0;

  // ============================================================
  // LED mapping (2 pages via HB)
  // hb=0 : PC bits
  // hb=1 : hazards + halt + status
  // ============================================================
  reg [5:0] led_on;

  always @(*) begin
    if (hb == 1'b0) begin
      led_on[0] = 1'b0;
      led_on[1] = dbg_pc[1];
      led_on[2] = dbg_pc[2];
      led_on[3] = dbg_pc[3];
      led_on[4] = dbg_pc[4];
      led_on[5] = dbg_pc[5];
    end else begin
      led_on[0] = 1'b1;
      led_on[1] = last_stall  ? blink_slow : 1'b0;
      led_on[2] = last_flush  ? blink_fast : 1'b0;
      led_on[3] = last_bubble ? blink_mid  : 1'b0;
      led_on[4] = halted;
      led_on[5] = status_led;
    end
  end

  // active-low LEDs
  assign led_n = ~led_on;

endmodule 