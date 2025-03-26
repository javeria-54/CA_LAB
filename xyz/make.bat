rmdir -r build
mkdir build
riscv64-unknown-elf-gcc -c -O0 -o build/main.o src/main.c -march=rv32i -mabi=ilp32
riscv64-unknown-elf-gcc -o build/main.elf build/main.o -T linker.ld -nostdlib -march=rv32i -mabi=ilp32
riscv64-unknown-elf-objcopy -O binary --only-section=.data* --only-section=.text* build/main.elf build/main.bin
python maketxt.py build/main.bin > build/main.txt
riscv64-unknown-elf-objdump -S -s build/main.elf > build/main.dump
