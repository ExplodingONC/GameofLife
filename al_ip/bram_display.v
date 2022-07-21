/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/Users/AORUS/OneDrive/Projects_Anlogic/GameofLife/al_ip/bram_display.v
 ** Date	:	2020 10 16
 ** TD version	:	5.0.20999
\************************************************************/

`timescale 1ns / 1ps

module bram_display ( 
	dia, addra, cea, clka,
	dob, addrb, ceb, clkb
);

	output [23:0] dob;


	input  [23:0] dia;
	input  [12:0] addra;
	input  [12:0] addrb;
	input  cea;
	input  ceb;
	input  clka;
	input  clkb;



	parameter DATA_WIDTH_A = 24; 
	parameter ADDR_WIDTH_A = 13;
	parameter DATA_DEPTH_A = 8192;
	parameter DATA_WIDTH_B = 24;
	parameter ADDR_WIDTH_B = 13;
	parameter DATA_DEPTH_B = 8192;

	EG_LOGIC_BRAM #( .DATA_WIDTH_A(DATA_WIDTH_A),
				.DATA_WIDTH_B(DATA_WIDTH_B),
				.ADDR_WIDTH_A(ADDR_WIDTH_A),
				.ADDR_WIDTH_B(ADDR_WIDTH_B),
				.DATA_DEPTH_A(DATA_DEPTH_A),
				.DATA_DEPTH_B(DATA_DEPTH_B),
				.MODE("PDPW"),
				.REGMODE_A("NOREG"),
				.REGMODE_B("NOREG"),
				.WRITEMODE_A("NORMAL"),
				.WRITEMODE_B("NORMAL"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("9K"),
				.INIT_FILE("NONE"),
				.FILL_ALL("000000000000000000000000"))
			inst(
				.dia(dia),
				.dib({24{1'b0}}),
				.addra(addra),
				.addrb(addrb),
				.cea(cea),
				.ceb(ceb),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(clka),
				.clkb(clkb),
				.wea(1'b1),
				.web(1'b0),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(),
				.dob(dob));


endmodule