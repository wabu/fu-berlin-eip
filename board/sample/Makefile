RM = rm
TARGET_BOARD = -target=XK-1
XCCFLAGS = -O3 -Wall $(TARGET_BOARD)
XCC = xcc
XC_SRCS = $(wildcard *.xc)
C_SRCS = $(wildcard *.c)
OBJS = $(patsubst %.xc,%.o,$(XC_SRCS)) $(patsubst %.c,%.o,$(C_SRCS))
TARGET = main.xe

$(TARGET): $(OBJS)
	@echo 'Building target: $@'
	$(XCC) -o $(TARGET) $(XCCFLAGS) $(OBJS)

%.o: %.xc
	@echo 'Building file: $<'
	$(XCC) -c -o $@ $< $(XCCFLAGS)
%.o: %.c
	@echo 'Building file: $<'
	$(XCC) -c -o $@ $< $(XCCFLAGS)

all: $(TARGET)

clean:
	$(RM) -f $(OBJS) $(TARGET)
