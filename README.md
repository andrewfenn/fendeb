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

I use pbuilder a lot to build and test debian packages a lot and I often find
it difficult to manage especially if you're building the same package on
different releases such as the case is with distributions like Ubuntu.

I made fendeb as an easy way to use pbuilder without having to type in any of
the pbuilder commands or have to remember my exact environment variables.

Installing
----------

To install simply download the source code and type the standard make command

    $ sudo make install

This will install fendeb and it's man page

Usage
-----

For making a new environment

    $ fendeb create

For updating an environment

    $ fendeb update

For building a package with an environment

    $ fendeb make somepackage.dsc

Changing Environments
------------

Your current environment is set in `~/.fendeb/current-build`. You can set any
environment which you have already created that is listed in
`~/.fendeb/available-builds`.

To switch to a different environment you either type

    $ fendeb build

and then select from the interactive prompt, or you can type

    $ fendeb build debian/stable/amd64

which will switch your environment to the Debian Stable AMD64 environment,
assuming you have already created that environment.
