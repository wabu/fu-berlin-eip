# Customize below to fit your system

# paths
PREFIX = ${ROOT}
BINDIR = ${PREFIX}/bin
RESDIR = ${BINDIR}
MANDIR = ${PREFIX}/share/man
ETCDIR = ${PREFIX}/etc
LIBDIR = ${PREFIX}/lib
INCDIR = ${PREFIX}/include

# Includes and libs
INCARGS += -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include -I/share/download/XMOS/DevelopmentTools/11.2.0/target/include/gcc
LIBARGS += 

TARGET_BOARD = ${ROOT}/xViMo-L1C.xn
# Flags
CFLAGS += -fms-extensions -Wall $(TARGET_BOARD) -Os ${INCARGS}
LDFLAGS += ${LIBARGS} $(TARGET_BOARD)
XCCFLAGS = -Os -Wall $(TARGET_BOARD) ${INCARGS}

# Compiler
CC = xcc -c
XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = xcc
# Library
# Archiver
AR = ar crs

