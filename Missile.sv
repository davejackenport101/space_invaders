module missile (input enemy_shoot, player_shoot, frame_clk, hit,
					input [9:0] currX, currY, missilesize,
					output [9:0] missilex, missiley);
	logic movement, exist;
	
	always_ff @ (posedge frame_clk) begin
		if (player_shoot)
			movement <= -1;
		else if (enemy_shoot)
			movement <= 1;
		
		missiley <= (missiley + movement);
		missilex <= missilex;
		
		if (player_shoot == 1) begin
			exist <= 1;
			if (exist == 0) begin
				missilex <= currX;
				missiley <= currY;
			end
		end
		else if (enemy_shoot == 1) begin
			exist <= 1;
			missilex <= currX;
			missiley <= currY;
		end
		
		//If missile reaches top or bottom without colliding with an enemy it won't exist
		if (missiley + missilesize == 439)
			exist <= 0;
		else if (missiley == 0)
			exist <= 0;
		else if (hit)
			exist <= 0;
			
		//if the missile does not exist then place it off screen
		if (exist == 0) begin
			missilex <= 641;
			missiley <= 481;
		end
	end
					
	
endmodule
