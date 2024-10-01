import lcd_inst_pkg::*;

module user_interface_fsm (
    input  logic clk,
    input  logic reset,
    // Avalon-MM signals to LCD_Controller slave
    input  logic KEY1,
    input  logic KEY2,
    input  logic KEY3,
    output logic address,          // Address line for LCD controller
    output logic chipselect,
    output logic byteenable,
    output logic read,
    output logic write,
    input  logic waitrequest,
    input  logic [7:0] readdata,
    input  logic [1:0] response,
    output logic [7:0] writedata,
	 output integer select_state
);

    // FSM states
    typedef enum logic [3:0] {
        INIT,
        CLEARING_DISPLAY,
        DISPLAY_IS_ON,
        ENTRY_MODE,
        WRITE_STRING,
        FINISH
    } state_t;

    state_t state, next_state; // Declare the states

    // Flattened array for the messages
    logic [8:0] messages_flat [0:63];  // Array of messages (4 messages, each with 16 characters to fit the screen)
    integer message_index;  // Index for the current message (0-3)
    integer char_index;     // Index for the current character in the message
    logic [31:0] delay_counter;
    logic key1_prev, key2_prev, key3_prev;
    logic key1_pressed, key2_pressed, key3_pressed;

    // Initialize the flattened message array
    initial begin
        // Center the message names and add "KEY1" on the right and "KEY3" on the left

        // "KEY3   NORMAL    KEY1"
        messages_flat[0]  = _K;
        messages_flat[1]  = _E;
        messages_flat[2]  = _Y;
        messages_flat[3]  = _3;
        messages_flat[4]  = _LESS_THAN;
        messages_flat[5]  = _N;
        messages_flat[6]  = _O;
        messages_flat[7]  = _R;
        messages_flat[8]  = _M;
        messages_flat[9]  = _A;
        messages_flat[10] = _L;
        messages_flat[11] = _GREATER_THAN;
        messages_flat[12] = _K;
        messages_flat[13] = _E;
        messages_flat[14] = _Y;
        messages_flat[15] = _1;
        
        // "KEY3   BLURR1    KEY1"
        messages_flat[16]  = _K;
        messages_flat[17]  = _E;
        messages_flat[18]  = _Y;
        messages_flat[19]  = _3;
        messages_flat[20]  = _LESS_THAN;
        messages_flat[21]  = _B;
        messages_flat[22]  = _L;
        messages_flat[23]  = _U;
        messages_flat[24]  = _R;
        messages_flat[25]  = _R;
        messages_flat[26]  = _1;
        messages_flat[27]  = _GREATER_THAN;
        messages_flat[28]  = _K;
        messages_flat[29]  = _E;
        messages_flat[30]  = _Y;
        messages_flat[31]  = _1;
        
        // "KEY3   BLURR2    KEY1"
        messages_flat[32]  = _K;
        messages_flat[33]  = _E;
        messages_flat[34]  = _Y;
        messages_flat[35]  = _3;
        messages_flat[36]  = _LESS_THAN;
        messages_flat[37]  = _B;
        messages_flat[38]  = _L;
        messages_flat[39]  = _U;
        messages_flat[40]  = _R;
        messages_flat[41]  = _R;
        messages_flat[42]  = _2;
        messages_flat[43]  = _GREATER_THAN;
        messages_flat[44]  = _K;
        messages_flat[45]  = _E;
        messages_flat[46]  = _Y;
        messages_flat[47]  = _1;

        // "KEY3   EDGING (EDGE DETECTION)    KEY1"
        messages_flat[48]  = _K;
        messages_flat[49]  = _E;
        messages_flat[50]  = _Y;
        messages_flat[51]  = _3;
        messages_flat[52]  = _LESS_THAN;
        messages_flat[53]  = _E;
        messages_flat[54]  = _D;
        messages_flat[55]  = _G;
        messages_flat[56]  = _I;
        messages_flat[57]  = _N;
        messages_flat[58]  = _G;
        messages_flat[59]  = _GREATER_THAN;
        messages_flat[60]  = _K;
        messages_flat[61]  = _E;
        messages_flat[62]  = _Y;
        messages_flat[63]  = _1;

        message_index = 0;  // Start with the first message ("NORMAL")
        char_index = 0;     // Start with the first character in the message
        select_state = 0;
    end
	 
    // Sequential logic for state transitions and index update
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT;
            delay_counter <= 0;
            char_index <= 0;  // Initialize character index on reset
            key1_prev <= 1'b0;
            key2_prev <= 1'b0;
            key3_prev <= 1'b0;
            key1_pressed <= 1'b0;
            key3_pressed <= 1'b0;
        end else begin
            // Detect rising edges of the buttons
            key1_pressed <= (KEY1 && !key1_prev);
            key2_pressed <= (KEY2 && !key2_prev);
            key3_pressed <= (KEY3 && !key3_prev);

            key1_prev <= KEY1;
            key2_prev <= KEY2;
            key3_prev <= KEY3;

            // Handle key press for KEY1 (next message)
            if (key1_pressed) begin
                if (message_index < 3) begin
                    message_index <= message_index + 1;  // Go to the next message
                end else begin
                    message_index <= 0;  // Wrap to the first message
                end
                char_index <= 0;  // Reset character index for the new message
                state <= CLEARING_DISPLAY; // Clear screen before writing new message
            end
            else if (key2_pressed) begin
                select_state <= message_index;
            end

            // Handle key press for KEY3 (previous message)
            else if (key3_pressed) begin
                if (message_index > 0) begin
                    message_index <= message_index - 1;  // Go to the previous message
                end else begin
                    message_index <= 3;  // Wrap to the last message
                end
                char_index <= 0;  // Reset character index for the new message
                state <= CLEARING_DISPLAY; // Clear screen before writing new message
            end

            else begin
                state <= next_state;  // Continue normal state transitions
            end

            // Wait between LCD operations (delay logic)
            if (waitrequest == 1'b0 && delay_counter > 0) begin
                delay_counter <= delay_counter - 1;
            end else if (delay_counter == 0) begin
                delay_counter <= 32'd50000;  // Insert delay between commands
            end

            // Update the character index 'char_index' when in the WRITE_STRING state
            if (state == WRITE_STRING && waitrequest == 1'b0) begin
                char_index <= char_index + 1;
            end
        end
    end

    // Combinational logic to determine the next state and output control signals
    always_comb begin
        // Default values for Avalon-MM interface signals
        address = 1'b0;      // Default address: command register (RS = 0)
        chipselect = 1'b0;
        byteenable = 1'b1;   // Byte enable active
        read = 1'b0;
        write = 1'b0;
        writedata = 8'h00;   // Default write data
        
        // Default state transition
        next_state = state;

        // FSM behavior based on current state
        case (state)
            INIT: begin
                next_state = CLEARING_DISPLAY;
            end

            CLEARING_DISPLAY: begin
                chipselect = 1'b1;
                write = 1'b1;
                address = CLEAR_DISPLAY[8];  // Use RS bit (bit 8) for command/data
                writedata = CLEAR_DISPLAY[7:0];  // Send lower 8 bits (the command)
                if (waitrequest == 1'b0) next_state = DISPLAY_IS_ON;
            end

            DISPLAY_IS_ON: begin
                chipselect = 1'b1;
                write = 1'b1;
                address = DISPLAY_ON[8];  // Use RS bit (bit 8) for command/data
                writedata = DISPLAY_ON[7:0];  // Send lower 8 bits (the command)
                if (waitrequest == 1'b0) next_state = ENTRY_MODE;
            end

            ENTRY_MODE: begin
                chipselect = 1'b1;
                write = 1'b1;
                address = ENTRY_DIR_RIGHT[8];  // Use RS bit (bit 8) for command/data
                writedata = ENTRY_DIR_RIGHT[7:0];  // Send lower 8 bits (the command)
                if (waitrequest == 1'b0) next_state = WRITE_STRING;
            end

            WRITE_STRING: begin
                chipselect = 1'b1;
                address = messages_flat[message_index * 16 + char_index][8];  // Access RS bit
                write = 1'b1;
                writedata = messages_flat[message_index * 16 + char_index][7:0];  // Send ASCII character

                if (waitrequest == 1'b0) begin
                    if (char_index >= 15) begin  // 16 characters total (message + KEY1/KEY3)
                        next_state = FINISH;
                    end
                end
            end

            FINISH: begin
                chipselect = 1'b0;
                write = 1'b0;
            end

            default: begin
                next_state = INIT;
            end
        endcase
    end
endmodule
