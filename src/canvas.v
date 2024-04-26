/*
 * canvas.v
 *
 * This module provides block RAM space for a canvas.
 *
 * The size of the canvas in bytes is 336x256.
 *
 * The column index ranges from 0 to 335, taking 9 bits.
 * The row index ranges from 0 to 255, taking 8 bits.
 * Thus, the total address space is 17 bits.
 *
 * Since the size of the canvas in pixels is 336x256, it has a
 * margin of 8 pixels around a screen size of 320x240 (i.e.,
 * there are 8 extra pixels on the left, right, top, and bottom).
 * The margin allows for smooth scrolling.
 *
 * The data in each cell is as follows:
 *
 *  Alpha: 2 bits
 *  Color: 8 bits
 *
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module canvas(
        input wire wea,               // write enable A
        input wire web,               // write enable B
        input wire clka,              // clock A
        input wire clkb,              // clock B
        input wire [9:0] dia,         // data in A
        input wire [9:0] dib,         // data in B
        input wire [16:0] addra,      // address A
        input wire [16:0] addrb,      // address B
        output reg [9:0] doa,         // data out A
        output reg [9:0] dob          // data out B
    );

    reg [9:0] pixels [0:335][0:255];

    //initial $readmemh("../font/sample_text8x8.bits", pixels);

    always @(posedge clka) begin
        if (wea) begin
            pixels[addra] <= dia;
        end else
            doa <= pixels[addra];
    end

    always @(posedge clkb) begin
        if (web) begin
            pixels[addrb] <= dib;
        end else
            dob <= pixels[addrb];
    end
endmodule
