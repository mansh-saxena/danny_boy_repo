module convolutionv3 #(parameter W = 32, W_FRAC = 16, WIDTH = 640, HEIGHT = 480, K = 5) (
    input clk,
	 input integer filt_select,
	 input [$clog2(1024)-1:0] display_value,
    dstream.in x,
    dstream.out y
);
    logic signed [W-1:0] kernel [0:K-1][0:K-1];

	 logic signed [W-1:0] horizontal_edge [0:K-1][0:K-1];
	 logic signed [W-1:0] gaus_kernel_0_5 [0:K-1][0:K-1];

	 logic signed [W-1:0] gaus_kernel_1 [0:K-1][0:K-1];
	 logic signed [W-1:0] gaus_kernel_2 [0:K-1][0:K-1];
	 logic signed [W-1:0] identity_kernel [0:K-1][0:K-1];
	 logic signed [W-1:0] whitey [0:K-1][0:K-1];


initial begin
    identity_kernel = '{
        '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000}, // First row
        '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000}, // Second row
        '{32'h00000000, 32'h00000000, 32'h00010000, 32'h00000000, 32'h00000000}, // Third row
        '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000}, // Fourth row
        '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000}  // Fifth row
    };
 gaus_kernel_0_5 = '{
        '{32'h000000FF, 32'h000003FE, 32'h000005FD, 32'h000003FE, 32'h000000FF}, // First row
        '{32'h000003FE, 32'h00001000, 32'h00001803, 32'h00001000, 32'h000003FE}, // Second row
        '{32'h000005FD, 32'h00001803, 32'h000023FE, 32'h00001803, 32'h000005FD}, // Third row
        '{32'h000003FE, 32'h00001000, 32'h00001803, 32'h00001000, 32'h000003FE}, // Fourth row
        '{32'h000000FF, 32'h000003FE, 32'h000005FD, 32'h000003FE, 32'h000000FF}  // Fifth row
    };
 
    gaus_kernel_1 = '{
        '{32'h000000C4, 32'h00000353, 32'h000005A1, 32'h00000353, 32'h000000C4}, // First row
        '{32'h00000353, 32'h00000F1A, 32'h000018D4, 32'h00000F1A, 32'h00000353}, // Second row
        '{32'h000005A1, 32'h000018D4, 32'h0000286B, 32'h000018D4, 32'h000005A1}, // Third row
        '{32'h00000353, 32'h00000F1A, 32'h000018D4, 32'h00000F1A, 32'h00000353}, // Fourth row
        '{32'h000000C4, 32'h00000353, 32'h000005A1, 32'h00000353, 32'h000000C4}  // Fifth row
    };
 
 gaus_kernel_2 = '{
        '{32'h000000F2, 32'h0000003C, 32'h0000068D, 32'h0000003C, 32'h000000F2}, // First row
        '{32'h0000003C, 32'h00000F00, 32'h0000185F, 32'h00000F00, 32'h0000003C}, // Second row
        '{32'h0000068D, 32'h0000185F, 32'h00002673, 32'h0000185F, 32'h0000068D}, // Third row
        '{32'h0000003C, 32'h00000F00, 32'h0000185F, 32'h00000F00, 32'h0000003C}, // Fourth row
        '{32'h000000F2, 32'h0000003C, 32'h0000068D, 32'h0000003C, 32'h000000F2}  // Fifth row
    };
 
horizontal_edge = '{
        '{32'hFFFE0000, 32'hFFFF0000, 32'h00000000, 32'h00010000, 32'h00020000}, // First row
        '{32'hFFFE0000, 32'hFFFF0000, 32'h00000000, 32'h00010000, 32'h00020000}, // Second row
        '{32'hFFFC0000, 32'hFFFE0000, 32'h00000000, 32'h00020000, 32'h00040000}, // Third row
        '{32'hFFFE0000,32'hFFFF0000, 32'h00000000, 32'h00010000, 32'h00020000}, // Fourth row
        '{32'hFFFE0000, 32'hFFFF0000, 32'h00000000, 32'h00010000, 32'h00020000}  // Fifth row
    };
	 
 whitey = '{
        '{32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff}, // First row
        '{32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff}, // Second row
        '{32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff}, // Third row
        '{32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff}, // Fourth row
        '{32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff}  // Fifth row
    };

end

    // Kernel selection based on filt_select
//    always_comb begin
//        case(filt_select)
//            2'b00: kernel = identity_kernel;   // Identity filter
//            2'b01: kernel = gaus_kernel_1;   // Gaussian kernel 0.5
//            2'b10: kernel = gaus_kernel_2;     // Gaussian kernel 1
//            2'b11: kernel = gaus_kernel_3;     // Gaussian kernel 2
//            default: kernel = gaus_kernel_2; // Default to identity filter
//        endcase
//    end

    // 1. Assign x.ready: we are ready for data if the module we output to (y.ready) is ready (this module does not exert backpressure).
    assign x.ready = y.ready;

    localparam SR_LENGTH = 3*WIDTH;

    logic [1:0] conv_ready = 0;
    logic signed [30:0] output_counter = 0;

    // Shift register to hold pixel data

    // Pipeline registers for each stage
    logic signed [2*W-1 : 0] mult_stage1 [K*K-1:0];  // Store multiplications
    logic signed [$clog2(K*K)+ 2*W : 0] macc_stage2;         // Store accumulation
	 

   // 2. Make a shift register of depth = impulse response size.
	 logic signed [W-1:0] shift_reg [0:WIDTH*K - 1];
    always_ff @(posedge clk) begin : h_shift_register
        if (x_valid_q & x.ready) begin

            shift_reg[0] <= signed'(x.data);

            for (int i = 1; i < WIDTH*K; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end
	
	logic new_image;
	logic wait_flag =0;
		
	always_ff @(posedge clk) begin
		if (new_image ) begin
			output_counter <= 0;
        end else if (output_counter < WIDTH*HEIGHT) begin
            output_counter <= output_counter + 1;
        end
	end
	
	always_ff @(posedge clk) begin
		if  (((output_counter % WIDTH) < K-1) || (output_counter < (K -1) * WIDTH)) begin
			wait_flag <= 1'b1;
		end else  begin
			wait_flag <= 1'b0;
		end
	end
	
    // Stage 2: Multiply each register by corresponding kernel value
//    always_ff @(posedge clk) begin : mult_stage
//			if (ready) begin
//            mult_stage1[0] <= signed'(shift_reg[0]) * signed'(kernel[0][0]);
//            mult_stage1[1] <= signed'(shift_reg[1]) * signed'(kernel[0][1]);
//            mult_stage1[2] <= signed'(shift_reg[2]) * signed'(kernel[0][2]);
//            mult_stage1[3] <= signed'(shift_reg[WIDTH]) * signed'(kernel[1][0]);
//            mult_stage1[4] <= signed'(shift_reg[WIDTH+1]) * signed'(kernel[1][1]);
//            mult_stage1[5] <= signed'(shift_reg[WIDTH+2]) * signed'(kernel[1][2]);
//            mult_stage1[6] <= signed'(shift_reg[WIDTH*2]) * signed'(kernel[2][0]);
//            mult_stage1[7] <= signed'(shift_reg[WIDTH*2+1]) * signed'(kernel[2][1]);
//            mult_stage1[8] <= signed'(shift_reg[WIDTH*2+2]) * signed'(kernel[2][2]);
//			end
//	 end

always_comb begin : h_multiply    
    macc_stage2 = 0;

    if (display_value >= 100) begin
        // Override kernel with whitey if display_value >= 1
        for (int y = 0; y < K; y++) begin
            for (int x = 0; x < K; x++) begin
                mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(whitey[K-1 - y][K-1 - x]);
					  case(filt_select)
                    2'b00: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(gaus_kernel_1[K-1 - y][K-1 - x]);
                    2'b01: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(gaus_kernel_2[K-1 - y][K-1 - x]);
                    2'b10: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(horizontal_edge[K-1 - y][K-1 - x]);
                    2'b11: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(whitey[K-1 - y][K-1 - x]);
                    default: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(whitey[K-1 - y][K-1 - x]);
				     endcase
            end
        end
    end else begin
        // Default behavior based on filt_select
        for (int y = 0; y < K; y++) begin
            for (int x = 0; x < K; x++) begin
                case(filt_select)
                    2'b00: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(identity_kernel[K-1 - y][K-1 - x]);
                    2'b01: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(gaus_kernel_1[K-1 - y][K-1 - x]);
                    2'b10: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(gaus_kernel_2[K-1 - y][K-1 - x]);
                    2'b11: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(horizontal_edge[K-1 - y][K-1 - x]);
                    default: mult_stage1[y * K + x] = signed'(shift_reg[y * WIDTH + x]) * signed'(identity_kernel[K-1 - y][K-1 - x]);
                endcase
            end
        end
    end

    // Accumulate the results
    for (int x = 0; x < K*K; x++) begin
        macc_stage2 = macc_stage2 + mult_stage1[x];
    end
end

    // 5. Output reg: use y.data as a register, load the result of the MACC into y.data if x.valid and x.ready are high (i.e. data is moving).
    // y.valid should be set as a register here too.
    logic overflow; // Optional (not marked): detect for overflow.
    logic x_valid_q; // Delay x.valid by 1 clock cycle

    // is this necessary???
    assign new_image = x.valid & (~x_valid_q);

    always_ff @(posedge clk) begin : output_reg
        if (x_valid_q & x.ready) begin
            y.data <= macc_stage2[W-1+W_FRAC: W_FRAC];
            //overflow <= (macc[$clog2(N)+2*W:W+W_FRAC] != {($clog2(N)+2*W-W-W_FRAC+1){macc[W+W_FRAC-1]}}); // Optional overflow detection
            x_valid_q <= x.valid;
            y.valid <= x_valid_q & ~wait_flag; // 2 clock cycles for valid data to get from x to y
        end
    end

endmodule
