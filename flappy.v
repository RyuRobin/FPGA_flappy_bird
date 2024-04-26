`timescale 1ns / 1ps

module block_controller(
	input clk, 
	input bright,
	input rst,
	input up,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background,
	output reg [3:0] score
   );
	wire player_fill;
	wire pipe_fill;
	
	reg [9:0] xpos, ypos;
	reg signed [9:0] yvelocity;

	reg signed [9:0] yGap; // Position of the gap between the pipes
	reg signed [9:0] pipeX; // X position of the pipes
	reg signed [9:0] yGapSpeed;
	reg [1:0] state; 

	reg scored; // Flag to check whether player scored or not
	
	// List of all colors we will use
	parameter RED   = 12'b1111_0000_0000;
	parameter GREEN = 12'b0000_1111_0000;
	parameter BLUE  = 12'b0000_0000_1111;
	parameter SKY_BLUE = 12'b0110_1001_0111;
	parameter GROUND_COLOR = 12'b1001_1001_1001;
	parameter PIPE_COLOR = 12'b0011_0011_0011;
	parameter BIRD_COLOR = 12'b1111_1111_0000;

	// Dimensions for the pipes
	parameter PIPE_WIDTH = 50; // Width of the pipes
	parameter PIPE_GAP = 200; // Gap between upper and lower pipes

	// Other game parameters
	parameter GRAVITY = 1; // Gravity affecting the bird
	parameter JUMP_STRENGTH = -10; // Strength of bird's jump
	parameter PIPE_SPEED = 5; // Speed of the pipes moving left
	parameter PLAYER_HEIGHT = 20;

	
	
	always@ (*) begin
		if (~bright) 
			rgb = 12'b0000_0000_0000;
    	else if (player_fill) 
			rgb = BIRD_COLOR; 
		else if (pipe_fill)
			rgb = PIPE_COLOR;
		else
			rgb=background;
	end
		
	assign player_fill=vCount>=(ypos-10) && vCount<=(ypos+10) && hCount>=(xpos-10) && hCount<=(xpos+10);

	assign pipe_fill=hCount>=(pipeX - 25) && hCount<=(pipeX + 25) && ((vCount >= (yGap + PIPE_GAP)) || (vCount <= yGap));


	always @(posedge clk, posedge rst) begin
		if (rst) begin
			xpos <= 200; // Initial X position of the bird
			ypos <= 250; // Initial Y position of the bird
			yvelocity <= 0;
			yGap <= 350; // Initial gap between upper and lower pipes
			pipeX <= 700; // Initial X position of the pipes
			state <= 0; // Set initial game state to start
			score <= 0;
			yGapSpeed <= 0;
			scored <= 0;
		end else if (clk) begin
			// Game logic based on current game state
			case (state)
				0: begin // Start state
					xpos <= 200; // Initial X position of the bird
					ypos <= 250; // Initial Y position of the bird
					yvelocity <= 0;
					yGap <= 350; // Initial gap between upper and lower pipes
					pipeX <= 800; // Initial X position of the pipes
					yGapSpeed <= 5;
					scored <= 0;

					if (up) begin
						state <= 1; // Switch to playing state on jump
						yvelocity <= JUMP_STRENGTH; // Bird jumps on start
					end
				end
				1: begin // Playing state
					// Bird movement and gravity
					yvelocity <= yvelocity + GRAVITY;
					ypos <= ypos + yvelocity;

					// Bird jumping
					if (up) begin
						yvelocity <= JUMP_STRENGTH;
					end


					// Pipe movement
					pipeX <= pipeX - 7;

					// Check for collision with ground
					if ((ypos - 10) <= 34 || (ypos + 10) >= 514) begin
						state <= 2;
					end

					// Collision detection with pipes
					if (xpos >= (pipeX - 35)  && xpos <= (pipeX + 35) && (ypos >= (yGap + PIPE_GAP - 10) || ypos <= (yGap + 10))) begin
						state <= 2;
					end


					//This makes the gap of the pipes go up and down continuously
					if (yGap >= 480) begin
						yGapSpeed <= -7;
					end
					if (yGap <= 50) begin
						yGapSpeed <= 7;
					end
					yGap <= yGap + yGapSpeed;

					// Checking for updating score
					if ((scored==0) && (xpos >= (pipeX + 35))) begin
						scored <= 1;
						score <= score + 1;
					end
					if ((scored == 1) && (xpos <= (pipeX - 25))) begin
						scored <= 0;
					end

				end
				2: begin // Game over state
					if (up) begin
						state <= 0; // Restart game on jump
					end
				end
				default: begin
							state <= 0; // Default to start state
						end
			endcase
		end
	end


	// Make a white background
	always@(posedge clk, posedge rst) begin
		if(rst)
			background <= 12'b1111_1111_1111;
	end

	
	
endmodule
