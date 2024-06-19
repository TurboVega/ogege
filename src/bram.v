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
        input wire rst,             // reset
        input wire csa,             // chip select A
        input wire csb,             // chip select B
        input wire wea,             // write enable A
        input wire web,             // write enable B
        input wire clka,            // clock A
        input wire clkb,            // clock B
        input wire [7:0] dia,       // data in A
        input wire [7:0] dib,       // data in B
        input wire [15:0] addra,    // address A
        input wire [15:0] addrb,    // address B
        output reg [7:0] doa,       // data out A
        output reg [7:0] dob,       // data out B
        output reg dra,             // data ready A
        output reg drb              // data ready B
    );

    reg [7:0] bram [0:65535];

    initial $readmemh("../ram/ram.bits", bram);

    always @(posedge clka) begin
        if (rst) begin
            dra <= 0;
        end else if (~csa)
            // do nothing
        end else if (wea) begin
            bram[addra] <= dia;
        end else begin
            doa <= bram[addra];
            dra <= 1;
        end
    end

    always @(posedge clkb) begin
        if (rst) begin
            drb <= 0;
        end else if (~csb)
            // do nothing
        end else if (web) begin
            bram[addra] <= dib;
        end else begin
            dob <= bram[addra];
            drb <= 1;
        end
    end
endmodule
