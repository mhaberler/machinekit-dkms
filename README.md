# machinekit-dkms
DKMS modules for machinekit

machinekit uses the occasional kernel driver, but including those in a package build is painful.
The best solution I could come up with is making those drivers [DKMS](https://en.wikipedia.org/wiki/Dynamic_Kernel_Module_Support) debian packages.
The resulting debs contain the source of the
drivers and instructions on how to build on the target platform for every kernel installed. A kernel upgrade
will cause an automatic rebuild of DKMS-packaged drivers for the new kernel. This requires the installation
supports out-of-tree builds (kernel headers installed, module build working).

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


