module mul(
	input [3:0] a,b,
	output [7:0]res
);

	assign res = a*b;

endmodule


interface mul_if;
	
	logic [3:0]a,b;
	logic [7:0]res;
	
endinterface