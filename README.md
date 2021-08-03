# Proyecto-Digital-I
Proyecto curso Digital I, camara VGA
## Funcionamiento de Modulo OV7670
El módulo OV7670 es un  sensor de imagen capaz de tomar hasta un máximo de 30 fotogramas por segundo , con una  resolución de 640x480 pixeles y voltaje de operación 3.3V. Para este proyecto se configuro los registros internos de este módulo mediante el uso  del puerto I2C de un Arduino mega 2560. Esta configuración nos permitió modificar el formato de imagen que nos envía la cámara , que  posteriormente será procesado por la FPGA.

Lo que se configura en los registros internos de la cámara es principalmente la exposición y el control de ganancia , la exposición debido a que esto hace que el lente de la  cámara tome de una mejor o peor  manera  la imagen que se desea capturar . Esta configuración nos permitió modificar la forma como se enviaron la señales:
<ol>HREF: Sincroniza los pixeles en  forma horizontal </ol> 
<ol>VSYNC: Sincroniza los pixeles en  forma vertical </ol>
<ol>PCLK: Reloj que nos envía la cámara</ol>  
<img src="https://user-images.githubusercontent.com/80170093/126074371-762d4df3-53be-41d3-aef7-fd3918965739.PNG"width="700"height="400">

Como este tipo de módulo no tiene memoria FIFO que permita guardar los datos , este nos enviara datos  de pixeles constante mente , es por esto que mediante el uso de la FPGA creamos nuestra memoria FIFO a partir de registros . 



Los registros configurados fueron:

* Configuración del formato RGB de imagen  : 

![image](https://user-images.githubusercontent.com/80170093/128038045-9a07b324-59e9-4749-b8da-636ba2b47c6e.png)


Como se evidencia en la tabla del registro 12 (COM7), para configurar la cámara en  formato RGB es necesario que el valor del registro en formato binario sea 0000100  que en hexadecimal  es 04.

OV7670_write(0x12, 0x04);


Para configurar la cámara en RGB 444 se usa el registro 8C (RGB 444):

![image](https://user-images.githubusercontent.com/80170093/128046962-a5e39cf9-b1a1-4965-8a59-a387d90ff102.png)


OV7670_write(0x8C,0x02); 
 OV7670_write(0x40,0xD0);

Como se evidencia en la tabla del registro 8C (RGB 444) , para configurar la cámara en  formato RGB 444 es necesario que el valor del registro en formato binario sea 00000010  que en hexadecimal  es 02, esto solo es valido cundo el registro 40( COM15[4]) en el posicion 4  esta en alto (1) , en este casa cundo esta activa la función RGB 555 o RGB 565.



Para que nuestra cámara nos envié la imagen en formato QQVGA es necesario entender la relación que existen entré este formato y el formato VGA:


![image](https://user-images.githubusercontent.com/80170093/128084881-2d9955db-8f55-4b4e-9e19-003ccd6c4e96.png)

Como se evidencia en el anterior gráfico , el frame timing del formato QQVGA es 1/4 del frame timing del VGA, por tal motivo es necesario dividir el reloj del formato VGA entre 4, para esto modificamos los siguientes registros:

* Activa el factor de escala  : OV7670_write(0x0C, 0x04);      

![image](https://user-images.githubusercontent.com/80170093/128079565-0ba940eb-b79c-49fe-8668-b26ef7c39d39.png)

Para esto el bit[3] del registro 0C(COM3) debe estar en alto , es así como el dato binario que debe estar en este registro debe ser 00000100 que en hexadecimal es 04 , esto solo sucede si  se establece un formato predefinido , el cual es que el registro 3E (COM14) en su posición 3 (COM14[3]) este en estado alto para que se de el ajuste manual. 

* Para dividir el PCLK entre 4 es necesario configurar el registro 3E(COM14):


![image](https://user-images.githubusercontent.com/80170093/128082814-3d66666f-85f2-496f-a0fe-a7a2589a163b.png)

OV7670_write(0x3E, 0x1A);

como muestra la anterior tabla , dado que se tiene que dividir entre 4 el PCLK (reloj que genera la Cámara) entonces los 3 primeros bit de byte son 010 , el 4 bit debe ser 1 dado que es una condición que se estableció anteriormente para el ajuste manual el 5 bit debe ser 1 debido a que con este se habilita el  DCW y la escala del PCLK , y los bit restantes son 0, es así como el valor binario  que le corresponde al registro 3E (COM14) es 00011010 que en hexadecimal es  1A . 


Para configurar el factor de escala usamos el registro 72:

![image](https://user-images.githubusercontent.com/80170093/128089954-2ecf45c3-f0f7-4979-bf1b-004d42da8d57.png)

Como se debe dividir entre 4 la escala inicial , entonces quiere decir que cada muestra  horizontal hacia  a bajo equivale a 4  muestras del reloj original , para configurar la representación hacemos que los 2 primeros bits menos significativos del byte sean 1 y 0 , para las muestras verticales se configura de la misma manera haciendo que el bits[5:4] sean 1 y 0 .Es así como el factor de escala es configurada manualmente a partir del número binario 00100010 que en hexadecimal es 34 .

 OV7670_write(0x72,0x22);
 
 Ahora realizamos la divicion  del PCLK usando el registro 73:
 
 ![image](https://user-images.githubusercontent.com/80170093/128091745-fcd51946-1b0b-4974-9bc9-4a94d1183729.png)

 Para poder hacer la división primero escogemos la magnitud entera a la cual se va a dividir,  que en este caso es 4 , mirando la anterior tablan  vemos que para dividir entre este valor, los tres primeros bit de menor peso deben ser 010. Para la configuración del divisor de reloj de bypass para control de escala DSP,  tenemos que seleccionar la opción divisor de reloj de bypass , esto se hace colocando el 4 bit del byte en 1 en el registro 73 , finalmente tenemos que el valor del byte en el registro 72  en binario debe se de 11110010 que en hexadecimal es F2.
 
 OV7670_write(0x73,0xF2);
 
 
 
 
 

Para configurar la ganancia de la camara  se medifico el registro 



## Documentación de Código 
El proyecto se dividió en cuatro módulos: test_VGA , buffer_ram_dp, VGA_Driver640x480 y FSM_data.
### test_VGA
Es el top del proyecto y tiene como función llamar a todos los demás módulos con los inputs y outputs correctos. También se encarga de enviar y recibir los datos de los pixeles y reloj al monitor y la cámara, asi como de recibir la selección del filtro en lo switches de la FPGA. Otra funcion es la de escalar la imagen de la camara a la seleccionada en el VGADriver.

A continuacion vemos el código del modulo test_VGA

```verilog
module test_VGA(
    input wire clk,           // board clock: 32 MHz quacho 100 MHz nexys4 
    input wire rst,         	// reset button
	 
	  
	 input [7:0]dat, // Datos provenientes de la camara
	 input vsync, //Vsync de la camara
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
wire clk31M;
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
la pantalla VGA es RGB 444, pero por falta de un DAC en la tarjeta se envia 
solo RGB 111
**************************************************************************** */
	assign VGA_R =data_RGB444[2];
	assign VGA_G =data_RGB444[1];
	assign VGA_B =data_RGB444[0];





/* ***************************************************************************
Se crear dos relojes, uno para la pantalla de 31.5 MHz y otro para la camara 
de 24 MHz
**************************************************************************** */
assign clk50M =clk;

clk50to31 clk31(
	.inclk0(clk50M),
	.c0(clk31M)
	
);

clk50to24 clk24(
	.inclk0(clk50M),
	.c0(clk24M)
	
);

/* ****************************************************************************
Modulo de RAM, en la tarjeta es solo suficiente para guardar una imagen 
de 160x120
**************************************************************************** */
buffer_ram_dp #( AW,DW)
	DP_RAM(  
	.clk_w(pclk), //clk25M
	.addr_in(DP_RAM_addr_in), 
	.data_in(DP_RAM_data_in),
	.regwrite(DP_RAM_regW),
	.filter(FILTER),

	.clk_r(clk31M), 
	.addr_out(DP_RAM_addr_out),
	.data_out(data_mem)
	);
	

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver640x480 VGA640x480
(
	.rst(~rst),
	.clk(clk31M), 				// 25MHz  para 60 hz de 640x480
	.pixelIn(data_mem), 		// entrada del valor de color  pixel RGB 444 
	.pixelOut(data_RGB444), // salida del valor pixel a la VGA 
	.Hsync_n(VGA_Hsync_n),	// señal de sincronizaciÓn en horizontal negada
	.Vsync_n(VGA_Vsync_n),	// señal de sincronizaciÓn en vertical negada 
	.posX(VGA_posX), 			// posición en horizontal del pixel siguiente
	.posY(VGA_posY) 			// posición en vertical  del pixel siguiente

);

 
/* ****************************************************************************
LÓgica para actualizar el pixel acorde con la buffer de memoria y el pixel de 
VGA
**************************************************************************** */

reg [10:0] tempx;
reg [10:0] tempy;

always @ (VGA_posX, VGA_posY) begin
		tempx = VGA_posX/4; // Se divide ancho del frame de la cámara 640 en 4 para los 160 del QQVGA
	  tempy = VGA_posY/4;  // Se divide ancho del frame de la cámara 480 en 4 para los 120 del QQVGA
		DP_RAM_addr_out=tempx+tempy*CAM_SCREEN_X;	
end





assign resetcam=~rst;
assign xclk=clk24M;
assign pwdn=0;


//assign DP_RAM_addr_out=10000;

/*****************************************************************************

este bloque debe crear un nuevo archivo 
**************************************************************************** */
FSM_data  datos( 
		.D(dat),
		.VSYNC(vsync),
		.PCLK(pclk),
		.HREF(href),
		.rst(rst),
		
		.mem_px_addr(DP_RAM_addr_in),
      .mem_px_data(DP_RAM_data_in),
      .px_wr(DP_RAM_regW)
		
   );
	
endmodule
```
### buffer_ram_dp
Este modulo se encarga de guardar los datos de los pixeles enviados por el modulo FSM_data (pixeles provenientes de la cámara luego de procesarlos), para ello se vale del reloj que envia la camara para saber cuando puede escribir y cuando no. Por otro lado se encarag de leer los datos guardados en la ram, para ello se usa el reloj de la VGA (31.5 MHz) y la direccion dada por el test_VGA segun sea la resolucion de la camara y el VGA (escalamiento de la imagen).
```verilog
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
```
### VGA_Driver640x480
Se encarga de controlar la posicion donde se dibujan los pixeles, tambien fija la resolucion de la pantalla. Esto lo hace con dos contadores que va recorriendo los pixeles de la resolucion especificada en vertical y horizontal (cuando llegan al final se resetean). Estos contadores funcionan como un sistema de coodenadas que inidican la direccion del pixel al test_VGA. Tambien a partir de estos contadores se crean las señales Vsync y Hsync ve van a la pantalla.
```verilog
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
		countX <= TOTAL_SCREEN_X- 10; /*para la simulación sea mas rapido*/
		countY <= TOTAL_SCREEN_Y-4;/*para la simulación sea mas rapido*/
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
```
### FSM_data
Este modulo se encarga de recibir los datos del pixel de la cámara, asi como el reloj PCLK, y las señales de sincronización de la imagen VSYNC y HREF. Tambien convierte el formato de los datos de RGB 444 a RGB 111, crea la señal de direccion de memoria de escritura con un contador.

Es de notar que un pixel lo recibe en 2 pulsos de PCLK debido a que la camara solo puede manda 8 bits al tiempo y se requieren 16 para un pixel en RGB 444.

Para el funcionamiento de este modulo se uso una maquina de estado finito, el siguiente es el diagrama de flujo:

![Diagrama en blanco](https://user-images.githubusercontent.com/80001669/127943928-d61f879d-2907-4582-af90-1c705169d446.png)

Y el diagrama de estados queda:

![image](https://user-images.githubusercontent.com/80001669/127943799-a0db8879-5577-4575-9c1a-4c5c34d0d902.png)

El código en verilog es:
```verilog
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
```
## Diagrama de bloques
A continuacion vemos un diagrama de bloques mostrando el la interconexión de los distintos modulos, asi como el flujo de datos desde y hacia disposistivos externos (pantalla, cámara, switches y arduino).

![image](https://user-images.githubusercontent.com/80001669/126925228-673c0f92-5e86-4c93-a49d-dac757951ee3.png)
