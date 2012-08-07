#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Getopt::Std;
use Font::TTF::Dumper;

our $opt_g;
getopt('g');

unless (defined $ARGV[1])
{
    die <<'EOT';

    ttfstriphints [-g glyphlist] <infile> <outfile>

Strips the TrueType hints from a ttf without touching anything else.
If -g supplied, glyphlist is a comma-separated list of glyph IDs (decimal)
from which hints will be stripped. 
Otherwise all glyphs are affected as well as the global hint code.

EOT
}

my $f = Font::TTF::Font->open($ARGV[0]) || die "Cannot open TrueType font '$ARGV[0]' for reading.\n";

# Read in the glyf (and loca) table:
$f->{'glyf'}->read || die "Cannot read glyf table in '$ARGV[0]'.\n"; 

# define sub to handle one glyph:
sub DoOneGlyph
{
	my $g = shift;
	return unless $g;
	$g->read_dat;
	undef $g->{'hints'};
	$g->{'instLen'} = 0;
	$g->{' isDirty'} = 1;
}

if ($opt_g)
{
	my $numGlyphs = $f->{'maxp'}->read->{'numGlyphs'} || die "Cannot find out number of glyphs in '$ARGV[0]'.\n";
	my $glyphs = $f->{'loca'}{'glyphs'};
	map { DoOneGlyph ($glyphs->[$_]) unless ($_ < 0 || $_ >= $numGlyphs) } split (',', $opt_g);
}
else
{
	# removing global hinting code:
	for ('cvt ', 'fpgm', 'prep')
	{	delete $f->{$_};}
	# remove all individual glyph hints:
	$f->{'loca'}->glyphs_do(\&DoOneGlyph);
	foreach (qw(maxZones maxTwilightPoints maxStorage maxFunctionDefs maxInstructionDefs maxStackElement maxSizeOfInstructions))
	{
		$f->{'maxp'}{$_} = 0;
	}	
}

$f->out($ARGV[1]);
