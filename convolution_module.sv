module convolution_module(
input wire clk_50,
input wire btn_resend,
output wire led_config_finished,
output wire vga_hsync,
output wire vga_vsync,
output wire [7:0] vga_r,
output wire [7:0] vga_g,
output wire [7:0] vga_b,
output wire vga_blank_N,
output wire vga_sync_N,
output wire vga_CLK,
input wire ov7670_pclk,
output wire ov7670_xclk,
output  logic [17:0] LEDR,
input wire ov7670_vsync,
input wire ov7670_href,
input wire [7:0] ov7670_data,
output wire ov7670_sioc,
inout wire ov7670_siod,
output wire ov7670_pwdn,
output wire ov7670_reset,
input integer curr_select,
input logic [$clog2(1024)-1:0] display_value
);




// DE2-115 board has an Altera Cyclone V E, which has ALTPLL's'
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
wire [7:0] red; wire [7:0] green; wire [7:0] blue;
wire activeArea;

//  assign vga_r = red[7:0];;
//  assign vga_g = green[7:0];
//  assign vga_b = 8'hffff;
  my_altpll Inst_vga_pll(
      .inclk0(clk_50),
    .c0(clk_50_camera),
    .c1(clk_25_vga));

  // take the inverted push button because KEY0 on DE2-115 board generates
  // a signal 111000111; with 1 with not pressed and 0 when pressed/pushed;
  assign resend =  ~btn_resend;
//  assign vga_vsync = vSync;
//  assign vga_blank_N = nBlank;
//  VGA Inst_VGA(
//      .CLK25(clk_25_vga),
//    .clkout(vga_CLK),
//    .Hsync(vga_hsync),
//    .Vsync(vSync),
//    .Nblank(nBlank),
//    .Nsync(vga_sync_N),
//    .activeArea(activeArea));
//	always_comb begin
//			 LEDR = 18'b0;  // Initialize LEDR to zero (turn off all LEDs)
//			 case (curr_select)
//				  2'b00: LEDR[0] = 1'b1;  // Light LEDR[0] for select 0
//				  2'b01: LEDR[1] = 1'b1;  // Light LEDR[1] for select 1
//				  2'b10: LEDR[2] = 1'b1;  // Light LEDR[2] for select 2
//				  2'b11: LEDR[3] = 1'b1;  // Light LEDR[3] for select 3
//				  default: LEDR = 18'b0;   // Turn off all LEDs
//			 endcase
//	end

  ov7670_controller Inst_ov7670_controller(
      .clk(clk_50_camera),
    .resend(resend),
    .config_finished(led_config_finished),
    .sioc(ov7670_sioc),
    .siod(ov7670_siod),
    .reset(ov7670_reset),
    .pwdn(ov7670_pwdn),
    .xclk(ov7670_xclk));

  ov7670_capture Inst_ov7670_capture(
      .pclk(ov7670_pclk),
    .vsync(ov7670_vsync),
    .href(ov7670_href),
    .d(ov7670_data),
    .addr(wraddress),
    .dout(wrdata),
    .we(wren));

  frame_buffer Inst_frame_buffer(
      .rdaddress(rdaddress),
    .rdclock(clk_25_vga),
    .q(rddata),
    .wrclock(ov7670_pclk),
    .wraddress(wraddress[16:0]),
    .data(wrdata),
    .wren(wren));
//
//  RGB Inst_RGB(
//      .Din(rddata),
//    .Nblank(activeArea),
//    .R(red),
//    .G(green),
//    .B(blue));
//
//  Address_Generator Inst_Address_Generator(
//      .CLK25(clk_25_vga),
//    .enable(activeArea),
//    .vsync(vSync),
//    .address(rdaddress));
	integer row = 0;
	integer col = 0;
	integer row_old = 0; 
	integer col_old = 0;
	logic [30:0] vga_data;
	logic vga_ready,vga_start,vga_end;
	always @(posedge clk_25_vga) begin
		if (resend) begin
			col <= 0; row <= 0;
		end else if (vga_ready) begin
			if (col>=319) begin
				 col<=0;
				 if (row>=239) row<=0;
				 else row<=row+1;
			end else col<=col+1;
			row_old<=row;
			col_old<=col;
		end
	end
		
	always @(*) begin
		if (col_old == 0 && row_old == 0) vga_start = 1;
		else vga_start = 0;
		
		if (col_old == 319 && row_old ==239) vga_end = 1;
		else vga_end = 0;
		
		rdaddress = row*320+col;
	end
		
	logic sink_valid;
	assign sink_valid = 1'b1; 
	
	 localparam W = 32;
    localparam W_FRAC = 16;
	 localparam WIDTH = 640;
	 localparam HEIGHT = 480;
	 localparam K = 5; 
	 
dstream #(.N(W)) x_r ();
dstream #(.N(W)) y_r ();
	 
dstream #(.N(W)) x_g ();
dstream #(.N(W)) y_g ();
	 
dstream #(.N(W)) x_b ();
dstream #(.N(W)) y_b ();

	 assign x_r.valid = 1'b1;
	 assign x_g.valid = 1'b1;
	 assign x_b.valid = 1'b1;
	 
	 assign y_r.ready = vga_ready;
	 assign y_g.ready = vga_ready;
	 assign y_b.ready = vga_ready;

	 
assign x_r.data = {rddata[11:8], 16'b0};  // Output data should be accessed via modport out
assign x_g.data = {rddata[7:4], 16'b0};
assign x_b.data = {rddata[3:0], 16'b0};
//
always @(*) begin
    vga_data = {
        {y_r.data[19:16], y_r.data[19:16], 2'b00},  // Red channel: Top 4 bits, repeated, 2 zeros
        {y_g.data[19:16], y_g.data[19:16], 2'b00},  // Green channel: Top 4 bits, repeated, 2 zeros
        {y_b.data[19:16], y_b.data[19:16], 2'b00}   // Blue channel: Top 4 bits, repeated, 2 zeros
    };
end


//always @(*) begin
//    vga_data = {
//        {(y_r.data >> 8), (y_r.data >> 8), 2'b00},  // Right shift by 8 bits (division by 256)
//        {(y_g.data >> 8), (y_g.data >> 8), 2'b00},  // Right shift by 8 bits (division by 256)
//        {(y_b.data >> 8), (y_b.data >> 8), 2'b00}   // Right shift by 8 bits (division by 256)
//    };
//end



//always @(*) begin
//    vga_data = {
//        8'b11111111, 2'b00, // Full intensity for red (10 bits)
//        8'b11111111, 2'b00, // Full intensity for green (10 bits)
//        8'b11111111, 2'b00   // Full intensity for blue (10 bits)
//    };
//end

	convolutionv3 #(
        .W(W), 
        .W_FRAC(W_FRAC),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .K(K)
    ) convolution_r (
        .clk(clk_25_vga),
		  .filt_select(curr_select),
		  .display_value(display_value),
        .x(x_r),  // Input stream
        .y(y_r),  // Output stream
    );

	 convolutionv3 #(
        .W(W), 
        .W_FRAC(W_FRAC),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .K(K)
    ) convolution_g (
        .clk(clk_25_vga),
		  .filt_select(curr_select),
		  .display_value(display_value),

        .x(x_g),  // Input stream
        .y(y_g),  // Output stream
    );
	 
	 convolutionv3 #(
        .W(W), 
        .W_FRAC(W_FRAC),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .K(K)
    ) convolution_b (
        .clk(clk_25_vga),
		  .filt_select(curr_select),
		  .display_value(display_value),

        .x(x_b),  // Input stream
        .y(y_b),  // Output stream
    );
	 
	 
VGAoutput vgaoutput_u0(
		.clk_clk(clk_25_vga),                                         //                                       clk.clk
		.reset_reset_n(btn_resend),                                   //                                     reset.reset_n
		.video_scaler_0_avalon_scaler_sink_startofpacket(vga_start), //         video_scaler_0_avalon_scaler_sink.startofpacket
		.video_scaler_0_avalon_scaler_sink_endofpacket(vga_end),   //                                          .endofpacket
		.video_scaler_0_avalon_scaler_sink_valid(sink_valid),         //                                          .valid
		.video_scaler_0_avalon_scaler_sink_ready(vga_ready),         //                                          .ready
		.video_scaler_0_avalon_scaler_sink_data(vga_data),          //                                          .data
		.video_vga_controller_0_external_interface_CLK(vga_CLK),   // video_vga_controller_0_external_interface.CLK
		.video_vga_controller_0_external_interface_HS(vga_hsync),    //                                          .HS
		.video_vga_controller_0_external_interface_VS(vga_vsync),    //                                          .VS
		.video_vga_controller_0_external_interface_BLANK(vga_blank_N), //                                          .BLANK
		.video_vga_controller_0_external_interface_SYNC(vga_sync_N),  //                                          .SYNC
		.video_vga_controller_0_external_interface_R(vga_r),     //                                          .R
		.video_vga_controller_0_external_interface_G(vga_g),     //                                          .G
		.video_vga_controller_0_external_interface_B(vga_b)      //                                          .B
	);


endmodule