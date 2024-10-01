module top_level1(
    input wire CLOCK_50,
    input wire btn_resend,
    output wire led_config_finished,
	 input  wire [17:0] SW,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire VGA_BLANK,
    output wire VGA_SYNC,
    output wire VGA_CLK,
    input wire ov7670_pclk,
    output wire ov7670_xclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    output wire ov7670_sioc,
    inout wire ov7670_siod,
    output wire ov7670_pwdn,
    output wire ov7670_reset
);

// DE2-115 board has an Altera Cyclone V E, which has ALTPLL's
wire clk_50_camera;
wire clk_25_vga;
wire wren;
wire resend;
wire nBlank;
wire vSync;
wire [16:0] wraddress;
wire [11:0] wrdata;
wire [16:0] rdaddress;
wire [11:0] rddata;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;
wire activeArea;

assign VGA_R = red[7:0];
assign VGA_G = green[7:0];
assign VGA_B = blue[7:0];

my_altpll Inst_vga_pll(
    .inclk0(CLOCK_50),
    .c0(clk_50_camera),
    .c1(clk_25_vga)
);

// Take the inverted push button because KEY0 on DE2-115 board generates
// a signal 111000111; with 1 when not pressed and 0 when pressed/pushed;
assign resend = ~btn_resend;
assign VGA_VSYNC = vSync;
assign VGA_BLANK_N = nBlank;

//VGA Inst_VGA(
//    .CLK25(clk_25_vga),
//    .clkout(VGA_CLK),
//    .Hsync(VGA_HSYNC),
//    .Vsync(VGA_VSYNC),
//    .Nblank(nBlank),
//    .Nsync(VGA_SYNC_N),
//    .activeArea(activeArea)
//);

ov7670_controller Inst_ov7670_controller(
    .clk(clk_50_camera),
    .resend(resend),
    .config_finished(led_config_finished),
    .sioc(ov7670_sioc),
    .siod(ov7670_siod),
    .reset(ov7670_reset),
    .pwdn(ov7670_pwdn),
    .xclk(ov7670_xclk)
);

ov7670_capture Inst_ov7670_capture(
    .pclk(ov7670_pclk),
    .vsync(ov7670_vsync),
    .href(ov7670_href),
    .d(ov7670_data),
    .addr(wraddress),
    .dout(wrdata),
    .we(wren)
);

frame_buffer Inst_frame_buffer(
    .rdaddress(rdaddress),
    .rdclock(clk_25_vga),
    .q(rddata),
    .wrclock(ov7670_pclk),
    .wraddress(wraddress[16:0]),
    .data(wrdata),
    .wren(wren)
);

 //Uncomment the following lines if needed
// RGB Inst_RGB(
//     .Din(rddata),
//     .Nblank(activeArea),
//     .R(red),
//     .G(green),
//     .B(blue)
// );
//
// Address_Generator Inst_Address_Generator(
//     .CLK25(clk_25_vga),
//     .enable(activeArea),
//     .vsync(vSync),
//     .address(rdaddress)
// );

vga disp_stream_0 (		
    .clk_clk(CLOCK_50),
    .filter_select_filter_select(SW[0]),
    .rd_address_address(rdaddress),
    .reset_reset_n(1'b1),
    .vga_CLK(VGA_CLK),
    .vga_HS(VGA_HS),
    .vga_VS(VGA_VS),
    .vga_BLANK(VGA_BLANK),
    .vga_SYNC(VGA_SYNC),
    .vga_R(red),
    .vga_G(green),
    .vga_B(blue)
);

endmodule
