module sdram_controller (input clk, vsync, Reset,
								input [9:0] drawxsig, drawysig,
								output RE, WE, 
								output [25:0] ADDR);
	logic rw, mem_select, rw_temp, mem_select_temp;
	assign rw_temp = ~(rw);
	assign mem_select_temp = ~(mem_select);
		
	initial begin : mem_select_init
		RE = 0;
		WE = 0;
		rw = 0;
		mem_select = 0;
	end
	
	
	always_comb begin
		ADDR[18:0] = (drawxsig + drawysig*640);
		ADDR[25:20] = 7'h00;
		
		
	end
	
	//alternate which registers we are reading and writing from everytime we finish a frame
	always_ff @ (posedge clk or posedge vsync) 
	begin
	//ensure we are never reading/writing the same VRAM at once 
		//else if (vsync) mem_select <= ~ (mem_select);
		if (vsync)
			mem_select <= mem_select_temp;
		if (clk)
		begin
			rw <= rw_temp;
			if (rw == 1) begin
				ADDR[19] <= ~(mem_select);
				RE <= 0;
				WE <= 1;
			end
			else begin
				ADDR[19] <= mem_select;
				WE <= 0;
				RE <= 1;
			end
		end
			
	end 
	
endmodule
