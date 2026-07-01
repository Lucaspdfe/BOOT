CC=i686-elf-gcc
LD=i686-elf-ld
AS=nasm

FINAL_IMG  = ./build/scratchboot.img
STAGE1     = ./build/stage1.bin
STAGE1_DIR = ./src/stage1
STAGE2     = ./build/stage2.bin
STAGE2_DIR = ./src/stage2
BUILD  = ./build

PARTITION_START = 2048

.PHONY: all stage1 stage2 img clean
all: clean img

img: stage1 stage2
	dd if=/dev/zero of=$(FINAL_IMG) bs=1M count=256

	parted -s $(FINAL_IMG) mklabel msdos
	parted -s $(FINAL_IMG) mkpart primary fat32 $(PARTITION_START)s 100%
	parted -s $(FINAL_IMG) set 1 boot on

	mkfs.fat -F 32 --offset=$(PARTITION_START) -h $(PARTITION_START) $(FINAL_IMG)

	install-mbr $(FINAL_IMG)

	dd if=$(STAGE1) of=$(FINAL_IMG) bs=1 count=3 seek=$$(($(PARTITION_START) * 512)) conv=notrunc
	dd if=$(STAGE1) of=$(FINAL_IMG) bs=1 skip=90 seek=$$((($(PARTITION_START) * 512) + 90)) conv=notrunc

	mcopy -i $(FINAL_IMG)@@$$(($(PARTITION_START) * 512)) $(STAGE2) ::/STAGE2.BIN

stage1: $(STAGE1)
$(STAGE1): always
	$(AS) -f bin $(STAGE1_DIR)/boot.asm -o $(STAGE1)

stage2: $(STAGE2)
$(STAGE2): always
	$(AS) -f bin $(STAGE2_DIR)/main.asm -o $(STAGE2)

always:
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)