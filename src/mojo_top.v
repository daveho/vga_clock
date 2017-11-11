module mojo_top(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0]led,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full
	 // VGA signals
    output hsync,
	 output vsync,
	 output[3:0] red_out,
	 output[3:0] green_out,
	 output[3:0] blue_out
	 );

wire vgaclk;

vga_clock vga_clock(
      .CLK_IN1(clk),
      .CLK_VGA(vgaclk)
);

wire rst = ~rst_n; // make reset active high

// these signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;

assign led[6:0] = 7'b0;
assign led[7] = rst;

reg hsync;
reg vsync;

reg[10:0] hsync_count;
reg[9:0] vsync_count;

reg[3:0] red_out;
reg[3:0] green_out;
reg[3:0] blue_out;

// Generate hsync
always @(posedge vgaclk) begin
  // Generate hsync, count scanlines for vsync generation
  if (hsync_count < 800) begin
    // visible
	 hsync <= 1'b1;
	 hsync_count <= hsync_count + 1;
	 
	 if (vsync_count < 600) begin
	   // visible line
		// just generate a test pattern
		red_out <= (vsync >> 2);
		green_out <= (hsync >> 2);
		blue_out <= (hsync >> 4);
	 end else begin
	   // not in a visible line
		red_out <= 4'b0;
		green_out <= 4'b0;
		blue_out <= 4'b0;
	 end
  end else if (hsync_count >= 800 && hsync_count < 840) begin
    // front porch
	 hsync <= 1'b1;
	 hsync_count <= hsync_count + 1;
	 // not in a visible line
	 red_out <= 4'b0;
	 green_out <= 4'b0;
	 blue_out <= 4'b0;
  end else if (hsync_count >= 840 && hsync_count < 968) begin
    // hsync pulse
	 hsync <= 1'b0;
	 hsync_count <= hsync_count + 1;
	 // not in a visible line
	 red_out <= 4'b0;
	 green_out <= 4'b0;
	 blue_out <= 4'b0;
  end else if (hsync_count >= 968 && hsync_count < 1055) begin
    // back porch
	 hsync <= 1'b1;
	 hsync_count <= hsync_count + 1;
	 // not in a visible line
	 red_out <= 4'b0;
	 green_out <= 4'b0;
	 blue_out <= 4'b0;
  end else if (vsync_count < 627) begin
    // not end of frame yet
    // end of back porch, next clock will begin new scan line
	 hsync <= 1'b1;
	 hsync_count <= 11'b0;
	 vsync_count <= vsync_count + 1;
	 // not in a visible line
	 red_out <= 4'b0;
	 green_out <= 4'b0;
	 blue_out <= 4'b0;
  end else begin
    // end of frame
    // end of back porch, next clock will begin new scan line
	 hsync <= 1'b1;
	 hsync_count <= 11'b0;
	 vsync_count <= 10'b0;
	 // not in a visible line
	 red_out <= 4'b0;
	 green_out <= 4'b0;
	 blue_out <= 4'b0;
  end
  
  // Generate vsync
  if (vsync_count >= 601 && vsync_count < 605) begin
    // generate vsync pulse
    vsync <= 1'b0;
  end else begin
    // no vsync pulse
    vsync <= 1'b1;
  end
end

endmodule