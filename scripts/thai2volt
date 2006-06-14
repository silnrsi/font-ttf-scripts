#! /usr/bin/perl
use Font::TTF::Scripts::Thai;
use Getopt::Std;
use Pod::Usage;

getopts('a:chk:x:z');

unless (defined $ARGV[1] || $opt_h)
{
    pod2usage(1);
    exit;
}
elsif ($opt_h)
{
    pod2usage(verbose => 2);
    exit;
}

$font = Font::TTF::Scripts::Thai->new($ARGV[0], $opt_c, $opt_z, $opt_a, $opt_x) || die "Can't open $ARGV[0]";

for ($i = 0; $i <= $#{$font->{'all_glyphs'}}; $i++)
{
    $glyph = $font->{'all_glyphs'}[$i];
    $res .= "DEF_GLYPH \"$glyph->{'name'}\" ID $i";
    if ($#{$glyph->{'unicode'}} > 0)
    { $res .= " UNICODEVALUES \"" . join(",", map {sprintf("U+%04X", $_)}
            sort {$a <=> $b} @{$glyph->{'unicode'}}) . '"'; }
    elsif ($#{$glyph->{'unicode'}} == 0)
    { $res .= " UNICODE $glyph->{'unicode'}[0]"; }

    $res .= " TYPE $glyph->{'type'}" if ($glyph->{'type'} ne '');
    $res .= " END_GLYPH\n";
}

$res .= <<'EOT';
DEF_SCRIPT NAME "Thai" TAG "thai"

DEF_LANGSYS NAME "Default" TAG "dflt"

DEF_FEATURE NAME "Mark to Base" TAG "mark"
 LOOKUP "base"
END_FEATURE
DEF_FEATURE NAME "Mark to Mark" TAG "mkmk"
 LOOKUP "udia" LOOKUP "ldia"
END_FEATURE
DEF_FEATURE NAME "Canonical Composition" TAG "ccmp"
 LOOKUP "yoying" LOOKUP "saraam"
END_FEATURE
EOT

if ($opt_k)
{
    $res .= <<'EOT';
DEF_FEATURE NAME "Kerned" TAG "kern"
EOT

    if ($opt_k & 1)
    { 
        $kernai_str = '';
        foreach $k (sort keys %{$font->{'glyphs'}})
        {
            $glyph = $font->{'glyphs'}{$k};
            $kernai_str .= " GLYPH \"$k\" BY POS ADV $glyph->{'kern'}{'stem'}" .
                        " DX $glyph->{'kern'}{'stem'} END_POS\n"
                        if ($glyph->{'kern'}{'stem'});
        }

        $res .= " LOOKUP \"Kern_ai\"\n" if ($kernai_str);
    }

    if ($opt_k & 2)
    {
        $kerna_str = '';
        foreach $k (sort keys %{$font->{'glyphs'}})
        {
            $glyph = $font->{'glyphs'}{$k};
            $kerna_str .= " GLYPH \"$k\" BY POS ADV $glyph->{'kern'}{'tall-udia'}" .
                         " DX $glyph->{'kern'}{'tall-udia'} END_POS\n"
                                if ($glyph->{'kern'}{'tall-udia'});
        }

        $res .= " LOOKUP \"Kern_a\"\n" if ($kerna_str);
    }

    $res .= "END_FEATURE\n";
}

$res .= <<'EOT';
END_LANGSYS
END_SCRIPT
DEF_GROUP "yoyings"
 ENUM GLYPH "uni0e0d" GLYPH "uni0e10" END_ENUM
END_GROUP
DEF_GROUP "yoyings-"
 ENUM GLYPH "unif70f" GLYPH "unif700" END_ENUM
END_GROUP
EOT

    foreach $n (qw(base_cons base_tall base_vowel base_kern udia_kern ldia udia))
    {
        next if ($n =~ /kern$/ && !$opt_k);
        $res .= "DEF_GROUP \"$n\"\n ENUM ";
        foreach $k (@{$font->{'class'}{'groups'}{$n}})
        { $res .= "GLYPH $k "; }
        $res .= "END_ENUM\nEND_GROUP\n";
    }

    $res .= <<'EOT';
DEF_LOOKUP "yoying" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
 RIGHT GROUP "ldia"
END_CONTEXT
AS_SUBSTITUTION
SUB GLYPH "uni0e0d"
WITH GLYPH "unif70f"
END_SUB
SUB GLYPH "uni0e10"
WITH GLYPH "unif700"
END_SUB
END_SUBSTITUTION
DEF_LOOKUP "saraam" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
END_CONTEXT
AS_SUBSTITUTION
SUB GLYPH "uni0e33"
WITH GLYPH "uni0e4d" GLYPH "uni0e32"
END_SUB
END_SUBSTITUTION
DEF_LOOKUP "base" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
END_CONTEXT
AS_POSITION
ATTACH GROUP "base_cons" GROUP "base_tall" GROUP "base_vowel"
TO GROUP "udia" AT ANCHOR "U" GROUP "ldia" AT ANCHOR "L"
END_ATTACH
END_POSITION
EOT

if ($opt_k & 1 && $kernai_str)
{
    $res .= <<'EOT';
DEF_LOOKUP "Kern_ai" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
 LEFT GROUP "base_cons"
END_CONTEXT
AS_POSITION
ADJUST_SINGLE
EOT

    $res .= $kernai_str;
    $res .= <<'EOT';
END_ADJUST
END_POSITION
EOT
}

if ($opt_k & 2 && $kerna_str)
{
    $res .= <<'EOT';
DEF_LOOKUP "Kern_a" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
 LEFT GROUP "base_tall"
 RIGHT GROUP "udia_kern"
END_CONTEXT
IN_CONTEXT
 LEFT GROUP "udia"
 RIGHT GROUP "udia_kern"
END_CONTEXT
IN_CONTEXT
 LEFT GROUP "base_tall"
 LEFT GROUP "ldia"
 RIGHT GROUP "udia_kern"
END_CONTEXT
IN_CONTEXT
 LEFT GROUP "base_tall"
 LEFT GROUP "ldia"
 LEFT GROUP "ldia"
 RIGHT GROUP "udia_kern"
END_CONTEXT
AS_POSITION
ADJUST_SINGLE
EOT
        $res .= $kerna_str;
        $res .= <<'EOT';
END_ADJUST
END_POSITION
EOT
}

$res .= <<'EOT';
DEF_LOOKUP "udia" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
END_CONTEXT
AS_POSITION
ATTACH GROUP "udia"
TO GROUP "udia" AT ANCHOR "U1"
END_ATTACH
END_POSITION
DEF_LOOKUP "ldia" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR
IN_CONTEXT
END_CONTEXT
AS_POSITION
ATTACH GROUP "ldia"
TO GROUP "ldia" AT ANCHOR "L1"
END_ATTACH
END_POSITION
EOT

foreach $k (sort keys %{$font->{'glyphs'}})
{
    $glyph = $font->{'glyphs'}{$k};
    foreach $i (sort keys %{$glyph->{'anchor'}})
    {
        $res .= "DEF_ANCHOR \"$i\" ON $glyph->{'gid'} GLYPH $k COMPONENT 1 " .
                "AT POS DX $glyph->{'anchor'}{$i}[0] DY $glyph->{'anchor'}{$i}[1] END_POS " .
                "END_ANCHOR\n";
    }
}

$res .= <<'EOT';
GRID_PPEM 20
PRESENTATION_PPEM 72
PPOSITIONING_PPEM 144
CMAP_FORMAT 1 0 0
CMAP_FORMAT 3 1 4
EOT

$res .= "END\n\n";

$res =~ s/\n/\r/og;
$res .= "\000" x 7;
$font->{'font'}{'TSIV'} = Font::TTF::Table->new(dat => $res, PARENT => $font->{'font'});
$font->{'font'}->out($ARGV[1]);

__END__

=head1 TITLE

thai2volt - Create VOLT code for standard Thai fonts

=head1 SYNOPSIS

  THAI2VOLT [-a angle] [-c] [-k flags] [-x file] infile outfile
Copies the input font to the output font adding various tables on the way. If
the font is not already a Unicode font, it will be converted to one.

=head1 OPTIONS

  -a angle  Sets italic angle
  -c        Don't add circle glyph (U+25CC) if one not present. Adding a circle 
            glyph destroys the hmdx, VDMX & LTSH tables.
  -k        Add empty kerning tables to VOLT table. Bitfield of tables
              0 - ai moving left over consonants
              1 - wide upper diacritics moving base right following tall things
  -x        XML point database file for infile
  -z        Don't add zwsp (U+200B) if not present

=head1 DESCRIPTION

This program does a number of things:

=over 4

=item .

It creates a dotted circle glyph if one is not present and adds it to the font.
And also a blank ZWSP (U+200B) glyph if not present.

=item .

It reencodes the font to conform to Unicode encoding appropriate to OpenType
fonts and also to Win95 Thai editions

=item .

It creates attachment points for each glyph

=item .

It adds kerning rules to ensure glyphs don't clash.

=back

Since positioning is dependent on italic angle. If thai2gdl is used on an italic
font the slope of the font should be given to the program if it is not already
specified in the POST table in the font.

=head1 SEE ALSO

thai2gdl, thai2ot

=cut

