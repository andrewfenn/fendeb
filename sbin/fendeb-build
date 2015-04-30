#!/bin/bash

set -e

if [ -z "$PROG" ]; then
    source fendeb.sh build $@
    exit 0
fi

if [ $VERBOSE ]; then
    echo "Creating $DISTRO $ $ARCH"
    echo "pbuilder binary: $PBUILDER_BIN"
fi

required_checks
configure_path
set_working_builder $REQ_ENV
