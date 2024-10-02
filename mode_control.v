module mode_control(
	clk, rst, psw_out, step_view, mem_view, io_view );
	
	input  clk, rst;
	input  [19:0] psw_out;
	output step_view, mem_view, io_view;
	reg    step_view, mem_view, io_view;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			step_view <= 1'b1;
		end else if( psw_out[9] == 1'b1 ) begin
			step_view <= 1'b1;
		end else if( psw_out[4] == 1'b1 ) begin
			step_view <= ~step_view;
		end
	end
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			mem_view <= 1'b0;
		end else if( psw_out[19] == 1'b1 ) begin
			mem_view <= 1'b0;
		end else if( psw_out[14] == 1'b1 ) begin
			mem_view <= ~mem_view;
		end
	end
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			io_view <= 1'b0;
		end else if( psw_out[14] == 1'b1 ) begin
			io_view <= 1'b0;
		end else if( psw_out[19] == 1'b1 ) begin
			io_view <= ~io_view;
		end
	end
	
endmodule
