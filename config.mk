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
INCARGS += -I/usr/include -I/usr/local/include -I/usr/include/win32api
LIBARGS += -L/usr/lib -L/usr/local/lib -lc -lGL -lGLU -lglut -lX11 -lm

TARGET_BOARD = -target=XK-1
# Flags
CFLAGS += -Wall -g -O0 ${INCARGS}
LDFLAGS += -g ${LIBARGS}
XCCFLAGS = -O3 -Wall $(TARGET_BOARD) ${INCARGS}

# Compiler
CC = cc -c
XCC = xcc
# Linker (Under normal circumstances, this should *not* be 'ld')
LD = cc
# Library
SO = cc -shared
# Archiver
AR = ar crs

# Tag files for vim
TAGFILE=
# you don't want to use ctags, comment out the next 2 lines
TG = ctags
TAGFILE=tags
# you don't want to use scope, comment out the next 2 lines
TG = echo | cscope $(INCARGS)
TAGFILE=cscope.out
