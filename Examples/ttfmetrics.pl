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
    getopts('cd:fh', \%opts);

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
my $cmap = $f->{'cmap'}->find_ms;
die "No Unicode cmap in '$ARGV[0]'\n" unless $cmap;
my $loca = $f->{'loca'}->read;
die "No loca table in '$ARGV[0]'\n" unless $loca;
my $hmtx = $f->{'hmtx'}->read;
die "No hmtx table in '$ARGV[0]'\n" unless $hmtx;

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

print join($delim, qw(Unicode Glyph AdvWidth LSdBearing Xmin Xmax Ymin Ymax XCentre)), "\n";

for my $u (sort {$a <=> $b} keys %{$cmap->{'val'}})
{
	my $gid = $cmap->{'val'}{$u};
	next if $gid == 0;
	my $usv = sprintf("U+%04X", $u);
	my $g = $loca->{'glyphs'}[$gid];
	my ($xMin, $xMax, $yMin, $yMax) = (0,0,0,0);
	if (defined $g)
	{
		$g->read;
		($xMin, $xMax, $yMin, $yMax) = (map {$g->{$_}} (qw(xMin xMax yMin yMax)));
	}
	if (defined($g) or $opts{'f'})
	{
		print join($delim, $usv, $gid, $hmtx->{'advance'}[$gid], $hmtx->{'lsb'}[$gid], $xMin, $xMax, $yMin, $yMax,$hmtx->{'lsb'}[$gid] + ($xMax - $xMin)/2), "\n";
	}
	elsif ($hmtx->{'lsb'}[$gid])
	{
		# This case would be unusual, but just in case it happens:
		print join($delim, $usv, $gid, $hmtx->{'advance'}[$gid], $hmtx->{'lsb'}[$gid]), "\n";
	}
	else
	{
		print join($delim, $usv, $gid, $hmtx->{'advance'}[$gid]), "\n";
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
  -h        Get full help

=head1 DESCRIPTION

ttfmetrics reads a single font and outputs CSV (Comma-Separated Value) text
of the font-wide metrics and, for all encoded glyphs, the individual glyph metrics. 

If the C<-c> option is not supplied, the output is to STDOUT. If C<-c> is
supplied, output is to a file whose name is constructed by replacing the
file name suffix (e.g., C<-.ttf>) with C<_metrics.csv>.

The default field delimiter is comma followed by space. This default 
can be overridden with the C<-d> option.

For glyphs that have no outline, ttfmetrics normally omits the left side bearing
and bounding box metrics. With C<-f> supplied, zeros are output for these
metrics.

=cut
