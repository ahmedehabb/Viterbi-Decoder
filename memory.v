module memory #(parameter k, m, n )
(clk, load, reset, state_address, input_address, next_state_data, output_data, nextStates,outputStates);


input clk; // The clock signal.
input [0:0]reset; // The asynchronous reset signal (reset the whole decoder).
input [0:0] load; // This signal tells the decoder to read an entry to the Next State Table and the Output table
input [0:m-k-1] state_address; // The address of the state in the tables into which we want to write (the row according to the tables in the project description)
input [0:k-1] input_address; // The address of the input in the tables into which we want to write (the column according to the tables in the project description)
input [0:m-k-1] next_state_data; // The next state to write into the Next State Table
input [0:n-1] output_data; // The output to write into the Output Table

output reg [(2**k)*(m-k)-1 : 0] nextStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2m-2k-1 --> m-k-2 | m-k-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------

output reg [(2**k)*n - 1 : 0] outputStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2n-1 --> n-2      | n-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------


integer row;
integer j;


always @(posedge clk, reset) begin
    if (reset == 1'b1) begin
        // looping on whole memory to reset it
        for (j=0; j < 2**(m-k); j=j+1) begin
            nextStates[j] <= 0; //reset array
            outputStates[j] <= 0; //reset array
        end
    end else if(clk && load == 1'b1)begin
        // state_address '000' mean row 0 in our memory so convert to integer =0
        row = state_address;
        j = input_address;
        // input_address : 00 -> j = 0
        nextStates[row][(2**k -j)*(m-k) - 1 -: (m-k) ] = next_state_data; 
        outputStates[row][(2**k -j)*n - 1  -: n ] = output_data;    
    end
end



endmodule 