#! /usr/bin/perl
# 1.1   RMH    06-Feb-00     Extract a raw TTF table to a file

use Font::TTF::Font;
require 'getopts.pl';
Getopts('at:');

unless (defined $ARGV[0])
{
    die <<'EOT';

    TTFExtractTable [-t table] [-a] infontfile [outdatafile]

Extracts the named table from a TrueType font file and writes the raw data
to a file. -t identifies which table to dump (default TSIV). -a specifies
to use "ascii" mode output (if needed on your platform) to convert line-endings
to PC-compatible crlf, etc. (do this only on "text" tables such as TSIV).

Example:  TTFExtractTable -tVTIS -a SomeFont.ttf out.txt

Copyright (c) 2002 SIL International; All Rights Reserved.

EOT
}

$opt_t = 'TSIV' unless defined $opt_t;

$f = Font::TTF::Font->open($ARGV[0]) or die "Could not open font '$ARGV[0]'\n";

exists $f->{$opt_t} or die "Cannot find table '$opt_t' in file '$ARGV[0]'. Available tables are: " . join(',', map {m/^ / ? () : $_} keys %$f) . ".\n";

$f->{$opt_t}->read_dat;

open(STDOUT, ">" . $ARGV[1]) or die "Couldn't open '$ARGV[1]' for writing" if defined $ARGV[1];

binmode(STDOUT) unless $opt_a;

print $f->{$opt_t}->{' dat'};

__END__
:endofperl
