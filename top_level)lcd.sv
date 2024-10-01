`timescale 1 ps / 1 ps
module top_level_lcd (
		input  wire       CLOCK_50,         //                clk.clk
		inout  wire [7:0] LCD_DATA,    // external_interface.DATA
		output wire       LCD_ON,      //                   .ON
		output wire       LCD_BLON,    //                   .BLON
		output wire       LCD_EN,      //                   .EN
		output wire       LCD_RS,      //                   .RS
		output wire       LCD_RW,      //                   .RW
		input  wire [3:0] KEY        //              reset.reset
	);
	 
	wire       address;     //   avalon_lcd_slave.address
	wire       chipselect;  //                   .chipselect
	wire       read;        //                   .read
	wire       write;       //                   .write
	wire [7:0] writedata;   //                   .writedata
	wire [7:0] readdata;    //                   .readdata
	wire       waitrequest; //                   .waitrequest
	wire [6:0] curr_select;
	user_interface_fsm (
		 .clk(CLOCK_50),
		 .reset(~KEY[0]),
		 .KEY1(~KEY[1]),
		 .KEY2(~KEY[2]),
		 .KEY3(~KEY[3]),
		 // Avalon-MM signals to LCD_Controller slave
		 .address(address),          // Address line for LCD controller
		 .chipselect(chipselect),
		 .byteenable(),
		 .read(),
		 .write(write),
		 .waitrequest(waitrequest),
		 .readdata(),
		 .response(),
		 .writedata(writedata),
		 .select_state(curr_select)
	);
	
	char_display u_char_display (
		.clk         (CLOCK_50),         //                clk.clk
		.reset       (~KEY[0]),       //              reset.reset
		.address     (address),     //   avalon_lcd_slave.address
		.chipselect  (chipselect),  //                   .chipselect
		.read        (read),        //                   .read
		.write       (write),       //                   .write
		.writedata   (writedata),   //                   .writedata
		.readdata    (readdata),    //                   .readdata
		.waitrequest (waitrequest), //                   .waitrequest
		.LCD_DATA    (LCD_DATA),    // external_interface.export
		.LCD_ON      (LCD_ON),      //                   .export
		.LCD_BLON    (LCD_BLON),    //                   .export
		.LCD_EN      (LCD_EN),      //                   .export
		.LCD_RS      (LCD_RS),      //                   .export
		.LCD_RW      (LCD_RW)       //                   .export
	);

endmodule
