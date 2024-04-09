/*
 * frame_buffer.v
 *
 * This module provides block RAM space for the frame buffer,
 * which has enough memory for any of the following modes:
 *
 *  320x240 pixels: 8 bit palette index per pixel, 1 pixel per byte
 *  320x480 pixels: 4 bit palette index per pixel, 2 pixels per byte
 *  640x240 pixels: 4 bit palette index per pixel, 2 pixels per byte
 *  640x480 pixels: 2 bit palette index per pixel, 4 pixels per byte
 *
 * Since BRAM can be accessed in a 40-bit-wide manner, that
 * corresponds to exactly 5 data bytes, yielding the following read
 * or write groupings:
 *
 * 
 * 
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module frame_buffer #(
        parameter DATA_WIDTH=80,
        parameter ADDR_WIDTH=9
    )(
        input wire wea,
        input wire web,
        input wire clka,
        input wire clkb,
        input wire [DATA_WIDTH-1:0] dia,
        input wire [DATA_WIDTH-1:0] dib,
        input wire [ADDR_WIDTH-1:0] addra,
        input wire [ADDR_WIDTH-1:0] addrb,
        output reg [DATA_WIDTH-1:0] doa,
        output reg [DATA_WIDTH-1:0] dob
    );

    localparam WORD = (DATA_WIDTH-1);
    localparam DEPTH = (2**ADDR_WIDTH-1);
    reg [WORD:0] memory [0:DEPTH];
    initial $readmemb("splash_screen.bits", memory);

    always @(posedge clka) begin
        if (wea) begin
            memory[addra] <= dia;
        end else
            doa <= memory[addra];
    end

    always @(posedge clkb) begin
        if (web) begin
            memory[addrb] <= dib;
        end else
            dob <= memory[addrb];
    end
endmodule
