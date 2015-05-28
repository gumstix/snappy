Ubuntu Snappy Core for Gumstix
==============================
This repository provides tools to build Snappy Core images for Gumstix systems
as well as Beagleboard and PandaBoard.

Snappy Core is under ongoing development and, as such, these images are meant
only to provide a basis for experimentation and a starting point for Snappy +
Gumstix. See [Kudos and Caveats](#kudos-and-caveats).

Prebuilt Images
---------------
Prebuilt images are available for [Overo][overo-img], [DuoVero][duovero-img],
[Pepper][pepper-img], [Beagle][beagle-img], and [Panda][panda-img]. These
images can be directly copied to a 4GB or greater microSD card.  Warning: this
erases anything currently on the microSD card!  Note that any mounted
partititions of the SD card should be unmounted before writing the image. These
steps each take several minutes; your computer isn't hanging, the files are
just large.

    # substitute one of 'overo', 'duovero', 'pepper', 'beagle' or 'panda' in
    # place of <machine>
    $ wget http://gumstix-snappy.s3.amazonaws.com/<machine>.img.xz
    $ xz -d <machine>.img.xz

    # substitute the path to the drive e.g. /dev/sdd or /dev/mmcblk0 (not the
    # path of a partition e.g. /dev/sdd1 or /dev/mmcblk0p1) in place of <drive>
    # use 'udevadm monitor' when you insert the card to determine the path
    $ sudo dd if=<machine>.img bs=4k of=<drive>
    $ sync

After the process completes, plug the microSD card into your Gumstix (or TI)
system, boot, login as *ubuntu* with password *ubuntu* and start playing with
your shiny new Ubuntu Snappy Core!

By way of example, try installing the *xkcd-webserver* package so you can
enjoy random XKCD comics delivered to your browser by your Snappy system:

    # on your snappy system
    $ sudo snappy install xkcd-webserver

On your development machine (on the same network as your snappy device),
navigate to http://*machine-name*.local

An autobuilder generates weekly images for [Overo][overo-auto],
[DuoVero][duovero-auto], [Pepper][pepper-auto], [Beagle][beagle-auto], and
[Panda][panda-auto] from the latest code. This is a good place to look to try
out the latest features or access a particular older version.

[overo-img]: http://gumstix-snappy.s3.amazonaws.com/overo.img.xz
[duovero-img]: http://gumstix-snappy.s3.amazonaws.com/duovero.img.xz
[pepper-img]: http://gumstix-snappy.s3.amazonaws.com/pepper.img.xz
[beagle-img]: http://gumstix-snappy.s3.amazonaws.com/beagle.img.xz
[panda-img]: http://gumstix-snappy.s3.amazonaws.com/panda.img.xz
[overo-auto]: https://catalina.gumstix.com/binaries/?sort=-last_updated&search=snappy-overo-master
[duovero-auto]: https://catalina.gumstix.com/binaries/?sort=-last_updated&search=snappy-duovero-master
[pepper-auto]: https://catalina.gumstix.com/binaries/?sort=-last_updated&search=snappy-pepper-master
[beagle-auto]: https://catalina.gumstix.com/binaries/?sort=-last_updated&search=snappy-beagle-master
[panda-auto]: https://catalina.gumstix.com/binaries/?sort=-last_updated&search=snappy-panda-master

Assemble Your Own Image
-----------------------
**1. Grab some required software.**

    $ sudo apt-get install -y git build-essential make gcc-arm-linux-gnueabihf \
                              ubuntu-device-flash snappy-tools

**2. (optional) Download an OEM Snappy package.**

This package includes any components such as a bootloader that are specific to
a particular device (i.e. [Overo][overo-snap], [DuoVero][duovero-snap], [Pepper]
[pepper-snap], [Beagle][beagle-snap], and [Panda][panda-snap]).

    $ wget http://gumstix-snappy.s3.amazonaws.com/<machine>.snap

As well as device-specific components, a system vendor could distribute a logo
or pre-install other useful packages into any generated images. To make your own
OEM package, see [below](#building-from-scratch).

------------------------------------------------------------------------------
**Note:**

As these OEM snaps are now available through the Snappy App Store, this step
is optional.  Just replace *machine-name*.snap with *machine-name*.gumstix in
the *--oem* argument below and the OEM snap will be automatically fetched from
the store.

------------------------------------------------------------------------------

**3. Assembly a flashable image.**

To support Snappy's rollback system, it has two OS partitions, *system-a* and
*system-b*, both sized to be ~1GB as well as boot (*system-boot*) and user
(*writable*) partitions; keep it roomy by creating a 4GB image.  We'll use the
*15.04* release and enable ssh as well *developer-mode* so we can install
unsigned packages.

    $ sudo ubuntu-device-flash core 15.04 -o <machine>.img --size 4 \
                                    --oem <machine>.snap --developer-mode

Format a microSD as described [above](#prebuilt-images) with the newly
created *img* file.  Once the card is created, take a look at the partition
structure---there should be four as described above.

**Technical Aside**

There is unpartitioned space at the beginning of the card in which, on some
installations, booloader components such as *MLO* and *u-boot.img* are written,
rather than storing them on the system-boot partition.  OMAP4 (DuoVero/Panda)
 and AM335x (Pepper) use this but, as OMAP3 (Overo/Beagle) u-boot would require
a *raw* boot mode patch, we just place *MLO* and *u-boot.img* on the
*system-boot* partition instead.

------------------------------------------------------------------------------
**Note:**

These steps were developed & tested on an Ubuntu 15.04 system. If you get
errors about unknown arguments to *ubuntu-device-flash*, you probably have
an older version.  Grab the latest from the PPA:

    $ sudo add-apt-repository ppa:snappy-dev/beta
    $ sudo apt-get update
    $ sudo apt-get install ubuntu-device-flash snappy-tools

------------------------------------------------------------------------------

[overo-snap]: http://gumstix-snappy.s3.amazonaws.com/overo.snap
[duovero-snap]: http://gumstix-snappy.s3.amazonaws.com/duovero.snap
[pepper-snap]: http://gumstix-snappy.s3.amazonaws.com/pepper.snap
[beagle-snap]: http://gumstix-snappy.s3.amazonaws.com/beagle.snap
[panda-snap]: http://gumstix-snappy.s3.amazonaws.com/panda.snap

Building From Scratch
---------------------
The included *Makefile* should automate much of this process.  Use the *-j* flag
to specify the number of concurrent make processes.

    $ make MACHINE=<machine> -j4

After some git-fetching and compiling, [fresh binaries](#u-boot) built from
the newly checked out *u-boot* repository should be packaged up in a Snappy OEM
package, *machine-name*.snap.  The [package build system][1] for Snappy is pretty
simple.  Have a look at the *package.yaml* file in the machine's *meta*
directory and then try building.

    $ cd <machine>
    $ snappy build
    $ cp <machine>.snap ../
    $ cd ..

If you make changes to any source files, just call *make* again to rebuild. We
can also clean the build---we keep checked-out source around though.

    $ make MACHINE=<machine> clean

Individual components can be also be (re-)built and cleaned e.g.

    $ make MACHINE=overo uboot
    $ make MACHINE=overo clean-uboot
    $ make MACHINE=pepper oem
    $ make MACHINE=pepper clean-oem

[1]: http://developer.ubuntu.com/en/snappy/tutorials/build-snaps/

### U-Boot
We grab the *2015.04* version of the *u-boot* bootloader from the Gumstix
repository and store it in the *u-boot* directory.

    $ git clone git://github.com/gumstix/u-boot.git -b v2015.04 u-boot

We then configure it using the machine-specific *defconfig*:

Machine  | Machine defconfig
---------|-------------------
overo    | omap3_overo_defconfig
duovero  | duovero_defconfig
pepper   | pepper_defconfig
beagle   | omap3_beagle_defconfig
panda    | omap4_panda_defconfig

    $ cd u-boot
    $ make CROSS_COMPILE=arm-linux-gnueabihf- <machine_defconfig>

Build and install the resulting *MLO* and *u-boot.img* files.

    $ make CROSS_COMPILE=arm-linux-gnueabihf-
    $ cp MLO u-boot.img ../<machine>/

<!---
COMMENT OUT as this is experimental
The *Makefile* can also checkout and build a custom kernel and then pack the
kernel image along with any modules and dtbs into a device-specific tarball
that can be pulled into an image using the *-device-part* argument to 
the *ubuntu-device-flash* tool. The following sections summarize the what is
done to build each component.

### Linux
We download the *yocto-v3.17.y* branch of Gumstix's Linux repository to the
*linux* directory.

    $ git clone git://github.com/gumstix/linux.git -b yocto-v3.17.y linux

We then grab a machine-specific defconfig from this top-level directory and
use it to configure the kernel.

    $ cd linux
    $ cp ../<machine>_defconfig .config
    $ make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- oldconfig

Build the kernel as well as any DTBs and modules.

    $ make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
    $ make INSTALL_MOD_PATH=../device/system ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install
    $ make INSTALL_DTBS_PATH=../device/assets/dtbs ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs_install
    $ cp arch/arm/boot/zImage ../device/assets/vmlinuz

### Device Tarball
All we need to do now is *tar* the populated *device* directory:

    $ tar -C device-<machine> -cavf device.tar.xz -xform s:'./':: .

With the device tarball created, create an image file
[as described](#assemble-your-own-image) and dump it on to a microSD card!

To build for a different machine, make sure to clean-up first:

    $ make MACHINE=overo clean
    $ make MACHINE=pepper -j8
-->
Kudos and Caveats
-----------------
In making this repository, there [were][2] [many][3] [useful][4]
[references][5]. And of course, thanks to the good folks on the *snappy-devel*
[list][6] :).

A few known issues:

 * There is a long (~15 second) pause after 'Starting Kernel...' as the ramdisk
   gets loaded.  It is not frozen---just be patient.
 * Building the Snappy OEM package yields errors such as
   "(MANUAL REVIEW) type 'oem' not allowed".  This is expected for OEM packages.
   The package will still be generated.

Currently, this is a *yay-it-boots* kinda thing; there is no customization of
the filesystem, validation that all the hardware works, or any kernel config
adjustments.  If you find things that are broken or have suggestions,
leave a comment, raise an issue, or best of all, send a pull request!

[2]: https://github.com/dz0ny/snappy-cubox-i
[3]: https://developer.ubuntu.com/en/snappy/guides/porting/
[4]: https://code.launchpad.net/~ogra/+junk/snappy-device-builder
[5]: https://lists.ubuntu.com/archives/snappy-devel/2015-April/000578.html
[6]: https://lists.ubuntu.com/mailman/listinfo/snappy-devel
