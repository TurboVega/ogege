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

module psram (
	input   wire i_rst,
	input   wire i_clk,
    input   reg i_stb,
	input   reg i_we,
	input   reg [23:0] i_addr,
	input   reg [7:0] i_din,
    output  reg o_busy,
    output  reg o_done,
	output  reg [7:0] o_dout,
	output  reg o_psram_csn,
	output  reg o_psram_sclk,
	inout   reg [7:0] io_psram_dinout
);

enum {
    RESET_JUST_NOW,
    RESET_CLOCK_HIGH,
    RESET_CLOCK_LOW,
    MODE_SELECT_CMD_7,
    MODE_CMD_6,
    MODE_CMD_5,
    MODE_CMD_4,
    MODE_CMD_3,
    MODE_CMD_2,
    MODE_CMD_1,
    MODE_CMD_0,
    MODE_DESELECT,
    IDLE,
    READ_CMD_3_0,
    READ_ADDR_23_20,
    READ_ADDR_19_16,
    READ_ADDR_15_12,
    READ_ADDR_11_8,
    READ_ADDR_7_4,
    READ_ADDR_3_0,
    READ_WAIT,
    READ_DATA_7_4,
    READ_DATA_3_0,
    READ_DESELECT,
    WRITE_CMD_3_0,
    WRITE_ADDR_23_20,
    WRITE_ADDR_19_16,
    WRITE_ADDR_15_12,
    WRITE_ADDR_11_8,
    WRITE_ADDR_7_4,
    WRITE_ADDR_3_0,
    WRITE_WAIT,
    WRITE_DATA_7_0,
    WRITE_DESELECT
} MachineState;

// The main clock (i_clk) here is 100 MHz, which ticks every
// 10 nS. In order to wait 150 uS upon reset, we must count
// at least 15000 ticks. So, we wait 20000, to be safe.
reg [14:0] delay;

reg MachineState state;

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        // Reset the SPI state machine
        delay <= 0;
        state <= RESET_JUST_NOW;
        o_busy <= 1;
        o_done <= 0;
        o_psram_csn <= 1;
        o_psram_sclk <= 0;
        io_psram_dinout <= 8'd0;
    else begin
        case (state)
            // Startup delay
            RESET_JUST_NOW: begin
                    if (delay == 19999)
                        state <= RESET_CLOCK_HIGH;
                    else
                        delay <= delay + 1;
                    end
                end

            // Post-reset clock high
            RESET_CLOCK_HIGH: begin
                    o_psram_sclk <= 1;
                    state <= RESET_CLOCK_LOW;
                end
            
            // Post-reset clock low
            RESET_CLOCK_LOW: begin
                    o_psram_sclk <= 0;
                    o_busy <= 0;
                    io_psram_dinout <= 8'bZ;
                    state <= MODE_SELECT_CMD_7;
                end

            // Entering QPI mode is done by command 35H
            // The command bits are sent 1-at-a-time, on both PSRAM chips
            MODE_SELECT_CMD_7: begin
                    o_psram_csn <= 0;
                    io_psram_dinout[1] = 0;
                    io_psram_dinout[5] = 0;
                    state <= MODE_CMD_6;
                end

            MODE_CMD_6: begin
                    io_psram_dinout[1] = 0;
                    io_psram_dinout[5] = 0;
                    state <= MODE_CMD_5;
                end

            MODE_CMD_5: begin
                    io_psram_dinout[1] = 1;
                    io_psram_dinout[5] = 1;
                    state <= MODE_CMD_4;
                end

            MODE_CMD_4: begin
                    io_psram_dinout[1] = 1;
                    io_psram_dinout[5] = 1;
                    state <= MODE_CMD_3;
                end

            MODE_CMD_3: begin
                    io_psram_dinout[1] = 0;
                    io_psram_dinout[5] = 0;
                    state <= MODE_CMD_2;
                end

            MODE_CMD_2: begin
                    io_psram_dinout[1] = 1;
                    io_psram_dinout[5] = 1;
                    state <= MODE_CMD_1;
                end

            MODE_CMD_1: begin
                    io_psram_dinout[1] = 0;
                    io_psram_dinout[5] = 0;
                    state <= MODE_CMD_0;
                end

            MODE_CMD_0: begin
                    io_psram_dinout[1] = 1;
                    io_psram_dinout[5] = 1;
                    state <= MODE_DESELECT;
                end

            MODE_DESELECT: begin
                    o_psram_csn <= 1;
                    o_busy <= 0;
                    o_done <= 1;
                end

            // Idle, awaiting command
            IDLE: begin
                    if (i_stb) begin
                        if (i_we) begin
                            // A write to PSRAM is done by command 38H
                            // The command bits are sent 4-at-a-time, on both PSRAM chips
                            io_psram_dinout[3:0] = 4'h3;
                            io_psram_dinout[7:4] = 4'h3;
                            state <= WRITE_CMD_3_0;
                        else begin
                            // A write to PSRAM is done by command EBH
                            // The command bits are sent 4-at-a-time, on both PSRAM chips
                            io_psram_dinout[3:0] = 4'hE;
                            io_psram_dinout[7:4] = 4'hE;
                            state <= READ_CMD_3_0;
                        end
                        o_psram_csn <= 0;
                        o_busy <= 1;
                        o_done <= 0;
                    end
                end

            READ_CMD_3_0: begin
                    io_psram_dinout[3:0] = 4'hE;
                    io_psram_dinout[7:4] = 4'hE;
                    state <= READ_ADDR_23_20;
                end

            READ_ADDR_23_20: begin
                    io_psram_dinout[3:0] = i_addr[23:20];
                    io_psram_dinout[7:4] = i_addr[23:20];
                    state <= READ_ADDR_19_16;
                end

            READ_ADDR_19_16: begin
                    io_psram_dinout[3:0] = i_addr[19:16];
                    io_psram_dinout[7:4] = i_addr[19:16];
                    state <= READ_ADDR_15_12;
                end

            READ_ADDR_15_12: begin
                    io_psram_dinout[3:0] = i_addr[15:12];
                    io_psram_dinout[7:4] = i_addr[15:12];
                    state <= READ_ADDR_11_8;
                end

            READ_ADDR_11_8: begin
                    io_psram_dinout[3:0] = i_addr[11:8];
                    io_psram_dinout[7:4] = i_addr[11:8];
                    state <= READ_ADDR_7_4;
                end

            READ_ADDR_7_4: begin
                    io_psram_dinout[3:0] = i_addr[7:4];
                    io_psram_dinout[7:4] = i_addr[7:4];
                    state <= READ_ADDR_3_0;
                end

            READ_ADDR_3_0: begin
                    io_psram_dinout[3:0] = i_addr[3:0];
                    io_psram_dinout[7:4] = i_addr[3:0];
                    ?
                    state <= READ_WAIT;
                end

            READ_WAIT: begin
                ?
                end

            READ_DATA_7_4: begin
                end

            READ_DATA_3_0: begin
                end

            READ_DESELECT: begin
                end

            WRITE_CMD_3_0: begin
                    io_psram_dinout[3:0] = 4'h8;
                    io_psram_dinout[7:4] = 4'h8;
                    state <= WRITE_ADDR_23_20;
                end

            WRITE_ADDR_23_20: begin
                    io_psram_dinout[3:0] = i_addr[23:20];
                    io_psram_dinout[7:4] = i_addr[23:20];
                    state <= WRITE_ADDR_19_16;
                end

            WRITE_ADDR_19_16: begin
                    io_psram_dinout[3:0] = i_addr[19:16];
                    io_psram_dinout[7:4] = i_addr[19:16];
                    state <= WRITE_ADDR_15_12;
                end

            WRITE_ADDR_15_12: begin
                    io_psram_dinout[3:0] = i_addr[15:12];
                    io_psram_dinout[7:4] = i_addr[15:12];
                    state <= WRITE_ADDR_11_8;
                end

            WRITE_ADDR_11_8: begin
                    io_psram_dinout[3:0] = i_addr[11:8];
                    io_psram_dinout[7:4] = i_addr[11:8];
                    state <= WRITE_ADDR_7_4;
                end

            WRITE_ADDR_7_4: begin
                    io_psram_dinout[3:0] = i_addr[7:4];
                    io_psram_dinout[7:4] = i_addr[7:4];
                    state <= WRITE_ADDR_3_0;
                end

            WRITE_ADDR_3_0: begin
                    io_psram_dinout[3:0] = i_addr[3:0];
                    io_psram_dinout[7:4] = i_addr[3:0];
                    state <= WRITE_DATA_7_0;
                end

            WRITE_DATA_7_0: begin
                    io_psram_dinout = i_din;
                end

            WRITE_DESELECT: begin
                end
        end
    end
end



endmodule
