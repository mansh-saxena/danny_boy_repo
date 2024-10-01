  `timescale 1ps/1ps
module mic_load #(parameter N=16) (
	input bclk, // Assume a 18.432 MHz clock
    input adclrc,
	input adcdat,
    // No ready signal nor handshake: as this module streams live audio data, it cannot be stalled, therefore we only have the valid signal.
    output logic valid,
    output logic [N-1:0] sample_data
);
    // Assume that i2c has already configured the CODEC for LJ data, MSB-first and N-bit samples.

    // Rising edge detect on ADCLRC to sense left channel
    logic redge_adclrc, adclrc_q; 
    always_ff @(posedge  bclk) begin : adclrc_rising_edge_ff
        adclrc_q <= adclrc;
    end
    assign redge_adclrc = ~adclrc_q & adclrc; // rising edge detected!

    logic [N-1:0] temp_rx_data;
    logic [4:0] bit_index;


    always_ff @(posedge bclk) begin
        if (redge_adclrc) begin
            // On rising edge of ADCLRC, reset bit_index and valid
            bit_index <= 5'd0;
            valid <= 0;
        end else begin
            // Sample audio data on each bit clock (BCLK)
            if (bit_index < N) begin
                temp_rx_data[(N-1) - bit_index] <= adcdat; // Capture data, MSB-first
                bit_index <= bit_index + 1;
                valid <= 0;
            end
            else if (bit_index == N) begin
                // After N bits (16 bits for audio sample), store data and assert valid signal
                sample_data <= temp_rx_data * 16'd2;
                valid <= 1;
            end
            else begin
                // Once data is valid, clear the valid signal for the next cycle
                valid <= 0;
            end
        end
    end

endmodule

