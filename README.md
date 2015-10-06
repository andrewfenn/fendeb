README of fendeb
=================

* &copy; Andrew Fenn, andrewfenn@gmail.com, 2015
* This application is licenced under [GNU General Public License, Version 3.0]

Summary
-------

Fendeb is a collection of helper scripts used to quickly get you using pbuilder
and building debian packages from source.


About
-----

I use pbuilder a lot to build and test debian packages and I often find
it difficult to manage especially if you're building the same package on
different releases such as the case is with distributions like Ubuntu.

I made fendeb as an easy way to use pbuilder without having to type in any of
the pbuilder commands or have to remember my exact environment variable options.

Installing
----------

If you're using ubuntu make sure you have the ```ubuntu-dev-tools packaging-dev``` package installed.

To install simply download the source code and type the standard make command

    $ sudo make install

This will install fendeb and it's man page

Usage
-----

For making a new environment

    $ fendeb create

Or you can specify exactly what you want and skip the menu prompts

    $ fendeb create -d debian -m http://ftp.th.debian.org/debian/ -r stable -a amd64

For updating an environment

    $ fendeb update

For building a package with an environment

    $ fendeb build somepackage.dsc

To login to an environment's command line as root

    $ fendeb login

Changing Environments
------------

Your current environment is set in `~/.fendeb/current-env`. You can set any
environment which you have already created that is listed in
`~/.fendeb/available-envs`.

To switch to a different environment

    $ fendeb env debian/stable/amd64

To see which environment you're currently on

    $ fendeb env

To list all the environments you currently have installed

    $ fendeb env list
