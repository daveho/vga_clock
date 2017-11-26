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
	 // System reset signal (from microcontroller)
	 input sys_rst,
	 // VGA signals
    output reg hsync,
	 output reg vsync,
	 output reg[3:0] red_out,
	 output reg[3:0] green_out,
	 output reg[3:0] blue_out /*,
	 // Connections for write port of test block memory
	 input tbm_clka, // clock (data is written to selected address on rising edge)
	 input[0:0] tbm_wea, // write enable (1=enable, 0=disable)
	 input[7:0] tbm_dina // data inputs
	 */
	 );

// Wire for VGA clock signal
wire vgaclk;

// Instantiation of VGA clock module
vga_clock vga_clock(
      .CLK_IN1(clk),
      .CLK_VGA(vgaclk)
);

/*
// Wires for test_blockmem: these are for:
// - the read port, which is only used internally, and
// - the address of the write port, which is only
//   used internally.
// The clock, write enable, and data inputs of the
// write port are connected to external pins.
wire[7:0] tbm_addra;
wire tbm_clkb;       // read port clock
wire[7:0] tbm_addrb; // read port address
wire[7:0] tbm_doutb; // read port data
*/

/*
input clka;
input [0 : 0] wea;
input [7 : 0] addra;
input [7 : 0] dina;
input clkb;
input [7 : 0] addrb;
output [7 : 0] doutb;
*/
/*
// Instantiation of test block memory
blockmem test_blockmem(
	.clka(tbm_clka),
	.wea(tbm_wea),
	.addra(tbm_addra),
	.dina(tbm_dina),
	.clkb(tbm_clkb),
	.addrb(tbm_addrb),
	.doutb(tbm_doutb)
);
*/

wire rst = ~rst_n; // make reset active high

// these signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;

assign led[6:0] = 7'b0;
assign led[7] = rst;

/*
reg hsync;
reg vsync;
*/

reg[10:0] hsync_count;
reg[9:0] vsync_count;

/*
reg[3:0] red_out;
reg[3:0] green_out;
reg[3:0] blue_out;
*/

// VGA 800x600@60Hz signal timings
parameter VGA_HORIZ_RES = 800;
parameter VGA_VERT_RES = 600;
parameter VGA_HORIZ_FRONT_PORCH_END = 840;
parameter VGA_HORIZ_SYNC_END = 968;
parameter VGA_HORIZ_BACK_PORCH_END = 1055;
parameter VGA_VERT_FRONT_PORCH_END = 601;
parameter VGA_VERT_SYNC_END = 606;
parameter VGA_VERT_BACK_PORCH_END = 627;

// Generate hsync
always @(posedge vgaclk or posedge sys_rst) begin
  if (sys_rst) begin
	  // Reset, no signal
	  hsync <= 1'b1;
	  vsync <= 1'b1;
	  red_out <= 4'b0;
	  green_out <= 4'b0;
	  blue_out <= 4'b0;
  end else begin
	  // Generate hsync and color signals, count scanlines for vsync generation
	  if (hsync_count < VGA_HORIZ_RES) begin
		 // visible
		 hsync <= 1'b1;
		 hsync_count <= hsync_count + 1;
		 
		 if (vsync_count < VGA_VERT_RES) begin
			// visible line
			// just generate a test pattern
			red_out <= (vsync_count >> 2) & 4'hF;
			green_out <= (hsync_count >> 2) & 4'hF;
			blue_out <= (hsync_count >> 4) & 4'hF;
		 end else begin
			// not in a visible line
			red_out <= 4'b0;
			green_out <= 4'b0;
			blue_out <= 4'b0;
		 end
	  end else if (hsync_count >= VGA_HORIZ_RES && hsync_count < VGA_HORIZ_FRONT_PORCH_END) begin
		 // front porch
		 hsync <= 1'b1;
		 hsync_count <= hsync_count + 1;
		 // not in a visible line
		 red_out <= 4'b0;
		 green_out <= 4'b0;
		 blue_out <= 4'b0;
	  end else if (hsync_count >= VGA_HORIZ_FRONT_PORCH_END && hsync_count < VGA_HORIZ_SYNC_END) begin
		 // hsync pulse
		 hsync <= 1'b0;
		 hsync_count <= hsync_count + 1;
		 // not in a visible line
		 red_out <= 4'b0;
		 green_out <= 4'b0;
		 blue_out <= 4'b0;
	  end else if (hsync_count >= VGA_HORIZ_SYNC_END && hsync_count < VGA_HORIZ_BACK_PORCH_END) begin
		 // back porch
		 hsync <= 1'b1;
		 hsync_count <= hsync_count + 1;
		 // not in a visible line
		 red_out <= 4'b0;
		 green_out <= 4'b0;
		 blue_out <= 4'b0;
	  end else if (vsync_count < VGA_VERT_BACK_PORCH_END) begin
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
	  if (vsync_count > VGA_VERT_FRONT_PORCH_END && vsync_count < VGA_VERT_SYNC_END) begin
		 // generate vsync pulse
		 vsync <= 1'b0;
	  end else begin
		 // no vsync pulse
		 vsync <= 1'b1;
	  end
  
  end
end

endmodule