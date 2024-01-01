# Компиляторы
ASM := nasm
ASM_FLAGS := -f elf32
LD := ld
LD_FLAGS := -m elf_i386

# Директории
SRC_DIR := src
BIN_DIR := bin

# Исходные коды
ASM_SOURCES := $(wildcard $(SRC_DIR)/*.asm)
TARGET := $(BIN_DIR)/rpncalc
OTARGET := $(BIN_DIR)/rpncalc.o
TARGETS := $(patsubst $(SRC_DIR)/%.c,%,$(CSOURCES))

SUDO		  	= sudo
DEL_FILE      	= rm -f
CHK_DIR_EXISTS	= test -d
MKDIR         	= mkdir -p
COPY          	= cp -f
COPY_FILE     	= cp -f
COPY_DIR      	= cp -f -R
INSTALL_FILE   	= install -m 644 -p
INSTALL_PROGRAM = install -m 755 -p
INSTALL_DIR   	= cp -f -R
DEL_FILE      	= rm -f
SYMLINK       	= ln -f -s
DEL_DIR       	= rmdir
MOVE          	= mv -f
TAR           	= tar -cf
COMPRESS      	= gzip -9f
LIBS_DIRS     	= -I./include/
LIBS 		  	= -ltins $(LIBS_DIRS)
SED           	= sed
STRIP         	= strip

all: build install clean

build:
	$(ASM) $(ASM_FLAGS) $(ASM_SOURCES) -o $(OTARGET)
	$(LD) $(LD_FLAGS) $(OTARGET) -o $(TARGET)

install:
	$(SUDO) $(INSTALL_PROGRAM) $(TARGET) /usr/local/bin/;

clean:
	$(DEL_FILE) $(BIN_DIR)/*

.PHONY: build install clean
