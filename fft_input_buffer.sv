module fft_input_buffer #(
    parameter W = 16,
    parameter NSamples = 1024
) (
    input                clk,
     input                reset,
     input                audio_clk,
     dstream.in           audio_input,
     output logic [W-1:0] fft_input,
     output logic         fft_input_valid
);
    logic fft_read;
    logic [10:0] sample_counter;
    logic full, wr_full;
    async_fifo u_fifo (.aclr(reset),
                        .data(audio_input.data),.wrclk(audio_clk),.wrreq(audio_input.valid),.wrfull(wr_full),
                        .q(fft_input),          .rdclk(clk),      .rdreq(fft_read),         .rdfull(full)    );
    assign audio_input.ready = !wr_full;

    assign fft_input_valid = fft_read; // The Async FIFO is set such that valid data is read out whenever the rdreq flag is high.
    
    always_ff @(posedge clk or posedge reset) begin : fifo_flush
        if (reset) begin
            sample_counter <= 0;
            fft_read <= 0;
        end else begin
            if (full && !fft_read) begin
                fft_read <= 1;
                sample_counter <= 0;
            end

            if (fft_read) begin
                if (sample_counter < NSamples - 1) begin
                    sample_counter <= sample_counter + 1;
                end else begin
                    fft_read <= 0;
                end
            end
        end
    end

endmodule