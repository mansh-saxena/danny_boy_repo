module convolutionv3_tb;

    localparam TCLK = 20; // Clock period 20ns
    localparam W = 32;
    localparam W_FRAC = 16;
    localparam WIDTH = 640;
    localparam HEIGHT = 480;
    localparam K = 5;

    logic clk = 0;
    dstream #(.N(W)) x ();
    dstream #(.N(W)) y ();

    convolutionv3 #(
        .W(W),
        .W_FRAC(W_FRAC),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .K(K)
    ) DUT (
        .clk(clk),
        .x(x),
        .y(y)
    );

    always #(TCLK/2) clk = ~clk;

    // Reducing the length of test data to just 10 values
    localparam LEN = 150;  
    logic [W-1:0] input_data [0:LEN-1];  // Input data array
    logic [W-1:0] expected_output [0:LEN-1];  // Expected output array

    integer i = 0;  // Declare i at a higher scope

    // Initializing test data to 1s and expected output (hardcoded 1s)
    initial begin
        for (i = 0; i < LEN; i++) begin
            input_data[i] = 32'h00010000;  // Hardcoded value of 1 (in fixed-point representation, 32'hFFFFFFFF)
            expected_output[i] = 32'h00010000;  // Expected output is also hardcoded to 1
        end
        i = 0;  // Reset i after initialization
    end

    // Input driver
    logic start = 0;
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars();
        y.ready = 1'b0;
        #(TCLK*5);
        y.ready = 1'b1;
        start = 1'b1;
        @(posedge x.valid);
        @(negedge x.valid);
        #(TCLK*5);
        $finish();
    end

    always_ff @(posedge clk) begin
        if (start) begin
            x.data <= input_data[i];
            x.valid <= (i < LEN) ? 1'b1 : 1'b0;
            i <= (i < LEN) ? i + 1 : LEN;
        end
    end

    // Output check
    integer error_count = 0;
    always_ff @(posedge clk) begin
        if (start && y.valid) begin
            $display("Time: %0t | Expected: %h | Actual: %h", $time, expected_output[i-1], y.data);
            if (expected_output[i-1] !== y.data) begin
                error_count = error_count + 1;
            end
        end
    end

    // Test termination
    initial begin
        #50000;  // Simulation timeout
        if (error_count == 0)
            $display("Test Passed!");
        else
            $display("Test Failed with %0d errors.", error_count);
        $finish;
    end

endmodule

