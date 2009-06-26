#include <WConstants.h> //OUTPUT and friends
#include "ShiftRegister.h"

ShiftRegisterIn::ShiftRegisterIn(uint8_t clock_pin, uint8_t data_pin, uint8_t load_pin,
									uint8_t clear_pin /*= 0*/) :
                _clock_pin(clock_pin), _data_pin(data_pin),
                 _load_pin(load_pin), _clear_pin(clear_pin)
{
  //init the 165
  if (_clear_pin) {
	pinMode(_clear_pin, OUTPUT);
	digitalWrite(_clear_pin, 0); // enable input, you could also tie this pin to GND
  }
  pinMode(_data_pin, INPUT);
  pinMode(_clock_pin, OUTPUT);
  pinMode(_load_pin, OUTPUT);
}

/* Reads the values of the input pins. Returns a bitmap */
int ShiftRegisterIn::read()
{
  int temp = 0;
  digitalWrite(_load_pin, 0); // read into register (tells the 165 to take a snapshot of its input pins)
  digitalWrite(_load_pin, 1); // done reading into register, ready for us to read
  
  // read each of the 165's 8 inputs (or its snapshot of it rather)
  for(int i=0; i < 8; i++) {
    digitalWrite(_clock_pin, 0);  //start reading

    temp += (digitalRead(_data_pin) << i); // read the state

    digitalWrite(_clock_pin, 1); //done reading
  }
  return temp;
}