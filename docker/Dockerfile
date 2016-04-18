FROM machinekit/mk-builder:jessie-64
MAINTAINER Michael Haberler <haberlerm@gmail.com>

# temporarily patch up the mk-builder image for kbuild, dtb/dts and dkms use

RUN apt-get update -y && \
    apt-get install -y \
	    debhelper \
	    dkms \
	    fakeroot \
	    kernel-package \
	    libncurses5-dev \
	    kbuild \
	    device-tree-compiler
