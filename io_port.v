module io_port(
	clk, rst, 
	adrs, din, dout, rd, wr, 
	rtsw_a, rtsw_b, key, bz_val, bz_wr, 
	io24, io25, io26, io27 );
	
	input  clk, rst;
	input  [ 1:0] adrs;
	input  [ 7:0] din;
	output [ 7:0] dout;
	input  rd, wr;
	input  [ 3:0] rtsw_a;
	input  [ 3:0] rtsw_b;
	input  [19:0] key;
	output [ 7:0] bz_val;
	output bz_wr;
	output [ 7:0] io24, io25, io26, io27;
	
	reg    bz_wr;
	
	reg    [ 7:0] io_data[0:3];
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			io_data[0] <= 8'b00000000;
			io_data[1] <= 8'b00000000;
			io_data[2] <= 8'b00000000;
			io_data[3] <= 8'b00000000;
			bz_wr <= 1'b0;
		end else begin
			io_data[0] <= {rtsw_a, 4'h0};
			io_data[1] <= {4'h0, rtsw_b};
			case( key )
				20'h00001 : io_data[2] <= 8'h00;
				20'h00002 : io_data[2] <= 8'h01;
				20'h00004 : io_data[2] <= 8'h02;
				20'h00008 : io_data[2] <= 8'h03;
				20'h00020 : io_data[2] <= 8'h04;
				20'h00040 : io_data[2] <= 8'h05;
				20'h00080 : io_data[2] <= 8'h06;
				20'h00100 : io_data[2] <= 8'h07;
				20'h00400 : io_data[2] <= 8'h08;
				20'h00800 : io_data[2] <= 8'h09;
				20'h01000 : io_data[2] <= 8'h0A;
				20'h02000 : io_data[2] <= 8'h0B;
				20'h08000 : io_data[2] <= 8'h0C;
				20'h10000 : io_data[2] <= 8'h0D;
				20'h20000 : io_data[2] <= 8'h0E;
				20'h40000 : io_data[2] <= 8'h0F;
			endcase
			if( wr == 1'b1 ) begin
				io_data[adrs] <= din;
				bz_wr <= ( adrs == 2'b11 );
			end else begin
				bz_wr <= 1'b0;
			end
		end
	end
	
	assign dout = ( rd == 1'b1 ) ? io_data[adrs] : 8'bxxxxxxxx;
	assign bz_val = io_data[3];
	
	assign io24 = io_data[0];
	assign io25 = io_data[1];
	assign io26 = io_data[2];
	assign io27 = io_data[3];
	
endmodule
