/*
 * canvas.v
 *
 * This module provides block RAM space for a canvas.
 *
 * The size of the canvas in cells is 336x256. each
 * cell is one byte (8 bits). This is a total of
 * 86016 bytes of data (but may take more space in
 * BRAM, depending on how it is arranged).
 *
 * The column index ranges from 0 to 335, taking 9 bits.
 * The row index ranges from 0 to 255, taking 8 bits.
 * Thus, the total address space is 17 bits.
 *
 * Since the size of the canvas in cells is 336x256, it has a
 * margin of 8 cells around a screen size of 320x240 (i.e.,
 * there are 8 extra cells on the left, right, top, and bottom).
 * The margin allows for smooth scrolling.
 *
 * The data in each cell may be thought of in any of several
 * formats (modes), all of which use palette indexes:
 *
 *  Mode 0: 2 bpp - 4 colors - 672x512 pixels - screen 640x480
 *  Mode 1: 4 bpp - 16 colors - 336x512 pixels - screen 320x480
 *  Mode 2: 4 bpp - 16 colors - 672x256 pixels - screen 640x240
 *  Mode 3: 8 bpp - 256 colors - 336x256 pixels - screen 320x240
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
        input wire [7:0] dia,         // data in A
        input wire [7:0] dib,         // data in B
        input wire [8:0] cola,        // column A
        input wire [7:0] rowa,        // row A
        input wire [8:0] colb,        // column B
        input wire [7:0] rowb,        // row B
        output reg [7:0] doa,         // data out A
        output reg [7:0] dob          // data out B
    );

    reg [7:0] cells [0:335][0:255];

    initial $readmemh("../image/car336x256x256.bits", cells);

    always @(posedge clka) begin
        if (wea) begin
            cells[{cola,rowa}] <= dia;
        end else
            doa <= cells[{cola,rowa}];
    end

    always @(posedge clkb) begin
        if (web) begin
            cells[{colb,rowb}] <= dib;
        end else
            dob <= cells[{colb,rowb}];
    end
endmodule
