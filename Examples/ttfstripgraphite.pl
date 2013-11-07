#! /usr/bin/perl
# 1.0   RMH    2007-09-26 Strip Graphite tables from a font

use Font::TTF::Font;

($inFontFile, $outFontFile) = @ARGV;

unless ($#ARGV == 1)
{
    die <<'EOT';

    TTFStripGraphite infontfile outfontfile

Strips SIL Graphite tables (Silf, Feat, Gloc, Glat, Sill, and Sile) from
a font and writes the result to a new font file.

EOT
}

# Open the font 
$f = Font::TTF::Font->open($inFontFile) or die "Could not open font '$inFontFile'\n";


# Remove tables the user doesn't want:
for (qw(Silf Feat Gloc Glat Sill Sile)) { delete $f->{$_} };

# Write the font out!
$f->out($outFontFile);


__END__
:endofperl