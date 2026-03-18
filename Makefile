MTOOLARGS=-i $@@@1048576

build/boot.img: build/stage1.bin
	dd if=/dev/zero of=$@ bs=1M count=512
	printf "label: dos\nlabel-id: 0x12345678\nunit: sectors\n\nstart=2048, type=c, bootable\n" | sfdisk $@
	install-mbr $@
	mformat $(MTOOLARGS) -F -H2048 -v "BOOT" ::
	dd if=$< of=$@ bs=1 count=3 seek=1048576 conv=notrunc
	dd if=$< of=$@ bs=1 skip=90 seek=$$((1048576+90)) conv=notrunc
	mcopy $(MTOOLARGS) ./test.txt ::

build/stage1.bin: src/stage1/boot.asm
	nasm -f bin -o $@ $<
