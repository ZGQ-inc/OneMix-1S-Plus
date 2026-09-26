CC ?= gcc
CFLAGS ?= -O2 -Wall -fPIC
LDFLAGS ?= -shared -Wl,--version-script=shim.map -ldl

TARGET = focaltech-shim.so

all: $(TARGET)

$(TARGET): focaltech-shim.c shim.map
	$(CC) $(CFLAGS) focaltech-shim.c $(LDFLAGS) -o $(TARGET)
	strip $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean
