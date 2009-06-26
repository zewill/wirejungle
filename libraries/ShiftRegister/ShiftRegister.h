#ifndef ShiftRegister_h
#define ShiftRegister_h
#include <inttypes.h>

/* Drive an 74HC165 to read buttons */

class ShiftRegisterIn {
public:
  ShiftRegisterIn(uint8_t clock_pin, uint8_t data_pin, uint8_t load_pin, 
					uint8_t clear_pin = 0);
  int read();
  
private:
  uint8_t _clock_pin;
  uint8_t _data_pin;
  uint8_t _load_pin;
  uint8_t _clear_pin;
};

#endif