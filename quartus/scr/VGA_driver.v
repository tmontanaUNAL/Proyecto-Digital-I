//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date:    13:34:31 10/22/2019 
// Design Name: 	 Ferney alberto Beltran Molina
// Module Name:    VGA_Driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module VGA_Driver640x480 (
	input rst,
	input clk, 				// reloj de 31.5 MHz  para 60 hz de 640x480 proveniente de la tarjeta
	input  [2:0] pixelIn, 	// entrada del valor de color  pixel 
	output  [2:0] pixelOut, // salida del valor pixel a la VGA 
	output  Hsync_n,		// señal de sincronización en horizontal
	output  Vsync_n,		// señal de sincronización en vertical
	output  [10:0] posX, 	// posicion en horizontal del pixel siguiente
	output  [10:0] posY 		// posicion en vertical  del pixel siguiente
);

localparam SCREEN_X = 640; // tamaño de la pantalla visible en horizontal 
localparam FRONT_PORCH_X =16; 
localparam SYNC_PULSE_X = 64;  
localparam BACK_PORCH_X = 120;  
localparam TOTAL_SCREEN_X = SCREEN_X+FRONT_PORCH_X+SYNC_PULSE_X+BACK_PORCH_X; 	// total pixel pantalla en horizontal 


localparam SCREEN_Y = 480; // tamaño de la pantalla visible en Vertical 
localparam FRONT_PORCH_Y =1;  
localparam SYNC_PULSE_Y = 3;  
localparam BACK_PORCH_Y = 16; 
localparam TOTAL_SCREEN_Y = SCREEN_Y+FRONT_PORCH_Y+SYNC_PULSE_Y+BACK_PORCH_Y; 	// total pixel pantalla en Vertical 


reg  [10:0] countX;
reg  [10:0] countY;

assign posX    = countX;
assign posY    = countY;

assign pixelOut = (countX<SCREEN_X) ? (pixelIn ) : (3'b000) ; // si la ubicacion del pixel esta dentro de la pantalla se envia el pixel si no se envia 0.

assign Hsync_n = ~((countX>=SCREEN_X+FRONT_PORCH_X) && (countX<SCREEN_X+SYNC_PULSE_X+FRONT_PORCH_X)); 
assign Vsync_n = ~((countY>=SCREEN_Y+FRONT_PORCH_Y) && (countY<SCREEN_Y+FRONT_PORCH_Y+SYNC_PULSE_Y));


always @(posedge clk) begin
	if (rst) begin
		countX <= TOTAL_SCREEN_X;
		countY <= TOTAL_SCREEN_Y;
	end
	else begin 
		if (countX >= (TOTAL_SCREEN_X)) begin
			countX <= 0;
			if (countY >= (TOTAL_SCREEN_Y)) begin
				countY <= 0;
			end 
			else begin
				countY <= countY + 1;
			end
		end 
		else begin
			countX <= countX + 1;
			countY <= countY;
		end
	end
end

endmodule

