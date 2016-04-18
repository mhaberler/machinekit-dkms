#!/bin/bash -e

# for running in docker
# docker run -i -v $(pwd):/work mhaberler/mk-builder:jessie-64-kbuild /work/scripts/build_debs.sh

cd /work
sh scripts/rebuild.sh
