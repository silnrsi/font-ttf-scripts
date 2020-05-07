#!/usr/bin/perl

use strict;
use Font::TTF::Font;
use Getopt::Std;
use Pod::Usage;

our $VERSION = 0.1;     # RMH - Original coding  

our $CHAIN_CALL;
our %opts;
our $f;

unless($CHAIN_CALL)
{
    getopts('cd:fghp', \%opts);

    pod2usage( -verbose => 2, -noperldoc => 1) if $opts{'h'};

    pod2usage(-verbose => 1) unless defined $ARGV[0];

    $f = Font::TTF::Font->open($ARGV[0]) || die "Can't open file '$ARGV[0]': $^E\n";
}

my $delim = $opts{'d'} || ', ';

if ($opts{'c'})
{
	my $name = $ARGV[0];
	$name =~ s/(\.[^.]+)?$/_metrics.csv/o;
	open(STDOUT, '>', $name) or die "Cannot redirect STDOUT to '$name': $!";
}

my $head = $f->{'head'}->read;
my $maxp = $f->{'maxp'}->read;
my $cmap = $f->{'cmap'}->find_ms;
die "No Unicode cmap in '$ARGV[0]'\n" unless $cmap;
my $hmtx = $f->{'hmtx'}->read;
die "No hmtx table in '$ARGV[0]'\n" unless $hmtx;

my $post;
if ($opts{'p'})
{
    $post = $f->{'post'}->read;
    die "No post table in '$ARGV[0]'\n" unless $post;
}

my $loca;
if (defined $f->{'loca'})
{
	# Looks like a TTF
	$loca = $f->{'loca'}->read || die "No loca table in '$ARGV[0]'\n";
}


if (defined $f->{'OS/2'})
{
	my $OS2 = $f->{'OS/2'}->read;
	print join($delim, qw(EmSquare Xmin Xmax Ymin Ymax WinAscent WinDescent TypoAscender TypoDescender TypoLineGap)), "\n";
	print join($delim, $head->{'unitsPerEm'}, (map {$head->{$_}} (qw(xMin xMax yMin yMax))), (map {$OS2->{$_}} (qw(usWinAscent usWinDescent sTypoAscender sTypoDescender sTypoLineGap)))), "\n\n";
}
else
{
	print join($delim, qw(EmSquare Xmin Xmax Ymin Ymax)), "\n";
	print join($delim, $head->{'unitsPerEm'}, map {$head->{$_}} (qw(xMin xMax yMin yMax))), "\n\n";
}

if ($opts{'g'})
{
    print join($delim, qw(GlyphID Unicode)), $delim;
}
else
{
    print join($delim, qw(Unicode GlyphID)), $delim;
}

if ($opts{'p'})
{
    print join($delim, qw(GlyphName)), $delim;
}

if ($loca)
{
	print join($delim, qw(AdvWidth LSdBearing RSBearing Xmin Xmax Ymin Ymax XCentre)), "\n";
}
else
{
	print join($delim, qw(AdvWidth LSdBearing)), "\n";
}

if ($opts{'g'})
{
    my @map;
    @map = $f->{'cmap'}->reverse(array => 1);
    for my $gid (0 .. $maxp->{'numGlyphs'}-1)
    {
        my $usv;
        $usv = join(' ', map {sprintf("U+%04X", $_)} sort @{$map[$gid]}) if defined $map[$gid];
        print join($delim, $gid, $usv), $delim;
        DoTheRest($gid);
    }
}
else
{
    for my $u (sort {$a <=> $b} keys %{$cmap->{'val'}})
    {
    	my $gid = $cmap->{'val'}{$u};
    	next if $gid == 0;
    	my $usv = sprintf("U+%04X", $u);
        print join($delim, $usv, $gid), $delim;
        DoTheRest($gid);
    }
}

sub DoTheRest
{
    my $gid = shift;
    if ($opts{'p'})
    {
        print $post->{'VAL'}[$gid], $delim;
    }
	my $g = $loca->{'glyphs'}[$gid];
	my ($xMin, $xMax, $yMin, $yMax) = (0,0,0,0);
	my ($adv, $lsb, $rsb);
	if ($loca && defined $g)
	{
		$g->read;
		($xMin, $xMax, $yMin, $yMax) = (map {$g->{$_}} (qw(xMin xMax yMin yMax)));
	}
	$adv = $hmtx->{'advance'}[$gid];
	$lsb = $hmtx->{'lsb'}[$gid];
	$rsb = $adv - $lsb - ($xMax - $xMin);
	if ($loca && (defined($g) or $opts{'f'}))
	{
		print join($delim, $adv, $lsb, $rsb, $xMin, $xMax, $yMin, $lsb + ($xMax - $xMin)/2), "\n";
	}
	elsif ($hmtx->{'lsb'}[$gid])
	{
	    # Glyph has no outline but does have lsb.
		# This case would be unusual, but just in case it happens:
		print join($delim, $adv, $lsb, $rsb),"\n";
	}
	else
	{
		print join($delim, $hmtx->{'advance'}[$gid]), "\n";
	}
} 

__END__

=head1 TITLE

ttfmetrics - print CSV file of font metrics

=head1 SYNOPSIS

ttfmetrics [options] infont 

Opens infont and outputs the resulting font and glyph metrics as CSV data.

=head1 OPTIONS

  -c        Create output file name from input font file name
  -d delim  String to use for field delimiter rather than ', '
  -f        Output zeros rather than omit empty glyph metrics
  -g        Process font in glyph order, outputing all glyphs
  -h        Get full help
  -p        Include glyph psname

=head1 DESCRIPTION

ttfmetrics reads a single font and outputs CSV (Comma-Separated Value) text
of the font-wide metrics and individual glyph metrics. 

By default, ttfmetrics outputs glyph metrics for only the encoded glyphs, and
the data is sorted by USV. C<-g> causes all glyphs, not just encoded glyphs, 
to be output, in glyph order rather than character order, and the columns are 
rearranged accordingly. Note that multiply-encode glyphs will have multiple USVs.

If C<-p> is provided then glyph names are included in the output.

By default the output is to STDOUT. If C<-c> is
supplied, output is to a file whose name is constructed by replacing the
file name suffix (e.g., C<.ttf>) with C<_metrics.csv>.

The default field delimiter is comma followed by space. This default 
can be overridden with the C<-d> option.

For glyphs that have no outline, ttfmetrics normally omits the left side bearing
and bounding box metrics. With C<-f> supplied, zeros are output for these
metrics.

=cut
