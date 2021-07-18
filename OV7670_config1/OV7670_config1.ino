#include <Wire.h>

#define OV7670_I2C_ADDRESS 0x21 /*Dirección del bus i2c para ña camara*/

void setup() {
  Wire.begin();
  Serial.begin(9600);  
  Serial.println("prueba");
  set_cam_RGB565_QCIF();
  delay(100);
  get_cam_register();
  
}


void set_cam_RGB565_QCIF(){
   
  OV7670_write(0x12, 0x80);

delay(100);

 OV7670_write(0xFF, 0xF0); 
 //OV7670_write(0x12, 0x14);  //COM7: Set QQVGA (160x120) and RGB
 OV7670_write(0x12, 0x06);  //COM7: Set RGB creo que queda con VGA (640x480)
 OV7670_write(0x11, 0xC0);       //CLKR: Set internal clock to use external clock
 //OV7670_write(0x11, 0x80);    
 OV7670_write(0x0C, 0x04);       //COM3: Enable DCW
 //OV7670_write(0x0C, 0x00);
 OV7670_write(0x3E, 0x1A);     //Con DCW y con divisor del reloj pclk en 4
 //OV7670_write(0x3E, 0x13);   //Enable Scaling for Predefined Formats using COM14
 OV7670_write(0x8C,0x02);      //COM15: Set RGB 444
 OV7670_write(0x40,0xD0);      //COM15: Set RGB 444

 //Color Bar
 //OV7670_write(0x42, 0x08); 
 //OV7670_write(0x12, 0x0E);

 //Registros Mágicos 
 OV7670_write(0x3A,0x04); //Imagen no negativa, output UV nomal, secuencia UV del output YUYV
 OV7670_write(0x14,0x28); //Gain ceiling, maximo valor de AGC queda en 4x 
 OV7670_write(0x4F,0xB3); //Coeficiente 1 de la matriz queda con el valor 0xB3
 OV7670_write(0x50,0xB3); //Coeficiente 2 de la matriz queda con el valor 0xB3
 OV7670_write(0x51,0x00); //Coeficiente 3 de la matriz queda con el valor 0x00
 OV7670_write(0x52,0x3D); //Coeficiente 4 de la matriz queda con el valor 0x3D
 OV7670_write(0x53,0xA7); //Coeficiente 5 de la matriz queda con el valor 0xA7
 OV7670_write(0x54,0xE4); //Coeficiente 6 de la matriz queda con el valor 0xE4
 OV7670_write(0x58,0x9E); //Auto contraste activado, signos de los coeficientes de la matriz 011110 0=+ 1=-
 OV7670_write(0x3D,0xC0); //secuencia UV del output YUYV
 OV7670_write(0x17,0x16); //Formato de salida HREF (HSTART) 0001 0110 <= 8 MSB
 OV7670_write(0x18,0x04); //Formato de salida HREF (HSTOP) 0000 0100 <= 8 MSB
 OV7670_write(0x32,0xa4); //(HREF 1010 0100) Control HREF 10 <= offset del flanco de HREF, 100 <= 3 LSB de HSTOP, 100 <= 3 LSB de HSTART
 OV7670_write(0x19,0x02); //Formato de salida VREF (VSTRT) 0000 0010 <= 8 MSB
 OV7670_write(0x1A,0x7A); //Formato de salida VREF (VSTOP) 0111 1010 <= 8 MSB
 OV7670_write(0x03,0xA4); //(VREF 1010 0100) Control VREF 10 <= AGC, 10 <= reservado, 01 <= 2 LSB de VSTOP, 00 <= 2 LSB de VSTRT
 OV7670_write(0x0F,0x41); // HREF en negro optico desactivado, usar linea negra optica como señal BLC, BLC digital desactivado
 OV7670_write(0x32,0x80); //Repetido
 OV7670_write(0x1E,0x00); //Se seleccion imagen no en espejo
 OV7670_write(0x33,0x0B); //Array current control = 0000 1011
 OV7670_write(0x3C,0x78); //No hay HREF cuando VSYNC es 0
 OV7670_write(0x69,0x00); //Fix gain control, ganacia de 1x para canales Gr, Gb, R, B
 OV7670_write(0x74,0x00); //Control de ganacia digital por VREF[7:6]
 OV7670_write(0xB0,0x84); //Reservado
 OV7670_write(0xB1,0x0C); //Reservado
 OV7670_write(0xB2,0x0E); //Reservado
 OV7670_write(0xB3,0x80); //Digital BLC target = 1000 0000
 OV7670_write(0x72,0x22); //Control DCW
 OV7670_write(0x73,0xF2); //Division pclk en 4


/*prubas de ferney*/

/*
   OV7670_write(0x12, 0x00);  //COM7: Set QCIF and RGB Using COM7 and Color Bar    
  OV7670_write(0x40,0xC0);        //COM15: Set RGB 565  
  OV7670_write(0x11, 0x0A);       //CLKR: CSet internal clock to use external clock    
  OV7670_write(0x0C, 0x04);       //COM3: Enable Scaler   
  OV7670_write(0x14,0x6A);       
  
  OV7670_write(0x17, 0x16);      
  OV7670_write(0x18, 0x04);     
  */  
}

void get_cam_register(){
  Serial.println(get_register_value(0x12), HEX); //COM7
  Serial.println(get_register_value(0x11), HEX); //COM7
  Serial.println(get_register_value(0x40), HEX); //COM15
  Serial.println(get_register_value(0x0C), HEX); //COM3
  Serial.println(get_register_value(0x42), HEX); //
  Serial.println(get_register_value(0x14), HEX); 

  Serial.println(get_register_value(0x17), HEX); 
  Serial.println(get_register_value(0x18), HEX); 

}


int OV7670_write(int reg_address, byte data){
  return I2C_write(reg_address, &data, 1);
 }

int I2C_write(int start, const byte *pData, int size){
 //  Serial.println ("I2C init");   
    int n,error;
    Wire.beginTransmission(OV7670_I2C_ADDRESS);
    n = Wire.write(start);
    if(n != 1){
      Serial.println ("I2C ERROR WRITING START ADDRESS");   
      return 1;
    }
    n = Wire.write(pData, size);
    if(n != size){
      Serial.println( "I2C ERROR WRITING DATA");
      return 1;
    }
    error = Wire.endTransmission(true);
    if(error != 0){
      Serial.println( String(error));
      return 1;
    }
    Serial.println ("WRITE OK");
    return 0;
 }

byte get_register_value(int register_address){
  byte data = 0;
   Serial.println ("I2C read");   
  Wire.beginTransmission(OV7670_I2C_ADDRESS);
  Wire.write(register_address);
  Wire.endTransmission();
  Wire.requestFrom(OV7670_I2C_ADDRESS,1);
  while(Wire.available()<1);
  data = Wire.read();
  return data;
}


void set_color_matrix(){
    OV7670_write(0x4f, 0x80);
    OV7670_write(0x50, 0x80);
    OV7670_write(0x51, 0x00);
    OV7670_write(0x52, 0x22);
    OV7670_write(0x53, 0x5e);
    OV7670_write(0x54, 0x80);
    OV7670_write(0x56, 0x40);
    OV7670_write(0x58, 0x9e);
    OV7670_write(0x59, 0x88);
    OV7670_write(0x5a, 0x88);
    OV7670_write(0x5b, 0x44);
    OV7670_write(0x5c, 0x67);
    OV7670_write(0x5d, 0x49);
    OV7670_write(0x5e, 0x0e);
    OV7670_write(0x69, 0x00);
    OV7670_write(0x6a, 0x40);
    OV7670_write(0x6b, 0x0a);
    OV7670_write(0x6c, 0x0a);
    OV7670_write(0x6d, 0x55);
    OV7670_write(0x6e, 0x11);
    OV7670_write(0x6f, 0x9f);
    OV7670_write(0xb0, 0x84);
}


void loop(){
  
 }
