BUILD_DIR?=build/
ASM?=nasm
ASMFLAGS?=-f obj
CC16?=/usr/bin/watcom/binl64/wcc
CFLAGS16?=-4 -d3 -s -wx -ms -zl -zq -za99 # -oneatxzh 
LD16?=/usr/bin/watcom/binl64/wlink

SOURCES_C=$(wildcard *.c)
SOURCES_ASM=$(wildcard *.asm)
OBJECTS_C=$(patsubst %.c, $(BUILD_DIR)/boot/c/%.obj, $(SOURCES_C))
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/boot/asm/%.obj, $(SOURCES_ASM))

.PHONY: all stage2 clean always

all: $(BUILD_DIR)/boot/boot.bin

$(BUILD_DIR)/boot/boot.bin: $(OBJECTS_ASM) $(OBJECTS_C)
	@echo "Linking boot.bin"
	@$(LD16) NAME $(BUILD_DIR)/boot/boot.bin FILE \{ $(OBJECTS_ASM) $(OBJECTS_C) \} OPTION MAP=$(BUILD_DIR)/stage2.map @linker.lnk

$(BUILD_DIR)/boot/c/%.obj: %.c always
	@echo "Compiling $<"
	@$(CC16) $(CFLAGS16) -fo=$@ $<

$(BUILD_DIR)/boot/asm/%.obj: %.asm always
	@echo "Assembling $<"
	@$(ASM) $(ASMFLAGS) -o $@ $<

always:
	@mkdir -p $(BUILD_DIR)/boot/c
	@mkdir -p $(BUILD_DIR)/boot/asm
