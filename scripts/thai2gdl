#! /usr/bin/perl
use Font::TTF::Scripts::Thai;
use IO::File;
use Getopt::Std;
use Pod::Usage

%attach_map = (
    'U' => 'US',
    'U1' => 'US',
    'L' => 'LS',
    'L1' => 'LS',
    'MARK_U' => 'UM',
    'MARK_U1' => 'UM',
    'MARK_L' => 'LM',
    'MARK_L1' => 'LM',
    );

%class_map = (
    'LS' => 'tldia',
    'LM' => 'ldia',
    'US' => 'tudia',
    'UM' => 'udia',
    );

getopts('a:chi:x:z');

unless (defined $ARGV[2] || $opt_h)
{
    pod2usage(1);
    exit;
}
elsif ($opt_h)
{
    pod2usage(verbose => 2);
    exit;
}

$opt_i = "thai.gdl" unless ($opt_i);

$font = Font::TTF::Scripts::Thai->new($ARGV[0], $opt_c, $opt_z, $opt_a, $opt_x) || die "Can't open $ARGV[0]";
foreach $t (grep (m/^TS/, keys %{$font}))
{ delete $font->{$t}; }

$outfh = IO::File->new("> $ARGV[1]") || die "Can't create $ARGV[1]";

$outfh->print("/*\n    GDL Created for $ARGV[0] at " . scalar localtime() .
        "\n*/\n\ntable(glyph) {MUnits = $font->{'font'}{'head'}{'unitsPerEm'}};\n");
        
for ($i = 0; $i <= $#{$font->{'all_glyphs'}}; $i++)
{
    $glyphn = $font->{'all_glyphs'}[$i];
    $name = "$glyphn->{'name'}";
    $glyph = $font->{'glyphs'}{$name};
    $name = "g$name";
    if ($glyphn->{'unicode'}[0])
    { $res = "$name = unicode(" . sprintf("0x%04X)", $glyphn->{'unicode'}[0]); }
    else
    { $res = "$name = glyphid($i)"; }
    $pre = " {";

    foreach $k (keys %attach_map)
    {
        next unless ($glyph->{'anchor'}{$k});
        next if ($glyph->{'attaches'}{$attach_map{$k}});
        push (@{$classes{$attach_map{$k}}}, $name);
        $res .= "$pre$attach_map{$k} = point($glyph->{'anchor'}{$k}[0]m, $glyph->{'anchor'}{$k}[1]m)";
        $glyph->{'attaches'}{$attach_map{$k}} = 1;
        $pre = '; ';
    }
    if ($glyph->{'kern'}{'tall-udia'})
    {
        $res .= "${pre}tkern = $glyph->{'kern'}{'tall-udia'}m";
        $pre = '; ';
        push(@{$classes{'kern'}}, $name);
    }
    if ($glyph->{'kern'}{'stem'})
    {
        $have_skern = 1;
        $res .= "${pre}skern = $glyph->{'kern'}{'stem'}m";
        $pre = '; ';
	push(@{$classes{'skern'}}, $name);
    }
    $res .= "}" if ($pre eq '; ');
    $outfh->print("$res;\n");
}

foreach $k (keys %class_map)
{
    $outfh->print("\n" . list_class($classes{$k}, $class_map{$k}));
}

$outfh->print("\n#define has_zwsp\n") if ($font->{'font'}{'cmap'}->read->ms_lookup(0x200b));
$outfh->print("\n#define has_ckern\n" . list_class($classes{'kern'}, 'cKern')) if ($classes{'kern'});
$outfh->print("\n#define has_skern\n" . list_class($classes{'skern'}, 'cpreK')) if ($have_skern);
$outfh->print("endtable;\n\n#include \"$opt_i\"\n");
$outfh->close;

$font->{'font'}->out($ARGV[2]);

sub list_class
{
    my ($list, $name) = @_;
    my ($out, $res, $offset, $g);
    
    $out = "$name = (";
    $res = '';
    $offset = length($res) - 4;
    foreach $g (@{$list})
    {
        $res .= "$g ";
        if (length($res) > 75)
        {
            chop $res;
            $out .= "$res\n";
            $res = " " x $offset;
        }
    }
    if (length($res) > $offset)
    {
        chop $res;
        $out .= $res;
    }
    $out .= ");\n";
    $out;
}

__END__

=head1 TITLE

thai2gdl - Create GDL for a standard Thai font

=head1 SYNOPSIS

  thai2gdl [-a angle] [-c] [-i basegdl] [-x xmlfile] fontfile gdlfile outfont
Creates GDL for a Thai font.

=head1 OPTIONS

  -a angle        Italic angle in degrees
  -c              Don't create U+25CC if not present
  -i basegdl      which .gdl file to include [thai.gdl]
  -x file         XML point database file for fontfile
  -z              Don't create U+200B (zwsp) if not present

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

thai2ot, thai2volt

=cut
