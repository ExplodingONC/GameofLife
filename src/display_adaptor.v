module display_adaptor
	(
		input wire clk_mem_ctrl, clk_led_drive, clk_bram_disp_read,
		input wire rst_n, en, light,
		//bram input
		input wire [12:0]addr,
		input wire [23:0]data,
		input wire clk_bram_disp,
		input wire write_en,
		//display output
		output wire clk_disp,
		output wire oe,
		output wire le,
		output wire sin1R,
		output wire sin1G,
		output wire sin1B,
		output wire sin2R,
		output wire sin2G,
		output wire sin2B,
		output wire [4:0]abcde
	);
	
	
	// dispRam Outputs
	wire [23:0]dob;
	wire [12:0]addrb;
	
	// memcontrl Outputs
	wire [23:0]data1;
	wire [23:0]data2;

	// led drive
	wire leddriveclk;       
	wire read_en;
	wire [6:0]Ycount;
	wire [4:0]hangcount;
	
	reg [3:0]lightreg=0;
	
	bram_display display_buffer (
		.clka	( clk_bram_disp ),
		.addra	( addr[12:0] ),
		.cea	( write_en ),
		.dia	( data[23:0] ),
		.clkb	( clk_bram_disp_read ),
		.addrb	( addrb ),
		.ceb	( read_en ),
		.dob	( dob )
	);
	
	memory_control mem_control (
		.clk_in		( clk_mem_ctrl ),
		.data_in	( dob ),
		.en_in		( read_en ),
		.Ycount		( Ycount ),
		.hangcount	( hangcount ),
		
		.read_addr	( addrb ),
		.data1		( data1 ),
		.data2		( data2 )
	);
	

	led_display_driver #(
  		.DSIZE		( 24  ),
  		.ColPoint	( 128 ),
    	.RowPoint	( 64  ),
		.Vcount		( 19  ),
		.Hcount		( 32  ),
		.light		( 0   ),
		.CLK_RATE	( 10000000 ),
		.CLK_OUT	( 5000000  )
	) led_disp_driver (
		.clk_in		( clk_led_drive ),
		.en			( en ),
		.datain1	( data1 ),
		.datain2	( data2 ),
		
		.read_en	( read_en ),
		.clk_disp	( clk_disp ),
		.oe			( oe ),
		.le			( le ),
		.sin1R		( sin1R ),
		.sin1G		( sin1G ),
		.sin1B		( sin1B ),
		.sin2R		( sin2R ),
		.sin2G		( sin2G ),
		.sin2B		( sin2B ),
		.Ycount		( Ycount ),
		.hangcount	( hangcount ),
		.abcde		( abcde )
	);


endmodule
