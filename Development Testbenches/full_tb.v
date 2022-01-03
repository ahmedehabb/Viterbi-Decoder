// This is simple testbench for the viterbi decoder, the final testbench will be very similar
module FullViterbiDecoderTB();

localparam PERIOD = 10; // Period of one clock cycle
localparam n = 4; // The convolutional encoder takes k-bits every clk cycle and emits n-bits.
localparam k = 2;
localparam m = 4; // The generator size which is equal to k + the number of bits in the state register
localparam L = 6; // The number of clock cycles before the state returns to zero. So per example, the decoder will take n*L bits and return k*L bits

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
wire [0:n-1] encoded; // The encoded bits for this clock cycle
wire [0:k*L-1] decoded; // The result of the decoding process.
wire [E:0] error; // The number of errors found in the most likely sequence
wire ready; // Whether the decoder finished processing and the output is ready
reg load; // This signal tells the decoder to read an entry to the Next State Table and the Output table
reg [0:m-k-1] state_address; // The address of the state in the tables into which we want to write (the row according to the tables in the project description)
reg [0:k-1] input_address; // The address of the input in the tables into which we want to write (the column according to the tables in the project description)
reg [0:m-k-1] next_state_data; // The next state to write into the Next State Table
wire [0:n-1] output_data; // The output to write into the Output Table

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

// We will create generator polynomials and a convolutional encoder to test our decoder
localparam GEN_ADDRESS = clog2(n); // The number of bit in a polynomial address

reg [0:m-1] gen_input; // The input for the generator polynomial
reg gen_load; // Load enable for the generator polynomials module
reg [GEN_ADDRESS-1:0] gen_address; // the load address
reg [0:m-1] gen_data; // The polynomial coefficients
reg gen_reset; // asynchronous reset for the generator polynomials module
wire [0:n-1] gen_output; // The output of the generator polynomials

// Instantiation of the Generator Polynomial Module
GeneratorPolynomials #(n,m) GP(
	.X(gen_input),
	.load(gen_load),
	.address(gen_address),
	.data(gen_data),
	.clk(clk),
	.reset(gen_reset),
	.Y(gen_output)
);

reg [0:k-1] enc_input; // The input for the encoder
reg enc_load; // Load enable for the generator polynomials inside the encoder
reg [GEN_ADDRESS-1:0] enc_address; // the load address
reg [0:m-1] enc_data; // The polynomial coefficients
reg enc_reset; // asynchronous reset for the encoder
reg enc_restart; // restart the encoder (forget previous inputs)
reg enc_enable; // enable bit-shifting
wire [0:n-1] enc_output; // the encoder result

// Instantiation of the Encoder Module
ConvEncoder #(n,k,m) encoder(
	.I(enc_input),
	.load(enc_load),
	.address(enc_address),
	.data(enc_data),
	.clk(clk),
	.reset(enc_reset),
	.restart(enc_restart),
	.enable(enc_enable),
	.O(enc_output)
);

reg [0:n-1] noise; // Register to store the current noise

assign encoded = enc_output ^ noise; // Apply noise to the encoder output and send to the decoder
assign output_data = gen_output; // Send the generator result to the decoder in order to store it in its output table

localparam EXAMPLE_COUNT = 4; // The number of examples
localparam NOISE_COUNT = 3; // The number of noise pattern to use while testing
reg [0:L*k-1] example_inputs[0:EXAMPLE_COUNT-1];
reg [0:L*n-1] noise_patterns[0:NOISE_COUNT-1];
reg [0:m-1] generator_polynomials[0:n-1];

integer i,j, noise_index, success; // Some variables to use in the test bench
reg [0:m-1] polynomial_input; // Some variables to use in the test bench

initial begin
// First, we reset every variable till needed
i = 0;
j = 0;
noise_index = 0;
noise = 0;
polynomial_input = 0;
success = 0;

// Then we store the test cases and noise patterns
example_inputs[0] = 'b1011_0111_0000;
example_inputs[1] = 'b0101_1100_0000;
example_inputs[2] = 'b1101_1111_0000;
example_inputs[3] = 'b0100_0100_0000;
noise_patterns[0] = 'b0000_0000_0000_0000_0000_0000;
noise_patterns[1] = 'b0000_0100_0000_0000_0000_0000;
noise_patterns[2] = 'b0100_0000_0000_0000_1000_0000;
// Then we define our generator polynomial coefficients
generator_polynomials[0] = 'b1001;
generator_polynomials[1] = 'b1100;
generator_polynomials[2] = 'b0110;
generator_polynomials[3] = 'b0011;

// First we reset the decoder, encoder and generator polynomials and force every input to a defined value
clk = 0;
reset = 1;
restart = 0;
enable = 0;
load = 0;
state_address = 0;
input_address = 0;
next_state_data = 0;

gen_reset = 1;
gen_input = 0;
gen_load = 0;
gen_address = 0;
gen_data = 0;

enc_reset = 1;
enc_input = 0;
enc_load = 0;
enc_address = 0;
enc_data = 0;
enc_restart = 0;
enc_enable = 0;

#PERIOD
reset = 0;
gen_reset = 0;
enc_reset = 0;

// Now we will initialize the generator polynomials and the encoder
$display("Start Initializing The Generator and Encoder");
gen_load = 1;
enc_load = 1;
for(i = 0; i < n; i=i+1) begin
	gen_address = i;
	enc_address = i;
	gen_data = generator_polynomials[gen_address];
	enc_data = generator_polynomials[enc_address];
	#PERIOD;
end
gen_load = 0;
enc_load = 0;

// Now we will send the Next State and Output table to the decoder
$display("Start Loading Tables");
load = 1;

for(i=0; i<2**m; i=i+1) begin
	state_address = i;
	for(j=0; j<2**k; j=j+1) begin
		input_address = j;
		polynomial_input = { input_address, state_address };
		next_state_data = polynomial_input[0:m-k-1];
		gen_input = polynomial_input;
		#PERIOD;
	end
end
load = 0;

$display("Loading Tables Done");
// Now we test the decoder

for(noise_index=0;noise_index<NOISE_COUNT;noise_index=noise_index+1)begin
	for(i=0;i<EXAMPLE_COUNT;i=i+1) begin // For each example
		enable = 1; // We enable the decoder
		enc_enable = 1;
	
		for(j=0;j<L;j=j+1) begin
			noise = noise_patterns[noise_index][n*j+:n]; // We send the noise bits slice by slice
			enc_input = example_inputs[i][k*j+:k]; // And we send the input bits slice by slice to the encoder
			#PERIOD;
		end
		
		#PERIOD
		// The output should be ready here
		if(ready == 0) $display("The output is not ready yet, Something must be wrong");
		$display("Test Case (%0d-%0d). Decoded=%b (Error=%0d, Expected=%b, Noise=%b) %s", noise_index, i, decoded, error, example_inputs[i], noise_patterns[noise_index], decoded == example_inputs[i]?"SUCCESS":"FAILURE"); // Now the decoded value should be ready, so we print the results
		if(decoded == example_inputs[i]) success=success+1;
		enable = 0;
		#PERIOD
		restart = 1; // Before the next example, we restart the encoder-decoder (not reset since we still want the tables to be loaded)
		enc_restart = 1;
		#PERIOD
		restart = 0;
		enc_restart = 0;

	end
end

if(success == EXAMPLE_COUNT * NOISE_COUNT)
	$display("Success (%0d out of %0d test cases passed)", success, EXAMPLE_COUNT * NOISE_COUNT);
else
	$display("Failed (%0d out of %0d test cases passed)", success, EXAMPLE_COUNT * NOISE_COUNT);

$finish;

end

always #(PERIOD/2) clk = ~clk; // Keep toggling the clock forever

endmodule
