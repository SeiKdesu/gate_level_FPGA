module ram(
	clk, rst, 
	adrs, din, dout, rd, wr, 
	ram20, ram21, ram22, ram23 );
	
	input  clk, rst;
	input  [1:0] adrs;
	input  [7:0] din;
	output [7:0] dout;
	input  rd, wr;
	output [7:0] ram20, ram21, ram22, ram23;
	
	reg    [7:0] ram_data[0:3];
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			ram_data[0] <= 8'h00;
			ram_data[1] <= 8'h00;
			ram_data[2] <= 8'h00;
			ram_data[3] <= 8'h00;
		end else if( wr == 1'b1 ) begin
			ram_data[adrs] <= din;
		end
	end
	
	assign dout = ( rd == 1'b1 ) ? ram_data[adrs] : 8'bxxxxxxxx;
	
	assign ram20 = ram_data[0];
	assign ram21 = ram_data[1];
	assign ram22 = ram_data[2];
	assign ram23 = ram_data[3];
	
endmodule
