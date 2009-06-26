/*
	Copyright 2009 Ami Chayun
	
	Library to drive 74HC165 shift register
	
	This file is free software; you can redistribute it and/or modify
	it under the terms of either the GNU General Public License version 2
	or the GNU Lesser General Public License version 2.1, both as
	published by the Free Software Foundation.
*/
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
