/*
 * text_array8x8.v
 *
 * This module provides block RAM space for the text array.
 * 
 * Copyright (C) 2024 Curtis Whitley
 * License: APACHE
 */

`default_nettype none

module text_array8x8 #(
        parameter DATA_WIDTH=16,
        parameter ADDR_WIDTH=13
    )(
        input wire wea,                         // write enable A
        input wire web,                         // write enable B
        input wire clka,                        // clock A
        input wire clkb,                        // clock B
        input wire [DATA_WIDTH-1:0] dia,        // data in A
        input wire [DATA_WIDTH-1:0] dib,        // data in B
        input wire [ADDR_WIDTH-1:0] addra,      // address A
        input wire [ADDR_WIDTH-1:0] addrb,      // address B
        output reg [DATA_WIDTH-1:0] doa,        // data out A
        output reg [DATA_WIDTH-1:0] dob         // data out B
    );

    localparam WORD = (DATA_WIDTH-1);
    localparam DEPTH = (2**ADDR_WIDTH-1);
    reg [WORD:0] memory [0:DEPTH];

    initial $readmemh("../font/sample_text8x8.bits", memory);

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
