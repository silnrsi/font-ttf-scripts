#!/usr/bin/perl

use Font::TTF::Font;
use Getopt::Std;

getopts('g');

unless ($ARGV[1])
{
    die <<'EOT';
    ttfdiff [-g] font1.ttf font2.ttf
Compares two fonts to see if there are any glyph differences, based on cmap
entries.

    -g      Compare by glyphid rather than cmap
EOT
}

$f1 = Font::TTF::Font->open($ARGV[0]) || die "Can't open font file $ARGV[0]";
$f2 = Font::TTF::Font->open($ARGV[1]) || die "Can't open font file $ARGV[1]";
$c1 = $f1->{'cmap'}->read->find_ms;
$c2 = $f2->{'cmap'}->read->find_ms;
$f1->{'glyf'}->read;
$f2->{'glyf'}->read;
print "GID1,CMAP1,GID2,CMAP2\n";
if ($opt_g)
{
    @r1 = $f1->{'cmap'}->reverse;
    @r2 = $f2->{'cmap'}->reverse;
    $num1 = $f1->{'maxp'}{'numGlyphs'};
    $num2 = $f2->{'maxp'}{'numGlyphs'};
    for $i (0 .. min($num1, $num2) - 1)
    {
        $cid1 = $r1[$i];
        $cid2 = $r2[$i];
        $g1 = $f1->{'loca'}{'glyphs'}[$i];
        $g2 = $f2->{'loca'}{'glyphs'}[$i];
        if (defined $g1 and defined $g2)
        {
            $g1->read; $g2->read;
            report($i, $cid1, $i, $cid2) if ($g1->{' dat'} ne $g2->{' dat'});
        }
        elsif (!defined $g1 and !defined $g2)
        { }
        else
        { report($i, $cid1, $i, $cid2); }
    }
    if ($num1 > $num2)
    {
        for $i ($num2 .. $num1 - 1)
        { report($i, $r1[$i], $i, 0); }
    }
    elsif ($num2 > $num1)
    {
        for $i ($num1 .. $num2 - 1)
        { report($i, 0, $i, $r2[$i]); }
    }
}
else
{
    for $cid1 (sort {$a <=> $b} keys %{$c1->{'val'}})
    {
        $gid1 = $c1->{'val'}{$cid1};
        $gid2 = $c2->{'val'}{$cid1};
        $g1 = $f1->{'loca'}{'glyphs'}[$gid1];
        $g2 = $f2->{'loca'}{'glyphs'}[$gid2];
        if (defined $g1 and defined $g2)
        {
            $g1->read; $g2->read;
            report($gid1, $cid1, $gid2, $cid1) if ($g1->{' dat'} ne $g2->{' dat'});
        }
        elsif (!defined $g1 and !defined $g2)
        { }
        else
        { report($gid1, $cid1, $gid2, $cid1) }
    }
    for $cid2 (sort {$a <=> $b} keys %{$c2->{'val'}})
    {
        if (!defined $c1->{'val'}{$cid2})
        { report(0, $cid2, $c2->{'val'}{$cid2}, $cid2); }
    }
}

sub report { print join(",", @_) . "\n"; }

sub min { return ($_[0] < $_[1] ? $_[0] : $_[1]); }

