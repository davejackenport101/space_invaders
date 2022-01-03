module  player ( input Reset, frame_clk, collision,
					input [15:0] keycode,
					output player_shoot,
					output [1:0] lives,
               output [9:0]  PlayerX, PlayerY, PlayerS);
	 //movement signals
    logic [9:0] Player_X_Pos, Player_X_Motion, Player_Y_Pos, Player_Y_Motion, Player_Size;
	 
    parameter [9:0] Player_X_Center=320;  // Center position on the X axis
    parameter [9:0] Player_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] Player_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Player_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Player_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Player_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Player_X_Step=1;      // Step size on the X axis
    parameter [9:0] Player_Y_Step=1;      // Step size on the Y axis

    assign Player_Size = 5;  // assigns the value 5 as a 10-digit binary number, ie "0000000101"
   
    always_ff @ (posedge Reset or posedge frame_clk )
    begin: Move_Player
        if (Reset)  // Asynchronous Reset
        begin 
            Player_Y_Motion <= 10'd0; //Player_Y_Step;
				Player_X_Motion <= 10'd0; //Player_X_Step;
				Player_Y_Pos <= Player_Y_Center;
				Player_X_Pos <= Player_X_Center;
				lives = 3;
				
        end
           
		  else if (collision) lives = lives - 1;
		  
        else 
        begin 
				Player_Y_Pos <= (Player_Y_Pos + Player_Y_Motion);  // Update ball position
				Player_X_Pos <= (Player_X_Pos + Player_X_Motion);
		  
				 if ( (Player_Y_Pos + Player_Size) >= Player_Y_Max )  // Ball is at the bottom edge, STOP!
					  Player_Y_Pos <= Player_Y_Max - Player_Size - 1;  
					  
				 else if ( (Player_Y_Pos - Player_Size) <= Player_Y_Min )  // Ball is at the top edge, STOP!
					  Player_Y_Pos <= Player_Size + 1;
					  
				  else if ( (Player_X_Pos + Player_Size) >= Player_X_Max )  // Ball is at the Right edge, STOP!
					  Player_X_Pos <= Player_X_Max - Player_Size - 1;  
					  
				 else if ( (Player_X_Pos - Player_Size) <= Player_X_Min )  // Ball is at the Left edge, STOP!
					  Player_X_Pos <= Player_Size + 1;
					  
				 else 
					  Player_Y_Motion <= Player_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
					  
				 
				 case (keycode)
					16'h0400 : begin
						Player_X_Motion <= -1;//Left (A)
						Player_Y_Motion<= 0;
					end
					16'h042C : begin
						Player_X_Motion <= -1;//Left+Space (A)
						Player_Y_Motion<= 0;
					end
					16'h041A : begin //Left-Up (A+W)
						Player_X_Motion <= -1;
						Player_Y_Motion <=-1;
					end
					16'h0416 : begin //Left-Down (A+S)
						Player_X_Motion <= -1;
						Player_Y_Motion <= 1;
					end
					   
						
					16'h0700 : begin
						Player_X_Motion <= 1;//Right (D)
						Player_Y_Motion <= 0;
					end
					16'h072C : begin
						Player_X_Motion <= 1;//Right+Space (D)
						Player_Y_Motion <= 0;
					end
					16'h071A : begin
						Player_X_Motion <= 1;//Right-Up (W)
						Player_Y_Motion <= -1;
					end
					16'h0716 : begin
						Player_X_Motion <= 1;//Right-Down (D+S)
						Player_Y_Motion <= 1;
					end

							  
					16'h1600 : begin
						Player_X_Motion <= 0;//Down (S)
						Player_Y_Motion <= 1;
					end
					16'h162C : begin
						Player_X_Motion <= 0;//Down+Space (S)
						Player_Y_Motion <= 1;
					end
					16'h1604 : begin
						Player_X_Motion <= -1;//Down-Left (S+A)
						Player_Y_Motion <= 1;
					end
					16'h1607 : begin
						Player_X_Motion <= 1;//Down-Right (S+D)
						Player_Y_Motion <= 1;
					end
							 
							  
					16'h1A00 : begin
						Player_X_Motion <= 0;//Up (W)
						Player_Y_Motion <= -1;
					end
					16'h1A2C : begin
						Player_X_Motion <= 0;//Up+Space (W)
						Player_Y_Motion <= -1;
					end
					16'h1A04 : begin
						Player_X_Motion <= -1;//Up-Left (W+A)
						Player_Y_Motion <= -1;
					end
					16'h1A07 : begin
						Player_X_Motion <= 1;//Up-Right (W+D)
						Player_Y_Motion <= -1;
					end
				
					
					default : begin
						Player_Y_Motion <= 0;//no recognized button being pressed, stop movement
						Player_X_Motion <= 0;
					end
						
					
			   endcase
				 
				 
      
			
		end  
	 end
	 
	 always_comb begin
			if (keycode[15:8] == 8'h2C) player_shoot = 1;
			else if (keycode[7:0] == 8'h2C) player_shoot = 1;
			else player_shoot = 0;
    end
    
    assign PlayerX = Player_X_Pos;
    assign PlayerY = Player_Y_Pos;
    assign PlayerS = Player_Size;
    

endmodule
