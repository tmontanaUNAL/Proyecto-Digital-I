`timescale 1ns / 1ps

module FSM_data #(
		parameter AW = 15,
		parameter DW = 3)(
		input [7:0] data,
		input vsync,
		input pclk,
	   input href,
		input rst,
		
		output reg[AW-1: 0] mem_px_addr,
      output reg[DW-1: 0] mem_px_data,
      output reg px_wr
   );

localparam INICIO=0, ESCRITURA=1, NPixels=19199; //Npixels en QQVGA
reg [1:0] estado=0;

reg i=0;
reg vsync_antes=0;
always @(posedge pclk) begin

	case(estado)
		INICIO:begin
			i<=0;
			mem_px_addr<=-1;
			if (vsync==0 & vsync_antes==1)begin
			estado<=ESCRITURA;
			end
			else begin
			vsync_antes<=vsync;
			end
		end
		
		ESCRITURA:begin
			if((mem_px_addr==NPixels)|vsync) begin //Revisa si ya se termino el frame y manda al inicio
				estado<=INICIO;
	      end
			if(~vsync&href)begin //Verifica que los datos sean validos	
			px_wr<=0;
			if(i==0)begin
			mem_px_addr<=mem_px_addr+1;
			mem_px_data[2]<=(data[3:0]<8) ? (1'b0):(1'b1);
			end
			if(i==1)begin
			mem_px_data[1]<=(data[7:4]<8) ? (1'b0):(1'b1);
			mem_px_data[0]<=(data[3:0]<8) ? (1'b0):(1'b1);
			px_wr<=1;

			end
			i<=~i;		
			end
		end
	endcase
end
	

endmodule
 