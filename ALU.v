module ALU (Op_A, Op_B, AddSub, ALU_out);
	input [15 : 0] Op_A, Op_B;
	input AddSub;
	output reg [15 : 0] ALU_out;
	always @ (*) begin
		if (AddSub) 
			ALU_out = Op_A + Op_B;
		else
			ALU_out = Op_A - Op_B;
	end
endmodule