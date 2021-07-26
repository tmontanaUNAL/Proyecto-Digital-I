`timescale 1ns / 1ps

module FSM_data #(
		parameter AW = 15,
		parameter DW = 3)(
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
   
if((mem_px_addr==NPixels)|VSYNC) begin //Revisa si ya se termino el frame y manda al inicio
						mem_px_addr<=0;
	      end
	
	if(~VSYNC&HREF)begin //Verifica que los datos sean validos
	      
			px_wr<=0;
			if(i==0)begin
			mem_px_data[2]<=(D[3:0]<8) ? (1'b0):(1'b1);
			end
			if(i==1)begin
			mem_px_data[1]<=(D[7:4]<8) ? (1'b0):(1'b1);
	      mem_px_data[0]<=(D[3:0]<8) ? (1'b0):(1'b1);
			px_wr<=1;
			mem_px_addr<=mem_px_addr+1;
			
			end
	      i<=~i;		
		end 
end
	

endmodule
 