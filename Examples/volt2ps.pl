#!/usr/bin/perl

use strict;
use Font::TTF::Scripts::Volt;
use Pod::Usage;
use Getopt::Std;

my %opts;
my $VERSION;
our $CHAIN_CALL;
our ($if, $of);

$VERSION = 0.01;    # RMH      2008-10-29     First release

unless ($CHAIN_CALL)
{
    getopts('qhl:t:', \%opts);

    unless (defined $ARGV[1] || defined $opts{h})
    {
        pod2usage(1);
        exit;
    }

    if ($opts{h})
    {
        pod2usage( -verbose => 2, -noperldoc => 1);
        exit;
    }

    $if = Font::TTF::Scripts::Volt->read_font($ARGV[0], $opts{a}) || die "Can't read font $ARGV[0]";
}

my $font = $if->{'font'};
my $volt_text;

if ($opts{'t'})
{
    my ($inf) = IO::File->new("< $opts{'t'}") || die "Can't open file $opts{'t'}";
    while (<$inf>)
    { $volt_text .= $_; }
    $inf->close;
}
elsif (defined $font->{'TSIV'})
{ $volt_text = $font->{'TSIV'}->read->{' dat'}; }
else
{ die "No VOLT table in the font, nothing to do"; }
print "Parsing..." unless $opts{'q'};


my $v = $if->parse_volt($volt_text);

print "\nChanging..." unless $opts{'q'};

if ($opts{'l'})
{
	open LOG, ">$opts{'l'}" or die "Could not open log file \"$opts{'l'}\"";
	print LOG "GID: OldName -> NewName\n";
}
$font->{'post'}->read;

for my $g (0 .. $font->{'maxp'}{'numGlyphs'}-1)
{
	if ($font->{'post'}{'VAL'}[$g] ne $v->{'glyphs'}[$g]{'name'})
	{
		next unless exists $v->{'glyphs'}[$g]{'name'} and $font->{'post'}{'VAL'}[$g] ne $v->{'glyphs'}[$g]{'name'};
		next if $v->{'glyphs'}[$g]{'name'} =~ /^(glyph)?\d+$/;
		
		print LOG "$g: $font->{'post'}{'VAL'}[$g] -> $v->{'glyphs'}[$g]{'name'}\n" if $opts{'l'};
		$font->{'post'}{'VAL'}[$g] = $v->{'glyphs'}[$g]{'name'};
	}
}

close LOG if $opts{'l'};

unless ($CHAIN_CALL)
{ $if->{'font'}->update->out($ARGV[1]) || die "Can't write to font file $ARGV[1]. Do you have it installed?";}

print "\nDone.\n" unless $opts{'q'};

__END__

=head1 TITLE

volt2ps - replaces glyph ps names with their VOLT names

=head1 SYNOPSIS

  volt2ps [-t volt.txt] [-l logfile] [-q] infile.ttf outfile.ttf

Reads infile.ttf (and VOLT source volt.txt if supplied) renames glyphs, and writes the
results to outfile.ttf.

=head1 OPTIONS

  -t file     Volt source as text file to use instead of what is in the font
  -l logfile  name of file to contain record of changes.
  -q          Quiet
  -h          Help
    
=cut
