module led_display_driver
	#(
		parameter DSIZE = 24,
		parameter ColPoint = 128,
		parameter RowPoint = 64,
		parameter Vcount = 19,
		parameter Hcount = 32,
		parameter light = 0,
		parameter CLK_RATE = 10000000,
		parameter CLK_OUT = 5000000
	)
	(
		input clk_in, en,
		input [DSIZE-1:0]datain1,
		input [DSIZE-1:0]datain2,
		
		output reg read_en,
		output reg clk_disp,
		output reg oe, le,
		output reg sin1R, sin1G, sin1B,
		output reg sin2R, sin2G, sin2B,
		output reg [6:0]Ycount,
		output reg [4:0]hangcount,
		output wire [4:0]abcde
	);

	wire [7:0]disbuff1R;
	wire [7:0]disbuff1G;
	wire [7:0]disbuff1B;
	
	wire [7:0]disbuff2R;
	wire [7:0]disbuff2G;
	wire [7:0]disbuff2B;
	
	reg [4:0]changcount;
	reg [7:0]count;

	assign abcde = hangcount;
	
	
	always @( count, clk_in ) begin
		if ( count < ColPoint ) begin
			clk_disp <= ~clk_in;
		end else begin
			clk_disp <= 0;
		end
	end
	
	
	always @( posedge clk_in ) begin
		
		if ( ~en ) begin
			
			count=0;
			changcount=0;
			hangcount=0;
			
		end else begin
			
			if ( count < ColPoint + light ) begin
				count = count + 1;
			end else begin
				count = 0;
				if ( changcount < Vcount ) begin
					changcount = changcount + 1;
				end else begin
					changcount = 0;
					if ( hangcount < Hcount - 1 ) begin
						hangcount=hangcount + 1;
					end else begin
						hangcount = 0;
					end
				end
			end	
				
		end
		
	end
	
	assign disbuff1R = datain1[23:16];
	assign disbuff1G = datain1[15:8];
	assign disbuff1B = datain1[7:0];
			
	assign disbuff2R = datain2[23:16];
	assign disbuff2G = datain2[15:8];
	assign disbuff2B = datain2[7:0];	
	
	
	always @( negedge clk_in ) begin
		
		if ( count < ColPoint ) begin	
			
			case ( changcount )
				0,1,2,3,4: sin1R=disbuff1R[changcount];
				5,6: sin1R=disbuff1R[5];
				7,8,9,10: sin1R=disbuff1R[6];				
				11,12,13,14,15,16,17,18: sin1R=disbuff1R[7];
				default: sin1R=0;
			endcase
				
			case ( changcount )
				0,1,2,3,4: sin1G=disbuff1G[changcount];
				5,6: sin1G=disbuff1G[5];
				7,8,9,10: sin1G=disbuff1G[6];
				11,12,13,14,15,16,17,18: sin1G=disbuff1G[7];
				default: sin1G=0;
			endcase
			
			case ( changcount )
				0,1,2,3,4: sin1B=disbuff1B[changcount];
				5,6: sin1B=disbuff1B[5];
				7,8,9,10: sin1B=disbuff1B[6];				
				11,12,13,14,15,16,17,18: sin1B=disbuff1B[7];
				default: sin1B=0;
			endcase
			
			case ( changcount )
				0,1,2,3,4: sin2R=disbuff2R[changcount];
				5,6: sin2R=disbuff2R[5];
				7,8,9,10: sin2R=disbuff2R[6];				
				11,12,13,14,15,16,17,18: sin2R=disbuff2R[7];
				default: sin2R=0;
			endcase
				
			case ( changcount )
				0,1,2,3,4: sin2G=disbuff2G[changcount];
				5,6: sin2G=disbuff2G[5];
				7,8,9,10: sin2G=disbuff2G[6];
				11,12,13,14,15,16,17,18: sin2G=disbuff2G[7];
				default: sin2G=0;
			endcase
			
			case ( changcount )
				0,1,2,3,4: sin2B=disbuff2B[changcount];
				5,6: sin2B=disbuff2B[5];
				7,8,9,10: sin2B=disbuff2B[6];				
				11,12,13,14,15,16,17,18: sin2B=disbuff2B[7];
				default: sin2B=0;
			endcase
			
		end
		
	end


	always @( count, changcount, clk_in ) begin
		
		if ( count < ColPoint ) begin
			read_en = 1;
			Ycount = count;
		end else begin
			read_en = 0;
		end
		
		if ( count == ColPoint ) begin
			le = 1;
			//rden = 0;
		end else begin
			le = 0;
			//rden = 1;
		end

		case ( changcount )
			0: if(count<=15) oe=0; else oe=1;
			1,2,3,4: if(count<=30) oe=0; else oe=1;
			5,6,7,8,9,10,11,12: if(count<=60) oe=0; else oe=1;
			13,14,15,16,17,18: if(count<=120) oe=0; else oe=1;
			default: oe=1;
		endcase
		
	end
	

endmodule
