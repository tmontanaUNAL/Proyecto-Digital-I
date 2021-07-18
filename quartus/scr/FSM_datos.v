`timescale 1ns / 1ps

module FSM_game #(
		parameter AW = 15,
		parameter DW = 3)(
	 	input clk,
		input rst,
		input in1,
		input in2,
		input in3,
		
		output reg [AW-1: 0] mem_px_addr2,
		output reg [DW-1: 0] mem_px_data2,
		output reg px_wr2,
		
		output reg [AW-1: 0] mem_px_addr,
		output reg [DW-1: 0] mem_px_data,
		output reg px_wr
		

   );
	//Pantalla de 160x128
	
	localparam COLOR_BARRA = 3'b010;//verde
	localparam COLOR_BOLA = 3'b111;//blanco
	localparam COLOR_FONDO = 3'b001;//azul
	localparam ROJO = 3'b100;//rojo
	
	localparam tamano_X = 160;
	localparam tamano_Y = 128;
	
	reg [3:0] status = 0;
	reg [3:0] status_bola = 0;
	
	wire init;
	wire right;
	wire left;
	assign right = in1;
	assign left = in2;
	assign init = in3;
	
	//dirección de la pelota
	reg dirX=0;
	reg dirY=0;
	
	
	//8 bits para la posicion vertical y 9 para la horizonal
	
	reg [7:0] posX_barra;
	reg [7:0] posY_barra=96;
	
	reg [7:0] posX_bola;
	reg [7:0] posY_bola;
	
//	assign outprueba = movl;
	
	//Estados de la barra
	parameter START=0, PLAY=2, MOVL=3, MOVR=4;
	//Estados de la pelota 
	parameter MOVE_V=1, RIGHT=2, LEFT=3, UP=4, DOWN=5, MOVE_H=6, FIN=9;
	
	
	
	
	
	/* *********************************************
		Movimiento de la barra 
	
	**********************************************/
	localparam INICIO_LINEA = 15200;
	reg done_barrax=0;
	reg [2:0] count_Tam;
	parameter TAM_X_BARRA =5;
   reg pallet_draw=0;
	
	
	always @(posedge clk) begin
		if (rst) begin
			count_Tam<=0;
			px_wr<=0;
			posY_barra = 96;
		end

		if(pallet_draw)begin	

			done_barrax=0;
			px_wr <= 1;
			count_Tam<=count_Tam+1;
			case(count_Tam)
				(TAM_X_BARRA+2): begin
						mem_px_addr <= (posX_barra+posY_barra*tamano_X)+(count_Tam-1);
						mem_px_data <= COLOR_FONDO;
	     				done_barrax=1;
			   	   count_Tam<=0;
						pallet_draw=0;
					end	
				(TAM_X_BARRA+1): begin
						mem_px_addr <= (posX_barra-1+posY_barra*tamano_X);
						mem_px_data <= COLOR_FONDO;
					end
				default: begin
						mem_px_addr <= (posX_barra+posY_barra*tamano_X)+count_Tam;
						mem_px_data <= COLOR_BARRA;
				end
			endcase
		end
		
		
		case(status)
		
			START:begin
				posX_barra = 80;
				pallet_draw=1;
				if(init && done_barrax)begin
					pallet_draw=0;
					status<=PLAY;
				end
			end
			PLAY: begin
				if(done_barrax)begin
					pallet_draw=0;
					if(left)begin
						status<=MOVL;
					end
					if(right)begin
						status<=MOVR;
					end
				end
			end
			
			
			MOVL: begin
				if(posX_barra>3)begin
					posX_barra = posX_barra-1;
				end
				pallet_draw=1;
				status<=PLAY;
			end
			
			MOVR: begin
				if(posX_barra<(tamano_X-TAM_X_BARRA-4))begin
					posX_barra = posX_barra+1;
				end
				pallet_draw=1;
				status<=PLAY;
			end
			
		endcase
		
	end
	
	/*********************************
	Movimiento de la bola
	
	*******************************/	
	
	
	reg [3:0] count_Tam_ball;
	reg done_ball=0;
	reg ball_draw=0;
	reg lost;
	reg red_point_draw;
	reg borrar_punto=0;
	
	always @(posedge clk)begin
		if (rst) begin
			count_Tam_ball<=0;
			px_wr2<=0;
			lost=0;
			red_point_draw=0;
			borrar_punto=1;
		end
		
		if(borrar_punto)begin
			px_wr2<=1;
			mem_px_addr2 <= ((posX_bola)+(posY_bola)*tamano_X);
			mem_px_data2 <= COLOR_FONDO;
			borrar_punto=0;
			status_bola=START;
		end
		
		
		if(ball_draw)begin
			done_ball=0;
			px_wr2<=1;
			count_Tam_ball<=count_Tam_ball+1;
			case(count_Tam_ball)
				1:begin
					mem_px_addr2 <= ((posX_bola-1)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				2:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_BOLA;
				end
				3:begin
					mem_px_addr2 <= ((posX_bola+1)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				4:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola-1)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				5:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola+1)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
					done_ball=1;
					count_Tam_ball<=0;
					ball_draw=0;
				end
			endcase	
		end
		
		if(red_point_draw)begin
			px_wr2 <=1;
			mem_px_addr2 <= 10320;
			mem_px_data2 <= ROJO;
		end
		
		
		case(status_bola) 
		
				START: begin
					posX_bola=80;
					posY_bola=64;
					ball_draw=1;
					if(init && done_ball)begin
						ball_draw=0;
						status_bola=MOVE_V;
					end
				end
				
				MOVE_V: begin
					if(done_ball)begin
						ball_draw=0;
						if(dirY)begin
							status_bola<=DOWN;
						end else begin
							status_bola<=UP;
						end
					end
				end
				
				UP: begin
					if(posY_bola>4)begin
						posY_bola = posY_bola-1;
					end else begin
						dirY=~dirY;
					end
					ball_draw=1;
					status_bola<=MOVE_H;
				end
				
				DOWN: begin
					if(posY_bola<posY_barra-2)begin
						posY_bola = posY_bola+1;
					end else begin
						if((posX_bola>=(posX_barra-1))&&(posX_bola<=(posX_barra+TAM_X_BARRA+1)))begin
							dirY=~dirY;
						end else begin
							lost=1;
						end
					end
					if(lost)begin
						status_bola=FIN;
					end else begin
						ball_draw=1;
						status_bola<=MOVE_H;
					end
					
				end
				
				MOVE_H: begin
					if(done_ball)begin
						ball_draw=0;
						if(dirX)begin
							status_bola<=RIGHT;
						end else begin
							status_bola<=LEFT;
						end
					end
				end
				
				RIGHT:begin
					if(posX_bola<tamano_X-3)begin
						posX_bola=posX_bola+1;
					end else begin
						dirX=~dirX;
					end
					ball_draw=1;
					status_bola<=MOVE_V;
				end
				
				LEFT:begin
					if(posX_bola>4)begin
						posX_bola=posX_bola-1;
					end else begin
						dirX=~dirX;
					end
					ball_draw=1;
					status_bola<=MOVE_V;
				end	
				
				FIN:begin
					red_point_draw=1;
				end
		endcase	
	end
	
	
	
	

endmodule
