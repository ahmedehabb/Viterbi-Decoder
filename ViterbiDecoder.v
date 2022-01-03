module ViterbiDecoder#(parameter n =2,parameter k=1,parameter m=4, parameter L=7)(
	clk,
	reset,
	restart,
	load,
	encoded,
	state_address,
	input_address,
	next_state_data,
	output_data,
	enable,
	decoded,
	error,
	ready
);


function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction

parameter E = clog2(L*n);

// inputs
input clk; // The clock signal.
input reset; // The asynchronous reset signal (reset the whole decoder).
input restart; // This signal tells the decoder to discard its result and start processing a new stream of encoded bits.
input enable; // This signal can be used to pause the processing if equal zero.
input [0:n-1] encoded; // The encoded bits for this clock cycle
input load; // This signal tells the decoder to read an entry to the Next State Table and the Output table
input [0:m-k-1] state_address; // The address of the state in the tables into which we want to write (the row according to the tables in the project description)
input [0:k-1] input_address; // The address of the input in the tables into which we want to write (the column according to the tables in the project description)
input [0:m-k-1] next_state_data; // The next state to write into the Next State Table
input [0:n-1] output_data; // The output to write into the Output Table
//////////////////////////////////////////

// outputs
output wire [0:k*L-1] decoded; // The result of the decoding process.
output wire [E:0] error; // The number of errors found in the most likely sequence
output wire ready; // Whether the decoder finished processing and the output is ready



wire [2*m-2*k-1 : 0] nextStates [0 : 2**(m-k) -1];
wire [2*n - 1 : 0] outputStates [0 : 2**(m-k) -1];

memory #(k, m, n ) m1 (clk, load, reset, state_address, input_address, next_state_data, output_data, nextStates, outputStates);

reg [0:L*n -1] example;
wire [(L+1)*(m-k)-1 : 0] historyTable [0 : 2**(m-k)-1];
wire [(E+1)*(L+1) -1: 0] errorTable [0 : 2**(m-k)-1];
wire [k*(L+1)-1 : 0] backTrackingTable [0 : 2**(m-k)-1];


pathAndError #(k, m, n, L, E ) tables (clk, reset, load, restart, ready, encoded, historyTable,
                                    errorTable, backTrackingTable, nextStates, outputStates, decoded, error);



endmodule;
