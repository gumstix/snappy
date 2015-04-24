#/usr/bin/make -f
ifeq ($(strip $(MACHINE)),)
    $(error MACHINE variable not set. Usage: make MACHINE=<overo|duovero|pepper|beagle|panda>)
endif

#================================= CONFIG ======================================
CROSS_COMPILE := arm-linux-gnueabihf-
ARCH := arm

UBOOT_SRC_DIR := $(PWD)/u-boot
UBOOT_BRANCH := v2015.04

UBOOT_CONFIG_overo := omap3_overo_defconfig
UBOOT_CONFIG_duovero := duovero_defconfig
UBOOT_CONFIG_pepper := pepper_defconfig
UBOOT_CONFIG_beagle := omap3_beagle_defconfig
UBOOT_CONFIG_panda := omap4_panda_defconfig

# don't pass down MACHINE
MAKEOVERRIDES =
# prevent built-in rules---we're not using them
.SUFFIXES:

.PHONY: all uboot clean-uboot oem clean-oem
all: $(MACHINE).snap
clean: clean-uboot clean-oem

#================================== OEM =======================================
oem: $(MACHINE).snap
$(MACHINE).snap: uboot
	@(cd $(MACHINE) && snappy build)
	@cp $(MACHINE)/$(MACHINE)*.snap $(MACHINE).snap

clean-oem:
	@rm -f $(MACHINE)/$(MACHINE)*.snap $(MACHINE).snap

#================================= UBOOT ======================================
UBOOT_CONFIG := $(UBOOT_CONFIG_$(MACHINE))
ifeq ($(strip $(UBOOT_CONFIG)),)
    $(error No known u-boot configuration for $(MACHINE))
endif

UBOOT_OUT_DIR := $(PWD)/${MACHINE}
uboot: $(UBOOT_OUT_DIR)/MLO $(UBOOT_OUT_DIR)/u-boot.img
$(UBOOT_OUT_DIR)/MLO $(UBOOT_OUT_DIR)/u-boot.img: u-boot-output.intermediate

# Check-out u-boot (naively assume that if the directory exists, u-boot is checked out)
$(UBOOT_SRC_DIR):
	@git clone git://github.com/gumstix/u-boot.git --depth 1 -b $(UBOOT_BRANCH) $(UBOOT_SRC_DIR)

# configure u-boot
$(UBOOT_SRC_DIR)/.config: | $(UBOOT_SRC_DIR)
	@$(MAKE) -C $(UBOOT_SRC_DIR) CROSS_COMPILE=$(CROSS_COMPILE) $(UBOOT_CONFIG)

# if any file in the u-boot directory changes, build
.INTERMEDIATE: u-boot-output.intermediate
u-boot-output.intermediate: $(UBOOT_SRC_DIR)/.config $(shell find $(UBOOT_SRC_DIR) -type f 2>/dev/null)
	@$(MAKE) -C $(UBOOT_SRC_DIR) CROSS_COMPILE=$(CROSS_COMPILE)
	@cp $(UBOOT_SRC_DIR)/MLO $(UBOOT_SRC_DIR)/u-boot.img $(UBOOT_OUT_DIR)

clean-uboot:
	@-$(MAKE) -C $(UBOOT_SRC_DIR) CROSS_COMPILE=$(CROSS_COMPILE) distclean
	@-rm -f $(UBOOT_OUT_DIR)/MLO $(UBOOT_OUT_DIR)/u-boot.img


# This is experimental work-in-progress---ignore it for now
##================================ initrd ======================================
## To support a custom kernel, we need to (re-)build the initrd. As it isn't
## clear how to build this from scratch, let's borrow the method from
## snappy-device-builder :).
#DEVICE_DIR := $(PWD)/device-$(MACHINE)
#magical_upstream_tarball := http://cdimage.ubuntu.com/ubuntu-core/daily-preinstalled/current/vivid-preinstalled-core-armhf.device.tar.gz
#
#$(DEVICE_DIR):
#	@mkdir -p $(DEVICE_DIR)
#
## We don't re-fetch this by default...
#$(DEVICE_DIR)/upstream.tar.gz: | $(DEVICE_DIR)
#	@wget $(magical_upstream_tarball) -O $@
#
## use 'hardware.yaml' as an indicator
#$(DEVICE_DIR)/hardware.yaml: $(DEVICE_DIR)/upstream.tar.gz
#	@tar xzf $<  -C $(DEVICE_DIR)
#
#$(DEVICE_DIR)/ramdisk: $(DEVICE_DIR)/hardware.yaml
#	mkdir -p $(DEVICE_DIR)/ramdisk
#	xz --format=lzma -cd $(DEVICE_DIR)/assets/initrd.img | (cd $(DEVICE_DIR)/ramdisk && cpio -i)
#
## our re-packed version
#$(DEVICE_DIR)/fresh-initrd: kernel
#	find $(DEVICE_DIR)/ramdisk | sort | cpio --quiet -o -H newc | lzma > $(DEVICE_DIR)/assets/initrd.img
#	touch $@
#
#device: $(MACHINE).tar.xz
#$(MACHINE).tar.xz: $(DEVICE_DIR)/fresh-initrd $(shell find $(DEVICE_DIR) -type f)
#	@tar -C $(DEVICE_DIR) -cavf $(MACHINE).tar.xz --exclude fresh-initrd --exclude ramdisk --exclude upstream.tar.gz --xform s:'./':: .
#
#clean-device:
#	@rm -rf $(MACHINE).tar.xz $(DEVICE_DIR)
#
##================================= LINUX ======================================
## Check-out Linux (naively assume that if the directory exists, linux is checked out)
#KERNEL_SRC_DIR := $(PWD)/linux
#KERNEL_BRANCH := yocto-v3.17.y

#$(KERNEL_SRC_DIR):
#	@git clone git://github.com/gumstix/linux.git --depth 1 -b $(KERNEL_BRANCH) $(KERNEL_SRC_DIR)
#
## copy linux defconfig and run configuration
#$(KERNEL_SRC_DIR)/.config: $(PWD)/$(MACHINE)_snappy_defconfig | $(KERNEL_SRC_DIR)
#	@cp $< $@
#	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) oldconfig
#
#INSTALLED_KERNEL := $(DEVICE_DIR)/assets/vmlinuz
#INSTALL_MOD_PATH := $(DEVICE_DIR)/ramdisk
#INSTALL_DTBS_PATH := $(DEVICE_DIR)/assets/dtbs
#
#define install-kernel-extras
#@$(MAKE) INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) INSTALL_MOD_STRIP=1 modules_install
#@$(MAKE) INSTALL_DTBS_PATH=$(INSTALL_DTBS_PATH) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) dtbs_install
#endef
#
## Consider all files in the KERNEL_SRC_DIR to be prerequsites for building
## the kernel.  If any source files change, update the build (remove zImage to
## ensure it is updated even if a rebuild doesn't particularly update it). Build
## and install the kernel image and dtbs to 'assets'.  Modules live in 'system'
#KERNEL_OUTPUT_FILE := $(KERNEL_SRC_DIR)/arch/arm/boot/zImage
#
#$(INSTALLED_KERNEL): $(KERNEL_SRC_DIR)/.config $(shell find $(KERNEL_SRC_DIR) -type f)
#	rm -f $(KERNEL_OUTPUT_FILE)
#	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
#	$(install-kernel-extras)
#	cp $(KERNEL_OUTPUT_FILE) $(INSTALLED_KERNEL)
#
#kernel: $(INSTALLED_KERNEL)
#
#clean-kernel:
#	@-rm -rf $(INSTALLED_KERNEL) $(INSTALL_MOD_PATH) $(INSTALL_DTBS_PATH)*
#	@-$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) mrproper
