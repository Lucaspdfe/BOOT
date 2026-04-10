# How to build

First, this tutorial assumes you are running Debian/Ubuntu Linux, if you are on Windows, I recommend you use WSL and if you are on MacOS, you can try using Homebrew packages and running it, but it is not confirmed to work.

To build, you'll need the following utilities:

* `make`
* `nasm`
* `mtools`
* `install-mbr`

On Ubuntu/Debian:
```bash
sudo apt install make nasm mtools mbr
```

---

## Toolchain (i686-elf)

This project requires a **cross-compiler toolchain** targeting `i686-elf`.

### Requirements for building the toolchain

Install the required dependencies:

```bash
sudo apt install build-essential wget bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo xz-utils
```

---

### Build the toolchain

Run on root (use sudo or doas):

```bash
make -f toolchain.mk toolchain
```

This will:

* Download and build:

  * Binutils 2.46
  * GCC 15.2.0
* Install everything into:

```
/opt/i686-elf-toolchain/
```

> [!NOTE]
> This might take a while depending on your machine.

---

### Add to PATH

You must add the toolchain to your `PATH`.

#### Temporary (current shell):

```bash
export PATH="/opt/i686-elf-toolchain/bin:$PATH"
```

#### Permanent:

Add this line to your shell config file:

* `~/.bashrc` (bash)
* `~/.zshrc` (zsh)

```bash
export PATH="/opt/i686-elf-toolchain/bin:$PATH"
```

Then reload:

```bash
source ~/.bashrc
```

---

### Verify installation

```bash
i686-elf-gcc -v
```

You should see:

```
Target: i686-elf
```

---

## Building the project

Once everything is set up, simply run:

```bash
make
```

This will generate:

```
build/boot.img
```

This file is the complete bootloader image.

---

## Cleaning

To clean build artifacts:

```bash
make clean
```

To clean the toolchain build files:

```bash
make -f toolchain.mk clean-toolchain
```

To remove everything (including downloads):

```bash
make -f toolchain.mk clean-toolchain-all
```

---
