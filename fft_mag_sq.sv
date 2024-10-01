module fft_mag_sq #(
    parameter W = 16
) (
    input                clk,
    input                reset,
    input                fft_valid,
    input        [W-1:0] fft_imag,
    input        [W-1:0] fft_real,
    output logic [W*2:0] mag_sq,
    output logic         mag_valid
);

    logic signed [W*2-1:0] multiply_stage_real, multiply_stage_imag;
    logic signed [W*2:0]   add_stage;

    logic [1:0] valid_shift_reg; 
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            multiply_stage_real <= 0;
            multiply_stage_imag <= 0;
            add_stage <= 0;
            valid_shift_reg <= 0;
        end else begin
            if (fft_valid) begin
                multiply_stage_real <= signed'(fft_real) * signed'(fft_real); // Real part squared
                multiply_stage_imag <= signed'(fft_imag) * signed'(fft_imag); // Imaginary part squared
            end

            add_stage <= multiply_stage_real + multiply_stage_imag;
            valid_shift_reg <= {valid_shift_reg[0], fft_valid};
        end
    end

    assign mag_sq    = add_stage;
    assign mag_valid = valid_shift_reg[1];//TODO set to `1` when mag_sq valid **this should be 2 cycles after valid input!**
    // Hint: you can use a shift register to implement valid.

endmodule