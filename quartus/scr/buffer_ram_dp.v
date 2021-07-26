`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date:    13:34:31 10/22/2019 
// Design Name: 	 Ferney alberto Beltran Molina
// Module Name:    buffer_ram_dp 
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
module buffer_ram_dp #( 
	parameter AW = 15, // Cantidad de bits  de la dirección 
	parameter DW = 3) // cantidad de Bits de los datos 
	(  
	input  clk_w, // Reloj de escritura proveniente de la camara
	input  [AW-1: 0] addr_in, // Dirección de escritura proveniente de FSM_data
	input  [DW-1: 0] data_in, // Datos del pixel provenientes de FSM_data
	input  regwrite, // Habilitador escritura proveniente de FSM_data
	input  [7:0] filter, // Selector del filtro proveniente de los switches de la tarjeta
	
	input  clk_r, // Reloj de lectura proveniente de la FPGA
	input [AW-1: 0] addr_out, // direccion de lectrura proveniente de test_VGA
	output reg [DW-1: 0] data_out // datos del pixel leido
	);
	
	reg [2: 0] data;
	
// Calcular el numero de posiciones totales de memoria 
localparam NPOS = 2 ** AW; // Memoria

 reg [DW-1: 0] ram [0: NPOS-1];


//	 escritura  de la memoria

always @(negedge clk_w) begin
      

  if (regwrite==1)begin
  
		ram[addr_in]<=data_in;
		
	end 
	
end

   
always @(posedge clk_r) begin

	data <= ram[addr_out]; // escribe el pixel en un registro temporal para su posterior manipulación
	
	// cada caso representa un filtro de color aplicado al pixel, selecciona con los switches
	
	
	/*data_out[2] <= data[2];
	data_out[1] <= data[1];
	data_out[0] <= data[0];*/
	
	case(filter)
			
		8'd0:begin //sin filto
		data_out[2] <= data[2];
		data_out[1] <= data[1];
		data_out[0] <= data[0];
		end
		
		8'd1:begin //filtro color invertido
		data_out[2] <= ~data[2];
		data_out[1] <= ~data[1];
		data_out[0] <= ~data[0];
		end
		
		8'd2:begin //filtro rojo intenso
		data_out[2] <= data[2];
		data_out[1] <= 0;
		data_out[0] <= 0;
		end
		
		8'd3:begin //filtro verde intenso
		data_out[2] <= 0;
		data_out[1] <= data[1];
		data_out[0] <= 0;
		end
		
		8'd4:begin //filtro azul intenso
		data_out[2] <= 0;
		data_out[1] <= 0;
		data_out[0] <= data[0];
		end
		
		default:begin
	   data_out[2] <= data[2];
		data_out[1] <= data[1];
		data_out[0] <= data[0];
		end
		
	endcase
		
end

endmodule
