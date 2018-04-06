/*	Attributions
	We were struggling during the first two weeks, so we looked at https://github.com/heatonbe/simonSays_FPGA_DE2-115_Verilog
	to try to understand the basics. The main ideas we took from it was to have counters that waits for the colour inputs
	and also counter to allow the pattern to be displayed in game states.
	
	Also vga_adapter is from lab 6
	
*/
module simonsays
	(
	CLOCK_50,
	KEY,
	SW,
	LEDR,
	LEDG,
	HEX0, HEX1, HEX4, HEX5, HEX6, HEX7,
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B   						//	VGA Blue[9:0]
	);

	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [6:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0, HEX1, HEX4, HEX5, HEX6, HEX7;
	
	wire resetn;
	assign resetn = KEY[0];
	wire go;
	assign go = ~KEY[1];
	reg [30:0] counter, player_counter1, player_counter2;
	
	wire [3:0] colour;
	assign colour[3:0] = SW[3:0];
	//wire [4:0] state;
	reg [4:0] score, highscore;
	// pattern lights
	reg [6:0] led;
	// indicates player/game turn. 01 for computer, 10 for player
	reg [1:0] player_led;
	reg [4:0] lives;
	
	reg [0:0] lose_w;
	reg [0:0] win_w;
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
   reg [2:0] colour_vga;
   reg [7:0] x;
   reg [6:0] y;
	
	vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(colour_vga),
            .x(x),
            .y(y),
            .plot(1'b1),
            /* Signals for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";
		  
	
	initial
	begin
		lives <= 5'd3;
		highscore <= 5'd0;
		score <= 5'd0;
		player_led <= 2'b00;
		led <= 7'd0;
	end
    // Instansiate datapath
	//datapath myDatapath(CLOCK_50, resetn, state, counter, player_counter1, score, led);

    // Instansiate FSM control
	//control myControl(CLOCK_50, resetn, go, colour, state, counter, player_counter1);
	reg on_1st_seg;
	
	assign LEDR[6:0] = led;
	assign LEDG[1:0] = player_led;
	assign LEDG[7] = on_1st_seg;
	/*
	hex_display(lives, HEX4);
	hex_display(4'b0000, HEX5);
	hex_display(4'b0000, HEX1);
	hex_display(score, HEX0);
	hex_display(4'b0000, HEX7);
	hex_display(highscore, HEX6);
	*/
	wire [4:0] score_tens, score_ones, highscore_tens, highscore_ones;
	score_display(lives, HEX4);
	score_display(5'b0000, HEX5);
	
	assign score_ones = score % 10;
	assign score_tens = (score - score_ones) / 10;
	score_display(score_tens, HEX1);
	score_display(score_ones, HEX0);
	assign highscore_ones = highscore % 10;
	assign highscore_tens = (highscore - highscore_ones) / 10;
	score_display(highscore_tens, HEX7);
	score_display(highscore_ones, HEX6);
	
	reg [5:0] current_state, next_state;
	wire [3:0] colour1, colour2, colour3, colour4, colour5, colour6, randomize1, randomize2, randomize3, randomize4, randomize5, randomize6;
	
	lfsr my_lfsr1(randomize1, randomize2, randomize3, randomize4, randomize5, randomize6);
	mux_LUT my_mux1(randomize1, colour1);
	mux_LUT my_mux2(randomize2, colour2);
	mux_LUT my_mux3(randomize3, colour3);
	mux_LUT my_mux4(randomize4, colour4);
	mux_LUT my_mux5(randomize5, colour5);
	mux_LUT my_mux6(randomize6, colour6);
	
	
	// C for computer states, P for player states
	localparam 
	RESET = 6'd0,
	C1 = 6'd1,
	P1_1 = 6'd2,
	P1_Life =6'd3,
	C2 = 6'd4,
	P2_1 = 6'd5,
	P2_2 = 6'd6,
	P2_Life = 6'd7,
	C3 = 6'd8,
	P3_1 = 6'd9,
	P3_2 = 6'd10,
	P3_3 = 6'd11,
	P3_Life = 6'd12,
	C4 = 6'd13,
	P4_1 = 6'd14,
	P4_2 = 6'd15,
	P4_3 = 6'd16,
	P4_4 = 6'd17,
	P4_Life = 6'd18,
	C5 = 6'd19,
	P5_1 = 6'd20,
	P5_2 = 6'd21,
	P5_3 = 6'd22,
	P5_4 = 6'd23,
	P5_5 = 6'd24,
	P5_Life = 6'd25,
	C6 = 6'd26,
	P6_1 = 6'd27,
	P6_2 = 6'd28,
	P6_3 = 6'd29,
	P6_4 = 6'd30,
	P6_5 = 6'd31,
	P6_6 = 6'd32,
	P6_Life = 6'd33,
	UPDATE = 6'd34,
	WIN = 6'd35,
	GAMEOVER = 6'd36;
	
	// have the sequence of inputs be 1 state each, checking 1 colour each state
    always@(*)
    begin
            case (current_state)
					RESET: next_state = go ? C1 : RESET;
					C1:
					begin
						if(counter > 31'd50000000)
							next_state = P1_1;
						else
							next_state = C1;
					end
					P1_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C1;
					end
					P1_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = C2;
							else
								next_state = P1_Life;
						end
						else
							next_state = P1_1;
					end
					C2:
					begin
						if(counter > 31'd100000000)
							next_state = P2_1;
						else
							next_state = C2;
					end
					P2_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C2;
					end
					P2_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = P2_2;
							else
								next_state = P2_Life;
						end
						else
							next_state = P2_1;
					end
					P2_2:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0010)
								next_state = C3;
							else
								next_state = P2_Life;
						end
						else
							next_state = P2_2;
					end
					C3:
					begin
						if(counter > 31'd150000000)
							next_state = P3_1;
						else
							next_state = C3;
					end
					P3_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C3;
					end
					P3_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = P3_2;
							else
								next_state = P3_Life;
						end
						else
							next_state = P3_1;
					end
					P3_2:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0010)
								next_state = P3_3;
							else
								next_state = P3_Life;
						end
						else
							next_state = P3_2;
					end
					P3_3:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = C4;
							else
								next_state = P3_Life;
						end
						else
							next_state = P3_3;
					end
					C4:
					begin
						if(counter > 31'd200000000)

							next_state = P4_1;
						else
							next_state = C4;
					end
					P4_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C4;
					end
					P4_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = P4_2;
							else
								next_state = P4_Life;
						end
						else
							next_state = P4_1;
					end
					P4_2:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0010)
								next_state = P4_3;
							else
								next_state = P4_Life;
						end
						else
							next_state = P4_2;
					end
					P4_3:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = P4_4;
							else
								next_state = P4_Life;
						end
						else
							next_state = P4_3;
					end
					P4_4:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = C5;
							else
								next_state = P4_Life;
						end
						else
							next_state = P4_4;
					end
					C5:
					begin
						if(counter > 31'd250000000)
							next_state = P5_1;
						else
							next_state = C5;
					end
					P5_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C5;
					end
					P5_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = P5_2;
							else
								next_state = P5_Life;
						end
						else
							next_state = P5_1;
					end
					P5_2:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0010)
								next_state = P5_3;
							else
								next_state = P5_Life;
						end
						else
							next_state = P5_2;
					end
					P5_3:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = P5_4;
							else
								next_state = P5_Life;
						end
						else
							next_state = P5_3;
					end
					P5_4:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = P5_5;
							else
								next_state = P5_Life;
						end
						else
							next_state = P5_4;
					end
					P5_5:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0100)
								next_state = C6;
							else
								next_state = P5_Life;
						end
						else
							next_state = P5_5;
					end
					C6:
					begin
						if(counter > 31'd300000000)
							next_state = P6_1;
						else
							next_state = C6;
					end
					P6_Life:
					begin
						next_state = (lives == 1)? GAMEOVER : C6;
					end
					P6_1:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = P6_2;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_1;
					end
					P6_2:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0010)
								next_state = P6_3;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_2;
					end
					P6_3:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = P6_4;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_3;
					end
					P6_4:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b1000)
								next_state = P6_5;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_4;
					end
					P6_5:
					begin
						if(player_counter1>= 31'd50000000)
						begin
							if(colour == 4'b0100)
								next_state = P6_6;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_5;
					end
					P6_6:
					begin
						if(player_counter2>= 31'd50000000)
						begin
							if(colour == 4'b0001)
								next_state = UPDATE;
							else
								next_state = P6_Life;
						end
						else
							next_state = P6_6;
					end
					UPDATE: next_state = WIN;
					default:  next_state = RESET;	
        endcase
    end
	
	// current_state registers
    always@(posedge CLOCK_50)
    begin
        if(!resetn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end
	
	always @ (posedge CLOCK_50)
	begin
		if (!resetn)
		begin
			on_1st_seg <= 1'b0;
			score <= 5'd0;
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			led <= 7'b0;
			player_led <= 2'b00;
			lives <= 5'd3;
			win_w <= 1'b0;
			lose_w <= 1'b0;
		end
		else if (current_state == P1_Life || current_state == P2_Life || current_state == P3_Life || current_state == P4_Life || current_state == P5_Life || current_state == P6_Life)
		begin
			lives <= lives - 1;
			player_counter2 <= 31'd0;
			player_counter1 <= 31'd0;
			counter <= 31'd0;
		end
		if (current_state == C1)
		begin
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led blinks
			if(counter >= 31'd25000000 && counter < 31'd49999999)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd49999999)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P1_1)
		begin
			on_1st_seg <= 1'b1;
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
		end
		else if (current_state == C2)
		begin
			score <= 5'd1;
			on_1st_seg <= 1'b0;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led blinks then 2nd led blinks
			if(counter >= 31'd25000000 && counter <= 31'd50000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd50000000 && counter <= 31'd75000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd75000000 && counter <= 31'd100000000)
			begin
				led <= 7'b0000010;
			end
			else if(counter >= 31'd100000000)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P2_1)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b1;
		end
		else if (current_state == P2_2)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == C3)
		begin
			score <= 5'd3;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led, 2nd led, 4th led
			if(counter >= 31'd25000000 && counter <= 31'd50000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd50000000 && counter <= 31'd75000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd75000000 && counter <= 31'd100000000)
			begin
				led <= 7'b0000010;
			end
			else if(counter >= 31'd100000000 && counter <= 31'd125000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd125000000 && counter <= 31'd150000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd150000000)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P3_1)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b1;
		end
		else if (current_state == P3_2)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P3_3)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == C4)
		begin
			score <= 5'd6;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led, 2nd led, 4th led, 4th led again
			if(counter >= 31'd25000000 && counter <= 31'd50000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd50000000 && counter <= 31'd75000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd75000000 && counter <= 31'd100000000)
			begin
				led <= 7'b0000010;
			end
			else if(counter >= 31'd100000000 && counter <= 31'd125000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd125000000 && counter <= 31'd150000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd150000000 && counter <= 31'd175000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd175000000 && counter <= 31'd200000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd200000000)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P4_1)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b1;
		end
		else if (current_state == P4_2)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P4_3)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P4_4)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == C5)
		begin
			score <= 5'd10;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led, 2nd led, 4th led, 4th led again, 3rd
			if(counter >= 31'd25000000 && counter <= 31'd50000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd50000000 && counter <= 31'd75000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd75000000 && counter <= 31'd100000000)
			begin
				led <= 7'b0000010;
			end
			else if(counter >= 31'd100000000 && counter <= 31'd125000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd125000000 && counter <= 31'd150000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd150000000 && counter <= 31'd175000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd175000000 && counter <= 31'd200000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd200000000 && counter <= 31'd225000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd225000000 && counter <= 31'd250000000)
			begin
				led <= 7'b0000100;
			end
			else if(counter >= 31'd250000000)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P5_1)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b1;
		end
		else if (current_state == P5_2)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P5_3)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P5_4)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P5_5)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == C6)
		begin
			score <= 5'd15;
			player_counter1 <= 31'd0;
			player_counter2 <= 31'd0;
			counter <= counter + 31'd1;
			player_led <= 2'b01;
			
			// 1st led, 2nd led, 4th led, 4th led again, 3rd, 1st
			if(counter >= 31'd25000000 && counter <= 31'd50000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd50000000 && counter <= 31'd75000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd75000000 && counter <= 31'd100000000)
			begin
				led <= 7'b0000010;
			end
			else if(counter >= 31'd100000000 && counter <= 31'd125000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd125000000 && counter <= 31'd150000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd150000000 && counter <= 31'd175000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd175000000 && counter <= 31'd200000000)
			begin
				led <= 7'b0001000;
			end
			else if(counter >= 31'd200000000 && counter <= 31'd225000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd225000000 && counter <= 31'd250000000)
			begin
				led <= 7'b0000100;
			end
			else if(counter >= 31'd250000000 && counter <= 31'd275000000)
			begin
				led <= 7'b0000000;
			end
			else if(counter >= 31'd275000000 && counter <= 31'd300000000)
			begin
				led <= 7'b0000001;
			end
			else if(counter >= 31'd300000000)
			begin
				led <= 7'b0000000;
			end
		end
		else if (current_state == P6_1)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b1;
		end
		else if (current_state == P6_2)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P6_3)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P6_4)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P6_5)
		begin
			counter <= 31'd0;
			player_counter2 <= 31'd0;
			player_counter1 <= player_counter1 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == P6_6)
		begin
			counter <= 31'd0;
			player_counter1 <= 31'd0;
			player_counter2 <= player_counter2 + 31'd1;
			player_led <= 2'b10;
			on_1st_seg <= 1'b0;
		end
		else if (current_state == UPDATE)
		begin
			score <= 5'd21;
		end
		else if (current_state == WIN)
		begin
			led[6:0] = 7'b1111111;
			if (highscore < score) begin
				highscore <= score;
			end
			win_w <= 1'b1;
		end
		else if (current_state == GAMEOVER)
		begin
			// display L
			lives <= 4'b1111;
			if (highscore < score) begin
				highscore <= score;
			end
			lose_w <= 1'b1;
		end
	end

	/* ~~~~~~~~~~~~~~~ [begin VGA stuff] ~~~~~~~~~~~~~~~~~~~~ */
	localparam SPACE = 7'd5; 			// space b/t squares
	localparam SQSIZE = 7'd20; 		// size of square
	localparam RXL = 7'd10; 			// red x coord leftside
	localparam RXR = RXL + SQSIZE; 	// red x coord rightside
	localparam RYT = 7'd30; 			// red y coord top
	localparam RYB = RYT + SQSIZE;	// red y coord bottom
	localparam BXL = RXR + SPACE;
	localparam BXR = BXL + SQSIZE;
	localparam BYT = 7'd30;
	localparam BYB = BYT + SQSIZE;
	localparam GXL = BXR + SPACE;
	localparam GXR = GXL + SQSIZE;
	localparam GYT = 7'd30;
	localparam GYB = GYT + SQSIZE;
	localparam YXL = GXR + SPACE;
	localparam YXR = YXL + SQSIZE;
	localparam YYT = 7'd30;
	localparam YYB = YYT + SQSIZE;
	localparam TOPYB = 7'd35;			// Where Colour ends and White begins

	reg [3:0] colour_on; //1000=R 0100=B 0010=G 0001=Y Note: RGB
	reg [6:0] xx = 7'b0;
	reg [6:0] yy = 7'b0; // note: actually only goes to 120 (7 bit)
	reg [14:0] position = 15'b0;

	/* colour_vga SELECT MUX using the lit led's*/
	always @(*) begin

		 if (led == 7'b0001000)
			  colour_on <= 4'b1000;
		 else if (led == 7'b0000100)
			  colour_on <= 4'b0100;
		 else if (led == 7'b0000010)
			  colour_on <= 4'b0010;
		 else if (led == 7'b0000001)
			  colour_on <= 4'b0001;
		 else
			  colour_on <= 4'b0000;
	end

	always @(posedge CLOCK_50) begin
		/* draws pixels at the upper left coordinate while the position check is shifted
			one bit at a time. Due to use of CLOCK_50, it should be drawn extremely fast*/

		// for shifting position to draw. Restarts/redraws every time the position
		// hits the "end"
		if (position == 15'b100000000000000) begin
			position <= 15'b0;
		end

		xx[6:0] <= position[13:7];
		yy[6:0] <= position[6:0];

		 // draw red square unfilled except top -> coordinates
		 // (unsure if verilog can handle compound inequalities i.e 2 < y < 7)
		 //	XL,YT	 _______  XR,YT
		 //	TOPYB	|_______|
		 //	  		|       |
		 //	  		|       |
		 //	XL,YB	|_______| XR,YB

		if ((RXL < xx) && (xx < RXR) && (RYT < yy) && (yy < TOPYB)) begin
			  colour_vga <= 3'b100;

		end else if ((RXL < xx) && (xx < RXR) && (TOPYB < yy) && (yy < RYB)) begin
			// red fill/led on 1000
			if (colour_on == 4'b1000) begin
				colour_vga <= 3'b100;
			end
			// 'red' led off
			else begin
				colour_vga <= 3'b111;
			end
		end


		// green sq
		else if ((BXL < xx) && (xx < BXR) && (BYT < yy) && (yy < TOPYB)) begin
			colour_vga <= 3'b010;

		end else if ((BXL < xx) && (xx < BXR) && (TOPYB < yy) && (yy < BYB)) begin
			// green fill/led on 0100
			if (colour_on == 4'b0100) begin
				colour_vga <= 3'b010;
			end
			// 'green' led off
			else begin
				colour_vga <= 3'b111;
			end
		end

		// blue sq
		else if ((GXL < xx) && (xx < GXR) && (GYT < yy) && (yy < TOPYB)) begin
			colour_vga <= 3'b001;

		end else if ((GXL < xx) && (xx < GXR) && (TOPYB < yy) && (yy < GYB)) begin
			if (colour_on == 4'b0010) begin
				colour_vga <= 3'b001;
			end
			else begin
				colour_vga <= 3'b111;
			end
		end

		// yellow sq
		else if ((YXL < xx) && (xx < YXR) && (YYT < yy) && (yy < TOPYB)) begin
			colour_vga <= 3'b110;
		end else if ((YXL < xx) && (xx < YXR) && (TOPYB < yy) && (yy < YYB)) begin
			if (colour_on == 4'b0001) begin
				colour_vga <= 3'b110;
			end
			else begin
				colour_vga <= 3'b111;
			end
		end

		// WIN
    if ((win_w == 1'b1) && (
      (xx == 7'd70 && yy == 7'd80) ||
      (xx == 7'd71 && yy == 7'd80) ||
      (xx == 7'd78 && yy == 7'd80) ||
      (xx == 7'd79 && yy == 7'd80) ||
      (xx == 7'd81 && yy == 7'd80) ||
      (xx == 7'd82 && yy == 7'd80) ||
      (xx == 7'd84 && yy == 7'd80) ||
      (xx == 7'd85 && yy == 7'd80) ||
      (xx == 7'd89 && yy == 7'd80) ||
      (xx == 7'd90 && yy == 7'd80) ||
      (xx == 7'd70 && yy == 7'd81) ||
      (xx == 7'd71 && yy == 7'd81) ||
      (xx == 7'd78 && yy == 7'd81) ||
      (xx == 7'd79 && yy == 7'd81) ||
      (xx == 7'd81 && yy == 7'd81) ||
      (xx == 7'd82 && yy == 7'd81) ||
      (xx == 7'd84 && yy == 7'd81) ||
      (xx == 7'd85 && yy == 7'd81) ||
      (xx == 7'd86 && yy == 7'd81) ||
      (xx == 7'd89 && yy == 7'd81) ||
      (xx == 7'd90 && yy == 7'd81) ||
      (xx == 7'd70 && yy == 7'd82) ||
      (xx == 7'd71 && yy == 7'd82) ||
      (xx == 7'd72 && yy == 7'd82) ||
      (xx == 7'd77 && yy == 7'd82) ||
      (xx == 7'd78 && yy == 7'd82) ||
      (xx == 7'd79 && yy == 7'd82) ||
      (xx == 7'd81 && yy == 7'd82) ||
      (xx == 7'd82 && yy == 7'd82) ||
      (xx == 7'd84 && yy == 7'd82) ||
      (xx == 7'd85 && yy == 7'd82) ||
      (xx == 7'd86 && yy == 7'd82) ||
      (xx == 7'd87 && yy == 7'd82) ||
      (xx == 7'd89 && yy == 7'd82) ||
      (xx == 7'd90 && yy == 7'd82) ||
      (xx == 7'd71 && yy == 7'd83) ||
      (xx == 7'd72 && yy == 7'd83) ||
      (xx == 7'd74 && yy == 7'd83) ||
      (xx == 7'd75 && yy == 7'd83) ||
      (xx == 7'd77 && yy == 7'd83) ||
      (xx == 7'd78 && yy == 7'd83) ||
      (xx == 7'd81 && yy == 7'd83) ||
      (xx == 7'd82 && yy == 7'd83) ||
      (xx == 7'd84 && yy == 7'd83) ||
      (xx == 7'd85 && yy == 7'd83) ||
      (xx == 7'd86 && yy == 7'd83) ||
      (xx == 7'd87 && yy == 7'd83) ||
      (xx == 7'd88 && yy == 7'd83) ||
      (xx == 7'd89 && yy == 7'd83) ||
      (xx == 7'd90 && yy == 7'd83) ||
      (xx == 7'd71 && yy == 7'd84) ||
      (xx == 7'd72 && yy == 7'd84) ||
      (xx == 7'd73 && yy == 7'd84) ||
      (xx == 7'd74 && yy == 7'd84) ||
      (xx == 7'd75 && yy == 7'd84) ||
      (xx == 7'd76 && yy == 7'd84) ||
      (xx == 7'd77 && yy == 7'd84) ||
      (xx == 7'd78 && yy == 7'd84) ||
      (xx == 7'd81 && yy == 7'd84) ||
      (xx == 7'd82 && yy == 7'd84) ||
      (xx == 7'd84 && yy == 7'd84) ||
      (xx == 7'd85 && yy == 7'd84) ||
      (xx == 7'd87 && yy == 7'd84) ||
      (xx == 7'd88 && yy == 7'd84) ||
      (xx == 7'd89 && yy == 7'd84) ||
      (xx == 7'd90 && yy == 7'd84) ||
      (xx == 7'd72 && yy == 7'd85) ||
      (xx == 7'd73 && yy == 7'd85) ||
      (xx == 7'd74 && yy == 7'd85) ||
      (xx == 7'd75 && yy == 7'd85) ||
      (xx == 7'd76 && yy == 7'd85) ||
      (xx == 7'd77 && yy == 7'd85) ||
      (xx == 7'd81 && yy == 7'd85) ||
      (xx == 7'd82 && yy == 7'd85) ||
      (xx == 7'd84 && yy == 7'd85) ||
      (xx == 7'd85 && yy == 7'd85) ||
      (xx == 7'd88 && yy == 7'd85) ||
      (xx == 7'd89 && yy == 7'd85) ||
      (xx == 7'd90 && yy == 7'd85) ||
      (xx == 7'd73 && yy == 7'd86) ||
      (xx == 7'd76 && yy == 7'd86) ||
      (xx == 7'd81 && yy == 7'd86) ||
      (xx == 7'd82 && yy == 7'd86) ||
      (xx == 7'd84 && yy == 7'd86) ||
      (xx == 7'd85 && yy == 7'd86) ||
      (xx == 7'd89 && yy == 7'd86) ||
      (xx == 7'd90 && yy == 7'd86) ))
      begin
         colour_vga <= 3'b011; // teal
      end
		// GG
      else if ((lose_w == 1'b1) && (
      (xx == 7'd73 && yy == 7'd80) ||
      (xx == 7'd74 && yy == 7'd80) ||
      (xx == 7'd75 && yy == 7'd80) ||
      (xx == 7'd76 && yy == 7'd80) ||
      (xx == 7'd77 && yy == 7'd80) ||
      (xx == 7'd82 && yy == 7'd80) ||
      (xx == 7'd83 && yy == 7'd80) ||
      (xx == 7'd84 && yy == 7'd80) ||
      (xx == 7'd85 && yy == 7'd80) ||
      (xx == 7'd86 && yy == 7'd80) ||
      (xx == 7'd72 && yy == 7'd81) ||
      (xx == 7'd73 && yy == 7'd81) ||
      (xx == 7'd74 && yy == 7'd81) ||
      (xx == 7'd75 && yy == 7'd81) ||
      (xx == 7'd76 && yy == 7'd81) ||
      (xx == 7'd77 && yy == 7'd81) ||
      (xx == 7'd78 && yy == 7'd81) ||
      (xx == 7'd81 && yy == 7'd81) ||
      (xx == 7'd82 && yy == 7'd81) ||
      (xx == 7'd83 && yy == 7'd81) ||
      (xx == 7'd84 && yy == 7'd81) ||
      (xx == 7'd85 && yy == 7'd81) ||
      (xx == 7'd86 && yy == 7'd81) ||
      (xx == 7'd87 && yy == 7'd81) ||
      (xx == 7'd71 && yy == 7'd82) ||
      (xx == 7'd72 && yy == 7'd82) ||
      (xx == 7'd73 && yy == 7'd82) ||
      (xx == 7'd77 && yy == 7'd82) ||
      (xx == 7'd78 && yy == 7'd82) ||
      (xx == 7'd80 && yy == 7'd82) ||
      (xx == 7'd81 && yy == 7'd82) ||
      (xx == 7'd82 && yy == 7'd82) ||
      (xx == 7'd86 && yy == 7'd82) ||
      (xx == 7'd87 && yy == 7'd82) ||
      (xx == 7'd71 && yy == 7'd83) ||
      (xx == 7'd72 && yy == 7'd83) ||
      (xx == 7'd80 && yy == 7'd83) ||
      (xx == 7'd81 && yy == 7'd83) ||
      (xx == 7'd71 && yy == 7'd84) ||
      (xx == 7'd72 && yy == 7'd84) ||
      (xx == 7'd75 && yy == 7'd84) ||
      (xx == 7'd76 && yy == 7'd84) ||
      (xx == 7'd77 && yy == 7'd84) ||
      (xx == 7'd80 && yy == 7'd84) ||
      (xx == 7'd81 && yy == 7'd84) ||
      (xx == 7'd84 && yy == 7'd84) ||
      (xx == 7'd85 && yy == 7'd84) ||
      (xx == 7'd86 && yy == 7'd84) ||
      (xx == 7'd71 && yy == 7'd85) ||
      (xx == 7'd72 && yy == 7'd85) ||
      (xx == 7'd75 && yy == 7'd85) ||
      (xx == 7'd76 && yy == 7'd85) ||
      (xx == 7'd77 && yy == 7'd85) ||
      (xx == 7'd78 && yy == 7'd85) ||
      (xx == 7'd80 && yy == 7'd85) ||
      (xx == 7'd81 && yy == 7'd85) ||
      (xx == 7'd82 && yy == 7'd85) ||
      (xx == 7'd84 && yy == 7'd85) ||
      (xx == 7'd85 && yy == 7'd85) ||
      (xx == 7'd86 && yy == 7'd85) ||
      (xx == 7'd87 && yy == 7'd85) ||
      (xx == 7'd71 && yy == 7'd86) ||
      (xx == 7'd72 && yy == 7'd86) ||
      (xx == 7'd73 && yy == 7'd86) ||
      (xx == 7'd77 && yy == 7'd86) ||
      (xx == 7'd78 && yy == 7'd86) ||
      (xx == 7'd80 && yy == 7'd86) ||
      (xx == 7'd81 && yy == 7'd86) ||
      (xx == 7'd82 && yy == 7'd86) ||
      (xx == 7'd86 && yy == 7'd86) ||
      (xx == 7'd87 && yy == 7'd86) ||
      (xx == 7'd72 && yy == 7'd87) ||
      (xx == 7'd73 && yy == 7'd87) ||
      (xx == 7'd74 && yy == 7'd87) ||
      (xx == 7'd75 && yy == 7'd87) ||
      (xx == 7'd76 && yy == 7'd87) ||
      (xx == 7'd77 && yy == 7'd87) ||
      (xx == 7'd78 && yy == 7'd87) ||
      (xx == 7'd81 && yy == 7'd87) ||
      (xx == 7'd82 && yy == 7'd87) ||
      (xx == 7'd83 && yy == 7'd87) ||
      (xx == 7'd84 && yy == 7'd87) ||
      (xx == 7'd85 && yy == 7'd87) ||
      (xx == 7'd86 && yy == 7'd87) ||
      (xx == 7'd87 && yy == 7'd87) ||
      (xx == 7'd73 && yy == 7'd88) ||
      (xx == 7'd74 && yy == 7'd88) ||
      (xx == 7'd75 && yy == 7'd88) ||
      (xx == 7'd76 && yy == 7'd88) ||
      (xx == 7'd77 && yy == 7'd88) ||
      (xx == 7'd82 && yy == 7'd88) ||
      (xx == 7'd83 && yy == 7'd88) ||
      (xx == 7'd84 && yy == 7'd88) ||
      (xx == 7'd85 && yy == 7'd88) ||
      (xx == 7'd86 && yy == 7'd88) ))
      begin
         colour_vga <= 3'b101; // magenta
      end //else begin
        //colour_vga <= 3'b000;
      //end

		// push the coordinate data out to x and y for input to the vga adapter
		x[6:0] <= xx[6:0];
		y[6:0] <= yy[6:0];

		// increment
		position <= position + 1'b1;
	end
	/* ~~~~~ end VGA stuff ~~~~~~~~ */
endmodule

module led_1sec(clk, ledr);
	input clk;
	output [5:0] ledr;
	wire [27:0] counter;
	wire clk_1hz;
	
	assign counter = 28'b0010111110101111000001111111;
	rateDivider my_1hz(counter, clk, clk_1hz);
	
	
endmodule

module rateDivider(counter, clock, clkout);
	input [27:0] counter;
	input clock;
	reg [27:0] q;
	output reg clkout;

	initial
	begin
		q <= counter;
		clkout <= 1'b0;
	end
	
	always @(posedge clock)
	begin
		if (q == 0)
			begin
				q <= counter;
				clkout <= 1'b1;
			end
		else
			begin
				clkout <= 1'b0;
				q <= q - 1'b1;
			end
	end
endmodule

module displayCounter(clock, enable, clear_b, q);
	input clock, enable, clear_b;
	output reg [3:0] q;
	wire [3:0] d;
	
	always @(posedge clock)
	begin
		if (clear_b == 1'b0)
			q <= 0;
		else if (enable == 1'b1)
			q <= q + 1'b1;
		else if (enable == 1'b0)
			q <= q;
	end
endmodule

module hex_display(IN, OUT);
   input [3:0] IN;
   output reg [6:0] OUT;
   
   always @(*)
   begin
    case(IN[3:0])
      4'b0000: OUT = 7'b1000000;
      4'b0001: OUT = 7'b1111001;
      4'b0010: OUT = 7'b0100100;
      4'b0011: OUT = 7'b0110000;
      4'b0100: OUT = 7'b0011001;
      4'b0101: OUT = 7'b0010010;
      4'b0110: OUT = 7'b0000010;
      4'b0111: OUT = 7'b1111000;
      4'b1000: OUT = 7'b0000000;
      4'b1001: OUT = 7'b0011000;
      4'b1010: OUT = 7'b0001000;
      4'b1011: OUT = 7'b0000011;
      4'b1100: OUT = 7'b1000110;
      4'b1101: OUT = 7'b0100001;
      4'b1110: OUT = 7'b0000110;
      4'b1111: OUT = 7'b0001110;
      
      default: OUT = 7'b0111111;
    endcase

  end
endmodule

// displays 0-9 for hex
module score_display(IN, OUT);
   input [4:0] IN;
   output reg [6:0] OUT;
   
   always @(*)
   begin
    case(IN[4:0])
      5'b0000: OUT = 7'b1000000;
      5'b0001: OUT = 7'b1111001;
      5'b0010: OUT = 7'b0100100;
      5'b0011: OUT = 7'b0110000;
      5'b0100: OUT = 7'b0011001;
      5'b0101: OUT = 7'b0010010;
      5'b0110: OUT = 7'b0000010;
      5'b0111: OUT = 7'b1111000;
      5'b1000: OUT = 7'b0000000;
      5'b1001: OUT = 7'b0011000;
      5'b1111: OUT = 7'b1000111; // display L
      default: OUT = 7'b0111111;
    endcase

  end
endmodule

module lfsr (out, out1, out2, out3, out4, out5);

  output [3:0] out, out1, out2, out3, out4, out5;
  wire feedback, fb1, fb2, fb3, fb4, fb5;


  assign feedback = ~(out[3] ^ out[2]);
  assign out = {out[2:0], feedback};
  
  assign fb1 = ~(out[3] ^ out[2]);
  assign out1 = {out[2:0], fb1};
  
  assign fb2 = ~(out1[3] ^ out1[2]);
  assign out2 = {out1[2:0], fb2};
  
  assign fb3 = ~(out2[3] ^ out2[2]);
  assign out3 = {out2[2:0], fb3};
  
  assign fb4 = ~(out3[3] ^ out3[2]);
  assign out4 = {out3[2:0], fb4};
  
  assign fb5 = ~(out4[3] ^ out4[2]);
  assign out5 = {out4[2:0], fb5};
  
endmodule

module mux_LUT(MuxSelect, OUT);
	input [3:0] MuxSelect;
	output reg [3:0] OUT; 

	always @(*)
	begin 
		case(MuxSelect[3:0])
		4'b0000: OUT = 4'b0001;
      4'b0001: OUT = 4'b0010;
      4'b0010: OUT = 4'b0100;
      4'b0011: OUT = 4'b1000;
      4'b0100: OUT = 4'b1000;
      4'b0101: OUT = 4'b0100;
      4'b0110: OUT = 4'b0010;
      4'b0111: OUT = 4'b0001;
      4'b1000: OUT = 4'b0100;
      4'b1001: OUT = 4'b1000;
      4'b1010: OUT = 4'b0001;
      4'b1011: OUT = 4'b0010;
      4'b1100: OUT = 4'b1000;
      4'b1101: OUT = 4'b0100;
      4'b1110: OUT = 4'b0010;
      4'b1111: OUT = 4'b0001;
      
      default: OUT = 4'b0001;
		endcase
	end
endmodule
