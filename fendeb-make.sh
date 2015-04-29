#!/bin/bash

set -e

if [ -z "$PROG" ]; then
    source fendeb.sh make $@
    exit 0
fi

required_checks
configure_path
current=`get_working_builder`
if [ -z $current ]; then
    echo "No build selected or can be found. Select one with: fendeb build"
    exit 1
fi

IFS='/'
arr=($current)

DISTRO=${arr[0]}
RELEASE=${arr[1]}
ARCH=${arr[2]}

if [ $VERBOSE ]; then
    echo "Making build with environment:"
    echo "pbuilder binary: $PBUILDER_BIN"
    echo "Distribution: $DISTRO"
    echo "From Release: $RELEASE"
    echo "From Architecture: $ARCH"
    echo "Storage Path: $STORAGE_PATH"
fi

path="$STORAGE_PATH/$DISTRO/$RELEASE/$ARCH"
if [ $VERBOSE ]; then
    echo "Building with pbuilder at: $path"
fi

exit

if [ -z $3 ]; then
   echo "Must include dsc file"
   exit 1
fi

set -u

sudo pbuilder --build --basetgz $path/base.tar.gz \
			--architecture $ARCH \
			--buildplace $path/build \
			--distribution $DISTRO \
			--aptcache $path/cache \
			--buildresult $path/result \
			--override-config \
			--configfile $path/pbuilderrc \
			--extrapackages apt-utils $3 2>&1 | tee $path/logs/$3.log
