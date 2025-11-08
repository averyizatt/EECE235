module GuessTheNumber(
    input  wire        MAX10_CLK1_50,
    input  wire [1:0]  KEY,          // active low
    input  wire [9:0]  SW,
    output reg  [7:0]  HEX0,         // rightmost
    output reg  [7:0]  HEX1,
    output reg  [7:0]  HEX2,
    output reg  [7:0]  HEX3,
    output reg  [7:0]  HEX4,
    output reg  [7:0]  HEX5,         // leftmost
    output reg  [9:0]  LEDR
);
    // ===== Inputs made friendly
    wire clk  = MAX10_CLK1_50;
    wire key0 = ~KEY[0];   // submit
    wire key1 = ~KEY[1];   // increment

    reg  key0Prev, key1Prev;
    wire submitPulse = key0 & ~key0Prev;  // press edge
    wire incEdge     = key1 & ~key1Prev;

    // quick reset to stage 1 any time 
    wire quickReset = SW[2];

    // digit select
    wire selOnes  =  SW[0] & ~SW[1];
    wire selTens  = ~SW[0] &  SW[1];
    wire selValid = selOnes ^ selTens;

    // ===== Game data
    reg  [3:0] ones;
    reg  [3:0] tens;
    wire [6:0] guessVal = tens * 7'd10 + ones;

    parameter integer nTries = 7;
    reg [3:0] triesLeft;
    reg [6:0] target;

    reg [3:0] wins;
    reg [3:0] losses;

    // tiny rng
    reg [7:0] rng;
    always @(posedge clk) rng <= rng + 8'd1;

    // compare flags
    reg isHigh, isLow, isOk;
    reg [23:0] fbCount;

    // last hint persists during input
    localparam [1:0] hintNone = 2'b00, hintHi = 2'b01, hintLo = 2'b10, hintOk = 2'b11;
    reg [1:0] lastHint;

    // KEY1 hold repeat
    reg [23:0] repCount;
    reg        repArmed;

    // win leds
    reg [23:0] ledDiv;
    reg [9:0]  ledPat;

    // states
    localparam [2:0] stInput = 3'd0,
                     stError = 3'd1,
                     stEval  = 3'd2,
                     stFb    = 3'd3,
                     stWin   = 3'd4,
                     stLose  = 3'd5,
                     stStats = 3'd6;
    reg [2:0] state;

    // round control
    reg needTarget;
    reg needTries;

    // seven seg digits
    function [6:0] digit7;
        input [3:0] v;
        begin
            case (v)
                4'd0: digit7 = 7'b1000000;
                4'd1: digit7 = 7'b1111001;
                4'd2: digit7 = 7'b0100100;
                4'd3: digit7 = 7'b0110000;
                4'd4: digit7 = 7'b0011001;
                4'd5: digit7 = 7'b0010010;
                4'd6: digit7 = 7'b0000010;
                4'd7: digit7 = 7'b1111000;
                4'd8: digit7 = 7'b0000000;
                4'd9: digit7 = 7'b0010000;
                default: digit7 = 7'b1111111;
            endcase
        end
    endfunction

    // letter shapes, active low
    wire [6:0] patH     = 7'b0001001;
    wire [6:0] patI     = 7'b1111001;
    wire [6:0] patL     = 7'b1000111;
    wire [6:0] patO     = 7'b1000000;    // looks like 0
    wire [6:0] patK     = 7'b0001000;    // A lookalike
    wire [6:0] patE     = 7'b0000110;
    wire [6:0] patr     = 7'b0101111;
    wire [6:0] patBlank = 7'b1111111;
    wire [6:0] patU     = 7'b1000001;    // U shape
    wire [6:0] patY     = 7'b0010001;    // Y approximation
    wire [6:0] patA     = 7'b0001000;    // A using same as K on many displays

    // state 1 defaults
    initial begin
        key0Prev   = 1'b0;
        key1Prev   = 1'b0;
        ones       = 4'd0;
        tens       = 4'd0;
        triesLeft  = nTries[3:0];
        target     = 7'd42;
        wins       = 4'd0;
        losses     = 4'd0;
        fbCount    = 24'd0;
        repCount   = 24'd0;
        repArmed   = 1'b0;
        state      = stInput;
        needTarget = 1'b1;
        needTries  = 1'b1;
        LEDR       = 10'b0;
        ledDiv     = 24'd0;
        ledPat     = 10'b0000000001;
        rng        = 8'h5A;
        lastHint   = hintNone;
    end

    // helpers
    task doIncrement;
        begin
            if (selOnes)      ones <= (ones == 4'd9) ? 4'd0 : ones + 4'd1;
            else if (selTens) tens <= (tens == 4'd9) ? 4'd0 : tens + 4'd1;
        end
    endtask

    task resetRoundKeepRecord;
        begin
            ones       <= 4'd0;
            tens       <= 4'd0;
            needTarget <= 1'b1;
            needTries  <= 1'b1;
            lastHint   <= hintNone;
            state      <= stInput;
        end
    endtask

    wire [3:0] targetTens = target / 10;
    wire [3:0] targetOnes = target % 10;

    // main sequential
    always @(posedge clk) begin
        // edge sampling
        key0Prev <= key0;
        key1Prev <= key1;

        // quick reset to stage 1
        if (quickReset) begin
            resetRoundKeepRecord();
        end else begin
            // load tries at start of round
            if (state == stInput && needTries) begin
                triesLeft <= nTries[3:0];
                needTries <= 1'b0;
            end

            // increment with hold while editing stage 1
				
				
            if (state == stInput) begin
                if (key1) begin
                    if (incEdge) begin
                        doIncrement();
                        repArmed <= 1'b1;
                        repCount <= 24'd10_000_000;
                    end else if (repArmed) begin
                        if (repCount == 0) begin
                            doIncrement();
                            repCount <= 24'd4_000_000;
                        end else begin
                            repCount <= repCount - 1;
                        end
                    end
                end else begin
                    repArmed <= 1'b0;
                    repCount <= 24'd0;
                end
            end else begin
                repArmed <= 1'b0;
                repCount <= 24'd0;
            end

				
				
            // win leds
            if (state == stWin) begin
                ledDiv <= ledDiv + 24'd1;
                if (ledDiv == 24'd3_000_000) begin
                    ledDiv <= 24'd0;
                    ledPat <= {ledPat[8:0], ledPat[9]};
                end
                LEDR <= ledPat;
            end else begin
                LEDR  <= 10'b0000000000;
                ledDiv <= 24'd0;
            end

				
            case (state)
                stInput: begin
                    if (submitPulse) begin
                        if (!selValid) begin
                            state <= stError;
                        end else begin
                            if (needTarget) begin
                                if (rng[6:0] > 7'd99) target <= rng[6:0] - 7'd100;
                                else                   target <= rng[6:0];
                                needTarget <= 1'b0;
                                lastHint   <= hintNone; // fresh round clears hint
                            end
                            state <= stEval;
                        end
                    end
                end

					 
					 
					 
                stError: 
					 
					 begin
                    if (selValid) state <= stInput;
                end

					 
					 
					 
                stEval: 
					 
					 begin
                    isOk   <= (guessVal == target);
                    isHigh <= (guessVal >  target);
                    isLow  <= (guessVal <  target);

                    // update persistent hint now
                    if (guessVal == target)       lastHint <= hintOk;
                    else if (guessVal > target)   lastHint <= hintHi;
                    else                          lastHint <= hintLo;

                    if (guessVal != target && triesLeft != 0)
                        triesLeft <= triesLeft - 4'd1;

                    fbCount <= 24'd0;
                    state   <= stFb;
                end

					 
					 
                stFb:
					begin
                    fbCount <= fbCount + 24'd1;
                    if (fbCount == 24'd6_000_000) begin
                        if (isOk) begin
                            if (wins != 4'd9) wins <= wins + 4'd1;
                            state <= stWin;     // wait here until KEY0
                        end else if (triesLeft == 0) begin
                            if (losses != 4'd9) losses <= losses + 4'd1;
                            state <= stLose;    // wait here until KEY0
                        end else begin
                            state <= stInput;   // back to input, lastHint stays
                        end
                    end
                end

                stWin:
					
					begin
                    if (submitPulse) state <= stStats;   // go show record
                end

					 
                stLose:
					
					begin
                    if (submitPulse) state <= stStats;
                end

					 
                stStats: begin
                    if (submitPulse) resetRoundKeepRecord();  // back to stage 1
                end

					 
					 
                default: state <= stInput;
            endcase
        end
    end

    // ===== Display mapping, dp off on bit 7
    always @(*) begin
        // default play view
        HEX0 = {1'b1, digit7(ones)};
        HEX1 = {1'b1, digit7(tens)};
        HEX2 = {1'b1, patBlank};
        HEX3 = {1'b1, patBlank};
        HEX4 = {1'b1, digit7(triesLeft)};
        HEX5 = {1'b1, patBlank};

        // show ER when selector invalid
        if (state == stError) begin
            HEX3 = {1'b1, patE};
            HEX2 = {1'b1, patr};
        end
        // show last hint during input, eval, feedback, and even after a miss
        else if (state == stInput || state == stEval || state == stFb || state == stLose) begin
            case (lastHint)
                hintOk: begin HEX3 = {1'b1, patO}; HEX2 = {1'b1, patK}; end
                hintHi: begin HEX3 = {1'b1, patH}; HEX2 = {1'b1, patI}; end
                hintLo: begin HEX3 = {1'b1, patL}; HEX2 = {1'b1, patO}; end
                default: begin HEX3 = {1'b1, patBlank}; HEX2 = {1'b1, patBlank}; end
            endcase
        end

        // win view: show YAY on HEX3 HEX2 and the correct number on HEX1 HEX0

			if (state == stWin) begin
				 HEX5 = {1'b1, patY};                // Y
				 HEX4 = {1'b1, patA};                // A
				 HEX3 = {1'b1, patY};                // Y
				 HEX2 = {1'b1, patBlank};            // blank spacer
				 HEX1 = {1'b1, digit7(targetTens)};  // target tens
				 HEX0 = {1'b1, digit7(targetOnes)};  // target ones
			end


        // stats view: UU wins then L losses, waits for KEY0
        if (state == stStats) begin
            HEX5 = {1'b1, patU};
            HEX4 = {1'b1, patU};
            HEX3 = {1'b1, digit7(wins)};
            HEX2 = {1'b1, patL};
            HEX1 = {1'b1, digit7(losses)};
            HEX0 = {1'b1, patBlank};
        end
    end
endmodule
