/*
 * canvas.v
 *
 * This module provides a scrolling background canvas,
 * based on the given screen position (scan row and column),
 * and the canvas scroll position. 
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

typedef enum {
    RESET_JUST_NOW = 0,
    RESET_CLOCK_WAIT = 1,
    RESET_CLOCK_DONE = 2,
    MODE_SELECT_CMD_7 = 3,
    MODE_CMD_6 = 4,
    MODE_CMD_5 = 5,
    MODE_CMD_4 = 6,
    MODE_CMD_3 = 7,
    MODE_CMD_2 = 8,
    MODE_CMD_1 = 9,
    MODE_CMD_0 = 10,
    MODE_DESELECT = 11,
    IDLE = 12,
    READ_CMD_3_0 = 13,
    READ_ADDR_23_20 = 14,
    READ_ADDR_19_16 = 15,
    READ_ADDR_15_12 = 16,
    READ_ADDR_11_8 = 17,
    READ_ADDR_7_4 = 18,
    READ_ADDR_3_0 = 19,
    READ_WAIT = 20,
    READ_DATA_7_4 = 21,
    READ_DATA_3_0 = 22,
    READ_DESELECT = 23,
    WRITE_CMD_3_0 = 24,
    WRITE_ADDR_23_20 = 25,
    WRITE_ADDR_19_16 = 26,
    WRITE_ADDR_15_12 = 27,
    WRITE_ADDR_11_8 = 28,
    WRITE_ADDR_7_4 = 29,
    WRITE_ADDR_3_0 = 30,
    WRITE_DATA_7_4 = 31,
    WRITE_DATA_3_0 = 32,
    WRITE_DESELECT = 33
} MachineState;


module psram (
	input   wire i_rst,
	input   wire i_clk,
    input   reg i_stb,
	input   reg i_we,
	input   reg [23:0] i_addr,
	input   reg [15:0] i_din,
    output  reg o_busy,
    output  reg o_done,
	output  reg [15:0] o_dout,
    output  reg [5:0] o_state,
	output  reg o_psram_csn,
	output  wire o_psram_sclk,
	inout   wire [7:0] io_psram_dinout,
    output  reg [34:0] states_hit
);

// The main clock (i_clk) here is 100 MHz, which ticks every
// 10 nS. In order to wait 150 uS upon reset, we must count
// at least 15000 ticks. So, we wait 20000, to be safe.
reg [14:0] long_delay;

reg [3:0] short_delay;
reg hold_clk_lo;
reg out_enable;
reg [7:0] dinout;

assign o_psram_sclk = (hold_clk_lo ? 0 : i_clk);
assign io_psram_dinout = (out_enable ? dinout : 8'bZZZZZZZZ);

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        // Reset the SPI machine
        long_delay <= 0;
        o_state <= RESET_JUST_NOW;
        o_busy <= 1;
        o_done <= 0;
        o_psram_csn <= 1; // deselect
        o_dout <= 0;
        hold_clk_lo <= 1;
        dinout <= 8'd0;
        states_hit <= 0;
        out_enable <= 1;
    end else begin
        states_hit[o_state] <= 1;
        case (o_state)
            // Startup long_delay
            RESET_JUST_NOW: begin
                    if (long_delay == 19999)
                        o_state <= RESET_CLOCK_WAIT;
                    else
                        long_delay <= long_delay + 1;
                end

            // Post-reset clock wait start
            RESET_CLOCK_WAIT: begin
                    hold_clk_lo <= 0;
                    o_state <= RESET_CLOCK_DONE;
                end
            
            // Post-reset clock wait end
            RESET_CLOCK_DONE: begin
                    o_busy <= 0;
                    out_enable <= 0;
                    o_state <= MODE_SELECT_CMD_7;
                end

            // Entering QPI mode is done by command 35H
            // The command bits are sent 1-at-a-time, on both PSRAM chips
            MODE_SELECT_CMD_7: begin
                    o_psram_csn <= 0; // select
                    out_enable <= 1;
                    dinout <= 8'bZZZ0ZZZ0;
                    o_state <= MODE_CMD_6;
                end

            MODE_CMD_6: begin
                    dinout <= 8'bZZZ0ZZZ0;
                    o_state <= MODE_CMD_5;
                end

            MODE_CMD_5: begin
                    dinout <= 8'bZZZ1ZZZ1;
                    o_state <= MODE_CMD_4;
                end

            MODE_CMD_4: begin
                    dinout <= 8'bZZZ1ZZZ1;
                    o_state <= MODE_CMD_3;
                end

            MODE_CMD_3: begin
                    dinout <= 8'bZZZ0ZZZ0;
                    o_state <= MODE_CMD_2;
                end

            MODE_CMD_2: begin
                    dinout <= 8'bZZZ1ZZZ1;
                    o_state <= MODE_CMD_1;
                end

            MODE_CMD_1: begin
                    dinout <= 8'bZZZ0ZZZ0;
                    o_state <= MODE_CMD_0;
                end

            MODE_CMD_0: begin
                    dinout <= 8'bZZZ1ZZZ1;
                    o_psram_csn <= 1; // deselect
                    o_state <= MODE_DESELECT;
                    out_enable <= 0;
                end

            MODE_DESELECT: begin
                    o_busy <= 0;
                    o_done <= 1;
                    o_state <= IDLE;
                end

            // Idle, awaiting command
            IDLE: begin
                    if (i_stb) begin
                        if (i_we) begin
                            // A write to PSRAM is done by command 38H
                            // The command bits are sent 4-at-a-time, on both PSRAM chips
                            dinout[3:0] <= 4'h3;
                            dinout[7:4] <= 4'h3;
                            o_state <= WRITE_CMD_3_0;
                        end else begin
                            // A read from PSRAM is done by command EBH
                            // The command bits are sent 4-at-a-time, on both PSRAM chips
                            dinout[3:0] <= 4'hE;
                            dinout[7:4] <= 4'hE;
                            o_state <= READ_CMD_3_0;
                        end
                        o_psram_csn <= 0; // select
                        o_busy <= 1;
                        o_done <= 0;
                        out_enable <= 1;
                    end
                end

            READ_CMD_3_0: begin
                    dinout[3:0] <= 4'hB;
                    dinout[7:4] <= 4'hB;
                    o_state <= READ_ADDR_23_20;
                end

            READ_ADDR_23_20: begin
                    dinout[3:0] <= i_addr[23:20];
                    dinout[7:4] <= i_addr[23:20];
                    o_state <= READ_ADDR_19_16;
                end

            READ_ADDR_19_16: begin
                    dinout[3:0] <= i_addr[19:16];
                    dinout[7:4] <= i_addr[19:16];
                    o_state <= READ_ADDR_15_12;
                end

            READ_ADDR_15_12: begin
                    dinout[3:0] <= i_addr[15:12];
                    dinout[7:4] <= i_addr[15:12];
                    o_state <= READ_ADDR_11_8;
                end

            READ_ADDR_11_8: begin
                    dinout[3:0] <= i_addr[11:8];
                    dinout[7:4] <= i_addr[11:8];
                    o_state <= READ_ADDR_7_4;
                end

            READ_ADDR_7_4: begin
                    dinout[3:0] <= i_addr[7:4];
                    dinout[7:4] <= i_addr[7:4];
                    o_state <= READ_ADDR_3_0;
                end

            READ_ADDR_3_0: begin
                    dinout[3:0] <= i_addr[3:0];
                    dinout[7:4] <= i_addr[3:0];
                    short_delay <= 0;
                    o_state <= READ_WAIT;
                end

            READ_WAIT: begin
                    out_enable <= 0;
                    if (short_delay == 7)
                        o_state <= READ_DATA_7_4;
                    else
                        short_delay <= short_delay + 1;
                end

            READ_DATA_7_4: begin
                    o_dout[15:12] <= io_psram_dinout[7:4];
                    o_dout[11:8] <= io_psram_dinout[3:0];
                    o_state <= READ_DATA_3_0;
                end

            READ_DATA_3_0: begin
                    o_dout[7:4] <= io_psram_dinout[7:4];
                    o_dout[3:0] <= io_psram_dinout[3:0];
                    o_psram_csn <= 1; // deselect
                    o_state <= READ_DESELECT;
                end

            READ_DESELECT: begin
                    o_busy <= 0;
                    o_done <= 1;
                    o_state <= IDLE;
                end

            WRITE_CMD_3_0: begin
                    dinout[3:0] <= 4'h8;
                    dinout[7:4] <= 4'h8;
                    o_state <= WRITE_ADDR_23_20;
                end

            WRITE_ADDR_23_20: begin
                    dinout[3:0] <= i_addr[23:20];
                    dinout[7:4] <= i_addr[23:20];
                    o_state <= WRITE_ADDR_19_16;
                end

            WRITE_ADDR_19_16: begin
                    dinout[3:0] <= i_addr[19:16];
                    dinout[7:4] <= i_addr[19:16];
                    o_state <= WRITE_ADDR_15_12;
                end

            WRITE_ADDR_15_12: begin
                    dinout[3:0] <= i_addr[15:12];
                    dinout[7:4] <= i_addr[15:12];
                    o_state <= WRITE_ADDR_11_8;
                end

            WRITE_ADDR_11_8: begin
                    dinout[3:0] <= i_addr[11:8];
                    dinout[7:4] <= i_addr[11:8];
                    o_state <= WRITE_ADDR_7_4;
                end

            WRITE_ADDR_7_4: begin
                    dinout[3:0] <= i_addr[7:4];
                    dinout[7:4] <= i_addr[7:4];
                    o_state <= WRITE_ADDR_3_0;
                end

            WRITE_ADDR_3_0: begin
                    dinout[3:0] <= i_addr[3:0];
                    dinout[7:4] <= i_addr[3:0];
                    o_state <= WRITE_DATA_7_4;
                end

            WRITE_DATA_7_4: begin
                    dinout[7:4] <= i_din[15:12];
                    dinout[3:0] <= i_din[11:8];
                    o_state <= WRITE_DATA_3_0;
                end

            WRITE_DATA_3_0: begin
                    dinout[7:4] <= i_din[7:4];
                    dinout[3:0] <= i_din[3:0];
                    o_psram_csn <= 1; // deselect
                    o_state <= WRITE_DESELECT;
                    out_enable <= 0;
                end

            WRITE_DESELECT: begin
                    o_busy <= 0;
                    o_done <= 1;
                    o_state <= IDLE;
                end
        endcase
    end
end

endmodule
