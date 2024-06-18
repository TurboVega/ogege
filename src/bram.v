/*
 * bram.v
 *
 * This module provides a 64KB block RAM space for lower RAM.
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module bram_64kb(
        input wire wea,               // write enable A
        input wire web,               // write enable B
        input wire clka,              // clock A
        input wire clkb,              // clock B
        input wire [7:0] dia,         // data in A
        input wire [7:0] dib,         // data in B
        input wire [15:0] addra,       // address A
        input wire [15:0] addrb,       // address B
        output reg [7:0] doa,         // data out A
        output reg [7:0] dob          // data out B
    );

    reg [7:0] bram [0:65535];

    initial $readmemh("../ram/ram.bits", bram);

    always @(posedge clka) begin
        if (wea) begin
            bram[addra] <= dia;
        end else
            doa <= bram[addra];
    end

    always @(posedge clkb) begin
        if (web) begin
            bram[addra] <= dib;
        end else
            dob <= bram[addra];
    end
endmodule
