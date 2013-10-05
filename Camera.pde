/*
Read buffer three times due to lack of memory space.
*/

#include <avr/pgmspace.h>
#define PICTURE_SIZE 4500 //read three times

uint8_t MH,ML,high,low;
int curByteIndex = 0, photoIndex = 0, bufferIndex = 0;
uint8_t curByte, prevByte;
uint8_t picture[PICTURE_SIZE] = {0};
uint16_t pictureSize;
int address = 0x0000;

int i, j, k;

void setup()
{
  Serial.begin(9600);
  Serial1.begin(38400);
}

void loop()
{
  //reset the camera
  SendResetCmd();
  Serial.println("Reset sent.");
  delay(4000);
  while(Serial1.available() >0){
    Serial.print(Serial1.read(), HEX);
    Serial.print(" ");
  }
  Serial.println();
  
  //stop the current frame
  SendTakePhotoCmd();
  delay(100);
  while(Serial1.available() >0){
    Serial.print(Serial1.read(), HEX);
    Serial.print(" ");
  }
  Serial.println();
  
  //read the size of current frame
  GetFBUF();
  delay(100);
  curByteIndex=0;
  while(Serial1.available() >0){
    curByte = Serial1.read();
    Serial.print(curByte, HEX);
    Serial.print(" ");
    if (curByteIndex == 7)
      MH = curByte;
    if (curByteIndex == 8)
      ML = curByte;
    curByteIndex++;
    // 0 - x76
    // 1 - serial number
    // 2 - x34
    // 3 - x00
    // 4 - x04
    // 5 - data length 4 bytes
    // 6 - 00
    // 7 - MH
    // 8 - ML
  }
  Serial.println();
  Serial.println(MH, HEX);
  Serial.println(ML, HEX);
  
  pictureSize = (MH << 8) | ML;
  Serial.println(pictureSize, HEX);
    
  //read the picture
  while(photoIndex < pictureSize)
  {
    SendReadDataCmd();
    delay(100);
    curByteIndex = 0;
    while(Serial1.available())
    {
      curByte = Serial1.read();
      if (curByteIndex >= 5 && curByteIndex < 37)
      {
        picture[bufferIndex] = curByte;
        photoIndex++;
        bufferIndex++;
        if (bufferIndex == PICTURE_SIZE || photoIndex >= pictureSize){ //if the buffer is full or it's already the last "frame"
          for (i = 0 ; i < bufferIndex ; i++){
            Serial.print(picture[i],HEX);
            Serial.print(" ");
            picture[i] = 0;
          }
          Serial.println();
          bufferIndex = 0;
        }
      }
      curByteIndex++;
    }
  }

  
  while(1);//pause the program
}

//Send Reset command
void SendResetCmd()
{
      Serial1.print(0x56, BYTE);
      Serial1.print(0x00, BYTE);
      Serial1.print(0x26, BYTE);
      Serial1.print(0x00, BYTE);
}

//Send take picture command
void SendTakePhotoCmd()
{
      Serial1.print(0x56, BYTE);
      Serial1.print(0x00, BYTE);
      Serial1.print(0x36, BYTE);
      Serial1.print(0x01, BYTE);
      Serial1.print(0x00, BYTE);  
}

void GetFBUF()
{
  Serial1.print(0x56, BYTE);
  Serial1.print(0x00, BYTE);
  Serial1.print(0x34, BYTE);
  Serial1.print(0x01, BYTE);
  Serial1.print(0x00, BYTE);
}

void SendReadDataCmd()
{
      high=address/0x100;
      low=address%0x100;
      Serial1.print(0x56, BYTE);
      Serial1.print(0x00, BYTE);
      Serial1.print(0x32, BYTE);
      Serial1.print(0x0c, BYTE);
      Serial1.print(0x00, BYTE); //FBUF type
      Serial1.print(0x0a, BYTE); //control mode
      Serial1.print(0x00, BYTE); //starting address
      Serial1.print(0x00, BYTE);
      Serial1.print(high, BYTE);
      Serial1.print(low, BYTE);   
      Serial1.print(0x00, BYTE); //data length
      Serial1.print(0x00, BYTE);
      Serial1.print(0x00, BYTE);
      Serial1.print(0x20, BYTE);
      Serial1.print(0x10, BYTE); //delay
      Serial1.print(0x00, BYTE);
      address+=0x20; //32 bytes
}
      
void StopTakePhotoCmd()
{
      Serial1.print(0x56, BYTE);
      Serial1.print(0x00, BYTE);
      Serial1.print(0x36, BYTE);
      Serial1.print(0x01, BYTE);
      Serial1.print(0x03, BYTE);        
}
