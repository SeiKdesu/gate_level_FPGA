`timescale 1us/1us

module sim();
	
	reg  clk, rst;
	
	wire [7:0] adrs;
	wire rom_cs, ram_cs;
	wire mem_read;
	wire [7:0] rom_dout;
	wire [7:0] ram_dout;
	wire [7:0] mem2cpu;
	wire mem_write;
	wire [7:0] cpu2mem;
	wire a_sel = cpu.a_sel;
	wire [7:0] a = cpu.a;
	wire [7:0] b = cpu.b;
	wire [1:0] alu_sel = cpu.alu_sel;
	wire [7:0] y = cpu.y;
	wire pr_load = cpu.pr_load;
	wire [7:0] pr;
	wire mar_load = cpu.mar_load;
	wire [7:0] mar;
	wire ir_load = cpu.ir_load;
	wire [7:0] ir;
	wire gr_load = cpu.gr_load;
	wire [7:0] gr;
	wire sc_clear = cpu.sc_clear;
	wire [2:0] sc;
	wire [7:0] ram20, ram21, ram22, ram23;
	
	cpu cpu(
	  .clk(clk), .rst(rst), .adrs(adrs), .din(mem2cpu), .dout(cpu2mem), 
	  .mem_read(mem_read), .mem_write(mem_write),
	  .pr(pr), .mar(mar), .ir(ir), .gr(gr), .sc(sc) );
	
	rom rom(
	  .adrs(adrs), .dout(rom_dout), .rd(rom_cs & mem_read) );
	
	ram ram(
	  .clk(clk), .rst(rst), .adrs(adrs[1:0]), .din(cpu2mem), .dout(ram_dout), 
	  .rd(ram_cs & mem_read), .wr(ram_cs & mem_write), 
	  .ram20(ram20), .ram21(ram21), .ram22(ram22), .ram23(ram23) );
	
	assign rom_cs = ( adrs[7:5] == 3'b000 );
	assign ram_cs = ( adrs[7:2] == 6'b001000 );
	
	assign mem2cpu = ( ram_cs ) ? ram_dout : rom_dout;
	
	initial begin
		clk = 1'b1;
		forever #50 clk = ~clk;
	end
	
	initial begin
		rst = 1'b0;
		#50
		rst = 1'b1;
	end
	
endmodule
