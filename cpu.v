module cpu(
	clk, rst, adrs, din, dout, mem_read, mem_write, 
	pr, mar, ir, gr, sc );
	
	input  clk, rst;
	output [7:0] adrs;
	input  [7:0] din;
	output [7:0] dout;
	output mem_read;
	output mem_write;
	output [7:0] pr, mar, ir, gr;
	output [2:0] sc;
	
	wire   [7:0] a, b;
	wire   [7:0] y;
	wire   [1:0] alu_sel;
	wire   a_sel, pr_load, mar_load, ir_load, gr_load, sc_clear;
	
	assign a = ( a_sel == 1'b1 ) ? gr : pr;
	assign b = ( mem_read == 1'b1 ) ? din : 8'bxxxxxxxx;
	assign adrs = ( mem_read | mem_write == 1'b1 ) ? mar : 8'bxxxxxxxx;
	assign dout = ( mem_write == 1'b1 ) ? y : 8'bxxxxxxxx;
	
	reg8 reg_pr(  .clk(clk), .rst(rst), .load(pr_load),  .d(y), .q(pr)  );
	reg8 reg_mar( .clk(clk), .rst(rst), .load(mar_load), .d(y), .q(mar) );
	reg8 reg_ir(  .clk(clk), .rst(rst), .load(ir_load),  .d(y), .q(ir)  );
	reg8 reg_gr(  .clk(clk), .rst(rst), .load(gr_load),  .d(y), .q(gr)  );
	
	alu alu( .a(a), .b(b), .sel(alu_sel), .y(y) );
	
	cnt3 cnt_sc( .clk(clk), .rst(rst), .clear(sc_clear), .q(sc) );
	
	csg csg(
		.sc(sc), .ir(ir),
		.alu_sel(alu_sel), .a_sel(a_sel), 
		.pr_load(pr_load), .mar_load(mar_load), .ir_load(ir_load), .gr_load(gr_load), 
		.mem_read(mem_read), .mem_write(mem_write), .sc_clear(sc_clear) );
	
endmodule

module reg8(
	clk, rst, load, d, q );
	
	input  clk, rst, load;
	input  [7:0] d;
	output [7:0] q;
	reg    [7:0] q;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			q <= 8'h00;
		end else if( load == 1'b1 ) begin
			q <= d;
		end
	end
endmodule

module cnt3(
	clk, rst, clear, q );
	
	input  clk, rst, clear;
	output [2:0] q;
	reg    [2:0] q;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			q <= 3'h0;
		end else if( clear == 1'b1 ) begin
			q <= 3'h0;
		end else begin
			q <= q + 3'h1;
		end
	end
endmodule

module alu(
	a, b, sel, y );
	
	input  [7:0] a, b;
	input  [1:0] sel;
	output [7:0] y;
	reg    [7:0] y;
	
	always@( a or b or sel ) begin
		case( sel )
			2'b00 : y <= a;
			2'b01 : y <= b;
			2'b10 : y <= a + 1'b1;
			2'b11 : y <= a + b;
			default: y <= 8'hxx;
		endcase
	end
endmodule

module csg(
	sc, ir,
	alu_sel, a_sel, pr_load, mar_load, ir_load, gr_load,
	mem_read, mem_write, sc_clear );
	
	input  [7:0] ir;
	input  [2:0] sc;
	
	output [1:0] alu_sel;
	output a_sel, pr_load, mar_load, ir_load, gr_load;
	output mem_read, mem_write;
	output sc_clear;
	
	wire   [6:0] s;
	wire   [6:0] i;
	
	assign s[0] = ~sc[2] & ~sc[1] & ~sc[0];
	assign s[1] = ~sc[2] & ~sc[1] &  sc[0];
	assign s[2] = ~sc[2] &  sc[1] & ~sc[0];
	assign s[3] = ~sc[2] &  sc[1] &  sc[0];
	assign s[4] =  sc[2] & ~sc[1] & ~sc[0];
	assign s[5] =  sc[2] & ~sc[1] &  sc[0];
	assign s[6] =  sc[2] &  sc[1] & ~sc[0];
	
	assign i[1] = ~|ir[7:3] & ~ir[2] & ~ir[1] &  ir[0];
	assign i[2] = ~|ir[7:3] & ~ir[2] &  ir[1] & ~ir[0];
	assign i[3] = ~|ir[7:3] & ~ir[2] &  ir[1] &  ir[0];
	assign i[4] = ~|ir[7:3] &  ir[2] & ~ir[1] & ~ir[0];
	assign i[5] = ~|ir[7:3] &  ir[2] & ~ir[1] &  ir[0];
	assign i[6] = ~|ir[7:3] &  ir[2] &  ir[1] & ~ir[0];
	assign i[0] =  |ir[7:3] | ~|i[6:1];
	
	assign alu_sel[0] = s[2] | s[5] | s[6] & ( i[2] | i[4] );
	assign alu_sel[1] = s[1] | s[4] | s[5] & i[3] | s[6] & i[4];
	assign a_sel      = s[5] | s[6];
	assign mem_read   = s[2] | s[5] | s[6] & ( i[2] | i[4] );
	assign mem_write  = s[6] & i[5];
	assign pr_load    = s[1] | s[4] | s[5] & i[6];
	assign mar_load   = s[0] | s[3] & ~i[0] | s[5] & ( i[2] | i[4] | i[5] );
	assign ir_load    = s[2];
	assign gr_load    = s[5] & ( i[1] | i[3] ) | s[6] & ( i[2] | i[4] );
	assign sc_clear   = s[3] & i[0] | s[5] & ( i[1] | i[3] | i[6] ) | s[6];
	
endmodule
