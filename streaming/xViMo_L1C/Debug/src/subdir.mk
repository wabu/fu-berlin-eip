################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/checksum.c \
../src/mii_queue.c \
../src/mii_wrappers.c \
../src/swlock.c 

XC_SRCS += \
../src/cam.xc \
../src/delays.xc \
../src/eth_phy.xc \
../src/ethernet_rx_client.xc \
../src/ethernet_rx_filter.xc \
../src/ethernet_rx_server.xc \
../src/ethernet_server.xc \
../src/ethernet_tx_client.xc \
../src/ethernet_tx_server.xc \
../src/i2c.xc \
../src/image_processing.xc \
../src/main.xc \
../src/mii.xc \
../src/mii_filter.xc \
../src/smi.xc \
../src/udp.xc 

OBJS += \
./src/cam.o \
./src/checksum.o \
./src/delays.o \
./src/eth_phy.o \
./src/ethernet_rx_client.o \
./src/ethernet_rx_filter.o \
./src/ethernet_rx_server.o \
./src/ethernet_server.o \
./src/ethernet_tx_client.o \
./src/ethernet_tx_server.o \
./src/i2c.o \
./src/image_processing.o \
./src/main.o \
./src/mii.o \
./src/mii_filter.o \
./src/mii_queue.o \
./src/mii_wrappers.o \
./src/smi.o \
./src/swlock.o \
./src/udp.o 

C_DEPS += \
./src/checksum.d \
./src/mii_queue.d \
./src/mii_wrappers.d \
./src/swlock.d 

XC_DEPS += \
./src/cam.d \
./src/delays.d \
./src/eth_phy.d \
./src/ethernet_rx_client.d \
./src/ethernet_rx_filter.d \
./src/ethernet_rx_server.d \
./src/ethernet_server.d \
./src/ethernet_tx_client.d \
./src/ethernet_tx_server.d \
./src/i2c.d \
./src/image_processing.d \
./src/main.d \
./src/mii.d \
./src/mii_filter.d \
./src/smi.d \
./src/udp.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.xc
	@echo 'Building file: $<'
	@echo 'Invoking: XC Compiler'
	xcc -O3 -g -Wall -c -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d) $@ " -o $@ "$<" "../XC-1.xn"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: C Compiler'
	xcc -O3 -g -Wall -c -std=gnu89 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d) $@ " -o $@ "$<" "../XC-1.xn"
	@echo 'Finished building: $<'
	@echo ' '


