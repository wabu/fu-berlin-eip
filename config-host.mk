INFIX=.c

# Includes and libs
INCARGS += 
LIBARGS += 

# Flags
CFLAGS += -fms-extensions -Wall $(TARGET_BOARD) -Os ${INCARGS}
LDFLAGS += ${LIBARGS} $(TARGET_BOARD)
XCCFLAGS = -Os -Wall $(TARGET_BOARD) ${INCARGS}

# Compiler
CC = xcc -c
XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = xcc
# Archiver
AR = ar crs

