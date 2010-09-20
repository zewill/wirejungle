#include "HT1621.h"

#define DATA_PIN  2
#define WR_PIN    13
#define RD_PIN    4
#define CS_PIN    5

HT1621 ht1621(DATA_PIN, WR_PIN, RD_PIN, CS_PIN);

void setup()
{
  Serial.begin(9600);
  if (! ht1621.begin()) {
    Serial.println("Could not init device!\n");
  }
  
  //degrees celsius
  ht1621.writeMem(1, 0b1010);
  ht1621.writeMem(2, 0b1011);
}

int i = 0;
void loop()
{
  ht1621.writeMem(1, 0b1111);
  ht1621.writeMem(2, 0b1111);

  ht1621.writeMem(0, i % 16);
  Serial.println(i);
  i++;
  delay(2000);
}
