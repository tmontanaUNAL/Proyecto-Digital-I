`timescale 1ns / 1ps

module FSM_data #(
		parameter AW = 15,
		parameter DW = 3)(
	 	input CLK,
		input [7:0] D,
		input VSYNC,
		input PCLK,
	   input HREF,
		input rst,
		
		output reg[AW-1: 0] mem_px_addr,
      output reg[DW-1: 0] mem_px_data,
      output reg px_wr
   );

localparam INICIO=0, BT1=1, BT2=2, NPixels=19199; //Npixels en QQVGA
reg [1:0] estado=0;

reg i=0;
always @(posedge PCLK) begin
	//px_wr<=1;
   
if((mem_px_addr==NPixels)|VSYNC) begin //Revisa si ya se termino el frame y manda al inicio
						mem_px_addr<=0;
	      end
	
	if(~VSYNC&HREF)begin //Verifica que los datos sean validos
	      
			px_wr<=0;
			if(i==0)begin
			mem_px_data[0]<=(D[3:0]<8) ? (1'b0):(1'b1);
			//i<=~i;
			end
			if(i==1)begin
			mem_px_data[1]<=(D[7:4]<8) ? (1'b0):(1'b1);
	      mem_px_data[2]<=(D[3:0]<8) ? (1'b0):(1'b1);
			px_wr<=1;
			mem_px_addr<=mem_px_addr+1;
			//i<=~i;
			
			end
	      i<=~i;		
		end 
	/*if(rst) begin
		estado<=0;
		mem_px_addr<=0;
		mem_px_data<=0;
      px_wr<=0;
	end
	else begin
		case(estado)
			INICIO:begin
				if(~VSYNC&HREF)begin //Verifica que los datos sean validos
					estado<=BT1;
				end
				else begin
					mem_px_addr<=0;
					mem_px_data<=0;
					estado<=INICIO;
				end
			end
			BT1:begin
				//px_wr<=0;
				if(~VSYNC&HREF)begin //Verifica que los datos sean validos
					if(mem_px_addr==NPixels) begin //Revisa si ya se termino el frame y manda al inicio
						mem_px_addr<=0;
					end
					else begin
						mem_px_addr<=mem_px_addr+1;//Si el frame aun no termina le suma uno a la direccion
					end
					   px_wr<=1;
						mem_px_data[2]<=(D[3:0]<8) ? (1'b0):(1'b1); //Se escribe el bit del rojo convirtendo de RGB444 a RGB111
						estado<=BT2; //Manda a leer el byte 2
					
				end
				else begin
					estado<=BT1; //Queda en un loop en BT1 hasta que los datos sean validos.
				end
			end
			BT2:begin
				mem_px_data[1]<=(D[7:4]<8) ? (1'b0):(1'b1); //Se escribe el bit del verde convirtendo de RGB444 a RGB111
				mem_px_data[0]<=(D[3:0]<8) ? (1'b0):(1'b1);
					//Se escribe el bit del azul convirtendo de RGB444 a RGB111
				//mem_px_addr<=mem_px_addr+1;//Si el frame aun no termina le suma uno a la direccion
				estado<=BT1; //Manda a leer el byte 1
			end
		endcase
	end */
end
	
endmodule
 