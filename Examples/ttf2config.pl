#!/usr/bin/perl

use Font::TTF::Font;

$f = Font::TTF::Font->open($ARGV[0]);
$c = $f->{'cmap'}->read->find_ms;
$p = $f->{'post'}->read;
@rev = $f->{'cmap'}->reverse;

$num = $f->{'maxp'}->read->{'numGlyphs'};
$name = $f->{'name'}->read->find_name(4);
$upem = $f->{'head'}->read->{'unitsPerEm'};
print "<?xml version='1.0'?>\n";
print "<font name='$name' upem='$upem'>\n\n";
for ($i = 3; $i < $num; $i++)
{
    my ($pname) = $p->{'VAL'}[$i];
    my ($uid) = $rev[$i];

    print "<glyph PSName='$pname'";
    printf (" UID='%04X'", $uid) if ($uid);
    print "><base PSName='$pname'/></glyph>\n";
}
print "\n</font>\n";

