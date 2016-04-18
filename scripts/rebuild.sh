#!/bin/bash -e

# this should become a Makefile

DKMSDIR=/var/lib/dkms
DESTDIR=debs
DRIVERDIRS=$(ls -d1 drivers/*)
for driver in ${DRIVERDIRS}
do
	. ${driver}/dkms.conf
	dkms add ${driver}
	dkms mkdeb -m ${PACKAGE_NAME}/${PACKAGE_VERSION} --source-only
	cp ${DKMSDIR}/${PACKAGE_NAME}/${PACKAGE_VERSION}/deb/*.deb ${DESTDIR}
	dkms remove -m ${PACKAGE_NAME}/${PACKAGE_VERSION}  --all
done


