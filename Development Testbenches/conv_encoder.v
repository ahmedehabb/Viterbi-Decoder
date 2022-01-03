module ConvEncoder #(
	parameter n=2,
	parameter k=1,
	parameter m=4
)(
	input [0:k-1] I,
	input load,
	input [clog2(n)-1:0] address,
	input [0:m-1] data,
	input clk,
	input reset,
	input restart,
	input enable,
	output [0:n-1] O
);

function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction

reg [0:m-k-1] state;
wire [0:m-k-1] next_state;

wire [0:m-1] combined = {I, state};
assign next_state = combined[0:m-k-1];

GeneratorPolynomials #(n,m) GP(
	.X(combined),
	.load(load),
	.address(address),
	.data(data),
	.clk(clk),
	.reset(reset),
	.Y(O)
);

always@(posedge clk, posedge reset) begin
	if (reset) begin
		state <= 0;
	end else begin
		if (restart) begin
			state = 0;
		end else if (enable) begin
			state <= next_state;
		end
	end
end

endmodule
