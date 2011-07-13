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
LIBARGS += -L/usr/lib -L/usr/local/lib -lc -lGL -lGLU -lglut -lX11 -lm

TARGET_BOARD = -target=XK-1
# Flags
CFLAGS += -Wall $(TARGET_BOARD) -g -O0 ${INCARGS}
LDFLAGS += -g ${LIBARGS}
XCCFLAGS = -O3 -Wall $(TARGET_BOARD) ${INCARGS}

# Compiler
CC = xcc -c
XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = cc
# Library
SO = cc -shared
# Archiver
AR = ar crs

