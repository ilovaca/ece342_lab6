module regn(Rin, ld, Clock, Q);
	parameter n = 16;
	input [n-1:0] Rin;
	input ld, Clock;
	output [n-1:0] Q;
	reg [n-1:0] Q;
	always @(posedge Clock)
		if (ld)
			Q <= Rin;
endmodule