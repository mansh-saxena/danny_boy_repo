//----------------------------------------------------------------------
//  TB: FftTop Testbench (Hardcoded Input Data)
//----------------------------------------------------------------------
`timescale  1ns/1ns
module tb_fft #(
    parameter   N = 1024,    // Size of FFT (1024-point FFT)
    parameter   WIDTH = 32   // Data width (32-bit real and imaginary)
);

localparam      NN = log2(N);  //  Count Bit Width of FFT Point

//  log2 constant function
function integer log2;
    input integer x;
    integer value;
    begin
        value = x-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end
endfunction

//  Internal Regs and Nets
reg         clock;
reg         reset;
reg         di_en;
reg [WIDTH-1:0]  di_re;
reg [WIDTH-1:0]  di_im;
wire        do_en;
wire [WIDTH-1:0] do_re;
wire [WIDTH-1:0] do_im;

reg [WIDTH-1:0]  imem[0:2*N-1];  // Input memory to hold real and imaginary parts
reg [WIDTH-1:0]  omem[0:2*N-1];  // Output memory to capture real and imaginary FFT outputs

//----------------------------------------------------------------------
//  Clock and Reset
//----------------------------------------------------------------------
always begin
    clock = 0; #10;  // 50 MHz clock cycle (20 ns period)
    clock = 1; #10;
end

initial begin
    reset = 1;       // Assert reset at the beginning
    #100;            // Hold reset high for 100 ns
    reset = 0;       // Deassert reset
end

//----------------------------------------------------------------------
//  Output Data Capture
//----------------------------------------------------------------------
initial begin : OCAP
    integer n;
    forever begin
        n = 0;
        while (do_en !== 1) @(negedge clock);  // Wait for valid output
        while ((do_en == 1) && (n < N)) begin
            omem[2*n  ] = do_re;               // Store real part
            omem[2*n+1] = do_im;               // Store imaginary part
            n = n + 1;
            @(negedge clock);
        end
    end
end

//----------------------------------------------------------------------
//  Task to generate input wave from hardcoded memory
//----------------------------------------------------------------------
task GenerateInputWave;
    integer n;
begin
    di_en <= 1;
    for (n = 0; n < N; n = n + 1) begin
        di_re <= imem[2*n];       // Read real part from memory
        di_im <= imem[2*n+1];     // Read imaginary part from memory
        @(posedge clock);         // Wait for clock edge
    end
    di_en <= 0;
    di_re <= 'bx;
    di_im <= 'bx;
end
endtask

//----------------------------------------------------------------------
//  Hardcoded Input Data in the Testbench
//----------------------------------------------------------------------
initial begin
    // Initialize the input memory with real and imaginary parts
    integer i;
    for (i = 0; i < 2*N; i = i + 2) begin
        imem[i]   = $random;  // Random real values
        imem[i+1] = 32'h0000; // Set imaginary part to 0
    end

    // Wait for reset to deassert
    @(negedge reset);

    // Generate input wave from hardcoded data
    GenerateInputWave;

    // Wait for FFT computation to finish (wait for sufficient time)
    #50000;

    // Simulation end
    $stop;
end

//----------------------------------------------------------------------
//  FFT Instance
//----------------------------------------------------------------------
FFT #(.WIDTH(WIDTH)) FFT (
    .clock  (clock  ),  // i
    .reset  (reset  ),  // i
    .di_en  (di_en  ),  // i
    .di_re  (di_re  ),  // i
    .di_im  (di_im  ),  // i
    .do_en  (do_en  ),  // o
    .do_re  (do_re  ),  // o
    .do_im  (do_im  )   // o
);

endmodule
