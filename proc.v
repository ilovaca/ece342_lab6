module proc (DIN, Resetn, Clock, Run, Done, BusOutput);
	input [15:0] DIN;
	input Resetn, Clock, Run;
	output Done;
	output [15:0] BusOutput;
	parameter MV = 3'd0, MVI = 3'd1, ADD = 3'd2, SUB = 3'd3; 

	wire Clear;
	assign Clear = Done;
	wire ld_Ain, ld_IR, Tstep_Q, ld_G;
	wire [2 : 0] Opcode, Rx, Ry;
	wire [7 : 0] ld_R;
	wire [8 : 0] IR;
	wire [15 : 0] Ain, ALU_out, G_out;
	reg  [15 : 0] BusWires;

	/********************** Counter for Counting Cycles *****************/
	upcount Tstep (Clear, Clock, Tstep_Q);
	/********************** Instruction Decoding ************************/
	assign Opcode = IR[8 : 6];
	dec3to8 decX (IR[5:3], 1'b1, Rx);
	dec3to8 decY (IR[2:0], 1'b1, Ry);

	/********************** Control logic *******************************/
	always @(Tstep_Q or Opcode or Rx or Ry)	
	begin
		// . . . specify initial values
		if (Resetn) begin
			Clear = 1;
			ld_IR = 0;
			ld_EN = 0;
			ld_Ain = 0;
			ld_G = 0;
			R_sel = 8'bxxxx_xxxx;
			ld_sel = 8'bxxxx_xxxx;
			bus_reg_sel = 0;
			bus_Gout_sel = 0;
			bus_DIN_sel = 0;
			Done = 0;
		end
		else begin
			case (Tstep_Q)
				2'b00: // store DIN in IR in time step 0
					begin
						Clear = 0;
						ld_IR = 1;
						ld_EN = 0;
						ld_Ain = 0;
						ld_G = 0;
						R_sel = 8'bxxxx_xxxx;
						ld_sel = 8'bxxxx_xxxx;
						bus_reg_sel = 0;
						bus_Gout_sel = 0;
						bus_DIN_sel = 1;
						Done = 0;
					end
				2'b01: 
					case (Opocde)
						MV: begin
							ld_IR = 0;
							R_sel = Ry;
							bus_reg_sel = 1;
							ld_EN = 1;
							ld_sel = Rx;
							ld_Ain = 0;
							Done = 1;
						end
						MVI: begin
							ld_IR = 0;
							R_sel = 8'bxxxx_xxxx;
							BusWires = DIN;
							ld_EN = 1;
							ld_sel = Rx;
							ld_Ain = 0;
							Done = 1;
						end
						ADD: begin
							ld_IR = 0;
							R_sel = Rx;
							ld_EN = 0;
							ld_sel = 8'bxxxx_xxxx;
							ld_Ain = 1;
						end
						SUB: begin
							ld_IR = 0;
							R_sel = Rx;
							ld_EN = 0;
							ld_sel = 8'bxxxx_xxxx;
							ld_Ain = 1;
							
						end
						default: begin
							ld_Ain = 1'bx;
							ld_R = 1'bx;
							ld_EN = 0;

							ld_sel = 8'bxxxx_xxxx;
						end
					endcase
				2'b10: //define signals in time step 2
					case (Opcode)
						MV: begin
							/*set zero*/
							ld_IR = 0;
							ld_EN = 0;
							ld_sel = 8'bxxxx_xxxx;
							ld_Ain = 0;
							ld_G = 0;
						end
						MVI: begin
							/*set zero*/
							ld_IR = 0;
							ld_EN = 0;
							ld_sel = 8'bxxxx_xxxx;
							
							ld_Ain = 0;
							ld_G = 0;
						end 
						ADD: begin
							// cycle 2 we place Ry on the bus
							R_sel = Ry;
							ld_G = 1;
						end
						SUB: begin
							
						end
						default: begin
							
						end
					endcase
				2'b11: //define signals in time step 3
					case (Opcode)
						MV: begin
							
						end
						MVI: begin
							
						end
						ADD: begin
							
						end
						SUB: begin
							BusWires = G_out;
							ld_sel = Rx;
							Done = 1;
						end
						default:
					endcase
			endcase
		end
	end

	// assign R_sel = X_sel? Rx: Ry ;
	/************************** BUS mux ********************************/
	always @ (*) begin
		if (bus_reg_sel) begin
			case(R_sel) 
				8'b0000_0000: BusWires = R0;
				8'b0000_0010: BusWires = R1; 
				8'b0000_0100: BusWires = R2;
				8'b0000_1000: BusWires = R3;
				8'b0001_0000: BusWires = R4;
				8'b0010_0000: BusWires = R5;
				8'b0100_0000: BusWires = R6;
				8'b1000_0000: BusWires = R7;
			endcase
		end
		else if (bus_Gout_sel) begin
				BusWires = G_out;
		end
		else if (bus_DIN_sel) begin
				BusWires = DIN;
		end
		else 	// should not happen
				BusWires = 16'bxxxx_xxxx_xxxx_xxxx;
	end	

	/************************* Register Load Enable ********************/
	always @ (*)
		case(ld_sel)
			8'b0000_0000: ld_R[0] = ld_EN;
			8'b0000_0010: ld_R[1] = ld_EN; 
			8'b0000_0100: ld_R[2] = ld_EN;
			8'b0000_1000: ld_R[3] = ld_EN;
			8'b0001_0000: ld_R[4] = ld_EN;
			8'b0010_0000: ld_R[5] = ld_EN;
			8'b0100_0000: ld_R[6] = ld_EN;
			8'b1000_0000: ld_R[7] = ld_EN;
		endcase
	end

	/**************************** Registers ***************************/
	regn R_0 (BusWires, ld_R[0], Clock, R0);
	regn R_1 (BusWires, ld_R[1], Clock, R1);
	regn R_2 (BusWires, ld_R[2], Clock, R2);
	regn R_3 (BusWires, ld_R[3], Clock, R3);
	regn R_4 (BusWires, ld_R[4], Clock, R4);
	regn R_5 (BusWires, ld_R[5], Clock, R5);
	regn R_6 (BusWires, ld_R[6], Clock, R6);
	regn R_7 (BusWires, ld_R[7], Clock, R7);
	regn A_in(BusWires, ld_Ain, Clock, Ain);
	regn #(.n(9)) R_IR (DIN, ld_IR, Clock, IR);
	regn G   (ALU_out,  ld_G, Clock, G_out);
	/**************************** ALU **************************/
	ALU  alu (Ain, BusWires, AddSub, ALU_out);
	assign BusOutput = BusWires;
endmodule
