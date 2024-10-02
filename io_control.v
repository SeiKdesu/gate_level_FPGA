module io_control(
	clk, rst,
	bz_wr, bz_val, bz,
	psw_a, psw_b, psw_c, psw_d, psw_out,
	val_a, val_b, val_c, val_d,
	val_e, val_f, val_g, val_h,
	seg_outa, seg_outb, seg_sela, seg_selb );
	
	input  clk, rst;
	
	input  bz_wr;
	input  [ 7:0] bz_val;
	output bz;
	
	input  [ 4:0] psw_a, psw_b, psw_c, psw_d;
	output [19:0] psw_out;
	
	input  [ 3:0] val_a, val_b, val_c, val_d, val_e, val_f, val_g, val_h;
	output [ 7:0] seg_outa, seg_outb;
	output [ 3:0] seg_sela, seg_selb;
	
	io_bz io_bz(
	  .clk(clk), .rst(rst), .start(bz_wr), .val(bz_val), .bz(bz) );
	
	io_psw io_psw(
	  .clk(clk), .rst(rst), 
	  .psw_a(psw_a), .psw_b(psw_b), .psw_c(psw_c), .psw_d(psw_d), .psw_out(psw_out) );
	
	io_seg io_seg(
	  .clk(clk), .rst(rst), 
	  .val_a(val_a), .val_b(val_b), .val_c(val_c), .val_d(val_d),
	  .val_e(val_e), .val_f(val_f), .val_g(val_g), .val_h(val_h),
	  .seg_outa(seg_outa), .seg_outb(seg_outb), 
	  .seg_sela(seg_sela), .seg_selb(seg_selb) );
	
endmodule

/****************
  ブザー制御回路
 ****************/

module io_bz(
	clk, rst, 
	start, val, bz );
	
	input  clk;
	input  rst;
	input  start;
	input  [7:0] val;
	output bz;
	
	wire   enable, pitch;
	
	bz_time bt( .clk(clk), .rst(rst), .start(start), .val(val[7:4]), .enable(enable) );
	bz_pitch bp( .clk(clk), .rst(rst), .val(val[3:0]), .pitch(pitch) );
	
	assign bz = enable & pitch;
	
endmodule

/*
 * 音程生成回路
 *
 * 入力値に応じた周波数のピッチ信号を出力
 *
 */

module bz_pitch( 
	clk, rst, val, pitch );
	
	input  clk, rst;
	input  [3:0] val;
	output pitch;
	reg    pitch;
	reg    [15:0] cnt;
	reg    [15:0] cref;
	wire   max, zero;
	
	/* 入力値に応じてカウンタのしきい値を設定 */
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin	
			cref <= 16'hFFFF;
		end else begin
			case( val )                     /*        Hz */
				4'b0000: cref <= 16'hFFFF;  /* R    0.00 */
				4'b0001: cref <= 16'd38223; /* C  261.62 */
				4'b0010: cref <= 16'd34053; /* D  293.66 */
				4'b0011: cref <= 16'd30338; /* E  329.62 */
				4'b0100: cref <= 16'd28635; /* F  349.22 */
				4'b0101: cref <= 16'd25511; /* G  391.99 */
				4'b0110: cref <= 16'd22727; /* A  440.00 */
				4'b0111: cref <= 16'd20248; /* B  493.88 */
				4'b1000: cref <= 16'd19111; /* C  523.25 */
				4'b1001: cref <= 16'd17026; /* D  587.32 */
				4'b1010: cref <= 16'd15169; /* E  659.25 */
				4'b1011: cref <= 16'd14317; /* F  698.45 */
				4'b1100: cref <= 16'd12755; /* G  783.99 */
				4'b1101: cref <= 16'd11364; /* A  880.00 */
				4'b1110: cref <= 16'd10124; /* B  987.76 */
				4'b1111: cref <= 16'd09556; /* C 1046.50 */
				default: cref <= 16'hFFFF;
			endcase
		end
	end
	
	assign max = ( cnt == cref );
	assign zero = ( val == 4'h0 );
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cnt <= 16'h0;
		end else if( zero == 1'b1 ) begin
			/* 入力値が0の場合はカウンタを停止 */
			cnt <= 16'h0;
		end else if( max == 1'b1 ) begin
			/* しきい値に達したらカウンタを初期化 */
			cnt <= 16'h1;
		end else begin
			/* カウントを繰り返す */
			cnt <= cnt + 16'h1; 
		end
	end
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			pitch <= 1'b0;
		end else if( zero == 1'b1 ) begin
			/* 入力値が0の場合はピッチ信号を停止 */
			pitch <= 1'b0;
		end else if( max == 1'b1 ) begin
			/* カウンタからのパルスでピッチ信号を反転 */
			pitch <= ~pitch;
		end
	end
	
endmodule

/*
 * 音価生成回路
 *
 * トリガ入力の立ち上がりから
 * 入力値に応じた長さのイネーブル信号を出力
 */

module bz_time(
	clk, rst, start, val, enable );
	
	input clk, rst;
	input start;
	input [3:0] val;
	output enable;
	reg    [ 1:0] dly;
	reg    [23:0] cnt;
	reg    [23:0] cref;
	wire   max;
	
	/* 入力値に応じてカウンタのしきい値を設定 */
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cref <= 24'd0;
		end else begin
			case( val )                        /* sec */
				4'b0000: cref <= 24'd01000000; /* 0.1 */
				4'b0001: cref <= 24'd02000000; /* 0.2 */
				4'b0010: cref <= 24'd03000000; /* 0.3 */
				4'b0011: cref <= 24'd04000000; /* 0.4 */
				4'b0100: cref <= 24'd05000000; /* 0.5 */
				4'b0101: cref <= 24'd06000000; /* 0.6 */
				4'b0110: cref <= 24'd07000000; /* 0.7 */
				4'b0111: cref <= 24'd08000000; /* 0.8 */
				4'b1000: cref <= 24'd09000000; /* 0.9 */
				4'b1001: cref <= 24'd10000000; /* 1.0 */
				4'b1010: cref <= 24'd11000000; /* 1.1 */
				4'b1011: cref <= 24'd12000000; /* 1.2 */
				4'b1100: cref <= 24'd13000000; /* 1.3 */
				4'b1101: cref <= 24'd14000000; /* 1.4 */
				4'b1110: cref <= 24'd15000000; /* 1.5 */
				4'b1111: cref <= 24'd16000000; /* 1.6 */
				default: cref <= 24'd0;
			endcase
		end
	end
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			dly <= 2'b00;
		end else begin
			/* トリガ入力の立ち上がりを検出 */
			dly <= { dly[0], start };
		end
	end
	
	assign max = ( cnt == cref );
	assign enable = ( cnt != 24'h0 );
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cnt <= 24'd0;
		end else if( dly == 2'b10 ) begin
			/* トリガ入力を検出したらカウンタの動作開始 */
			cnt <= 24'd1;
		end else if( max == 1'b1 ) begin
			/* しきい値に達したらカウンタの動作停止 */
			cnt <= 24'd0;
		end else begin
			/* カウンタが停止するまでイネーブル信号を立ち上げる */
			cnt <= cnt + enable;
		end
	end
	
endmodule

/**************************
  プッシュスイッチ制御回路
 **************************/

module io_psw(
	clk, rst, 
	psw_a, psw_b, psw_c, psw_d, psw_out );
	
	input  clk, rst;
	input  [4:0] psw_a, psw_b, psw_c, psw_d;
	output [19:0] psw_out;
	
	wire ld;
	
	psw_pulse pp( .clk(clk), .rst(rst), .co(ld) );
	
	psw_detecter p00( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_a[0]), .psw_out(psw_out[0]) );
	psw_detecter p01( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_a[1]), .psw_out(psw_out[1]) );
	psw_detecter p02( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_a[2]), .psw_out(psw_out[2]) );
	psw_detecter p03( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_a[3]), .psw_out(psw_out[3]) );
	psw_detecter p04( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_a[4]), .psw_out(psw_out[4]) );
	psw_detecter p05( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_b[0]), .psw_out(psw_out[5]) );
	psw_detecter p06( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_b[1]), .psw_out(psw_out[6]) );
	psw_detecter p07( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_b[2]), .psw_out(psw_out[7]) );
	psw_detecter p08( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_b[3]), .psw_out(psw_out[8]) );
	psw_detecter p09( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_b[4]), .psw_out(psw_out[9]) );
	psw_detecter p10( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_c[0]), .psw_out(psw_out[10]) );
	psw_detecter p11( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_c[1]), .psw_out(psw_out[11]) );
	psw_detecter p12( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_c[2]), .psw_out(psw_out[12]) );
	psw_detecter p13( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_c[3]), .psw_out(psw_out[13]) );
	psw_detecter p14( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_c[4]), .psw_out(psw_out[14]) );
	psw_detecter p15( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_d[0]), .psw_out(psw_out[15]) );
	psw_detecter p16( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_d[1]), .psw_out(psw_out[16]) );
	psw_detecter p17( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_d[2]), .psw_out(psw_out[17]) );
	psw_detecter p18( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_d[3]), .psw_out(psw_out[18]) );
	psw_detecter p19( .clk(clk), .rst(rst), .ld(ld), .psw_in(psw_d[4]), .psw_out(psw_out[19]) );
	
endmodule

/*
 * 周期パルス出力回路
 *
 * 周期5msのパルスを出力
 *
 */

module psw_pulse(
	clk, rst, co );
	
	input  clk, rst;
	output co;
	reg    [16:0] cnt;
	
	assign co = ( cnt == 17'd100000 );
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cnt <= 17'h0;
		end else if( co == 1'b1 ) begin
			/* しきい値に達したらカウンタを初期化 */
			cnt <= 17'h1;
		end else begin
			/* カウントを繰り返す */
			cnt <= cnt + 17'h1; 
		end
	end
	
endmodule

/*
 * キー入力検出回路
 *
 * シフトレジスタでスイッチ入力を検出
 * 検出したら一定時間経過後にパルスを1回だけ出力
 *
 */

module psw_detecter(
	clk, rst, ld, psw_in, psw_out );
	
	input  clk, rst;
	input  ld;
	input  psw_in;
	output psw_out;
	
	reg    [1:0] dly;
	reg    [2:0] cnt;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			dly <= 2'b11;
		end else if( ld == 1'b1 ) begin
			/* シフトレジスタでスイッチ入力を検出 */
			dly <= { dly[0], psw_in };
		end
	end
	
	assign psw_out = &cnt;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cnt <= 3'h0;
		end else if( dly[0] == 1'b1 ) begin /* 01 or 11 */
			/* スイッチ入力がなければカウント停止 */
			cnt <= 3'h0;
		end else if( dly[1] == 1'b1 ) begin /* 10 */
			/* スイッチ入力を検出したらカウント開始 */
			cnt <= 3'h1;
		end else if( psw_out == 1'b1 ) begin
			/* しきい値に達したらカウント停止 */
			cnt <= 3'h0;
		end else if( cnt != 3'h0 ) begin
			/* 停止状態でなければカウントを繰り返す */
			cnt <= cnt + 3'h1;
		end
	end
	
endmodule

/************************
  7セグメントLED制御回路
 ************************/

module io_seg(
	clk, rst,
	val_a, val_b, val_c, val_d, val_e, val_f, val_g, val_h,
	seg_outa, seg_outb, seg_sela, seg_selb );
	
	input  clk;
	input  rst;
	input  [3:0] val_a, val_b, val_c, val_d, val_e, val_f, val_g, val_h;
	output [7:0] seg_outa, seg_outb;
	output [3:0] seg_sela, seg_selb;
	
	wire   [7:0] seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g, seg_h;
	wire   [3:0] sel;
	
	seg_selecter ss( .clk(clk), .rst(rst), .sel(sel) );
	
	seg_decoder sd1( .clk(clk), .rst(rst), .val(val_a), .seg(seg_a) );
	seg_decoder sd2( .clk(clk), .rst(rst), .val(val_b), .seg(seg_b) );
	seg_decoder sd3( .clk(clk), .rst(rst), .val(val_c), .seg(seg_c) );
	seg_decoder sd4( .clk(clk), .rst(rst), .val(val_d), .seg(seg_d) );
	seg_decoder sd5( .clk(clk), .rst(rst), .val(val_e), .seg(seg_e) );
	seg_decoder sd6( .clk(clk), .rst(rst), .val(val_f), .seg(seg_f) );
	seg_decoder sd7( .clk(clk), .rst(rst), .val(val_g), .seg(seg_g) );
	seg_decoder sd8( .clk(clk), .rst(rst), .val(val_h), .seg(seg_h) );
	
	seg_register sr_a( .clk(clk), .rst(rst), .sel(sel), 
	            .seg_in({seg_a, seg_b, seg_c, seg_d}), 
	            .seg_out(seg_outa) );
	seg_register sr_b( .clk(clk), .rst(rst), .sel(sel), 
	            .seg_in({seg_e, seg_f, seg_g, seg_h}), 
	            .seg_out(seg_outb) );
	
	assign seg_sela = sel;
	assign seg_selb = sel;
	
endmodule

/*
 * 7セグメントLED選択回路
 *
 * 一定時間ごとに出力先の7セグメントLEDの選択信号を切り換える
 *
 */

module seg_selecter(
	clk, rst, sel );
	
	input  clk, rst;
	output [ 3:0] sel;
	
	reg    [ 3:0] sel;
	reg    [13:0] cnt;
	wire   max;
	
	assign max = ( cnt == 14'h3000 );
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			cnt <= 14'h1;
		end else if( cnt == max ) begin
			/* しきい値に達したらパルスを出力 */
			cnt <= 14'h1;
		end else begin
			/* カウントを繰り返す */
			cnt <= cnt + 14'h1;
		end
	end
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			sel <= 4'b1110;
		end else if( max == 1'b1 ) begin
			/* カウンタからのパルスで選択信号を変更 */
			sel <= { sel[2:0], sel[3] };
		end
	end
	
endmodule

/*
 * 7セグメントLEDデコーダ
 *
 * 入力された値を7セグメントLEDの表示パターンにデコードする
 *
 */

module seg_decoder(
	clk, rst, val, seg );
	
	input  clk, rst;
	input  [3:0] val;
	output [7:0] seg;
	
	reg    [7:0] seg;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			seg <= 8'h0;
		end else begin
			case( val )
				4'h0: seg <= 8'b11111100;
				4'h1: seg <= 8'b01100000;
				4'h2: seg <= 8'b11011010;
				4'h3: seg <= 8'b11110010;
				4'h4: seg <= 8'b01100110;
				4'h5: seg <= 8'b10110110;
				4'h6: seg <= 8'b10111110;
				4'h7: seg <= 8'b11100000;
				4'h8: seg <= 8'b11111110;
				4'h9: seg <= 8'b11110110;
				4'hA: seg <= 8'b11101110;
				4'hB: seg <= 8'b00111110;
				4'hC: seg <= 8'b00011010;
				4'hD: seg <= 8'b01111010;
				4'hE: seg <= 8'b10011110;
				4'hF: seg <= 8'b10001110;
				default: seg <= 8'bxxxxxxxx;
			endcase
		end
	end
	
endmodule

/*
 * 7セグメントLED出力回路
 *
 * 7セグメントLEDに選択された表示パターンを出力する
 *
 */

module seg_register(
	clk, rst, sel, seg_in, seg_out );
	
	input  clk, rst;
	input  [31:0] seg_in;
	input  [ 3:0] sel;
	output [ 7:0] seg_out;
	
	reg    [ 7:0] seg_out;
	
	always@( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			seg_out <= 8'h0;
		end else begin
			case( sel )
				4'b1110: seg_out <= seg_in[31:24];
				4'b1101: seg_out <= seg_in[23:16];
				4'b1011: seg_out <= seg_in[15: 8];
				4'b0111: seg_out <= seg_in[ 7: 0];
				default: seg_out <= 8'hxx;
			endcase
		end
	end
	
endmodule
