# paths
PREFIX = ${ROOT}
BINDIR = ${PREFIX}/bin
RESDIR = ${BINDIR}
MANDIR = ${PREFIX}/share/man
ETCDIR = ${PREFIX}/etc
LIBDIR = ${PREFIX}/lib
INCDIR = ${PREFIX}/include

# Includes and libs
INCARGS += -I/usr/include
LIBARGS += -L/usr/lib

# Flags
CFLAGS += -std=c99 -Os -fms-extensions -Wall $(INCARGS)
LDFLAGS += $(LIBARGS)

# Compiler
CC = gcc -c
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = gcc
# Archiver
AR = ar crs

## XMOS

# Includes and libs
XMOS_INCARGS += -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include/gcc
XMOS_LIBARGS += 
XMOS_BINSUFFIX = .xe

# Flags
TARGET_BOARD = ${ROOT}/xViMo-L1C.xn
XMOS_CFLAGS += -Os -fms-extensions -Wall $(TARGET_BOARD) $(XMOS_INCARGS)
XMOS_XCCFLAGS += -Os -Wall $(TARGET_BOARD) $(XMOS_INCARGS)
XMOS_LDFLAGS += $(TARGET_BOARD) $(XMOS_LIBARGS)

# Compiler
XMOS_CC = xcc -c
XMOS_XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
XMOS_LD = xcc
# Archiver
XMOS_AR = ar crs

