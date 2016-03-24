# machinekit-dkms
DKMS modules for machinekit

machinekit uses the occasional kernel driver, but including those in a package build is painful.
The best solution I could come up with is making those drivers [DKMS](https://en.wikipedia.org/wiki/Dynamic_Kernel_Module_Support) debian packages.
The resulting debs contain the source of the
drivers and instructions on how to build on the target platform for every kernel installed. A kernel upgrade
will cause an automatic rebuild of DKMS-packaged drivers for the new kernel. This requires the installation
supports out-of-tree builds (kernel headers installed, module build working - see note at bottom).

## Initial build of the debian packages:

````bash
git clone git://github.com/mhaberler/machinekit-dkms.git
cd machinekit-dkms/
# tell dkms about the new modules:
dkms add hm2reg_uio/0.0.1
dkms add hm2adc_uio/0.0.1

# install them (builds modules, and debs):
dkms install hm2reg_uio/0.0.1
dkms install hm2adc_uio/0.0.1

# at this point, the modules are built for the installed kernels
# and can be modprobed:
root@mksocfpga:~# modprobe hm2reg_uio
root@mksocfpga:~# modprobe hm2adc_uio
root@mksocfpga:~# lsmod
Module                  Size  Used by
hm2reg_uio              3029  0
hm2adc_uio              3029  0
hello                    853  0
gpio_altera             4005  0
autofs4                21861  1

# build the debian packages:
dkms mkdeb -m hm2adc_uio -v 0.0.1
dkms mkdeb -m hm2reg_uio -v 0.0.1

# this will leave debs like so:

root@mksocfpga:~/machinekit-dkms# find /var/lib/dkms/|grep '\.deb$'
/var/lib/dkms/hm2adc_uio/0.0.1/deb/hm2adc-uio-dkms_0.0.1_all.deb
/var/lib/dkms/hm2reg_uio/0.0.1/deb/hm2reg-uio-dkms_0.0.1_all.deb

# upload those to the apt repo.

# to verify everyhing worked fine, remove the drivers
# NB this removes the above debs, so save them elsewhere before
dkms remove hm2adc_uio/0.0.1 --all
dkms remove hm2reg_uio/0.0.1 --all

# At this point all traces of our manual install are gone,
# so the modules cannot be loaded anymore:

root@mksocfpga:~/machinekit-dkms# modprobe hm2adc_uio
modprobe: FATAL: Module hm2adc_uio not found.

# to verify everyhing's fine, we install the debs:
dpkg -i  hm2adc-uio-dkms_0.0.1_all.deb  hm2reg-uio-dkms_0.0.1_all.deb
...

# and the drivers are back:

root@mksocfpga:~# modprobe hm2reg_uio
root@mksocfpga:~# modprobe hm2adc_uio
root@mksocfpga:~# lsmod
Module                  Size  Used by
hm2reg_uio              3029  0
hm2adc_uio              3029  0
hello                    853  0
gpio_altera             4005  0
autofs4                21861  1

`````

I have added these debs to the jessie stream on deb.machinekit.io
so you should be able to install those like so:

````bash
root@mksocfpga:~/machinekit-dkms# apt-cache search hm2
...
hm2adc-uio-dkms - hm2adc-uio driver in DKMS format.
hm2reg-uio-dkms - hm2reg-uio driver in DKMS format.

apt-get update
apt-get install hm2adc-uio-dkms hm2reg-uio-dkms 
`````

# Note on cross-built kernels

Out-of-tree module buils require the matching `linux-headers` package to be installed into
`/usr/src/linux-headers-<kernel version>`. This tree contains not only headers but several binaries
which are required for module building.

If the kernel was cross-built typically these binaries are compiled for the build host architecture (say amd64), and
distributed to a target of say arm architecture. This causes module builds to fail with weird error messages, see [this post] (http://lists.openembedded.org/pipermail/openembedded-core/2012-June/063380.html) for a description.

You can diagnose the issue by looking at the architecture of some binaries under `/usr/src/linux-headers-<kernel version>` like so:

````bash
# we're on an arm host
root@raspberrypi:/usr/src# arch
armv7l

# inspect important binaries
cd `/usr/src/linux-headers-<kernel version>`/scripts

# these look good - note ARM architecture:
root@raspberrypi:/usr/src/linux-headers-4.1.18-rt17-v7+/scripts# file basic/bin2c basic/fixdep kallsyms recordmcount
basic/bin2c:  ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32, BuildID[sha1]=d3832724ec76f419b6ef4eaaa1be41f66de480b1, not stripped
basic/fixdep: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32, BuildID[sha1]=53c156943bdb20f3802bb91643b5d8668a490636, not stripped
kallsyms:     ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=517fea36cfe40942c2cff44433a2d3caef711657, not stripped
recordmcount: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32, BuildID[sha1]=a86949572904fc070ce9291a1ffb1f850c017aba, not stripped

# something like this hints the binaries are for the wrong architecture (note x86-64):
# file basic/fixdep kallsyms recordmcount
basic/fixdep: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=1d3b83c509da6d6365d4990becfaa421b96fe56a, stripped
kallsyms:     ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=161872353bf7ec325a716b54499ce5b93e8abe6b, stripped
recordmcount: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=e2fbf2e1360e0a06eb46a51f7cd2f70ebe403fe1, stripped
`````

The issue can be fixed as follows (ugly but works):
````bash
cd `/usr/src/linux-headers-<kernel version`
# this should rebuild the binaries for the target architecture:
make scripts
````

If this fix fails with an error message like [here](https://github.com/igorpecovnik/lib/issues/74#issue-94508186), 
so something like:

`````
  HOSTCC  scripts/sortextable
scripts/sortextable.c:31:32: fatal error: tools/be_byteshift.h: No such file or directory
 #include <tools/be_byteshift.h>
                                ^
compilation terminated.
scripts/Makefile.host:91: recipe for target 'scripts/sortextable' failed
make[1]: *** [scripts/sortextable] Error 1
Makefile:555: recipe for target 'scripts' failed
make: *** [scripts] Error 2
`````

a patch over the kernel headers is needed:

````bash
wget https://raw.githubusercontent.com/igorpecovnik/lib/next/patch/headers-debian-byteshift.patch
patch -p1 < headers-debian-byteshift.patch
make scripts
````

After this building out-of-tree modules should work even with cross-built kernels.

I realize this fix is super-ugly - happy to take recommendations.







