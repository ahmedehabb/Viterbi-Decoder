// This is simple testbench for the viterbi decoder, the final testbench will be very similar
module ViterbiDecoderTB();

localparam PERIOD = 10; // Period of one clock cycle
localparam n = 2; // The convolutional encoder takes k-bits every clk cycle and emits n-bits.
localparam k = 1;
localparam m = 4; // The generator size which is equal to k + the number of bits in the state register
localparam L = 7; // The number of clock cycles before the state returns to zero. So per example, the decoder will take n*L bits and return k*L bits

// This is a function that calculated the ceil(log2(x)) for any integer x
function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction

// The maximum number of errors in an example is L*n so we should represent the error in clog2(L*n)+1 bits
localparam E = clog2(L*n);

reg clk; // The clock signal.
reg reset; // The asynchronous reset signal (reset the whole decoder).
reg restart; // This signal tells the decoder to discard its result and start processing a new stream of encoded bits.
reg enable; // This signal can be used to pause the processing if equal zero.

reg [0:n-1] encoded; // The encoded bits for this clock cycle
wire [0:k*L-1] decoded; // The result of the decoding process.

wire [E:0] error; // The number of errors found in the most likely sequence
wire ready; // Whether the decoder finished processing and the output is ready


reg load; // This signal tells the decoder to read an entry to the Next State Table and the Output table
reg [0:m-k-1] state_address; // The address of the state in the tables into which we want to write (the row according to the tables in the project description)
reg [0:k-1] input_address; // The address of the input in the tables into which we want to write (the column according to the tables in the project description)
reg [0:m-k-1] next_state_data; // The next state to write into the Next State Table
reg [0:n-1] output_data; // The output to write into the Output Table

// Instantiation of the unit under test
ViterbiDecoder #(n,k,m,L) uut(
	.clk(clk),
	.reset(reset),
	.restart(restart),
	.enable(enable),
	.encoded(encoded),
	.decoded(decoded),
	.error(error),
	.ready(ready),
	.load(load),
	.state_address(state_address),
	.input_address(input_address),
	.next_state_data(next_state_data),
	.output_data(output_data)
);

localparam EXAMPLE_COUNT = 2; // The number of examples
reg [0:L*n-1] examples[0:EXAMPLE_COUNT-1];
reg [0:L*k-1] expected_outputs[0:EXAMPLE_COUNT-1];
integer i,j, success; // Some variables to use in the test bench

initial begin

examples[0] = 'b11_11_01_11_01_01_11;
examples[1] = 'b01_11_01_11_01_01_11; // The second test case is the same as the first test case but with one wrong bit
expected_outputs[0] = 'b1011_000;
expected_outputs[1] = 'b1011_000;
success = 0;

// First we reset the decoder and force every input to a defined value
clk = 0;
reset = 1;
restart=0;
enable = 0;
encoded = 0;
load = 0;
state_address = 0;
input_address = 0;
next_state_data = 0;
output_data = 0;

#PERIOD

// Now we will send the Next State and Output table to the decoder
$display("Start Loading Tables");
reset = 0;
load = 1;

state_address = 3'b000; input_address=1'b0; next_state_data = 3'b000; output_data=2'b00;
#PERIOD
state_address = 3'b000; input_address=1'b1; next_state_data = 3'b100; output_data=2'b11;
#PERIOD

state_address = 3'b001; input_address=1'b0; next_state_data = 3'b000; output_data=2'b11;
#PERIOD
state_address = 3'b001; input_address=1'b1; next_state_data = 3'b100; output_data=2'b00;
#PERIOD

state_address = 3'b010; input_address=1'b0; next_state_data = 3'b001; output_data=2'b10;
#PERIOD
state_address = 3'b010; input_address=1'b1; next_state_data = 3'b101; output_data=2'b01;
#PERIOD

state_address = 3'b011; input_address=1'b0; next_state_data = 3'b001; output_data=2'b01;
#PERIOD
state_address = 3'b011; input_address=1'b1; next_state_data = 3'b101; output_data=2'b10;
#PERIOD

state_address = 3'b100; input_address=1'b0; next_state_data = 3'b010; output_data=2'b11;
#PERIOD
state_address = 3'b100; input_address=1'b1; next_state_data = 3'b110; output_data=2'b00;
#PERIOD

state_address = 3'b101; input_address=1'b0; next_state_data = 3'b010; output_data=2'b00;
#PERIOD
state_address = 3'b101; input_address=1'b1; next_state_data = 3'b110; output_data=2'b11;
#PERIOD

state_address = 3'b110; input_address=1'b0; next_state_data = 3'b011; output_data=2'b01;
#PERIOD
state_address = 3'b110; input_address=1'b1; next_state_data = 3'b111; output_data=2'b10;
#PERIOD

state_address = 3'b111; input_address=1'b0; next_state_data = 3'b011; output_data=2'b10;
#PERIOD
state_address = 3'b111; input_address=1'b1; next_state_data = 3'b111; output_data=2'b01;
#PERIOD

$display("Loading Tables Done");

// Now we test the decoder
load = 0;

for(i=0;i<EXAMPLE_COUNT;i=i+1) begin // For each example
	enable = 1; // We enable the decoder

	encoded[0:n-1] = examples[i][0:n-1]; // And send the first slice of bits to the decoder
    	for(j=1;j<L;j=j+1) begin
		#PERIOD encoded[0:n-1] = examples[i][n*j+:n]; // We keep sending the bits slice by slice
	end
	
	#PERIOD
	if(ready == 0) $display("The output is not ready yet, Something must be wrong");
	$display("%0d. Recieved=%b => Decoded=%b (Error=%0d)", i, examples[i], decoded, error); // Now the decoded value should be ready, so we print the results
	#PERIOD
	if(decoded == expected_outputs[i]) success=success+1;
	enable = 0;
	#PERIOD
	restart = 1; // Before the next example, we restart the decoder (not reset since we still want the tables to be loaded)
	#PERIOD
	restart = 0;

end



if(success == EXAMPLE_COUNT)
	$display("Success (%0d out of %0d test cases passed)", success, EXAMPLE_COUNT);
else
	$display("Failed (%0d out of %0d test cases passed)", success, EXAMPLE_COUNT);

//$finish;

end

always #(PERIOD/2) clk = ~clk; // Keep toggling the clock forever

endmodule
