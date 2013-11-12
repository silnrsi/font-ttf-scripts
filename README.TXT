=head1 INTRODUCTION

This module contains various scripts using the Font::TTF module. 

Any suggestions, improvements, additions, subclasses, etc. would be gratefully
received and probably included in a future release. Please send them to me.

This module has been tested on Win32, Unix and Mac.

=head1 INSTALLATION

If you have received this package as part of an Activestate PPM style .zip file
then type

    ppm install Font-TTF.ppd

Otherwise.

To configure this module, cd to the directory that contains this README file
and type the following.

    perl Makefile.PL

Alternatively, if you plan to install Font::TTF somewhere other than
your system's perl library directory. You can type something like this:

    perl Makefile.PL PREFIX=/home/me/perl INSTALLDIRS=perl

You need the following dependencies installed:
Algorithm::Diff
IO::String
Text::PDF
XML::Parser
Unicode::String
Text::Unicode::Equivalents

(On Debian/Ubuntu the corresponding packages to install are:
libalgorithm-diff-perl
libio-string-perl
libtext-pdf-perl
libxml-parser-perl
libunicode-string-perl
libtext-unicode-equivalents-perl)

Then to build you run make.

    make

If you have write access to the perl library directories, you may then
install by typing:

    make install

(sudo make install on Ubuntu)

To tidy up, type:

    make realclean

Win32 users should use pmake instead of make. Alternatively installation can be
done on Win32 by typing:

    Setup

Or using the install feature in tools like WinZip.


=head1 AUTHOR

Martin Hosken L<Martin_Hosken@sil.org>
(see CONTRIBUTORS for other authors).

=head1 LICENSING

Copyright (c) 1998-2013, SIL International (http://www.sil.org)

This module and all the various scripts are released under the terms of the
Artistic License 2.0. For details, see the full text of the license in the file
LICENSE.

The fonts in the test suite are released under the Open Font License 1.1, see t/OFL.txt.

