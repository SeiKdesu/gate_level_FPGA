`timescale 1us/1us

module top(
	rx_clk, rk_clk, rst,
	psw_a, psw_b, psw_c, psw_d, rtsw_a, rtsw_b, 
	bz, led, seg_a, seg_b, seg_sela, seg_selb );
	
	input  rx_clk, rk_clk, rst;
	input  [ 4:0] psw_a, psw_b, psw_c, psw_d;
	input  [ 3:0] rtsw_a, rtsw_b;
	output bz;
	output [ 7:0] led;
	output [ 7:0] seg_a, seg_b;
	output [ 3:0] seg_sela, seg_selb;
	
	wire   [19:0] psw_out;
	wire   [ 7:0] bz_val;
	wire   bz_wr;
	wire   [ 3:0] val_a, val_b, val_c, val_d, val_e, val_f, val_g, val_h;
	wire   [ 7:0] ram20, ram21, ram22, ram23;
	wire   [ 7:0] io24,  io25,  io26,  io27;
	wire   [ 7:0] pr,    mar,   ir,    gr;
	wire   [ 2:0] sc;
	
	wire   [ 7:0] adrs, mem2cpu, cpu2mem;
	wire   [ 7:0] io_dout, ram_dout, rom_dout;
	wire   io_cs, ram_cs, rom_cs;
	wire   mem_read, mem_write;
	wire   cpu_clk;
	wire   step_view, mem_view, io_view;
	
	mode_control mode_control(
	  .clk(rx_clk), .rst(rst), .psw_out(psw_out), 
	  .step_view(step_view), .mem_view(mem_view), .io_view(io_view) );
	
	cpu cpu(
	  .clk(cpu_clk), .rst(rst), .adrs(adrs), .din(mem2cpu), .dout(cpu2mem), 
	  .mem_read(mem_read), .mem_write(mem_write), 
	  .pr(pr), .mar(mar), .ir(ir), .gr(gr), .sc(sc) );
	
	rom rom(
	  .adrs(adrs), .dout(rom_dout), .rd(rom_cs & mem_read) );
	
	ram ram(
	  .clk(cpu_clk), .rst(rst), .adrs(adrs[1:0]), .din(cpu2mem), .dout(ram_dout), 
	  .rd(ram_cs & mem_read), .wr(ram_cs & mem_write), 
	  .ram20(ram20), .ram21(ram21), .ram22(ram22), .ram23(ram23) );
	
	io_port io_port(
	  .clk(rx_clk), .rst(rst), .adrs(adrs[1:0]), .din(cpu2mem), .dout(io_dout), 
	  .rd(io_cs & mem_read), .wr(io_cs & mem_write), 
	  .rtsw_a(rtsw_a), .rtsw_b(rtsw_b), .key(psw_out), .bz_val(bz_val), .bz_wr(bz_wr),
	  .io24(io24), .io25(io25), .io26(io26), .io27(io27) );
	
	io_control io_control(
	  .clk(rx_clk), .rst(rst), 
	  .bz_wr(bz_wr), .bz_val(bz_val), .bz(bz),
	  .psw_a(psw_a), .psw_b(psw_b), .psw_c(psw_c), .psw_d(psw_d), .psw_out(psw_out),
	  .val_a(val_a), .val_b(val_b), .val_c(val_c), .val_d(val_d),
	  .val_e(val_e), .val_f(val_f), .val_g(val_g), .val_h(val_h),
	  .seg_outa(seg_a), .seg_outb(seg_b), 
	  .seg_sela(seg_sela), .seg_selb(seg_selb) );
	
	assign cpu_clk = ( step_view ) ? psw_out[9] : rk_clk;
	
	assign rom_cs = ( adrs[7:5] == 3'b000 );
	assign ram_cs = ( adrs[7:2] == 6'b001000 );
	assign io_cs  = ( adrs[7:2] == 6'b001001 );
	
	assign mem2cpu = ( io_cs  ) ? io_dout  : 
	                 ( ram_cs ) ? ram_dout : rom_dout;
	
	assign { val_a, val_b, val_c, val_d, val_e, val_f, val_g, val_h } = 
	       ( mem_view == 1'b1 ) ? { ram20, ram21, ram22, ram23 } : 
	       ( io_view  == 1'b1 ) ? { io24,  io25,  io26,  io27  } : 
	                              { pr,    mar,   ir,    gr    } ;
	
	assign led = { ~step_view, step_view, mem_view, io_view, cpu_clk, sc };
	
endmodule
