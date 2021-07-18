# Proyecto-Digital-I
Proyecto curso Digital I, camara VGA
## Funcionamiento de Modulo OV7670
El módulo OV7670 es un  sensor de imagen capaz de tomar hasta un máximo de 30 fotogramas por segundo , con una  resolución de 640x480 pixeles y voltaje de operación 3.3V. Para este proyecto se configuro los registros internos de este módulo mediante el uso  del puerto I2C de un Arduino mega 2560. Esta configuración nos permitió modificar el formato de imagen que nos envía la cámara , que  posteriormente será procesado por la FPGA.

Lo que se configura en los registros internos de la cámara es principalmente la exposición y el control de ganancia , la exposición debido a que esto hace que el lente de la  cámara tome de una mejor o peor  manera  la imagen que se desea capturar . Esta configuración nos permitió modificar la forma como se enviaron la señales:
<ol>HREF: Sincroniza los pixeles en  forma horizontal </ol> 
<ol>VSYNC: Sincroniza los pixeles en  forma vertical </ol>
<ol>PCLK: Reloj que nos envía la cámara</ol>  
![image](https://user-images.githubusercontent.com/80170093/126074226-df90e6f8-6943-49a2-b1b6-cc991c2ddb74.png)


Como este tipo de módulo no tiene memoria FIFO que permita guardar los datos , este nos enviara datos  de pixeles constante mente , es por esto que mediante el uso de la FPGA creamos nuestra memoria FIFO a partir de registros 
## Documentación de Código 
El proyecto se dividió en cuatro módulos: test_VGA , buffer_ram_dp, VGA_Driver640x480 y FSM_data.
### test_VGA
Es el top del proyecto y tiene como función llamar a todos los demás módulos con los inputs y outputs correctos. También se encarga de enviar y recibir los datos de los pixeles y reloj al monitor y la cámara, asi como de recibir la selección del filtro en lo switches de la FPGA.

```verilog
module test_VGA(
    input wire clk,           // board clock: 32 MHz quacho 100 MHz nexys4 
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
la pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
	assign VGA_R =data_RGB444[2];
	assign VGA_G =data_RGB444[1];
	assign VGA_B =data_RGB444[0];





/* ****************************************************************************
  Este bloque se debe modificar según sea le caso. El ejemplo esta dado para
  fpga Spartan6 lx9 a 32MHz.
  usar "tools -> IP Generator ..."  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA , a partir de una frecuencia de 12 Mhz
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


//assign clk25M=clk;
//assign clkout=clk25M;

/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  según los calculos realizados en el Wp01
se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
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
