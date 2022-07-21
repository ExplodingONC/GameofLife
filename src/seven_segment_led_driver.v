module seven_segment_led_driver
	(
		input wire clk_in,
		input wire rst_n,
		input wire zero_fill,
		input wire [19:0]digit,
		output wire [7:0]seven_segment_s_port,
		output wire [3:0]seven_segment_d_port
	);
	
	parameter [255:0]character_table = {
		8'b00001110,	//F.
		8'b00000110,	//E.
		8'b00100001,	//d.
		8'b01000110,	//C.
		8'b00000011,	//b.
		8'b00001000,	//A.
		8'b00010000,	//9.
		8'b00000000,	//8.
		8'b01111000,	//7.
		8'b00000010,	//6.
		8'b00010010,	//5.
		8'b00011001,	//4.
		8'b00110000,	//3.
		8'b00100100,	//2.
		8'b01111001,	//1.
		8'b01000000,	//0.
		8'b10001110,	//F
		8'b10000110,	//E
		8'b10100001,	//d
		8'b11000110,	//C
		8'b10000011,	//b
		8'b10001000,	//A
		8'b10010000,	//9
		8'b10000000,	//8
		8'b11111000,	//7
		8'b10000010,	//6
		8'b10010010,	//5
		8'b10011001,	//4
		8'b10110000,	//3
		8'b10100100,	//2
		8'b11111001,	//1
		8'b11000000		//0
	};

	parameter total_segments = 8;
	parameter total_digits = 4;
	reg [1:0]current_digit = 0;
	reg display_zero = 0;
	
	reg [7:0]segment_display;
	reg [3:0]digit_display;
	assign seven_segment_s_port = segment_display;
	assign seven_segment_d_port = digit_display;
	
	parameter digit_refresh_time = 16'd6000;
	reg [15:0]digit_refresh_counter;
	

	always @(posedge clk_in) begin
	
		//reset button		
		if ( rst_n == 0 ) begin
			segment_display <= 8'b00000000;
			digit_display <= 4'b0000;
			current_digit <= 2'b00;
			display_zero = 1'b0;
		end
		
		//normal working
		else begin
			
			if ( digit_refresh_counter >= digit_refresh_time - 1 ) begin
				digit_refresh_counter <= 16'b0;
				current_digit <= current_digit - 1'b1;
				
				if ( zero_fill == 1 ) begin
					segment_display <= character_table[ 8 * digit[ 5 * current_digit +: 5 ] +: 8 ];
					digit_display <= ~( 4'b0001 << current_digit );
				end else begin
					if ( current_digit == 2'd0 || digit[ 5 * current_digit +: 5 ] != 5'b0 ) begin
						display_zero = 1'b1;
					end else if ( current_digit == 2'd3 ) begin
						display_zero = 1'b0;
					end
					if ( display_zero ) begin
						segment_display <= character_table[ 8 * digit[ 5 * current_digit +: 5 ] +: 8 ];
					end else begin
						segment_display <= 8'b11111111;
					end
					digit_display <= ~( 4'b0001 << current_digit );
				end
			end
			else begin
				digit_refresh_counter <= digit_refresh_counter + 1'b1;		
			end
			
		end
		
	end

endmodule
