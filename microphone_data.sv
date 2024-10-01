module microphone_data (
    input                CLOCK_50,
    output  logic        I2C_SCLK,
    inout                I2C_SDAT,
    input                AUD_ADCDAT,
    input                AUD_BCLK,
	 output 					[6:0] HEX0,
	 output 					[6:0] HEX1,
	 output 					[6:0] HEX2,
	 output 					[6:0] HEX3,
	 input  					[3:0] KEY,
    output  logic        AUD_XCK,
    input                AUD_ADCLRCK,
    output  logic [17:0] LEDR,
    output  logic  [$clog2(NSamples)-1:0] display_value  // Output to send display_value
);

   localparam W        = 16;   //NOTE: To change this, you must also change the Twiddle factor initialisations in r22sdf/Twiddle.v.
   localparam NSamples = 1024; //NOTE: To change this, you must also change the SdfUnit instantiations in r22sdf/FFT.v.

    // Clock generation for audio codec and I2C
    logic adc_clk;  // Declare clock signal
    adc_pll adc_pll_u ( 
        .areset(1'b0), 
        .inclk0(CLOCK_50), 
        .c0(adc_clk)
    );  // Instantiate PLL for 18.432 MHz clock

    logic i2c_clk;  // Declare I2C clock signal
    i2c_pll i2c_pll_u ( 
        .areset(1'b0), 
        .inclk0(CLOCK_50), 
        .c0(i2c_clk)
    );  // Instantiate PLL for 20 kHz clock

    // I2C interface to set up audio codec
    set_audio_encoder set_codec_u (
        .i2c_clk(i2c_clk), 
        .I2C_SCLK(I2C_SCLK), 
        .I2C_SDAT(I2C_SDAT)
    );
        
    // Microphone input data capture
	dstream #(.N(W))                audio_input ();
   dstream #(.N($clog2(NSamples))) pitch_output ();
    
	mic_load #(.N(W)) u_mic_load (
    .adclrc(AUD_ADCLRCK),
	 .bclk(AUD_BCLK),
	 .adcdat(AUD_ADCDAT),
    .sample_data(audio_input.data),
	 .valid(audio_input.valid)
   );
    
	assign AUD_XCK = adc_clk;
	
   fft_pitch_detect #(.W(W), .NSamples(NSamples)) DUT (
	    .clk(adc_clk),
		 .audio_clk(AUD_BCLK),
		 .reset(~KEY[0]),
		 .audio_input(audio_input),
		 .pitch_output(pitch_output)
    );
	
	always_ff @(posedge adc_clk) begin
		if (pitch_output.valid) display_value <= pitch_output.data;  // Assign value to output
	end

	display u_display (.clk(adc_clk),.value(display_value),.display0(HEX0),.display1(HEX1),.display2(HEX2),.display3(HEX3));

endmodule
