BUILD_DIR?=build/
ASM?=nasm

.PHONY: all always clean

all: $(BUILD_DIR)/boot/bootsect.bin

$(BUILD_DIR)/boot/bootsect.bin:
	@echo "Building bootsect.bin"
	@$(ASM) boot.asm -f bin -o $(BUILD_DIR)/boot/bootsect.bin

always:
	@mkdir -p $(BUILD_DIR)/boot
