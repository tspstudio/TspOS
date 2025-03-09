# TspOS

### Building

Install Open Watcom v2 compiler with 16-bit support, make sure /usr/bin/watcom/binl64/wcc exists and works properly.
Install mtools, qemu, nasm, dosfstools

```
make image # build floppy image
```

```
qemu-system-i386 -fda build/floppy.img # run image with qemu
```