#!/bin/bash -e

DKMSDIR=/var/lib/dkms
for p in adcreg hm2reg_uio
do
	. $p/dkms.conf
	dkms add $p
	dkms mkdeb -m ${PACKAGE_NAME}/${PACKAGE_VERSION} --source-only
	cp ${DKMSDIR}/${PACKAGE_NAME}/${PACKAGE_VERSION}/deb/*.deb .
	dkms remove -m ${PACKAGE_NAME}/${PACKAGE_VERSION}  --all
done


