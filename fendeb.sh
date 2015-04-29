#!/bin/bash

set -e

PROG=`basename $0`
VERSION=0.1.0

# Screen Colours used for text
RED="\e[01;31m"
GREEN="\e[01;32m"
NO_COLOUR="\033[0m"
CLEAR_LINE="\033[2K"
CLEAR_LINE_ABOVE="\033[A\033[2K"


# Need to run through these before doing anything to make sure
# everything is setup correctly to run
required_checks()
{
    user=$(whoami)
    if [ ! $AUTOMATED ] && [ "$user" == "root" ]; then
        echo -en $RED"Error$NO_COLOUR: Must not run as root\n"
        error=yes
    fi

    if [ -z "$DEBFULLNAME" ]; then
        echo -en $RED"Error$NO_COLOUR: 'DEBFULLNAME' isn't set you must add the following to '$HOME/.bashrc'\n"
        echo -en "\texport DEBFULLNAME=\"Your Name\"\n"
        error=yes
    fi

    if [ -z "$DEBEMAIL" ]; then
        echo -en $RED"Error$NO_COLOUR: 'DEBEMAIL' isn't set you must add the following to '$HOME/.bashrc'\n"
        echo -en "\texport DEBEMAIL=\"youremail@domain.com\"\n"
        error=yes
    fi

    if [ $error ]; then
        exit 1
    fi

    PBUILDER_BIN=`get_full_path "pbuilder"`
    if [ -z "$PBUILDER_BIN" ]; then
        echo -en $RED"Error$NO_COLOUR: pbuilder missing. Did you want to install it now?\n"
        if [ $AUTOMATED ] || [ `confirm` ]; then
            opts="--quiet"
            if [ $VERBOSE ]; then
                opts=
            fi
            sudo apt-get $opts install whiptail debian-keyring devscripts build-essential fakeroot debhelper gnupg pbuilder patch cdbs quilt lintian
        else
            exit 2
        fi
    fi
}

choose_distro()
{
    if [ ! $AUTOMATED ] && [ -z $DISTRO ]; then

        dist=$(whiptail --title "Distribution" --menu \
            "Select which distribution you want to use for packaging" 10 40 2 \
            "debian" "" \
            "ubuntu" "" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi
            # cancelled
            exit
        fi
        DISTRO=$dist
    fi

    if [ -z $DISTRO ]; then
        echo -en $RED"Error$NO_COLOUR: Distribution is not set. Use the -d option to set one.\n"
        exit 2
    fi
}

choose_mirror()
{
    if [ ! $AUTOMATED ] && [ -z $MIRROR ]; then

        case $DISTRO in
        debian)
            mirrorsite="http://ftp.th.debian.org/debian/"
        ;;
        ubuntu)
            mirrorsite="http://archive.ubuntu.com/ubuntu/dists/"
            mirrorslist="http://mirrors.ubuntu.com/mirrors.txt"
        ;;
        *)
            echo -en $RED"Error$NO_COLOUR: Distribution not found\n"
            exit 3
        ;;
        esac

        path=`get_fendeb_path`
        file="$path/mirror-urls-$DISTRO"

        if [ -f $file ]; then

            if [ $VERBOSE ]; then
                echo "Mirrors list cached: $file"
            fi

            one_day=86400
            seconds_mod=`expr $(date +%s) - $(date +%s -r $file)`

            if [ $one_day -lt $seconds_mod ]; then
                if [ $VERBOSE ]; then
                    echo "Removing old mirror cache file: $file"
                fi
                rm $file
            fi
        fi

        if [ ! -f $file ]; then
            if [ $VERBOSE ]; then
                echo "Downloading mirror urls from: $mirrorslist"
            fi

            wget -q -O $file "$mirrorslist"
            if [ $? != 0 ]; then
                echo -en $RED"Error$NO_COLOUR: Could not download mirror list\n"
                exit 4
            fi
        fi

        mirrors=`cat $file | awk '!/^ / && NF {print $1; print $1;}'`
        mirror=$(whiptail --title "Mirror" --menu --noitem \
            "Select which mirror you wish to download packages from" 15 60 5 $mirrors 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi
            # cancelled
            exit
        fi

        MIRROR=$mirror
    fi

    if [ -z $MIRROR ]; then
        echo -en $RED"Error$NO_COLOUR: Mirror is not set. Use the -m option to set one.\n"
        exit 2
    fi
}

choose_release()
{
    if [ ! $AUTOMATED ] && [ -z $RELEASE ]; then

        path=`get_fendeb_path`
        file="$path/releases-$DISTRO"

        if [ -f $file ]; then
            if [ $VERBOSE ]; then
                echo "Release list cached: $file"
            fi
            one_day=86400
            seconds_mod=`expr $(date +%s) - $(date +%s -r $file)`

            if [ $one_day -lt $seconds_mod ]; then
                if [ $VERBOSE ]; then
                    echo "Removing old releases cache file: $file"
                fi
                rm $file
            fi
        fi

        if [ ! -f $file ]; then
            if [ $VERBOSE ]; then
                echo "Downloading release list from: $MIRROR"
            fi

            wget -q -O $file "$MIRROR/dists"
            if [ $? != 0 ]; then
                echo -en $RED"Error$NO_COLOUR: Could not download release list\n"
                exit 4
            fi

            # stips out all the HTML and gives us just the release names
            rawreleases=`cat $file | grep -i "href=[\"]*[^/.*]*/" | sed s/^.*href=\"// | cut -d\" -f1 | cut -d\- -f1 | cut -d/ -f1 | sort -ur`
            releases=""
            archs=""

            # iterate the list and look for the componets available
            for rel in $rawreleases; do

                rel_file="$path/test-release-page.tmp"
                wget -q -O $rel_file "$MIRROR/dists/$rel/Release"

                if [ $VERBOSE ]; then
                    echo "Verifying $rel link is a release"
                fi

                # get the components for each release
                if [ $? = 0 ]; then
                    components=`cat $rel_file | grep "Components" | sed s/^Components\://`
                    rawarchs=`cat $rel_file | grep "Architectures" | sed s/^Architectures\://`

                    if [ ! -z "$components" ]; then
                        releases+="$rel $components\n"
                        archs+="$rel $rawarchs\n"
                    fi
                fi

                rm -f $rel_file
            done

            `echo -en "$releases" > $file`
            `echo -en "$archs" > "$file-archs"`
        fi

        releases=`cat $file | awk '!/^ / && NF {print $1; print $1;}'`
        release=$(whiptail --title "Release" --menu --noitem \
            "Select which release you wish to download packages from" 15 30 5 $releases 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi
            # cancelled
            exit
        fi

        RELEASE=$release
    fi

    if [ -z $RELEASE ]; then
        echo -en $RED"Error$NO_COLOUR: Release is not set. Use the -r option to set one.\n"
        exit 2
    fi
}

choose_arch()
{
    if [ ! $AUTOMATED ] && [ -z $ARCH ]; then

        path=`get_fendeb_path`
        file="$path/releases-$DISTRO-archs"

        rawarchs=`cat $file | grep "$RELEASE" | awk '{$1 = ""; print $0; }' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
        archs=""
        for arch in $rawarchs; do
            archs+="$arch \"\" "
        done

        arch=$(whiptail --title "Arch" --menu --noitem \
            "Select which arch you wish to build with" 15 30 5 $archs 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi
            # cancelled
            exit
        fi

        ARCH=$arch
    fi

    if [ -z $ARCH ]; then
        echo -en $RED"Error$NO_COLOUR: Architecture is not set. Use the -a option to set one.\n"
        exit 2
    fi

    # get components for this arch
    file="$path/releases-$DISTRO"
    components=`cat $file | grep "$RELEASE" | awk '{$1 = ""; print $0; }' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
    COMPONENTS=$components
}

set_working_builder()
{
    path=`get_fendeb_path`
    current=$1

    if [ ! $AUTOMATED ] && [ -z $current ]; then

        file="$path/available-builds"
        rawbuilds=`cat $file`
        builds=""
        for build in $rawbuilds; do
            builds+="$build \"\" "
        done

        current=$(whiptail --title "Current working build" --menu --noitem \
            "Select a new current working build" 15 30 5 $builds 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi

            current=`get_working_builder`
            echo "On build $current"
            # cancelled
            exit 2
        fi
    fi

    if [ ! -z $current ]; then
        file="$path/current-build"
        echo "$current" > $file
    fi

    current=`get_working_builder`
    echo "On build $current"
}

get_working_builder()
{
    path=`get_fendeb_path`
    file="$path/current-build"

    if [ -f $file ]; then
        current=`cat $file`
        dir=$STORAGE_PATH/$current

        if [ -d $dir ]; then
            echo $current
        fi
    fi
}

configure_path()
{
    path=`get_fendeb_path`

    # get config for the storage path
    file="$path/storage-path"
    if [ -f $file ]; then
        STORAGE_PATH=`cat $file`
    fi
    if [ ! $AUTOMATED ] && [ -z $STORAGE_PATH ]; then
        STORAGE_PATH=$(whiptail --inputbox "Please select a directory for storing all the pbuilder files." 8 78 $HOME/fendeb --title "pbuilder storage" 3>&1 1>&2 2>&3)
        if [ $? != 0 ]; then
            if [ $VERBOSE ]; then
                echo "User cancelled"
            fi
            # cancelled
            exit
        fi

        `echo $STORAGE_PATH > $file`
    fi
    if [ -z $STORAGE_PATH ]; then
        echo -en $RED"Error$NO_COLOUR: Storage path not set. Use to -s option to set one.\n"
        exit 2
    fi
}

show_help()
{
    if [ -n "$HAS_GNU_ENHANCED_GETOPT" ]; then
       echo "$LONG_HELP"
    else
        echo "$SHORT_HELP"
    fi
}

# helper function used to bring up a handy confirm
# yes / no reader
confirm()
{
    ret=
    while [ "$ret" == "" ]; do
        read -r -p "${1:-[yes/no]} " response
        case $response in
            [yY][eE][sS]|[yY])
                echo "yes"
                exit 0
            ;;
            [nN][o]|[nN])
                exit 1
            ;;
            *)
                ret=
            ;;
        esac
        echo -en "$CLEAR_LINE_ABOVE"
    done
}

# helper function for full program path without
# disabling stop on all errors
# called like so: PBUILDER_BIN=`get_full_path "pbuilder"`
get_full_path()
{
    set +e
    command -v $1
    ret=$?
    set -e
}

get_fendeb_path()
{
    FENDEB_DIR="$HOME/.fendeb"
    if [ ! -d $FENDEB_DIR ]; then
        mkdir $FENDEB_DIR;

        if [ $? != 0 ]; then
            echo -en $RED"Error$NO_COLOUR: Can not create directory at $FENDEB_DIR"
        fi
    fi

    echo $FENDEB_DIR
}

show_version()
{
    echo -en "fendeb $VERSION
Copyright (C) 2015 Andrew Fenn
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Andrew Fenn, see <https://github.com/andrewfenn/fendeb>.\n"
}

SHORT_OPTS=m:d:r:a:pvhV
LONG_OPTS=mirror:,distribution:,release:,architecture:,automated,verbose,version,help

HELP="Usage: $PROG [options] arguments

By default fendeb will give you interactive prompts. The below commands are
only needed if you're trying to use fendeb in an automated way.

Options:"

SHORT_HELP="$HELP
  -m   which mirror you wish to use. e.g. http://archive.debian.org/debian/
  -d   which distro you wish to use. i.e. debian, ubuntu
  -r   which release you wish to use. e.g. stable, testing
  -a   which arch you wish to use. i.e. i386, amd64
  -p   for automated use, will not display interactive screens however, may error if required information not supplied
  -s   changes the storage path where pbuilder files are kept for building debs
  -v   show extra information
  -h   show this help message
  -V   show version information"

LONG_HELP="$HELP
  -m | --mirror         which mirror you wish to use. e.g. http://archive.debian.org/debian/
  -d | --distribution   which distro you wish to use. i.e. debian, ubuntu
  -r | --release        which release you wish to use. e.g. stable, testing
  -a | --architecture   which arch you wish to use. i.e. i386, amd64
  -p | --automated      for automated use, will not display interactive screens however may error if required information not supplied
  -s | --storage        changes the storage path where pbuilder files are kept for building debs
  -v | --verbose        show extra information
  -h | --help           show this help message
  -V | --version        show version information"

# Detect if GNU Enhanced getopt is available
HAS_GNU_ENHANCED_GETOPT=
if getopt -T >/dev/null; then :
else
  if [ $? -eq 4 ]; then
    HAS_GNU_ENHANCED_GETOPT=yes
  fi
fi

# Run getopt (runs getopt first in `if` so `trap ERR` does not interfere)

if [ -n "$HAS_GNU_ENHANCED_GETOPT" ]; then
  # Use GNU enhanced getopt
  if ! getopt --name "$PROG" --long $LONG_OPTS --options $SHORT_OPTS -- "$@" >/dev/null; then
    echo "$PROG: usage error (use -h or --help for help)" >&2
    exit 2
  fi
  ARGS=`getopt --name "$PROG" --long $LONG_OPTS --options $SHORT_OPTS -- "$@"`
else
  # Use original getopt (no long option names, no whitespace, no sorting)
  if ! getopt $SHORT_OPTS "$@" >/dev/null; then
    echo "$PROG: usage error (use -h for help)" >&2
    exit 2
  fi
  ARGS=`getopt $SHORT_OPTS "$@"`
fi
eval set -- $ARGS

## Process parsed options (customize this: 2 of 3)
while [ $# -gt 0 ]; do
    case "$1" in
        -d | --distro)
            DISTRO="$2"
        ;;
        -m | --mirror)
            MIRROR="$2"
        ;;
        -r | --release)
            RELEASE="$2"
        ;;
        -a | --arch)
            ARCH="$2"
        ;;
        -p | --automated)
            AUTOMATED=yes

            # disable colours for scripts
            RED=""
            GREEN=""
            NO_COLOUR=""
        ;;
        -s | --storage)
            STORAGE_PATH="$2"
        ;;
        -v | --verbose)
            VERBOSE=yes
        ;;
        -h | --help)
            show_help
            exit 0
        ;;
        -V | --version)
            show_version
            exit 0
        ;;
        --) shift; break;; # end of options
    esac
    shift
done

## Process remaining arguments and use options (customize this: 3 of 3)
action=
if [ $# -gt 0 ]; then
    for ARG in "$@"; do
        case "$ARG" in
            help)
                action="help"
            ;;
            build)
                if [ -z $action ]; then
                    action="build"
                fi
            ;;
            create)
                if [ -z $action ]; then
                    action="create"
                fi
            ;;
            update)
                if [ -z $action ]; then
                    action="update"
                fi
            ;;
            make)
                if [ -z $action ]; then
                    action="make"
                fi
            ;;
            *)
                action="error"
            ;;
        esac
    done
fi

case "$action" in
    build)
        source fendeb-build.sh
    ;;
    create)
        source fendeb-create.sh
    ;;
    update)
        source fendeb-update.sh
    ;;
    make)
        source fendeb-make.sh
    ;;
    help)
        show_help
        exit 0
    ;;
    *)
        echo -en "$PROG: '$1' is not a command. See '$PROG --help'.\n\n"
        show_help
        exit 1
    ;;
esac
