RM = rm
TARGET_BOARD = -target=XC-1
XCCFLAGS = -O0 -g -Wall $(TARGET_BOARD)
XCC = xcc
XC_SRCS = $(wildcard *.xc)
OBJS = $(patsubst %.xc,%.o,$(XC_SRCS))
TARGET = downsample.xe

$(TARGET): $(OBJS)
	@echo 'Building target: $@'
	$(XCC) -o $(TARGET) $(XCCFLAGS) $(OBJS)

%.o: %.xc
	@echo 'Building file: $<'
	$(XCC) -c -o $@ $< $(XCCFLAGS)

all: $(TARGET)

clean:
	$(RM) -f $(OBJS) $(TARGET)
