module top_level (
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
    output  logic [17:0] LEDR
);
   localparam W        = 16;   //NOTE: To change this, you must also change the Twiddle factor initialisations in r22sdf/Twiddle.v. You can use r22sdf/twiddle_gen.pl.
   localparam NSamples = 1024; //NOTE: To change this, you must also change the SdfUnit instantiations in r22sdf/FFT.v accordingly.

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
//    // Handshake logic and connection of microphone data to FIR filter input
//    assign audio_input.data = data;  // Input microphone data into the FIR filter
//    assign audio_input.valid = 1'b1; // Assume the input data is always valid
//    assign pitch_output.ready = 1'b1; // Assume the output is always ready to receive data
		
//    // Handling FIR filter output
//    always_ff @(posedge CLOCK_50) begin
//        if (y_stream.valid) begin
//            // Threshold to consider the output significant (indicating talking)
//            logic [15:0] threshold = 16'd100;  // Adjust the threshold as needed
//            
//            // Compute the absolute value (magnitude) of y_stream.data
//            logic [15:0] abs_y_data;
//            if (y_stream.data[15])  // If the result is negative (2's complement)
//                abs_y_data = ~y_stream.data[15:0] + 1;  // Convert negative to magnitude
//            else
//                abs_y_data = y_stream.data[15:0];  // Direct positive value
//
//            // Light up the LEDs when the magnitude is above the threshold (indicating talking)
//            if (abs_y_data >= threshold) begin
//                LEDR[15:0] <= 16'hFFFF;  // Turn on all LEDs
//            end else begin
//                LEDR[15:0] <= 16'h0000;  // Turn off LEDs
//            end
//        end
//    end
	display u_display (.clk(adc_clk),.value(pitch_output.data),.display0(HEX0),.display1(HEX1),.display2(HEX2),.display3(HEX3));

endmodule
