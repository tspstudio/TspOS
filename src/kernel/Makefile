BUILD_DIR?=build/
ASM?=nasm

.PHONY: all always kernel clean

all: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin:
	@$(ASM) main.asm -f bin -o $(BUILD_DIR)/kernel.bin

always:
#@#