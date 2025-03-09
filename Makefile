ASM=nasm
CC=gcc
CC16=/usr/bin/watcom/binl64/wcc
LD16=/usr/bin/watcom/binl64/wlink

SRC_DIR=src
TOOLS_DIR=tools
BUILD_DIR=build

TARGET=$(BUILD_DIR)/floppy.img

.PHONY: all image kernel boot clean always tools

all: image tools

#
# Floppy image
#
image: $(TARGET)

$(TARGET): boot kernel
	@echo "Creating floppy image"
	@dd if=/dev/zero of=$(TARGET) bs=512 count=2880
	@mkfs.fat -F 12 -n "TSPOS" $(TARGET)
	@dd if=$(BUILD_DIR)/boot/bootsect.bin of=$(TARGET) conv=notrunc
	@mcopy -i $(TARGET) $(BUILD_DIR)/boot/boot.bin "::boot.bin"
	@mcopy -i $(TARGET) $(BUILD_DIR)/kernel.bin "::kernel.bin"

boot: $(BUILD_DIR)/boot/bootsect.bin $(BUILD_DIR)/boot/boot.bin

$(BUILD_DIR)/boot/bootsect.bin: always
	@$(MAKE) -C $(SRC_DIR)/boot/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

$(BUILD_DIR)/boot/boot.bin: always
	@$(MAKE) -C $(SRC_DIR)/boot/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	@$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR))

tools: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	@mkdir -p $(BUILD_DIR)/tools
	@$(MAKE) -C tools/fat BUILD_DIR=$(abspath $(BUILD_DIR))

always:
	@$(MAKE) -C $(SRC_DIR)/boot/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) always
	@$(MAKE) -C $(SRC_DIR)/boot/stage2 BUILD_DIR=$(abspath $(BUILD_DIR)) always
	@$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) always

#
# Clean
#
clean:
	@rm -rf $(BUILD_DIR)/*
