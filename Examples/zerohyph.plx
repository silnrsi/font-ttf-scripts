require 'getopts.pl';
use Font::TTF::Font;

Getopts('u:s:');

unless (defined $ARGV[1])
{
    die <<'EOT';
    ZEROHYPH [-u unicode] [-s width] infile outfile
Converts the hyphen glyph (or whichever Unicode valued glyph) to a zero width
space.

Handles the following tables: hmtx, loca, glyf, hdmx, LTSH, kern (MS
compatability only).

    -s width        Set hyphen to be width per mille of the width of a space
    -u unicode      unicode value in hex [002D]
EOT
}

$opt_u = "2D" unless defined $opt_u;
$opt_u = hex($opt_u);

my ($hyphnum);          # local scope for anonymous subs

$f = Font::TTF::Font->open($ARGV[0]);
$hyphnum = $f->{'cmap'}->read->ms_lookup($opt_u);
if ($opt_s)
{
    $spacenum = $f->{'cmap'}->ms_lookup(32);
    $opt_s = $f->{'hmtx'}->read->{'advance'}[$spacenum] * $opt_s / 1000;
}
$f->{'hmtx'}->read->{'advance'}[$hyphnum] = $opt_s;
$f->{'hmtx'}{'lsb'}[$hyphnum] = 0;
$f->{'loca'}->read->{'glyphs'}[$hyphnum] = "";
$f->{'hdmx'}->read->tables_do(sub { $_[0][$hyphnum] = 0; }) if defined $f->{'hdmx'};
$f->{'LTSH'}->read->{'glyphs'}[$hyphnum] = 1 if defined $f->{'LTSH'};

# deal with MS kerning only.
if (defined $f->{'kern'} && $f->{'kern'}->read->{'tables'}[0]{'type'} == 0)
{
    delete $f->{'kern'}{'tables'}[0]{'kerns'}{$hyphnum};
    while (($l, $r) = each(%{$f->{'kern'}{'tables'}[0]}))
    {  delete $r->{$g} if defined $r->{$g}; }
}

$f->out($ARGV[1]);


