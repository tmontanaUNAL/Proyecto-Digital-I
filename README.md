# Proyecto-Digital-I
Proyecto curso Digital I, camara VGA
## Funcionamiento de Modulo OV7670
El módulo OV7670 es un  sensor de imagen capaz de tomar hasta un máximo de 30 fotogramas por segundo , con una  resolución de 640x480 pixeles y voltaje de operación 3.3V. Para este proyecto se configuro los registros internos de este módulo mediante el uso  del puerto I2C de un Arduino mega 2560. Esta configuración nos permitió modificar el formato de imagen que nos envía la cámara , que  posteriormente será procesado por la FPGA.


Como este tipo de módulo no tiene memoria FIFO que permita guardar los datos , este nos enviara datos  de pixeles constante mente , es por esto que mediante el uso de la FPGA creamos nuestra memoria FIFO
## Documentación de Código 
El proyecto se dividió en cuatro módulos: test_VGA , buffer_ram_dp, VGA_Driver640x480 y FSM_data.
### test_VGA
Es el top del proyecto y tiene como función llamar a todos los demás módulos con los inputs y outputs correctos. También se encarga de enviar y recibir los datos de los pixeles y reloj al monitor y la cámara, asi como de recibir la selección del filtro en lo switches de la FPGA.

```rb
# quartus/scr/test_VGA.v
```