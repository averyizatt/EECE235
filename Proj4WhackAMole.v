module Proj4WhackAMole(

    input MAX10_CLK1_50,
    input [9:0] SW,
    inout [35:0] GPIO,

    output [7:0] HEX0,
    output [7:0] HEX1,
    output [7:0] HEX4,
    output [7:0] HEX5,
    output [9:0] LEDR
);

// =====================================================
// Clock Divider 100 kHz
// =====================================================
wire clk100k;
ClockDivider100k div1(
    .clk_in(MAX10_CLK1_50),
    .clk_out(clk100k)
);

// Row scan counter
reg [2:0] row_sel = 0;
always @(posedge clk100k)
    row_sel <= row_sel + 1;

// =====================================================
// External buttons (active low)
// =====================================================
wire smash_TL = ~GPIO[32];
wire smash_TR = ~GPIO[34];
wire smash_BL = ~GPIO[33];
wire smash_BR = ~GPIO[35];

wire [1:0] smash_zone =
    smash_TL ? 2'b00 :
    smash_TR ? 2'b01 :
    smash_BL ? 2'b10 :
    smash_BR ? 2'b11 :
    2'b11; 

// =====================================================
// Switches
// =====================================================
wire start = SW[0];  
wire reset = SW[1];  
wire stats = SW[2];
wire difficulty = SW[3];

// =====================================================
// FSM outputs
// =====================================================
wire [1:0] mole_row_group;
wire [1:0] mole_col_group;

wire [7:0] score;
wire [7:0] timer_val;
wire [4:0] lives;
wire show_mole;

// =====================================================
// FSM
// =====================================================
WhackFSM_QSMASH fsm(
    .clk(clk100k),
    .start(start),
    .reset(reset),
    .smash_zone(smash_zone),
    .stats(stats),
    .difficulty(difficulty),
    .mole_row_group(mole_row_group),
    .mole_col_group(mole_col_group),
    .score(score),
    .timer_out(timer_val),
    .lives(lives),
    .show_mole(show_mole)
);

// =====================================================
// Matrix Driver with auto-orientation support
// =====================================================
wire [7:0] row_drive;
wire [7:0] col_drive;

MatrixDriver2x2 matrix(
    .row_sel(row_sel),
    .mole_row_group(mole_row_group),
    .mole_col_group(mole_col_group),
    .show(show_mole),
    .row_out(row_drive),
    .col_out(col_drive)
);

// =====================================================
// GPIO OUTPUT MAPPING
// =====================================================

// Rows (active low)
assign GPIO[0]  = row_drive[0];
assign GPIO[2]  = row_drive[1];
assign GPIO[4]  = row_drive[2];
assign GPIO[6]  = row_drive[3];
assign GPIO[8]  = row_drive[4];
assign GPIO[10] = row_drive[5];
assign GPIO[12] = row_drive[6];
assign GPIO[14] = row_drive[7];

// Columns (active low)
assign GPIO[16] = col_drive[0];
assign GPIO[18] = col_drive[1];
assign GPIO[20] = col_drive[2];
assign GPIO[22] = col_drive[3];
assign GPIO[24] = col_drive[4];
assign GPIO[26] = col_drive[5];
assign GPIO[28] = col_drive[6];
assign GPIO[30] = col_drive[7];

// =====================================================
// Lives and HEX displays
// =====================================================

assign LEDR[4:0] = lives;

SevenSeg s0(score % 10, HEX0);
SevenSeg s1(score / 10, HEX1);

SevenSeg s4(timer_val % 10, HEX4);
SevenSeg s5(timer_val / 10, HEX5);

endmodule


// =====================================================
// QUADRANT WHACK FSM (Option A)
// =====================================================
module WhackFSM_QSMASH(
    input clk,
    input start,
    input reset,
    input [1:0] smash_zone,
    input stats,
    input difficulty,

    output reg [1:0] mole_row_group,
    output reg [1:0] mole_col_group,

    output reg [7:0] score,
    output reg [7:0] timer_out,
    output reg [4:0] lives,
    output reg show_mole
);

reg [2:0] state = 0;

localparam IDLE = 0;
localparam LIGHT_MOLE = 1;
localparam WAIT_INPUT = 2;
localparam CHECK = 3;
localparam SCORE_UPDATE = 4;
localparam NEXT_ROUND = 5;
localparam GAME_OVER = 6;

reg [15:0] timer;
reg [15:0] allowed_time = 20000;

// LFSR
reg [7:0] lfsr = 8'hA3;
always @(posedge clk)
    lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5]};

// Convert mole to smash quadrant
wire [1:0] mole_zone =
    (mole_row_group < 2 && mole_col_group < 2) ? 2'b00 :
    (mole_row_group < 2 && mole_col_group > 1) ? 2'b01 :
    (mole_row_group > 1 && mole_col_group < 2) ? 2'b10 :
                                                 2'b11;

always @(posedge clk) begin

    if (reset)
        state <= IDLE;

    case(state)

        IDLE: begin
            score <= 0;
            lives <= 5;
            show_mole <= 0;
            timer_out <= 0;
            allowed_time <= difficulty ? 12000 : 20000;
            if (start)
                state <= LIGHT_MOLE;
        end

        LIGHT_MOLE: begin
            mole_row_group <= lfsr[1:0];
            mole_col_group <= lfsr[3:2];
            show_mole <= 1;
            timer <= allowed_time;
            timer_out <= 0;
            state <= WAIT_INPUT;
        end

        WAIT_INPUT: begin
            timer <= timer - 1;
            timer_out <= timer_out + 1;

            if (smash_zone == mole_zone)
                state <= SCORE_UPDATE;

            else if (smash_zone != 2'b11 && smash_zone != mole_zone)
                state <= CHECK;

            else if (timer == 0) begin
                lives <= lives - 1;
                if (!lives)
                    state <= GAME_OVER;
                else
                    state <= NEXT_ROUND;
            end
        end

        CHECK: begin
            lives <= lives - 1;
            if (!lives)
                state <= GAME_OVER;
            else
                state <= NEXT_ROUND;
        end

        SCORE_UPDATE: begin
            score <= score + 1;
            if (allowed_time > 3500)
                allowed_time <= allowed_time - 600;
            state <= NEXT_ROUND;
        end

        NEXT_ROUND: begin
            show_mole <= 0;
            state <= LIGHT_MOLE;
        end

        GAME_OVER: begin
            show_mole <= 0;
            if (start)
                state <= IDLE;
        end
    endcase
end

endmodule


// =====================================================
// MATRIX DRIVER WITH AUTO FLIP
// =====================================================

module MatrixDriver2x2(
    input [2:0] row_sel,
    input [1:0] mole_row_group,
    input [1:0] mole_col_group,
    input show,
    output reg [7:0] row_out,
    output reg [7:0] col_out
);

// If matrix appears upside down:
// change FLIP_ROW or FLIP_COL from 0 to 1
parameter FLIP_ROW = 0;
parameter FLIP_COL = 0;

wire [2:0] r0 = {mole_row_group,1'b0};
wire [2:0] r1 = r0 + 1;

wire [2:0] c0 = {mole_col_group,1'b0};
wire [2:0] c1 = c0 + 1;

// Fix row selection if matrix rotated
wire [2:0] real_row_sel = FLIP_ROW ? (3'd7 - row_sel) : row_sel;

// Drive rows (active low)
always @(*) begin
    row_out = 8'b11111111;
    row_out[real_row_sel] = 1'b0;
end

// Fix columns if rotated
wire [2:0] rc0 = FLIP_COL ? (3'd7 - c0) : c0;
wire [2:0] rc1 = FLIP_COL ? (3'd7 - c1) : c1;

// Drive columns
always @(*) begin
    if (!show)
        col_out = 8'b11111111;
    else if (real_row_sel == r0 || real_row_sel == r1) begin
        col_out = 8'b11111111;
        col_out[rc0] = 1'b0;
        col_out[rc1] = 1'b0;
    end
    else
        col_out = 8'b11111111;
end

endmodule




// =====================================================
// SEVEN SEG DECODER
// =====================================================
module SevenSeg(
    input [3:0] val,
    output reg [7:0] seg
);

always @(*) begin
    case(val)
        0: seg = 8'b11000000;
        1: seg = 8'b11111001;
        2: seg = 8'b10100100;
        3: seg = 8'b10110000;
        4: seg = 8'b10011001;
        5: seg = 8'b10010010;
        6: seg = 8'b10000010;
        7: seg = 8'b11111000;
        8: seg = 8'b10000000;
        9: seg = 8'b10010000;
        default: seg = 8'b11111111;
    endcase
end

endmodule


// =====================================================
// CLOCK DIVIDER 100 kHz
// =====================================================
module ClockDivider100k(
    input clk_in,
    output reg clk_out
);

reg [8:0] count = 0;

always @(posedge clk_in) begin
    if (count == 249) begin
        count <= 0;
        clk_out <= ~clk_out;
    end else begin
        count <= count + 1;
    end
end

endmodule
