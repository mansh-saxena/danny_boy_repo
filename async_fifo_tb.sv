module async_fifo_tb;

    // Testbench signals (match the async_fifo module)
    logic aclr;            // Reset signal
    logic [15:0] data;     // Data to write into the FIFO
    logic rdclk;           // Read clock
    logic rdreq;           // Read request signal
    logic wrclk;           // Write clock
    logic wrreq;           // Write request signal
    logic [15:0] q;        // Data output from FIFO
    logic rdfull;          // Read full (signals FIFO is full for reading)
    logic wrfull;          // Write full (signals FIFO is full for writing)

    // Clock generation for both write and read clocks
    initial begin
        wrclk = 0;
        rdclk = 0;
        forever begin
            #5 wrclk = ~wrclk;  // Write clock toggles every 5 time units (100 MHz)
            #7 rdclk = ~rdclk;  // Read clock toggles every 7 time units (roughly 71.4 MHz)
        end
    end

    // Instantiate the async_fifo module
    async_fifo dut (
        .aclr(aclr),        // Connect reset
        .data(data),        // Connect write data input
        .rdclk(rdclk),      // Connect read clock
        .rdreq(rdreq),      // Connect read request
        .wrclk(wrclk),      // Connect write clock
        .wrreq(wrreq),      // Connect write request
        .q(q),              // Connect output data
        .rdfull(rdfull),    // Connect read full status
        .wrfull(wrfull)     // Connect write full status
    );

    // Testbench procedure
    initial begin
        // Initialize signals
        aclr = 1;         // Assert reset
        data = 16'h0000;  // Initialize data
        rdreq = 0;        // Read request is initially 0
        wrreq = 0;        // Write request is initially 0

        // Assert reset (aclr) for 20 ns, then release it
        #20 aclr = 0;

        // Wait a few clock cycles to let FIFO recover from reset
        #50;

        // Start writing data to FIFO
        // Write 10 data elements into the FIFO
        $display("Starting to write data to the FIFO...");
        repeat (10) begin
            @(posedge wrclk);
            if (!wrfull) begin       // Check that FIFO is not full
                wrreq = 1;           // Assert write request
                data = data + 1;     // Increment the data to be written
                $display("Writing data: %h", data);  // Display data being written
            end
            else begin
                $display("FIFO is full, cannot write more data");
                wrreq = 0;
            end
            #10;
        end
        @(posedge wrclk);
        wrreq = 0; // Stop writing

        // Wait for a few cycles before reading
        #50;

        // Start reading from FIFO
        $display("Starting to read data from the FIFO...");
        repeat (10) begin
            @(posedge rdclk);
            if (!rdfull) begin      // Check that FIFO has data to read
                rdreq = 1;          // Assert read request
                #10;
                $display("Read data: %h", q);  // Display the data read from FIFO
            end
            else begin
                $display("FIFO is empty, no data to read");
                rdreq = 0;
            end
        end
        @(posedge rdclk);
        rdreq = 0;  // Stop reading

        // End simulation
        $display("Simulation finished.");
        $finish;
    end

    // Monitor FIFO status during the simulation
    always_ff @(posedge wrclk or posedge rdclk) begin
        $display("Time: %t | wrreq: %b | Write Data: %h | rdreq: %b | Read Data: %h | wrfull: %b | rdfull: %b", 
                  $time, wrreq, data, rdreq, q, wrfull, rdfull);
    end

endmodule
