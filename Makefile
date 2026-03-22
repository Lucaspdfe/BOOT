MTOOLARGS=-i $@@@1048576

all: clean build/boot.img

build/boot.img: build/stage1.bin build/stage2.bin always
	dd if=/dev/zero of=$@ bs=1M count=512
	printf "label: dos\nlabel-id: 0x12345678\nunit: sectors\n\nstart=2048, type=c, bootable\n" | sfdisk $@
	install-mbr $@
	mformat $(MTOOLARGS) -F -H2048 -v "BOOT" ::
	dd if=build/stage1.bin of=$@ bs=1 count=3 seek=1048576 conv=notrunc
	dd if=build/stage1.bin of=$@ bs=1 skip=90 seek=$$((1048576+90)) conv=notrunc
	mcopy $(MTOOLARGS) ./test.txt ::
	mcopy $(MTOOLARGS) ./build/stage2.bin ::

build/stage1.bin: src/stage1/boot.asm always
	nasm -f bin -o $@ $<

build/stage2.bin: always
	@$(MAKE) -C src/stage2 BUILD_DIR=$(abspath build/) --no-print-directory

clean:
	rm -rf build/*

always:
	mkdir -p build
