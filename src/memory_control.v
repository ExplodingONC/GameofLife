module memory_control
	(
		input wire clk_in,
		input wire [23:0]data_in,
		input wire en_in,
		input wire [6:0]Ycount,
		input wire [4:0]hangcount,
		
		output reg [12:0]read_addr,
		output reg [23:0]data1,
		output reg [23:0]data2
	);

	reg [1:0]count = 0;
	
	always @( posedge clk_in ) begin
		if ( en_in ) begin
			if ( count < 1 ) begin
				count <= count+1;
			end else  begin
				count <= 0;
			end
		end else begin
			count <= 0;
		end
	end
	
	always @( count, en_in, hangcount, Ycount ) begin
		if ( en_in ) begin
			case ( count )  
				2'd0: read_addr <= hangcount * 128 + Ycount;
				2'd1: read_addr <= 4096 + hangcount * 128 + Ycount;
				default: read_addr <= 0;
			endcase
		end else begin
			read_addr <= 0;
		end
	end
	
	
	always @( negedge clk_in ) begin
		if ( en_in ) begin
			case ( count )
				2'd0: data1 <= data_in;
				2'd1: data2 <= data_in;
				default: data1 <= 0;
			endcase
		end else begin
			data1 <= 24'h00;
			data2 <= 24'h00;
		end
	end

endmodule
