#!/bin/bash

set -e

if [ -z "$PROG" ]; then
    source fendeb.sh create $@
    exit 0
fi

if [ $VERBOSE ]; then
    echo "Creating $DISTRO $ $ARCH"
    echo "pbuilder binary: $PBUILDER_BIN"
fi


required_checks
configure_path
choose_distro
choose_mirror
choose_release
choose_arch

if [ $VERBOSE ]; then
    echo "Creating new environment:"
    echo "pbuilder binary: $PBUILDER_BIN"
    echo "Distribution: $DISTRO"
    echo "From Release: $RELEASE"
    echo "With Components: $COMPONENTS"
    echo "From Mirror: $MIRROR"
    echo "From Architecture: $ARCH"
    echo "Storage Path: $STORAGE_PATH"
fi


path="$STORAGE_PATH/$DISTRO/$RELEASE/$ARCH"
if [ $VERBOSE ]; then
    echo "Creating directories for pbuilder at: $path"
fi

mkdir -p $path/
mkdir -p $path/hooks
mkdir -p $path/build
mkdir -p $path/logs
mkdir -p $path/cache
mkdir -p $path/result
touch $path/result/Packages

if [ $VERBOSE ]; then
    echo "Creating hook script to allow use of deb files that have been built already"
fi

echo "#!/bin/sh
(cd $path/result; apt-ftparchive packages . > Packages)
apt-get update" > $path/hooks/D10apt-ftparchive
chmod +x $path/hooks/D10apt-ftparchive

echo "OTHERMIRROR=\"deb file://$path/result ./\"
BINDMOUNTS=\"$path/result\"
HOOKDIR=\"$path/hooks\"
EXTRAPACKAGES=\"apt-utils\"
MIRRORSITE=\"$MIRROR\"
COMPONENTS=\"$COMPONENTS\"
" > $path/pbuilderrc


if [ $VERBOSE ]; then
    echo "Creating build, cache and result folders for pbuilder"
fi

if [ $VERBOSE ]; then
    echo "Initilising pbuilder to create new workspace"
fi

sudo "$PBUILDER_BIN" --create --basetgz "$path"/base.tar.gz \
            --architecture $ARCH \
            --mirror $MIRROR \
            --buildplace "$path"/build \
            --distribution $RELEASE \
            --aptcache "$path"/cache \
            --debootstrapopts --variant=buildd \
            --buildresult "$path"/result \
            --extrapackages apt-utils

if [ $? == 0 ]; then

    path=`get_fendeb_path`
    file="$path/available-builds"
    echo "$DISTRO/$RELEASE/$ARCH" >> $file

    echo -en $GREEN"Finished"$NO_COLOUR"\n"
    echo "Your files will be built in: $path"
    echo "Your deb files will be saved in: $path/result"
    echo "Downloaded deb files will be saved in: $path/cache"

    exit 0
fi

exit 1
