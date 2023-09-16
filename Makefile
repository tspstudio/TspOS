ASM=nasm

SRC_DIR=src
BUILD_DIR=build
TOOLS_DIR=tools

CC=gcc

.PHONY: run all floppy kernel boot clean always debug tools

floppy: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: boot kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "TspOS Live" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot/boot.asm always
	$(ASM) $(SRC_DIR)/boot/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/main.asm
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

run: floppy
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

debug: floppy
	bochs -f bochs_config

tools: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*