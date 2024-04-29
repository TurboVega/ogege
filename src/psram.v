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
    MODE_SELECT,
    MODE_CMD_7,
    MODE_CMD_6,
    MODE_CMD_5,
    MODE_CMD_4,
    MODE_CMD_3,
    MODE_CMD_2,
    MODE_CMD_1,
    MODE_CMD_0,
    MODE_DESELECT,
    READ_SELECT,
    READ_CMD_7_4,
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
    WRITE_SELECT,
    WRITE_CMD_7_4,
    WRITE_CMD_3_0,
    WRITE_ADDR_23_20,
    WRITE_ADDR_19_16,
    WRITE_ADDR_15_12,
    WRITE_ADDR_11_8,
    WRITE_ADDR_7_4,
    WRITE_ADDR_3_0,
    WRITE_WAIT,
    WRITE_DATA_7_4,
    WRITE_DATA_3_0,
    WRITE_DESELECT
} MachineState;

// The main clock (i_clk) here is 100 MHz, which ticks every
// 10 nS. In order to wait 150 uS upon reset, we must count
// at least 15000 ticks. So, we wait 20000, to be safe.
reg [14:0] delay;

reg [2:0] state;

always @(posedge i_rst or posedge i_clk) begin
    if (i_rst) begin
        // Reset the SPI state machine
        delay <= 0;
        state <= 0;
        o_busy <= 1;
        o_done <= 0;
        o_psram_csn <= 1;
        o_psram_sclk <= 0;
        io_psram_dinout <= 8'd0;
    else begin
        case (state)
            // Startup delay
            0: begin
                        if (delay == 19999)
                            state <= 1;
                        else
                            delay <= delay + 1;
                        end
                    end

            // Post-reset clock high
            1: begin
                        o_psram_sclk <= 1;
                        state <= 2;
                    end
            
            // Post-reset clock low
            2: begin
                        o_psram_sclk <= 0;
                        o_busy <= 0;
                        state <= 3;
                    end

            // Idle, awaiting command
            3: begin
                        if (i_stb) begin
                            if (i_we) begin
                                // Begin a write command
                                state <= ?;
                            else begin
                                // Begin a read command
                                state <= 3;
                            end
                            o_busy <= 1;
                            o_done <= 0;
                        end
                    end

        end
    end
end



endmodule
