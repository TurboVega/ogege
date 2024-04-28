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

module canvas (
    input  wire i_rst,
    input  wire i_pix_clk,
    input  wire i_blank,
    input  wire i_cmd_clk,
    input  wire [31:0] i_cmd_data,
    input  wire [8:0] i_scan_row,
    input  wire [9:0] i_scan_column,
    output wire [11:0] o_color
);

    // The color palette each holds 256 colors at 12 bits each (4 bits per
    // color component), since 12 bits is all that the board supports.
    //
    reg [11:0] reg_palette_color[0:255];

    // The scroll offsets default to zero, which means that the upper-left
    // visible pixel is the upper-left pixel in the text cell for text row 0
    // and text column 0.
    //
    reg [9:0] reg_scroll_x_offset;
    reg [8:0] reg_scroll_y_offset;

    reg reg_cmd_in_progress;
    reg reg_wea;
    reg reg_web;
    reg reg_clka;
    wire wire_clkb;
    reg [7:0] reg_dia;
    reg [7:0] reg_dib;
    reg [8:0] reg_cola;
    wire [8:0] wire_colb;
    reg [7:0] reg_rowa;
    wire [7:0] wire_rowb;
    reg [7:0] reg_doa;
    reg [7:0] reg_dob;

    frame_buffer frame_buffer_inst (
        .wea(reg_wea),
        .web(reg_web),
        .clka(reg_clka),
        .clkb(wire_clkb),
        .dia(reg_dia),
        .dib(reg_dib),
        .cola(reg_cola),
        .rowa(reg_rowa),
        .colb(wire_colb),
        .rowb(wire_rowb),
        .doa(reg_doa),
        .dob(reg_dob)
    );

    initial begin
        $readmemh("../image/car336x256x256.pal", reg_palette_color, 0, 255);
    end

    wire [9:0] adjusted_scan_row;
    wire [10:0] adjusted_scan_column;
    wire [9:0] wrapped_scan_row;
    wire [10:0] wrapped_scan_column;

    wire [7:0] cell_value;

    assign adjusted_scan_row = {1'b0,i_scan_row} + {1'b0,reg_scroll_y_offset};
    assign wrapped_scan_row = adjusted_scan_row >= 672 ?
        adjusted_scan_row - 672 : adjusted_scan_row;

    assign adjusted_scan_column = {1'b0,i_scan_column} + {1'b0,reg_scroll_x_offset};
    assign wrapped_scan_column = adjusted_scan_column >= 512 ?
        adjusted_scan_column - 512 : adjusted_scan_column;

    assign wire_colb = wrapped_scan_column[9:0];
    assign wire_rowb = wrapped_scan_row[8:0];
    //assign reg_web = 0;
    assign wire_clkb = i_pix_clk;

    assign o_color = reg_palette_color[reg_dob];

    always @(posedge i_rst) begin
        reg_scroll_x_offset <= 0;
        reg_scroll_y_offset <= 0;
        reg_cmd_in_progress <= 0;
        reg_wea <= 0;
        reg_web <= 0;
        reg_clka <= 0;
        //wire_clkb <= 0;
        reg_dia <= 0;
        reg_dib <= 0;
        reg_cola <= 0;
        reg_rowa <= 0;
        //wire_colb <= 0;
        //wire_rowb <= 0;
        //reg_addrb <= 0;
    end

endmodule
