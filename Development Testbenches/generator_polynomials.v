module GeneratorPolynomials #(
	parameter n=2,
	parameter m=4
)(
	input [0:m-1] X,
	input load,
	input [clog2(n)-1:0] address,
	input [0:m-1] data,
	input clk,
	input reset,
	output [0:n-1] Y
);

function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction

reg [0:m-1] g [0:n-1];

integer i;
always@(posedge clk, posedge reset) begin
	if (reset) begin
		for(i = 0; i < n; i=i+1) begin
			g[i] = 0;
		end
	end else begin
		if (load) begin
			g[address] = data;
		end
	end 
end

genvar x;
generate
for(x=0;x<n;x=x+1)begin: output_loop
assign Y[x] = ^(g[x] & X);
end
endgenerate

endmodule