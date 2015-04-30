% FENDEB(1) fendeb User Manual
% Andrew Fenn <andrewfenn@gmail.com>
% 2015-04-30

# NAME

fendeb - Conveniance scripts for using pbuilder

# SYNOPSIS

fendeb [actions] [options]

# DESCRIPTION

This manual page documents briefly the fendeb scripts suite.

Fendeb is a collection of helper scripts designed to allow you to quickly and easily prompt you through the management of multiple pbuilder environments that you can use to build debian files.

It abstracts away gathering details required to configure an environment by giving you easy on screen prompts to selecting which distribution, release and architecture you wish to use for building.

Finally it also tracks state such as what was the last environment you were using for building so that you don't have to continuously specify which environment you want to use when building debian files.

# ACTIONS

`create`
:   Creates a new pbuilder environment

`update`
:   Updates and upgrades an environment to include the latest packages from a release

`build`
:   Switches build environments so that you can use a different pbuilder environment on your system

`make`
:   Builds a new debian file using a .dsc file

`help`
:   Prints a usage help.

# OPTIONS

  -m | --mirror         which mirror you wish to use. e.g. http://archive.debian.org/debian/
  -d | --distribution   which distro you wish to use. i.e. debian, ubuntu
  -r | --release        which release you wish to use. e.g. stable, testing
  -a | --architecture   which arch you wish to use. i.e. i386, amd64
  -p | --automated      for automated use, will not display interactive screens however may error if required information not supplied
  -s | --storage        changes the storage path where pbuilder files are kept for building debs
  -v | --verbose        show extra information
  -h | --help           show this help message
  -V | --version        show version information"


`-m [mirror url]`, `--user [mirror url]`
:   Which mirror you wish to use. If no argument is given, you will be prompted for a release to choose.

`-d [distribution]`, `--distribution [distribution]`
:   Which distribution you wish to use. i.e. debian, ubuntu. If no argument is given, you will be prompted to choose.

`-r [release]`, `--release [release]`
:   Which release of a distribution you wish to use. e.g. stable in debian. vivid in Ubuntu. If no argument is given, you will be prompted to choose.

`-a`, `--architecture`
:   Which arch you wish to use. e.g. i386, amd64

`-p`, `--automated`
:   For script use. Will not display interactive screens, however may error if required information above not supplied.

`-s [directory]`, `--storage [directory]`
:   Sets the storage path where pbuilder files will be saved to. This setting will be saved in '~/.fendeb/storage-path' when first prompted unless overrided with this option in which case that option will be saved overwriting the previously set option.

`-v`, `--verbose`
:   Be verbose.

`-h`, `--help`
:   Prints some usage information.

`-V`, `--version`
:   Prints version.

# CONFIGURATION

To begin using fendeb first you must configure your debian settings. Please make sure the following settings are set before beginning in your '~/.bashrc' or related file.

    export DEBFULLNAME="Your name"
    export DEBEMAIL="your@email.com"

These variables are used by pbuilder when building your debian files and need to be set. If you don't set them then fendeb will error out and ask you to set them until you do.

# CREATING AN ENVIRONMENT

You can create a new build environment like so

    $ fendeb create

or for scripts

    $ fendeb create -a -m http://ftp.us.debian.org/debian -d debian -r stable -a amd64 -s ~/fendeb

When you create a new environment it automatically becomes your current working environment. This means when you use other commands such as update or make you don't need to specify which environment.

# SWITCHING ENVIRONMENTS

If you have more than one build environment you can switch which one is set to the current working environment like so

    $ fendeb build

or

    $ fendeb build debian/stable/amd64

# UPDATING AN ENVIRONMENT

Sometimes you might when to upgrade your environment with the latest packages. You can do this like so

    $ fendeb update

# BUILDING A DEB FILE WITH THE ENVIRONMENT

To build an environment you must first go into the project and run debuild. This will generate a .dsc file which you then feed through to fenbuild.

    $ fendeb make [target debian dsc file]

This will start pbuilder and generate a log file for you into your environment folder for reference.

# EXIT CODES

There are a bunch of different error codes and their corresponding error messages that may appear during bad conditions. At the time of this writing, the exit codes are:

`1`
:   Unknown error

`2`
:   Configuration error or pbuilder missing

`3`
:   Missing arguments

`4`
:   Build environment missing or no environment(s) found

# KNOWN ISSUES & BUGS

The upstream BTS can be found at <https://github.com/andrewfenn/fendeb/issues>.
