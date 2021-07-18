# Proyecto-Digital-I
Proyecto curso Digital I, camara VGA
## Funcionamiento de Modulo OV7670
El módulo OV7670 es un  sensor de imagen capaz de tomar hasta un máximo de 30 fotogramas por segundo , con una  resolución de 640x480 pixeles y voltaje de operación 3.3V. Para este proyecto se configuro los registros internos de este módulo mediante el uso  del puerto I2C de un Arduino mega 2560. Esta configuración nos permitió modificar el formato de imagen que nos envía la cámara , que  posteriormente será procesado por la FPGA.


Como este tipo de módulo no tiene memoria FIFO que permita guardar los datos , este nos enviara datos  de pixeles constante mente , es por esto que mediante el uso de la FPGA creamos nuestra memoria FIFO a partir de registros 
## Documentación de Código 
El proyecto se dividió en cuatro módulos: test_VGA , buffer_ram_dp, VGA_Driver640x480 y FSM_data.
### test_VGA
Es el top del proyecto y tiene como función llamar a todos los demás módulos con los inputs y outputs correctos. También se encarga de enviar y recibir los datos de los pixeles y reloj al monitor y la cámara, asi como de recibir la selección del filtro en lo switches de la FPGA.

```verilog
module test_VGA(
    input wire clk,           // reloj de la tarjeta 50MHz
    input wire rst,         	// reset button
	 
	  
	 input [7:0]dat, // Datos provenientes de la camara
	 input sync, //Vsync de la camara
	 input pclk, // Reloj proveniente de la camara
	 input href, // Href de la camara
	 
	 output pwdn, // Power Down de la camara (apagado o encendido)
	 output xclk, // Reloj mandado a la camara
	 output resetcam, // Resetear camara con 0
	 

	// VGA input/output  
    output wire VGA_Hsync_n,  // horizontal sync output
    output wire VGA_Vsync_n,  // vertical sync output
    output wire VGA_R,	// 4-bit VGA red output
    output wire VGA_G,  // 4-bit VGA green output
    output wire VGA_B,  // 4-bit VGA blue output
    output reg clkout,  
 	
	// input/output
	
	input wire [7:0]FILTER // Seleccion filtro con los switch.
		
);

// TAMAÑO DE visualización 
parameter CAM_SCREEN_X = 160; //160
parameter CAM_SCREEN_Y = 120; //120

localparam AW = 15; // LOG2(CAM_SCREEN_X*CAM_SCREEN_Y)
localparam DW = 3;

// El color es RGB 444
localparam RED_VGA =   3'b100;
localparam GREEN_VGA = 3'b010;
localparam BLUE_VGA =  3'b001;


// Clk 
wire clk50M;
wire clk108M;
wire clk24M;


// Conexión dual por ram

wire  [AW-1: 0] DP_RAM_addr_in;  
wire  [DW-1: 0] DP_RAM_data_in;
wire DP_RAM_regW;

reg  [AW-1: 0] DP_RAM_addr_out;  
	
// Conexión VGA Driver
wire [DW-1:0]data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0]data_RGB444;  // salida del driver VGA al puerto
wire [10:0]VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [10:0]VGA_posY;		   // Determinar la pos de memoria que viene del VGA


/* ****************************************************************************
la pantalla VGA es RGB 444, pero por falta de un DAC en la tarjeta se envia solo RGB 111
**************************************************************************** */
	assign VGA_R =data_RGB444[2];
	assign VGA_G =data_RGB444[1];
	assign VGA_B =data_RGB444[0];


/* ****************************************************************************
  Se crear dos relojes, uno para la pantalla de 31.5 MHz y otro para la camara de 24 MHz
**************************************************************************** */
assign clk50M =clk;


clk50to108_2 clk108(
	.inclk0(clk50M),
	.c0(clk108M)
	
);

clk50to24 clk24(
	.inclk0(clk50M),
	.c0(clk24M)
	
);

/* ****************************************************************************
Modulo de RAM, en la tarjeta es solo suficiente para guardar una imagen de 160x120
**************************************************************************** */
buffer_ram_dp #( AW,DW)
	DP_RAM(  
	.clk_w(pclk), //clk25M
	.addr_in(DP_RAM_addr_in), 
	.data_in(DP_RAM_data_in),
	.regwrite(DP_RAM_regW),
	.filter(FILTER),

	.clk_r(clk108M), 
	.addr_out(DP_RAM_addr_out),
	.data_out(data_mem)
	);
	

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver640x480 VGA640x480
(
	.rst(~rst),
	.clk(clk108M), 				// 25MHz  para 60 hz de 640x480
	.pixelIn(data_mem), 		// entrada del valor de color  pixel RGB 444 
//	.pixelIn(RED_VGA), 		// entrada del valor de color  pixel RGB 444 
	.pixelOut(data_RGB444), // salida del valor pixel a la VGA 
	.Hsync_n(VGA_Hsync_n),	// señal de sincronizaciÓn en horizontal negada
	.Vsync_n(VGA_Vsync_n),	// señal de sincronizaciÓn en vertical negada 
	.posX(VGA_posX), 			// posición en horizontal del pixel siguiente
	.posY(VGA_posY) 			// posición en vertical  del pixel siguiente

);

 
/* ****************************************************************************
LÓgica para actualizar el pixel acorde con la buffer de memoria y el pixel de 
VGA si la imagen de la camara es menor que el display  VGA, los pixeles 
adicionales seran iguales al color del último pixel de memoria 
**************************************************************************** */

reg [10:0] tempx;
reg [10:0] tempy;

always @ (VGA_posX, VGA_posY) begin
		tempx = VGA_posX/4;
	  tempy = VGA_posY/4;	
		DP_RAM_addr_out=tempx+tempy*CAM_SCREEN_X;	
end





assign resetcam=rst;
assign xclk=clk24M;
assign pwdn=0;


//assign DP_RAM_addr_out=10000;

/*****************************************************************************

este bloque debe crear un nuevo archivo 
**************************************************************************** */
FSM_data  datos( 
      .CLK(clk108M),
		.D(dat),
		.VSYNC(sync),
		.PCLK(pclk),
		.HREF(href),
		.rst(rst),
		
		.mem_px_addr(DP_RAM_addr_in),
      .mem_px_data(DP_RAM_data_in),
      .px_wr(DP_RAM_regW)
		
   );
	
endmodule
```
