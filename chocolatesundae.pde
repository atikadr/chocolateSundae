
// (Based on Ethernet's WebClient Example)

#include "WiFly.h"
#include "Credentials.h"
#include "Timer.h"

Timer t;

byte localhost[] = {192,168,43,60};
Client client(localhost, 80);

char response;
int index;

#define MOTOR_PIN 13

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);
  
  Serial.begin(9600);
  WiFly.begin();
  if (!WiFly.join(ssid, passphrase)) {
    Serial.println("Association failed.");
    while (1) {
      // Hang on failure.
    }
  }  
  Serial.println(WiFly.ip()); 
  if (client.connect()) {
    Serial.println("connected");
  }
  else {
    Serial.println("connection failed");
  }
  
  delay(1000); //1 second delay for setup
  
  t.every(10000, sendSlurrp);
  t.every(5000, receiveSlurrp);
}

void receiveSlurrp(){
  Serial.println("in receive slurrp");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/chocolateSundae/whipcream.php?");
  client.println();
  
  delay(1000);
  if (client.connected()) {Serial.println("still connected");}
  
  while(client.available()){
    char c = client.read();
    Serial.print(c);
    response = c;
  }
  
  Serial.print(response);
  if (response == '1') {digitalWrite(MOTOR_PIN, HIGH);}
  else {digitalWrite(MOTOR_PIN, LOW);}
}

void sendSlurrp(){
  Serial.println("in send slurrp");
  if (!client.connected()) {client.connect();} 
  client.println("GET /~Ben/chocolateSundae/whipcream.php?slurrp=3.14,1.68");
    client.println();
   
   delay(1000); //give it sometime to receive back
   
    while (client.available()) {
    char c = client.read();
    Serial.print(c);
  }
}

void loop() {
  t.update();
}


