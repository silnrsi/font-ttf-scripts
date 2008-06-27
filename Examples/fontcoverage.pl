#!/usr/bin/perl

use Font::TTF::Font;
use IO::File;

unless ($ARGV[1])
{
    die<<'EOT';
    ttfcoverage <infile> font1.ttf font2.ttf ...
Examines a text in <infile> and lists all the fonts required to cover all
the characters in that text. If any characters are not covered, list them
at the end. Earlier fonts take precedence over later ones.
EOT
}

my ($src) = shift @ARGV;
foreach $fn (@ARGV)
{
    my $f = Font::TTF::Font->open($fn) || die "Can't open font file $fn";
    my $c = $f->{'cmap'}->read->find_ms;
    foreach $u (sort keys %{$c->{'val'}})
    { $map{$u} = $fn unless (defined $map{$u}); }
    $f->release;
}

my $fin = IO::File->new("< $src") || die "Can't open $src";
while (<$fin>)
{
    chomp;
    my (@list) = unpack('U*', $_);
    foreach $l (@list)
    {
        if (defined $map{$l})
        { $flist{$map{$l}}++; }
        else
        { $unk{$l}++; }
    }
}

print "The text used the following fonts:\n";
print join("\n", sort keys %flist);
print "\nCharacters not covered by any fonts were:\n";
print join(" ", map { sprintf("U+%04X", $_) } sort {$a <=> $b} keys %unk);
print "\n";

