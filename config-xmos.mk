INFIX=.x

# Includes and libs
INCARGS += -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include/gcc
LIBARGS += 
BINSUFFIX = .xe

# Flags
TARGET_BOARD = -target=XK-1
CFLAGS += -Os -fms-extensions -Wall $(TARGET_BOARD) $(INCARGS)
XCCFLAGS += -Os -Wall $(TARGET_BOARD) $(INCARGS)
LDFLAGS += $(TARGET_BOARD) $(LIBARGS)

# Compiler
CC = xcc -c
XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = xcc
# Archiver
AR = ar crs

