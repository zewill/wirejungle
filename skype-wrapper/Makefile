CFLAGS+=-fPIC -Wall -ldl -march=i686 -m32

all: libskype_wrapper.so

libskype_wrapper.so: skype_wrapper.o
	$(CC) -march=i686 -m32 -shared -Wl,-soname,$@ -o $@ $< -ldl 

clean:
	/bin/rm -f skype_wrapper.o libskype_wrapper.so
