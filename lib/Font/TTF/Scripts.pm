package Font::TTF::Scripts;

use strict;

our $VERSION = '1.06_02';

1;

=head1 NAME

Font::TTF::Scripts - Smart font script supporting modules and scripts for TTF/OTF

=head1 DESCRIPTION

This module contains a number of useful command-line programs for hacking with TTF/OTF files. Highlights include:

  fret       - produces PDF report of an uninstalled font including all glyphs
  make_gdl   - build GDL source code Graphite fonts
  make_fea   - build Feature source code for OpenType fonts
  hackos2    - manipulates the OS/2 table of a font
  ttf2woff   - create WOFF version of a font
  ttfbuilder - builds a font from another font, attaching glyphs, subsetting, etc.
  ttfname    - renames a font
  ttfsubset  - removes parts of a font in order to produce a working, smaller, font.
  ttftable   - export/import/list tables in a font
  volt2ttf   - command-line VOLT compiler

When executed without parameters, most commands will emit usage message.

=head1 SEE ALSO

L<add_classes>,
L<check_attach>, 
L<dumpfont>, 
L<fret>, 
L<hackos2>, 
L<make_fea>, 
L<make_gdl>, 
L<make_volt>, 
L<psfix>, 
L<std2ap>, 
L<sfdmeld>, 
L<sfdmerge>, 
L<ttf2volt>, 
L<ttf2woff>, 
L<ttfascent>, 
L<ttfbboxfix>,
L<ttfbuilder>, 
L<ttfdeflang>, 
L<ttfeval>, 
L<ttffeatparms>, 
L<ttflang2tuner>, 
L<ttfname>, 
L<ttfremap>, 
L<ttfsetver>, 
L<ttfsubset>, 
L<ttftable>, 
L<typetuner>, 
L<volt2ap>, 
L<volt2ttf>.

=head1 AUTHOR

Martin Hosken L<http://scripts.sil.org/FontUtils>.
(see CONTRIBUTORS for other authors).

Repository available at L<https://github.com/silnrsi/font-ttf-scripts.git>

=head1 HISTORY

See F<Changes> file for a change log.

=head1 LICENSING

Copyright (c) 1998-2016, SIL International (http://www.sil.org)

This module and all the various scripts are released under the terms of the
Artistic License 2.0. For details, see the full text of the license in the file
LICENSE.

The fonts in the test suite are released under the Open Font License 1.1, see F<t/OFL.txt>.

=cut
