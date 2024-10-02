module rom(
	adrs, dout, rd );
	
	input  [7:0] adrs;
	output [7:0] dout;
	input  rd;
	
	reg    [7:0] rom_data;
	
	always@( adrs ) begin
		case( adrs )
			8'h00 : rom_data = 8'h01;
			8'h01 : rom_data = 8'h20;
			8'h02 : rom_data = 8'h05;
			8'h03 : rom_data = 8'h22;
			8'h04 : rom_data = 8'h03;
			8'h05 : rom_data = 8'h20;
			8'h06 : rom_data = 8'h05;
			8'h07 : rom_data = 8'h23;
			8'h08 : rom_data = 8'h02;
			8'h09 : rom_data = 8'h22;
			8'h0A : rom_data = 8'h04;
			8'h0B : rom_data = 8'h22;
			8'h0C : rom_data = 8'h06;
			8'h0D : rom_data = 8'h02;
			default : rom_data = 8'bxxxxxxxx;
		endcase
	end
	
	assign dout = ( rd == 1'b1 ) ? rom_data : 8'bxxxxxxxx;
	
endmodule
