module spaceInvaders(input MAX10_CLK1_50, 
						input [1:0] key,
						input [9:0] SW,
						output [9:0] LEDR,
						output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
						      ///////// SDRAM /////////
						output             DRAM_CLK,
						output             DRAM_CKE,
						output   [12: 0]   DRAM_ADDR,
						output   [ 1: 0]   DRAM_BA,
						inout    [15: 0]   DRAM_DQ,
						output             DRAM_LDQM,
						output             DRAM_UDQM,
						output             DRAM_CS_N,
						output             DRAM_WE_N,
						output             DRAM_CAS_N,
						output             DRAM_RAS_N,

						///////// VGA /////////
						output             VGA_HS,
						output             VGA_VS,
						output   [ 3: 0]   VGA_R,
						output   [ 3: 0]   VGA_G,
						output   [ 3: 0]   VGA_B,


						///////// ARDUINO /////////
						inout    [15: 0]   ARDUINO_IO,
						inout              ARDUINO_RESET_N 
						);

//================================================================================================
// NIOS II CPU
//================================================================================================

// Register/wire declarations and assignments
	logic Reset_h, SPI0_CS_N, SPI0_SCLK, SPI0_MISO, SPI0_MOSI, USB_GPX, USB_IRQ, USB_RST;
	logic [1:0] signs, hundreds;
	logic [3:0] hex_num_3, hex_num_2, hex_num_1, hex_num_0; //4 bit input hex digits
	logic [15:0] keycode; //[15:8] are keycode0, [7:0] are keycode1
		
	always_comb begin
		ARDUINO_IO[10] = SPI0_CS_N;
		ARDUINO_IO[13] = SPI0_SCLK;
		ARDUINO_IO[11] = SPI0_MOSI;
		ARDUINO_IO[12] = 1'bZ;
		SPI0_MISO = ARDUINO_IO[12];
		
		ARDUINO_IO[9] = 1'bZ; 
		USB_IRQ = ARDUINO_IO[9];
		
		//Assignments specific to Circuits At Home UHS_20
		ARDUINO_RESET_N = USB_RST;
		ARDUINO_IO[7] = USB_RST;//USB reset 
		ARDUINO_IO[8] = 1'bZ; //this is GPX (set to input)
		USB_GPX = 1'b0;//GPX is not needed for standard USB host - set to 0 to prevent interrupt
		
		//Assign uSD CS to '1' to prevent uSD card from interfering with USB Host (if uSD card is plugged in)
		ARDUINO_IO[6] = 1'b1;
	
		//HEX drivers to convert numbers to HEX output
		HEX3[7] = 1'b1;
		HEX2[7] = 1'b1;
		HEX1[7] = 1'b1;
		HEX0[7] = 1'b1;
	
		//fill in the hundreds digit as well as the negative sign
		HEX5 = {1'b1, ~signs[1], 3'b111, ~hundreds[1], ~hundreds[1], 1'b1};
		HEX4 = {1'b1, ~signs[0], 3'b111, ~hundreds[0], ~hundreds[0], 1'b1};
	
		//Assign reset button to active high
		{Reset_h}=~ (key[0]);
	end
		
// module declarations
// ---Hex Drivers---
	HexDriver hex_driver0 (hex_num_0, HEX0[6:0]);
	HexDriver hex_driver1 (hex_num_1, HEX1[6:0]);
	HexDriver hex_driver2 (hex_num_2, HEX2[6:0]);
	HexDriver hex_driver3 (hex_num_3, HEX3[6:0]);
	
// ---NIOS II---
	spaceInvaders_soc soc0 (
		.clk_clk                           (MAX10_CLK1_50),  //clk.clk
		.reset_reset_n                     (1'b1),           //reset.reset_n
		.altpll_0_locked_conduit_export    (),               //altpll_0_locked_conduit.export
		.altpll_0_phasedone_conduit_export (),               //altpll_0_phasedone_conduit.export
		.altpll_0_areset_conduit_export    (),               //altpll_0_areset_conduit.export
		.key_external_connection_export    (key),            //key_external_connection.export
		
		//USB SPI	
		.spi0_SS_n(SPI0_CS_N),
		.spi0_MOSI(SPI0_MOSI),
		.spi0_MISO(SPI0_MISO),
		.spi0_SCLK(SPI0_SCLK),
		
		//USB GPIO
		.usb_rst_export(USB_RST),
		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		
		//LEDs and HEX
		.hex_digits_export({hex_num_3, hex_num_2, hex_num_1, hex_num_0}),
		.leds_export({hundreds, signs, LEDR}),
		.keycode_export(keycode)
	 );
	
//================================================================================================
// RGB, VGA, and SDRAM Controllers (Operates at 50 MHz (Max10_CLK1_50) )
//================================================================================================
	
// Wire declarations and assignments
	logic RE, WE, BUS_ACK, blank, sync, VGA_Clk;
	logic [3:0] Red, Blue, Green;
	logic [9:0] drawxsig, drawysig; 
	logic [15:0] read_data, write_data;
	logic [25:0] ADDR;
	
	always_comb begin
		
		VGA_R = read_data[11:8];
		VGA_G = read_data[7:4];
		VGA_B = read_data[3:0];
		
		
		/*
		VGA_R = Red;
		VGA_G = Green;
		VGA_B = Blue;
		*/
		
		write_data[15:12] = 4'h0;
		write_data[11:8] = Red;
		write_data[7:4] = Green;
		write_data[3:0] = Blue;
	end
	
// Module declarations
// ---SDRAM---
	spaceInvaders_sdram sdram (
		.clk_clk					(MAX10_CLK1_50),
		.reset_reset_n			(1'b1),
		
		// External Bus to SDRAM
		.ext_bus_address		(ADDR),
		.ext_bus_byte_enable	(2'b11),
		.ext_bus_read			(RE),
		.ext_bus_write			(WE),
		.ext_bus_acknowledge	(BUS_ACK),
		.ext_bus_read_data	(read_data),
		.ext_bus_write_data	(write_data),
		
		// SDRAM
		.sdram_clk_clk			(DRAM_CLK),               //clk_sdram.clk
		.sdram_wire_addr		(DRAM_ADDR),              //sdram_wire.addr
		.sdram_wire_ba			(DRAM_BA),                //.ba
		.sdram_wire_cas_n		(DRAM_CAS_N),             //.cas_n
		.sdram_wire_cke		(DRAM_CKE),               //.cke
		.sdram_wire_cs_n		(DRAM_CS_N),              //.cs_n
		.sdram_wire_dq			(DRAM_DQ),                //.dq
		.sdram_wire_dqm		({DRAM_UDQM,DRAM_LDQM}),  //.dqm
		.sdram_wire_ras_n		(DRAM_RAS_N),             //.ras_n
		.sdram_wire_we_n		(DRAM_WE_N)               //.we_n
		);
		
// ---SDRAM Controller---
	sdram_controller sdram_ctrl(
		.clk		(MAX10_CLK1_50), 
		.vsync	(VGA_VS), 
		.Reset	(Reset_h), 
		.drawxsig,
		.drawysig,
		.RE,
		.WE,
		.ADDR
		);
	
// ---VGA Controller---
	vga_controller vga(
		.Clk			(MAX10_CLK1_50), 
		.Reset		(Reset_h), 
		.hs			(VGA_HS), 
		.vs			(VGA_VS), 
		.pixel_clk	(VGA_Clk), 
		.blank		(blank), 
		.sync			(sync), 
		.DrawX		(drawxsig), 
		.DrawY		(drawysig)
		);
				 
// ---Color Mapper---
	color_mapper color (
		.PlayerX(playerxsig), 
		.PlayerY(playerysig), 
		.DrawX(drawxsig), 
		.DrawY(drawysig), 
		.Player_size(playersizesig), 
		.Red,
		.Green,
		.Blue
		);

//================================================================================================
// Game Logic (Operates at 60 Hz (vsync) )
//================================================================================================
	
// Game wire declarations
	logic player_shoot, player_hit_enemy, enemy_hit_player, reset_characters, spawn;
	logic [1:0] lives;
	logic [9:0] playerxsig, playerysig, playersizesig, playermissilex, playermissiley, missilesize, enemysize;
	
	logic	[9:0] enemy1_1x, enemy1_2x, enemy1_3x, enemy1_4x, enemy1_5x, enemy1_6x, enemy1_7x, enemy1_8x, enemy1_9x, enemy1_10x;
	logic [9:0] enemy1_11x, enemy1_12x, enemy1_13x, enemy1_14x, enemy1_15x, enemy1_16x, enemy1_17x, enemy1_18x, enemy1_19x, enemy1_20x;
	logic	[9:0] enemy1_1y, enemy1_2y, enemy1_3y, enemy1_4y, enemy1_5y, enemy1_6y, enemy1_7y, enemy1_8y, enemy1_9y, enemy1_10y;
	logic [9:0] enemy1_11y, enemy1_12y, enemy1_13y, enemy1_14y, enemy1_15y, enemy1_16y, enemy1_17y, enemy1_18y, enemy1_19y, enemy1_20y;
	logic collision, collision1, collision2, collision3, collision4, collision5, collision6, collision7, collision8, collision9, collision10;
	logic collision11, collision12, collision13, collision14, collision15, collision16, collision17, collision18, collision19, collision20;	
	always_comb begin
		if (collision1 || collision2 || collision3 || collision4 || collision5 || collision6 || collision7 || collision8 || collision9 || collision10 || 
			collision11 || collision12 || collision13 || collision14 || collision15 || collision16 || collision17 || collision18 || collision19 || collision20)
				collision = 1;
		else
				collision = 0;
	
		missilesize = 10'h010;
		enemysize = 10'h010;
	end
	
// Module declarations
// ---Game State Machine---
	game_state GSM (
		.clk(VGA_VS),
		.Reset(Reset_h),
		.lives ,
		.keycode,
		.reset_characters,
		.spawn
		);
	
// ---Player Object---
	player main_char (
		.Reset(reset_characters), 
		.frame_clk(VGA_VS), 
		.keycode(keycode), 
		.player_shoot,
		.PlayerX(playerxsig), 
		.PlayerY(playerysig), 
		.PlayerS(playersizesig)
		);
	
// ---Player Missile---
	missile player_missile (
		.frame_clk		(VGA_VS),
		.player_shoot,
		.enemy_shoot	(1'b0),
		.hit				(player_hit_enemy),
		.currX			(playerxsig),
		.currY			(playerysig),
		.missilex		(playermissilex),
		.missiley		(playermissiley),
		.missilesize
		);
	
// ---Type 1 Enemy Object #1/20---
	enemy1 enemy1_1 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_1x),
		.enemyy(enemy1_1y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #2/20---
	enemy1 enemy1_2 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_2x),
		.enemyy(enemy1_2y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #3/20---
	enemy1 enemy1_3 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_3x),
		.enemyy(enemy1_3y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #4/20---
	enemy1 enemy1_4 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_4x),
		.enemyy(enemy1_4y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #5/20---
	enemy1 enemy1_5 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_5x),
		.enemyy(enemy1_5y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #6/20---
	enemy1 enemy1_6 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_6x),
		.enemyy(enemy1_6y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #7/20---
	enemy1 enemy1_7 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_7x),
		.enemyy(enemy1_7y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #8/20---
	enemy1 enemy1_8 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_8x),
		.enemyy(enemy1_8y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #9/20---
	enemy1 enemy1_9 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_9x),
		.enemyy(enemy1_9y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #10/20---
	enemy1 enemy1_10 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_10x),
		.enemyy(enemy1_10y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #11/20---
	enemy1 enemy1_11 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_11x),
		.enemyy(enemy1_11y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #12/20---
	enemy1 enemy1_12 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_12x),
		.enemyy(enemy1_12y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #13/20---
	enemy1 enemy1_13 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_13x),
		.enemyy(enemy1_13y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #14/20---
	enemy1 enemy1_14 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_14x),
		.enemyy(enemy1_14y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #15/20---
	enemy1 enemy1_15 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_15x),
		.enemyy(enemy1_15y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #16/20---
	enemy1 enemy1_16 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_16x),
		.enemyy(enemy1_16y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #17/20---
	enemy1 enemy1_17 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_17x),
		.enemyy(enemy1_17y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #18/20---
	enemy1 enemy1_18 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_18x),
		.enemyy(enemy1_18y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #19/20---
	enemy1 enemy1_19 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_19x),
		.enemyy(enemy1_19y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig
		);
		
// ---Type 1 Enemy Object #20/20---
	enemy1 enemy1_20 (
		.frame_clk(VGA_VS),
		.Reset(reset_characters),
		.spawn,
		.enemysize,
		.enemyxstart(10'h010),
		.enemyystart(10'h010),
		.enemyx(enemy1_20x),
		.enemyy(enemy1_20y),
		.missilex(player_missilex),
		.missiley(player_missiley),
		.missilesize,
		.playerxsig,
		.playerysig 
		);
		
endmodule
						