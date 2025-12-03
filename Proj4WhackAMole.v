module Proj4WhackAMole(

    input  MAX10_CLK1_50,
    input  [9:0] SW,
    inout  [35:0] GPIO,

    output [7:0] HEX0,
    output [7:0] HEX1,
    output [7:0] HEX2,
    output [7:0] HEX3,
    output [7:0] HEX4,
    output [7:0] HEX5,
    output [9:0] LEDR
);

// =====================================================
// Clock Divider 100 kHz for matrix scan
// =====================================================
wire clk100k;
ClockDivider100k div1(
    .clk_in(MAX10_CLK1_50),
    .clk_out(clk100k)
);

// Row scan counter for LED matrix (fast)
reg [2:0] row_sel = 0;
always @(posedge clk100k)
    row_sel <= row_sel + 1;

// =====================================================
// Slow game clock for FSM (about 100 Hz)
// =====================================================
wire clk_game;

SlowGameClock game_div(
    .clk_in(clk100k),   // 100 kHz in
    .clk_out(clk_game)  // about 100 Hz out
);

// =====================================================
// External buttons (active low)
// =====================================================
wire smash_TL = ~GPIO[29];
wire smash_TR = ~GPIO[31];
wire smash_BL = ~GPIO[33];
wire smash_BR = ~GPIO[35];

wire smash_any = smash_TL | smash_TR | smash_BL | smash_BR;

// encode zone
// 00 top left, 01 top right, 10 bottom left, 11 bottom right
wire [1:0] smash_zone =
    smash_TL ? 2'b00 :
    smash_TR ? 2'b01 :
    smash_BL ? 2'b10 :
    smash_BR ? 2'b11 :
    2'b11;   // default when no button

// =====================================================
// Switches
// =====================================================
wire start      = SW[0];   // start game
wire reset      = SW[1];   // reset game
wire stats      = SW[2];   // show stats after lose
wire difficulty = SW[3];   // 0 easy, 1 hard

// =====================================================
// FSM outputs
// =====================================================
wire [1:0] mole_row_group;
wire [1:0] mole_col_group;

wire [7:0] score;
wire [7:0] timer_val;   // hundredths of a second
wire [7:0] high_score;
wire [2:0] lives;       // three lives: 3,2,1,0
wire       show_mole;

// =====================================================
// FSM
// =====================================================
WhackFSM_QSMASH fsm(
    .clk(clk_game),          // slow game clock
    .start(start),
    .reset(reset),
    .smash_zone(smash_zone),
    .smash_any(smash_any),
    .stats(stats),
    .difficulty(difficulty),
    .mole_row_group(mole_row_group),
    .mole_col_group(mole_col_group),
    .score(score),
    .timer_out(timer_val),
    .high_score(high_score),
    .lives(lives),
    .show_mole(show_mole)
);

// =====================================================
// Matrix Driver (single dot mole)
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
// Rows needed inversion at the pins for your panel

assign GPIO[0]  = ~row_drive[0];
assign GPIO[2]  = ~row_drive[1];
assign GPIO[4]  = ~row_drive[2];
assign GPIO[6]  = ~row_drive[3];
assign GPIO[8]  = ~row_drive[4];
assign GPIO[10] = ~row_drive[5];
assign GPIO[12] = ~row_drive[6];
assign GPIO[14] = ~row_drive[7];

// Columns are active low as driven
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

// lives is 3,2,1,0 and we want three LEDs in a row
// LED0 = life 1, LED1 = life 2, LED2 = life 3

assign LEDR[0] = (lives >= 1);
assign LEDR[1] = (lives >= 2);
assign LEDR[2] = (lives >= 3);

// other LEDs unused here
assign LEDR[9:3] = 7'b0000000;

// -----------------------------------------------------
// Seven segment digit selection
// -----------------------------------------------------
reg [3:0] d0, d1, d2, d3, d4, d5;
reg [7:0] sec;
reg [7:0] hund;

// idle when fresh: three lives, no score, no mole
wire in_idle  = (lives == 3 && score == 0 && show_mole == 0);
// game over only when out of lives
wire game_over = (lives == 0);

// turn decimal point on except when showing stats
wire show_dp = !(game_over && stats);

always @(*) begin
    // default numeric display
    // score on HEX5 and HEX4
    d5 = score / 10;
    d4 = score % 10;

    // timer_val is in hundredths of a second at 100 Hz
    sec  = timer_val / 8'd100;   // whole seconds
    hund = timer_val % 8'd100;   // hundredths

    // time as SS.HH on HEX3..HEX0
    d3 = sec / 10;          // tens of seconds
    d2 = sec % 10;          // ones of seconds
    d1 = hund / 10;         // tens of hundredths
    d0 = hund % 10;         // ones of hundredths

    // idle screen: show "START"
    if (in_idle) begin
        d5 = 4'hF;   // blank
        d4 = 4'd5;   // S (digit 5)
        d3 = 4'hC;   // T
        d2 = 4'hA;   // A
        d1 = 4'hD;   // R
        d0 = 4'hC;   // T
    end
    // game over and stats switch off: show LOSE
    else if (game_over && !stats) begin
        d5 = 4'hF;
        d4 = 4'hB;   // L
        d3 = 4'd0;   // O
        d2 = 4'd5;   // S
        d1 = 4'hE;   // E
        d0 = 4'hF;
    end
    // game over and stats switch on: show high score only
    else if (game_over && stats) begin
        d5 = 4'hF;              // blank
        d4 = 4'hF;              // blank
        d3 = 4'hF;              // blank
        d2 = 4'hF;              // blank
        d1 = high_score / 10;   // tens
        d0 = high_score % 10;   // ones
    end
end

// -----------------------------------------------------
// Drive the seven segment displays
// -----------------------------------------------------
wire [7:0] h0, h1, h2, h3, h4, h5;

SevenSeg s0(d0, h0);
SevenSeg s1(d1, h1);
SevenSeg s2(d2, h2);
SevenSeg s3(d3, h3);
SevenSeg s4(d4, h4);
SevenSeg s5(d5, h5);

// decimal point between seconds and hundredths for time
// HEX3 HEX2 . HEX1 HEX0 is "SS.HH" when show_dp is true
assign HEX0 = h0;
assign HEX1 = h1;
assign HEX2 = show_dp ? (h2 & 8'b01111111) : h2; // dp on except in stats
assign HEX3 = h3;
assign HEX4 = h4;
assign HEX5 = h5;

endmodule


// =====================================================
// QUADRANT WHACK FSM (no win cap, infinite score)
// =====================================================
module WhackFSM_QSMASH(
    input clk,
    input start,
    input reset,
    input [1:0] smash_zone,
    input smash_any,
    input stats,
    input difficulty,

    output reg [1:0] mole_row_group,
    output reg [1:0] mole_col_group,

    output reg [7:0] score,
    output reg [7:0] timer_out,      // hundredths
    output reg [7:0] high_score,
    output reg [2:0] lives,          // 3,2,1,0
    output reg show_mole
);

reg [2:0] state = 3'd0;

localparam IDLE         = 3'd0;
localparam LIGHT_MOLE   = 3'd1;
localparam WAIT_INPUT   = 3'd2;
localparam CHECK        = 3'd3;
localparam SCORE_UPDATE = 3'd4;
localparam NEXT_ROUND   = 3'd5;
localparam GAME_OVER    = 3'd6;

reg [15:0] timer;
reg [15:0] allowed_time = 16'd200;   // about 2 seconds at 100 Hz

// LFSR for mole position
reg [7:0] lfsr = 8'hA3;

// Quadrant decode from group bits
wire [1:0] mole_zone =
    (mole_row_group < 2 && mole_col_group < 2) ? 2'b00 :
    (mole_row_group < 2 && mole_col_group > 1) ? 2'b01 :
    (mole_row_group > 1 && mole_col_group < 2) ? 2'b10 :
                                                 2'b11;

// edge detection for smash_any
reg prev_smash_any = 0;
wire smash_edge = smash_any & ~prev_smash_any;

// edge detection for start (to restart after game over)
reg prev_start = 0;
wire start_edge = start & ~prev_start;

reg [7:0] new_score;

always @(posedge clk) begin
    prev_smash_any <= smash_any;
    prev_start     <= start;

    if (reset) begin
        state        <= IDLE;
        score        <= 0;
        lives        <= 3;         // three lives
        show_mole    <= 0;
        timer_out    <= 0;
        allowed_time <= difficulty ? 16'd120 : 16'd200;
        lfsr         <= 8'hA3;
        high_score   <= 0;
    end else begin

        case(state)

            IDLE: begin
                show_mole    <= 0;
                timer_out    <= 0;
                allowed_time <= difficulty ? 16'd120 : 16'd200;
                score        <= 0;
                lives        <= 3;   // full lives on each new game
                if (start)
                    state <= LIGHT_MOLE;
            end

            LIGHT_MOLE: begin
                lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5]};

                mole_row_group <= lfsr[1:0];
                mole_col_group <= lfsr[3:2];

                show_mole      <= 1;
                timer          <= allowed_time;
                timer_out      <= 0;
                state          <= WAIT_INPUT;
            end

            WAIT_INPUT: begin
                if (timer != 0)
                    timer <= timer - 1;

                timer_out <= timer_out + 1;

                if (smash_edge) begin
                    if (smash_zone == mole_zone)
                        state <= SCORE_UPDATE;
                    else
                        state <= CHECK;  // wrong button press
                end else if (timer == 0) begin
                    state <= CHECK;      // timeout also counts as a miss
                end
            end

            CHECK: begin
                // miss or timeout: lose one life
                if (lives <= 1) begin
                    lives     <= 0;
                    show_mole <= 0;
                    state     <= GAME_OVER;
                end else begin
                    lives <= lives - 1;
                    state <= NEXT_ROUND;
                end
            end

            SCORE_UPDATE: begin
                new_score = score + 1;
                score     <= new_score;

                if (new_score > high_score)
                    high_score <= new_score;

                // speed up a little, but keep a reasonable minimum
                if (allowed_time > 16'd60)
                    allowed_time <= allowed_time - 16'd10;

                state <= NEXT_ROUND;
            end

            NEXT_ROUND: begin
                show_mole <= 0;
                state     <= LIGHT_MOLE;
            end

            GAME_OVER: begin
                show_mole <= 0;
                // Stay in GAME_OVER until the user toggles start OFF then ON.
                if (start_edge) begin
                    state <= IDLE;
                end
            end

            default: begin
                state <= IDLE;
            end

        endcase
    end
end

endmodule


// =====================================================
// MATRIX DRIVER, SINGLE DOT
// =====================================================
module MatrixDriver2x2(
    input  [2:0] row_sel,
    input  [1:0] mole_row_group,
    input  [1:0] mole_col_group,
    input        show,
    output reg [7:0] row_out,
    output reg [7:0] col_out
);

    parameter FLIP_ROW = 0;
    parameter FLIP_COL = 0;

    wire [2:0] mole_row_raw = {mole_row_group, 1'b0};
    wire [2:0] mole_col_raw = {mole_col_group, 1'b0};

    wire [2:0] mole_row = FLIP_ROW ? (3'd7 - mole_row_raw) : mole_row_raw;
    wire [2:0] mole_col = FLIP_COL ? (3'd7 - mole_col_raw) : mole_col_raw;

    wire [2:0] real_row_sel = FLIP_ROW ? (3'd7 - row_sel) : row_sel;

    always @(*) begin
        row_out = 8'b11111111;
        col_out = 8'b11111111;

        row_out[real_row_sel] = 1'b0;

        if (show && (real_row_sel == mole_row)) begin
            col_out[mole_col] = 1'b0;
        end
    end

endmodule


// =====================================================
// SEVEN SEG DECODER WITH LETTER SUPPORT
// =====================================================
module SevenSeg(
    input [3:0] val,
    output reg [7:0] seg
);

always @(*) begin
    case(val)
        4'd0: seg = 8'b11000000; // 0
        4'd1: seg = 8'b11111001; // 1
        4'd2: seg = 8'b10100100; // 2
        4'd3: seg = 8'b10110000; // 3
        4'd4: seg = 8'b10011001; // 4
        4'd5: seg = 8'b10010010; // 5  S
        4'd6: seg = 8'b10000010; // 6
        4'd7: seg = 8'b11111000; // 7
        4'd8: seg = 8'b10000000; // 8
        4'd9: seg = 8'b10010000; // 9

        4'hA: seg = 8'b10001000; // A or H style
        4'hB: seg = 8'b11000111; // L
        4'hC: seg = 8'b10000111; // T
        4'hD: seg = 8'b10101111; // r-ish
        4'hE: seg = 8'b10000110; // E
        4'hF: seg = 8'b11111111; // blank

        default: seg = 8'b11111111;
    endcase
end

endmodule


// =====================================================
// CLOCK DIVIDER 100 kHz
// =====================================================
module ClockDivider100k(
    input  clk_in,
    output reg clk_out
);

reg [8:0] count = 0;

always @(posedge clk_in) begin
    if (count == 9'd249) begin
        count   <= 0;
        clk_out <= ~clk_out;
    end else begin
        count <= count + 1;
    end
end

endmodule


// =====================================================
// Slow game clock: 100 kHz in to about 100 Hz out
// =====================================================
module SlowGameClock(
    input  clk_in,
    output reg clk_out
);

    reg [9:0] count = 0;

    always @(posedge clk_in) begin
        if (count == 10'd499) begin
            count   <= 0;
            clk_out <= ~clk_out;
        end else begin
            count <= count + 1;
        end
    end

endmodule
