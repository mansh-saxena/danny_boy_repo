module top_level (
    input                CLOCK_50,
    output  logic        I2C_SCLK,
    inout                I2C_SDAT,
    input                AUD_ADCDAT,
    input                AUD_BCLK,
    output [6:0]         HEX0,
    output [6:0]         HEX1,
    output [6:0]         HEX2,
    output [6:0]         HEX3,
    input   [3:0]        KEY,
    output  logic        AUD_XCK,
    input                AUD_ADCLRCK,
    output  logic [17:0] LEDR,
    output wire          led_config_finished,
    output wire          vga_hsync,
    output wire          vga_vsync,
    output wire [7:0]    vga_r,
    output wire [7:0]    vga_g,
    output wire [7:0]    vga_b,
    output wire          vga_blank_N,
    output wire          vga_sync_N,
    output wire          vga_CLK,
    input wire           ov7670_pclk,
    output wire          ov7670_xclk,
    input wire           ov7670_vsync,
    input wire           ov7670_href,
    input wire [7:0]     ov7670_data,
    output wire          ov7670_sioc,
    inout wire           ov7670_siod,
    output wire          ov7670_pwdn,
    output wire          ov7670_reset,
    inout wire [7:0]     LCD_DATA,
    output wire          LCD_ON,
    output wire          LCD_BLON,
    output wire          LCD_EN,
    output wire          LCD_RS,
    output wire          LCD_RW
);
    logic [$clog2(1024)-1:0] display_value;  // Define the signal to hold the display_value from microphone_data
    integer curr_select;  // Updated to match data width

    // Instance of microphone_data
    microphone_data u_microphone_data (
        .CLOCK_50(CLOCK_50),
        .I2C_SCLK(I2C_SCLK),
        .I2C_SDAT(I2C_SDAT),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_BCLK(AUD_BCLK),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .KEY(KEY),
        .AUD_XCK(AUD_XCK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .display_value(display_value)  // Connect the output display_value to this signal
    );
    // Instance of lcd_module
	 
    lcd_module u_lcd (
        .CLOCK_50(CLOCK_50),
        .LCD_DATA(LCD_DATA),    // external_interface.DATA
        .LCD_ON(LCD_ON),        //                   .ON
        .LCD_BLON(LCD_BLON),    //                   .BLON
        .LCD_EN(LCD_EN),        //                   .EN
        .LCD_RS(LCD_RS),        //                   .RS
        .LCD_RW(LCD_RW),        //                   .RW
        .KEY(KEY),              //              reset.reset
        .curr_select(curr_select) // Connect curr_select here to top-level
    );
	always_comb begin
			 LEDR = 18'b0;  // Initialize LEDR to zero (turn off all LEDs)
			 case (curr_select)
				  2'b00: LEDR[0] = 1'b1;  // Light LEDR[0] for select 0
				  2'b01: LEDR[1] = 1'b1;  // Light LEDR[1] for select 1
				  2'b10: LEDR[2] = 1'b1;  // Light LEDR[2] for select 2
				  2'b11: LEDR[3] = 1'b1;  // Light LEDR[3] for select 3
				  default: LEDR = 18'b0;   // Turn off all LEDs
			 endcase
	end

    // Instance of convolution module
    convolution_module(
        .clk_50(CLOCK_50),
        .btn_resend(KEY[0]),
        .led_config_finished(led_config_finished),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_blank_N(vga_blank_N),
        .vga_sync_N(vga_sync_N),
        .vga_CLK(vga_CLK),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_xclk(ov7670_xclk),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_href(ov7670_href),
        .ov7670_data(ov7670_data),
        .ov7670_sioc(ov7670_sioc),
        .ov7670_siod(ov7670_siod),
        .ov7670_pwdn(ov7670_pwdn),
        .ov7670_reset(ov7670_reset),
		  .curr_select(curr_select),
		  .display_value(display_value)
    );

endmodule
