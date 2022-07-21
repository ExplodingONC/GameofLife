`include "params.h"

module top
	(
		//basic
		input wire clk_in,
		input wire [4:0]button,
		input wire [15:0]switch,
		output wire [15:0]led,
		//UART
		output wire uart_tx,
		input wire uart_rx,
		//7segment display
		output wire [7:0]seven_segment_s_port,
		output wire [3:0]seven_segment_d_port,
		//led matrix display
		output wire clk_disp,
		output wire oe, le,
		output wire sin1R, sin1G, sin1B,
		output wire sin2R, sin2G, sin2B,
		output wire [4:0]abcde
	);
	
	//clocks
	pll_clock pll_clk (
		.refclk(clk_in),
		.reset(),
		.clk0_out(clk_main),
		.clk1_out(clk_bram_disp_read),
		.clk2_out(clk_mem_ctrl),
		.clk3_out(clk_led_drive)
	);
	
	//basic logic
	reg [4:0]button_reg;
	wire reset = ~button[0];
	wire [15:0]debug;
	integer ii;
	assign led = ~debug;
	
	
	//UART module
	reg tx_trigger, rx_trigger;
	wire tx_ready, rx_ready;
	reg [7:0]tx_data;
	wire [7:0]rx_data;
	uart_driver #(
		.CLOCK_IN(`CLOCK_RATE),
		.BAUD_RATE(`BAUD_RATE)
	) UART (
		.clk_in(clk_main),
		.rst_n(~reset),
		.tx_trigger(tx_trigger),
		.tx_ready(tx_ready),
		.tx_data(tx_data),
		.rx_trigger(rx_trigger),
		.rx_ready(rx_ready),
		.rx_data(rx_data),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx)
	);
	
	//BRAM driver
	reg [`ROWSIZE+1:0]line_buffer;
	wire [`ROWSIZE+1:0]line_out;
	reg [`ADDRLENGTH-1:0]line_addr;
	reg bram_ce, bram_we;
	bram_frame life_pool ( 
		.clka(clk_main),
		.addra(line_addr),
		.doa(line_out),
		.dia(line_buffer),
		.cea(bram_ce),
		.wea(bram_we)
	);
	
	
	//data flags
	reg header_valid;
	reg uart_receiving;
	reg process_trigger;
	//uart receiving
	reg [31:0]counter;
	reg [31:0]timer;
	reg [7:0]subpixel[3:0];
	reg [1:0]subpixel_counter;
	reg [7:0]data_buffer[53:0];
	//data processing
	reg [`ROWSIZE+1:0]line_above;
	reg [`ROWSIZE+1:0]line_middle;
	reg [`ROWSIZE+1:0]line_below;
	reg [3:0]neighbor_count[`ROWSIZE+1:0];
	//line processing
	reg [3:0]status_line;
	//frame processing
	reg [`ADDRLENGTH:0]status_frame;
	reg [31:0]gen_counter;
	reg [31:0]gen_timer;
	reg gen_trigger;
	reg gen_in_process;
	//display control
	reg disp_en;
	reg frame_ready;
	reg disp_in_process;
	reg [31:0]pixel_addr;
	reg [23:0]pixel_data;
	reg pixel_write;
	reg [7:0]count_horizontal;
	reg [7:0]count_vertical;
	
	
	display_adaptor disp_adaptor (
		.clk_mem_ctrl(clk_mem_ctrl),
		.clk_led_drive(clk_led_drive),
		.clk_bram_disp_read(clk_bram_disp_read),
		.rst_n(~reset),
		.en(disp_en),
		.light(1'b0),
		//bram input
		.addr(pixel_addr[12:0]),
		.data(pixel_data),
		.clk_bram_disp(clk_main),
		.write_en(pixel_write),
		//display output
		.clk_disp(clk_disp),
		.oe(oe),
		.le(le),
		.sin1R(sin1R),
		.sin1G(sin1G),
		.sin1B(sin1B),
		.sin2R(sin2R),
		.sin2G(sin2G),
		.sin2B(sin2B),
		.abcde(abcde)
	);
	
	
	// survival calculation
	always @( posedge clk_main ) begin
		
		//reset
		if ( reset ) begin
			tx_data <= 8'b0;
			tx_trigger <= 1'b0;
			rx_trigger <= 1'b0;
			header_valid <= 1'b0;
			uart_receiving <= 1'b0;
			process_trigger <=1'b0;
			counter <= 32'b0;
			timer <= 32'b0;
			subpixel_counter <= 2'b0;
			bram_ce <= 1'b0;
			status_frame <= 0;
			status_line <= 4'b0;
			gen_counter <= 32'b0;
			gen_in_process <= 1'b0;
			frame_ready <= 1'b0;
			disp_in_process <= 1'b0;
			disp_en <= 1'b0;
			frame_ready <= 1'b0;
			disp_in_process <= 1'b0;
			pixel_addr <= 32'b0;
			pixel_data <= 24'b0;
			pixel_write <= 1'b0;
			count_horizontal <= 8'b0;
			count_vertical <= 8'b0;
		end
		
		//work
		else begin
			
			//UART loop back
			if ( rx_ready ) begin
				tx_data <= rx_data;
			end	
			if ( rx_trigger ) begin
				tx_trigger <= 1'b1;
			end else begin
				tx_trigger <= 1'b0;
			end
			
			//locate image header
			if ( ~uart_receiving ) begin
				//receive
				if ( rx_ready ) begin
					data_buffer[counter] <= rx_data;
					counter <= counter + 1'b1;
					rx_trigger <= 1'b1;
				end else begin
					rx_trigger <= 1'b0;
				end
				//check file header
				if ( counter == 2 ) begin
					if ( data_buffer[0] == 8'h42 && data_buffer[1] == 8'h4D ) begin
						//valid header for .bmp files
					end else begin
						//invalid data
						counter <= 32'b1;
						data_buffer[0] <= data_buffer[1];	//shift the second byte
					end
				end else if ( counter == 54 ) begin		//valid header, stop processig for receiving
					counter <= 32'b0;
					header_valid <= 1'b1;
					uart_receiving <= 1'b1;
					count_horizontal <= 8'b0;
					count_vertical <= 8'b0;
					gen_counter <= 32'b0;
					gen_in_process <= 1'b0;
					disp_in_process <= 1'b0;
				end
			end
			//receive image data
			if ( uart_receiving ) begin
				//receive
				if ( rx_ready && subpixel_counter != 3 ) begin
					subpixel[subpixel_counter] <= rx_data;
					subpixel_counter <= subpixel_counter + 1'b1;
					rx_trigger <= 1'b1;
				end else begin
					rx_trigger <= 1'b0;
				end
				//data processing
				if ( subpixel_counter == 3 ) begin
					count_horizontal <= count_horizontal + 1;
					if ( count_horizontal < `ROWSIZE ) begin
						line_buffer[count_horizontal+1] <= ( ( subpixel[1] >> 7 ) | ( subpixel[2] >> 7 ) | ( subpixel[3] >> 7 ) ) ? 1'b1 : 1'b0;
						if ( count_horizontal < `ROWSIZE - 1 ) subpixel_counter <= 2'b0;
					end else if ( count_horizontal == `ROWSIZE ) begin
						line_addr <= count_vertical + 1;
						bram_we <= 1'b1;
						bram_ce <= 1'b1;
					end else if ( count_horizontal == `ROWSIZE + 1 ) begin
						bram_ce <= 1'b0;
						subpixel_counter <= 2'b0;
						count_horizontal <= 8'b0;
						count_vertical <= count_vertical + 1;
					end
				end
				//end
				if ( count_vertical >= `COLSIZE ) begin
					count_horizontal <= 8'b0;
					count_vertical <= 8'b0;
					uart_receiving <= 1'b0;
					frame_ready <= 1'b1;
				end
			end
			//clear triggers
			if ( header_valid ) header_valid <= 1'b0;
			
			
			//process the evolving life
			else begin
				
				//time control signal
				if ( ~gen_in_process && ~disp_in_process && gen_trigger ) begin
					gen_in_process <= 1'b1;
					gen_counter <= gen_counter + 1;
				end
				
				//generating process
				if ( gen_in_process && status_frame < `COLSIZE + 2 ) begin
					//
					case ( status_line )
						//load address
						0: begin
							line_addr <= status_frame;
							bram_we <= 1'b0;
							bram_ce <= 1'b1;
							status_line <= status_line + 4'b1;
						end
						//wait for 1 clk
						1: begin
							bram_ce <= 1'b0;
							status_line <= status_line + 4'b1;
						end
						//receive line data
						2: begin
							line_above <= line_middle;
							line_middle <= line_below;
							line_below <= line_out;
							status_line <= status_line + 4'b1;
						end
						//calculate neighbor count
						3: begin
							for ( ii = 1; ii < `ROWSIZE + 1; ii = ii + 1 ) begin
								neighbor_count[ii] <= 	  line_above[ii-1] 	+ line_above[ii]	+ line_above[ii+1]
														+ line_middle[ii-1]						+ line_middle[ii+1]
														+ line_below[ii-1] 	+ line_below[ii]	+ line_below[ii+1];
							end
							status_line <= status_line + 4'b1;
						end
						//calculate next gen
						4: begin
							for ( ii = 1; ii < `ROWSIZE + 1; ii = ii + 1 ) begin
								line_buffer[ii] <= ( line_middle[ii] == 1'b1 ) ?
													( ( neighbor_count[ii] >= 2 && neighbor_count[ii] <= 3 ) ? 1'b1 : 1'b0 ):
													( ( neighbor_count[ii] == 3 ) ? 1'b1 : 1'b0 );
							end
							line_buffer[0] <= 1'b0;
							line_buffer[`ROWSIZE + 1] <= 1'b0;
							status_line <= status_line + 4'b1;
						end
						//store the result
						5: begin
							if ( status_frame > 1 ) begin
								line_addr <= status_frame - 1;
								bram_we <= 1'b1;
								bram_ce <= 1'b1;
							end
							status_line <= status_line + 4'b1;
						end
						//wait for 1 clk
						6: begin
							bram_ce <= 1'b0;
							status_line <= status_line + 4'b1;
						end
						//clean up
						7: begin
							status_frame <= status_frame + 1;
							status_line <= 4'b0;
						end
						//err
						default: begin
							// don't come here
						end
						
					endcase
					
				end 
				
				//finish up the frame
				else begin
					
					//normal finish
					if ( gen_in_process ) begin
						frame_ready <= 1'b1;
						gen_in_process <= 1'b0;
					end
					//in case of failure
					status_frame <= 0;
					status_line <= 4'b0;
					
				end
				
			end
			
			//display the generation result
			if ( ~gen_in_process && ~disp_in_process && frame_ready ) begin
				frame_ready <= 1'b0;
				disp_in_process <= 1'b1;
				count_horizontal <= 8'b0;
				count_vertical <= 8'b0;
				//disp_en <= 1'b0;
			end
			
			//display process
			if ( disp_in_process ) begin
				
				if ( count_horizontal == 0 ) begin							//load data, cnt=0
					line_addr <= count_vertical + 1;
					bram_we <= 1'b0;
					bram_ce <= 1'b1;
					count_horizontal <= count_horizontal + 1;
				end else if ( count_horizontal == 1 ) begin					//wait for data, cnt=1
					bram_ce <= 1'b0;
					count_horizontal <= count_horizontal + 1;
				end else if ( count_horizontal <= `ROWSIZE + 1 ) begin		//write buffer, cnt=2..rowsize+1
					pixel_addr <= count_vertical * `ROWSIZE + count_horizontal - 2;
					pixel_data <= ( line_out[ count_horizontal - 1 ] ) ? `COLOR_ON : `COLOR_OFF;
					pixel_write <= 1'b1;
					count_horizontal <= count_horizontal + 1;
				end else if ( count_horizontal > `ROWSIZE + 1 ) begin		//finish the line
					pixel_write <= 1'b0;
					count_horizontal <= 8'b0;
					if ( count_vertical < `COLSIZE - 1 ) begin				//move to next line
						count_vertical <= count_vertical + 1;
					end else begin
						disp_in_process <= 1'b0;
						count_horizontal <= 8'b0;
						count_vertical <= 8'b0;
						disp_en <= 1'b1;
					end
				end
				
			end
			
		end
		
	end
	
	
	// time control
	localparam gen_time_interval = `CLOCK_RATE / `GEN_PER_SEC;
	always @( posedge clk_main ) begin
		
		button_reg <= button;
		
		if ( reset || uart_receiving ) begin	//no trigger time
			
			gen_timer <= 0;
			gen_trigger <= 1'b0;
			
		end else begin
			
			if ( switch[0] ) begin		//auto mode
				
				if ( gen_timer < gen_time_interval ) begin
					gen_timer <= gen_timer + 1;
					gen_trigger <= 1'b0;
				end else begin
					gen_timer <= 0;
					gen_trigger <= 1'b1;
				end
				
			end else begin				//manual mode
				
				gen_timer <= 0;
				if ( ~button[3] && button_reg[3] ) begin
					gen_trigger <= 1'b1;
				end else begin
					gen_trigger <= 1'b0;
				end
				
			end
			
		end
		
	end
	
	assign debug[15:2] = 14'b0;
	assign debug[1] = uart_receiving;
	assign debug[0] = switch[0];
	
	
	// generation-count display
	seven_segment_led_driver seven_seg_disp (
		.clk_in(clk_in),
		.rst_n(~reset),
		.zero_fill(1'b0),
		.digit({1'b0,gen_counter[15:12],1'b0,gen_counter[11:8],1'b0,gen_counter[7:4],1'b0,gen_counter[3:0]}),
		.seven_segment_s_port(seven_segment_s_port),
		.seven_segment_d_port(seven_segment_d_port)
	);
	always @(posedge clk_in) begin
		//empty for now
	end
	
	
	
endmodule
