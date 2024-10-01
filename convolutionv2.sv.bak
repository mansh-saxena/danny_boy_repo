module convolutionv2 #(
    parameter int W = 32, 
    parameter W_FRAC = 16,
    parameter WIDTH = 640,
    parameter HEIGHT = 480,
    parameter K = 5
)(		
    input clk,
    dstream.in x,
    dstream.out y
);

logic signed [W-1:0] kernel [0:K-1][0:K-1];

initial begin
    kernel = '{
        '{32'h00000100, 32'h00000400, 32'h00000600, 32'h00000400, 32'h00000100},
        '{32'h00000400, 32'h00001000, 32'h00001800, 32'h00001000, 32'h00000400},
        '{32'h00000600, 32'h00001800, 32'h00002400, 32'h00001800, 32'h00000600},
        '{32'h00000400, 32'h00001000, 32'h00001800, 32'h00001000, 32'h00000400},
        '{32'h00000100, 32'h00000400, 32'h00000600, 32'h00000400, 32'h00000100}
    };
end

// need to deal with the ready bit of the vga

    // Assign x.ready: we are ready for data if the module we output to (y.ready) is ready (this module does not exert backpressure).
    assign x.ready = y.ready;

    // 1D shift_register for shifting in new data from x. Think of it as K shift registers of width WIDTH (one for each line) flattened into a 1D array
    logic signed [W-1:0] shift_reg [0:K*WIDTH-1];
    always_ff @(posedge clk) begin : h_shift_register
        // On a handshake (x.valid & x.ready), shift signed'(x.data) into shift_reg and shift everything.
        for (int i=1; i<K*WIDTH; i=i+1) begin
            shift_reg[i] <= shift_reg[i-1];
        end
        shift_reg[0] <= signed'(x.data);
    end

    // Get the rising edge of x.valid to signal the beginning of a new frame
    logic re_x_valid;
    logic x_valid_q; // Delay x.valid by 1 clock cycle
    always_ff @(posedge clk) begin : rising_edge_x_valid
        x_valid_q <= x.valid;
    end
	 
    assign re_x_valid = x.valid & (~x_valid_q);


    int pixel_num;  // To keep track of the pixel number to know when to skip the convolution output
    always_ff @(posedge clk) begin : increment_pixel_num
        if (re_x_valid) pixel_num <= 0;
        else if (pixel_num < WIDTH * HEIGHT) begin
            pixel_num <= pixel_num + 1;
        end
    end

    logic skip_output = 0;  // To signal that the current output of the convolution should be skipped
    int column;
    assign column = pixel_num % WIDTH;
    always_comb begin : assign_skip_output
        if ((pixel_num < (K-1) * WIDTH) || (column < K-1)) skip_output = 1'b1;
        //   ^^^^^^^^^^^^^^^^^^^^^^^^^ Condition 1: Need to shift pixels in until it reaches the (K-1)th row otherwise not all values in the convolution are valid
        //                                  ^^^^^^^^^^^^^ Condition 2: Skip the first (K-1) convolutions on each row where the kernel wraps around
        else skip_output = 1'b0;
    end

    // Multiply each kernel value by its corresponding value in the shift register,
    // that is, the first K elements of each of the K 'lines' of the shift register (picturing it as a K x W array) 
    logic signed [2*W-1:0] mult_result [0:K*K-1];  // 2*W as the multiply doubles width
    always_comb begin : h_multiply
        // Set mult_result for each kernel value.
        for (int i=0; i<K; i=i+1) begin
            for (int j=0; j<K; j=j+1) begin
                // Multiply each element in the receptive field by the corresponding element in the kernel
                mult_result[i*K+j] = signed'(shift_reg[i*WIDTH+j]) * signed'(kernel[K-1-i][K-1-j]);  // Access the kernel in reverse order because the inputs are reversed
            end
        end
    end

    // Add all of the multiplication results together and shift the result into the output buffer.
    logic signed [$clog2(K*K)+2*W:0] macc; // $clog2(K*K)+1 to accomodate for overflows over the additions.
    always_comb begin : MAC
        macc = 0;
        // Set macc to be the sum of all elements in mult_result.
        for (int i=0; i<K*K; i=i+1) begin
            macc = macc + mult_result[i];
        end
    end

    // Output reg: use y.data as a register, load the result of the MACC into y.data if x.valid and x.ready are high (i.e. data is moving).
    // logic overflow; // Optional: detect for overflow.
    always_ff @(posedge clk) begin : output_reg
        if (x_valid_q & x.ready) begin  // Need to use x_valid_q so the last output is still updated after x.valid goes low
            y.data <= macc[W-1+W_FRAC: W_FRAC];
            // overflow <= ; // (Optional) Check if our INTEGER truncation causes overflow (remember 2's complement!!!)
            y.valid <= x_valid_q & (~skip_output); // 2 clock cycles for valid data to get from x to y
        end
    end

endmodule

