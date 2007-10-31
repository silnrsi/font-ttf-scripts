# 1.0   RMH    14-Feb-00     Insert a raw TTF table into a font file

use Font::TTF::Font;
require 'getopts.pl';
Getopts('d:t:');

($inFontFile, $inDataFile, $outFontFile) = @ARGV;

unless (defined $outFontFile)
{
    die <<'EOT';

    TTFReplaceTable [-t table] [-d deletelist] infontfile indatafile outfontfile

Inserts the named table into a TrueType font file and writes the new font
to a file. -t identifies which table to replace (default 'TSIV'). 

-d specifies an optional list of tables to delete from the font. Argument
should be a comma-separated list of table tags (default 'TSID,TSIP,TSIS').

Example:  TTFReplaceTable -tVTIS SomeFont.ttf out.txt OutFont.ttf

Copyright (c) 2002 SIL International; All Rights Reserved.

EOT
}

$opt_t = 'TSIV'				unless defined $opt_t;
$opt_d = 'TSID,TSIP,TSIS'	unless defined $opt_d;

# Open the font 
$f = Font::TTF::Font->open($inFontFile) or die "Could not open font '$inFontFile'\n";

# Create, if it doesn't exist, the table we are going to replace
$f->{$opt_t} = Font::TTF::Table->new (PARENT => $f, NAME => $opt_t) unless exists $f->{$opt_t};

# Read entire file into the table data
open (IN, $inDataFile) or die "Cannot open file '$inDataFile' for reading. Stopping at ";
$/ = undef;		# slurp mode for read:
binmode IN;
$f->{$opt_t}->{' dat'} = <IN>;
close IN;

# Remove tables the user doesn't want:
for (split(/,\s*/, $opt_d)) { delete $f->{$_} };

# Write the font out!
$f->out($outFontFile);


__END__
:endofperl
