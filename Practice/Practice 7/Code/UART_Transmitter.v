module UART_Transmitter (
    input sys_clk,
    input reset,
    input load,                  // Signal to load new data
    input [6:0] data_in,         // 7-bit ASCII data
    output reg tx                // Transmitted serial data
);

localparam IDLE = 0, START = 1, SEND = 2, PARITY = 3, STOP = 4;
reg [2:0] state = IDLE, next_state;
reg [6:0] shift_reg;
reg parity_bit;
reg [2:0] bit_counter = 0;
reg next_tx; // This will hold the next value for tx in the combinational block
reg [2:0] next_bit_counter; // This will hold the next value for bit_counter in the combinational block

always @(posedge sys_clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        tx <= 1;
        bit_counter <= 0;
    end else begin
        state <= next_state;
        tx <= next_tx; 
        bit_counter <= next_bit_counter; // Assigning next_bit_counter to bit_counter
    end
end

always @(state, bit_counter, load, shift_reg, data_in) begin
    next_state = state;
    next_tx = 1; // default for next_tx
    next_bit_counter = bit_counter; // default for next_bit_counter
    
    case (state)
        IDLE: begin
            if (load) next_state = START;
        end
        
        START: begin
            next_tx = 0; // Start bit
            shift_reg = data_in;
            next_state = SEND;
            next_bit_counter = 0;
        end
        
        SEND: begin
            next_tx = shift_reg[0];
            shift_reg = shift_reg >> 1;
            next_bit_counter = bit_counter + 1;
            if (bit_counter == 6) next_state = PARITY;
        end
        
        PARITY: begin
            parity_bit = ^data_in;
            next_tx = parity_bit;
            next_state = STOP;
        end
        
        STOP: begin
            next_tx = 1; // Stop bit
            next_state = IDLE;
        end
    endcase
end

endmodule 