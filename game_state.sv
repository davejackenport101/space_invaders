//======================================================================================================================
// State machine that handles game starting and ending
//======================================================================================================================
module game_state (input clk, Reset,
						input [1:0] lives,
						input [15:0] keycode,
						output spawn, reset_characters);

//======================================================================================================================
// Initialize control signals and handle state transitions with the clock here
//======================================================================================================================
	logic start;
	enum logic [1:0] {start_screen, in_game, end_screen} state, next_state;
	
	always_ff @ (posedge clk or posedge Reset) 
	begin
		if (Reset) 
			state <= start_screen;
		else
			state <= next_state;
	end
	
//======================================================================================================================
//assign state transitions and default control signal values here
//======================================================================================================================
	always_comb begin
		//default next_state to be current state
		next_state = state;	
		
		//assign next_state based on conditions
		unique case (state) 
			start_screen :
				if (start)
					next_state = in_game;

			in_game :
				if (lives == 2'b00)
					next_state = end_screen;

			end_screen :
				if (start)
					next_state = start_screen;
		endcase
	end
	
//======================================================================================================================
// assign control signals depending on current state here
//======================================================================================================================
	always_comb begin
		//default control signal values
		start = 0;
		spawn = 0;
		reset_characters = 0;
		
		case (state)
			start_screen :
			begin
				reset_characters = 1;
				if (keycode[15:8] == 8'h28 || keycode[7:0] == 8'h28)
					start = 0;
			end
			
			in_game :
			begin
				spawn = 1;
			end
			
			end_screen :
			begin
				reset_characters = 1;
			end
				
		endcase
	end

endmodule
