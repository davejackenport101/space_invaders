//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//                                                                       --
//    Fall 2014 Distribution                                             --
//                                                                       --
//    For use with ECE 385 Lab 7                                         --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module  color_mapper ( input        [9:0] PlayerX, PlayerY, DrawX, DrawY, Player_size,
                       output logic [3:0]  Red, Green, Blue );
    
    logic player_on;
	 
 /* Old Ball: Generated square box by checking if the current pixel is within a square of length
    2*Ball_Size, centered at (BallX, BallY).  Note that this requires unsigned comparisons.
	 
    if ((DrawX >= BallX - Ball_size) &&
       (DrawX <= BallX + Ball_size) &&
       (DrawY >= BallY - Ball_size) &&
       (DrawY <= BallY + Ball_size))
		 
	Circle Ball:
		assign Size = Player_size;
		
		if ( ( DistX*DistX + DistY*DistY) <= (Size * Size) )

     New Ball: Generates (pixelated) circle by using the standard circle formula.  Note that while 
     this single line is quite powerful descriptively, it causes the synthesis tool to use up three
     of the 12 available multipliers on the chip!  Since the multiplicants are required to be signed,
	  we have to first cast them from logic to int (signed by default) before they are multiplied). */
		//int DistX, DistY, Size;
		//assign DistX = DrawX - PlayerX;
		//assign DistY = DrawY - PlayerY;
    
	 
    always_comb
    begin:Player_on_proc
        if	((DrawX >= 100) &&
				(DrawX <= 200) &&
				(DrawY >= 100) &&
				(DrawY <= 200))
				
            player_on = 1'b1;
        else 
            player_on = 1'b0;
     end 
       
    always_comb
    begin:RGB_Display
        if ((player_on == 1'b1)) 
        begin 
            Red = 4'h0;
            Green = 'hf;
            Blue = 4'h0;
        end   
		  
        else 
        begin 
            Red = 4'hf; 
            Green = 4'h0;
            Blue = 4'h0;
        end      
    end 
    
endmodule
