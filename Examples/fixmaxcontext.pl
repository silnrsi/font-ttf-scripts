use strict;
use Font::TTF::Font;
use Getopt::Std;

our $opt_v;		# Verbose
getopts('v');

unless (defined $ARGV[1])
{
    die <<'EOT';

    fixmaxcontext <infile> <outfile>

Recalculates OS/2 table usMaxContext.  
-v enables a status message that is written to STDOUT.

EOT
}

my $f = Font::TTF::Font->open($ARGV[0]) || die "Cannot open TrueType font '$ARGV[0]' for reading.\n";

if (exists $f->{'OS/2'} && ((exists $f->{'GPOS'} && $f->{'GPOS'}->read) || (exists $f->{'GSUB'} && $f->{'GSUB'}->read)))
{
    # OS_2 plus one or both of GPOS & GSUB exist, so recalcuate usMaxContexts
    $f->{'OS/2'}->read;
    my ($lp, $ls, $l);
    $lp = $f->{'GPOS'}->maxContext if exists $f->{'GPOS'};
    $ls = $f->{'GSUB'}->maxContext if exists $f->{'GSUB'};
    $l = ($lp > $ls ? $lp : $ls);
    if ($l != $f->{'OS/2'}{'maxLookups'})
    {
    	print "usMaxContext changed from $f->{'OS/2'}{'maxLookups'} to $l\n" if $opt_v;
    	$f->{'OS/2'}{'maxLookups'} = $l;
    	$f->{'OS/2'}->dirty;
    }
    else
    {
    	print "usMaxContext unchanged at $f->{'OS/2'}{'maxLookups'}\n" if $opt_v;
    }
}
else
{
	print "missing OS/2 or GPOS/GSUB tables\n" if $opt_v;
}

$f->out($ARGV[1]);

