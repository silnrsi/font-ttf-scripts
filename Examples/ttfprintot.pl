#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Font::TTF::OTTags qw( %tttags %ttnames readtagsfile );
use Font::TTF::Scripts::Volt;
use IO::File;
use Getopt::Std;
use Pod::Usage;

our ($opt_h, $opt_l, $opt_t, $opt_v);
getopts('hlt:v');

unless (defined $ARGV[0] || defined $opt_h)
{
    pod2usage(1);
    exit;
}

if ($opt_h)
{
    pod2usage( -verbose => 2, -noperldoc => 1);
    exit;
}

# See if we can find any VOLT source:

if ($opt_t)
{
    my ($inf) = IO::File->new("< $opt_t") || die "Can't open file $opt_t";
    $opt_t = '';
    while (<$inf>)
    { $opt_t .= $_; }
    $inf->close;
}


my %LookupText = (
GSUB => ['Single substitution', 'Multiple', 'Alternate', 'Ligature', 'Contextual', 'Chain contextual', 'Extension', 'Reverse Chain'],
GPOS => ['Single Adjustment', 'Pair Adjustment', 'Cursive', 'Mark to base', 'Mark to ligature', 'Mark to mark', 'Contextual', 'Chain contextual', 'Extension']
);

my @FlagDetail = (
	[0x0001, "RightToLeft"],
	[0x0002, "IgnoreBase"],
	[0x0004, "IgnoreLigatures"],
	[0x0008, "IgnoreMarks"],
	[0x0010, "UseMarkFilteringSet"],
);

foreach (@ARGV)
{
	my $if = Font::TTF::Scripts::Volt->read_font($_);
	unless ($if)
	{
		warn "Can't read font $_";
		next;
	}
	my $font = $if->{'font'};
	
	print "Font file: '$_'\n" if $#ARGV > 0;
	
	my %lookupNames = (GSUB => [], GPOS => []);
	
	# See if any VOLT source:
	my $volt_text = defined $font->{'TSIV'} ? $font->{'TSIV'}->read->{' dat'} : $opt_t;
	if (defined ($volt_text))
	{
		# Parse the VOLT text and extract lookup names:
		my $volt = $if->parse_volt($volt_text);
		foreach my $l (@{$volt->{'lookups'}})
		{
			my $name = $l->{'id'};
			# NB: In VOLT source, a series of "lookups" with names like zork\a, zork\b, zork\c represent
			# subtables of a single actual OpenType lookup.
			$name =~ s/\\.*$//oi;	# strip off subtable indicator if any
			my $type = 'G' . uc($l->{'lookup'}[0]);		# gives GSUB or GPOS
			push @{$lookupNames{$type}}, $name unless $lookupNames{$type}[-1] eq $name;
		}
	}
			
	foreach my $t (qw(GSUB GPOS))
	{
		next unless exists $font->{$t};
		print "$t:\n";
		my $g = $font->{$t}->read;
		print "  Scripts:\n";
		foreach my $s (sort {$a cmp $b} keys (%{$g->{'SCRIPTS'}}))
		{
			print "    <$s> ", $ttnames{'SCRIPT'}{$s};
			if (defined $g->{'SCRIPTS'}{$s}{' REFTAG'})
			{
				print " -> '$g->{'SCRIPTS'}{$s}{' REFTAG'}'\n";
			}
			else
			{
				print "\n";
				foreach my $l ('DEFAULT', @{$g->{'SCRIPTS'}{$s}{'LANG_TAGS'}})
				{
					next if $l =~ /^zz\d\d$/ && !$opt_v;
					print "      <$l> ", $ttnames{'LANGUAGE'}{$l};
					if (!defined $g->{'SCRIPTS'}{$s}{$l})
					{
						print " not defined\n";
					}
					elsif (defined $g->{'SCRIPTS'}{$s}{$l}{' REFTAG'})
					{
						print " -> '$g->{'SCRIPTS'}{$s}{$l}{' REFTAG'}'\n";
					}
					
					else
					{
						print "\n";
						foreach my $f (@{$g->{'SCRIPTS'}{$s}{$l}{'FEATURES'}})
						{
							print "        <$f> ", $ttnames{'FEATURE'}{substr($f,0,4)}, "\n";
						}
					}
				}
			}
		}
		print "  Features:\n";
		foreach my $f (@{$g->{'FEATURES'}{'FEAT_TAGS'}})
		{
			next if $f =~ /^zz\d\d$/ && !$opt_v;
			print "    <$f> ", $ttnames{'FEATURE'}{substr($f,0,4)}, " -> ", join (',', @{$g->{'FEATURES'}{$f}{'LOOKUPS'}}), "\n";
		}	
		
		if ($opt_l)
		{
			print "  Lookups:\n";
			foreach my $il (0 .. scalar(@{$g->{'LOOKUP'}})-1)
			{
				my $l = $g->{'LOOKUP'}[$il];
				print "    $il: ";
				print "Name = $lookupNames{$t}[$il]\n        " if defined $volt_text;
				print "Type = $l->{'TYPE'} ($LookupText{$t}[$l->{'TYPE'}-1])";
				if ($l->{'FLAG'})
				{
					print " Flag = $l->{'FLAG'} (";
					my $x=0;
					foreach (@FlagDetail)
					{
						print $x++ ? ' ' : '', "$_->[1]" if ($l->{'FLAG'} & $_->[0]);
					}
					print $x++ ? ' ' : '', "ProcessMarkClass=", ($l->{'FLAG'}) >> 8 if ($l->{'FLAG'} & 0xFF00);
					print ')';
				}
				print "\n";
				foreach my $is (0 .. scalar(@{$l->{'SUB'}})-1)
				{
					print "        Subtable $is: Format = $l->{'SUB'}[$is]{'FORMAT'} " . 
						(defined $l->{'SUB'}[$is]{'RULES'} ? "Number of rules = " . scalar(@{$l->{'SUB'}[$is]{'RULES'}}) : "No rules") . "\n";
				}
			}
		}
		
	}
	
	$font->release;
}


=head1 TITLE

ttfprintot - prints the Script/Language/Feat hierarchy of OpenType files

=head1 SYNOPSIS

  ttfprintot [-l] [-t volt.txt] [-v] infile.ttf ...
  ttfprintot -h

Prints to STDOUT information about the Script, Language, and Feature structure of one or more OpenType font files.

=head1 OPTIONS

  -l   enumerate Lookups as well as Scripts, Languages and Features
  -t   Volt source file to use instead of what is in the font
  -v   include debugging entries added by Microsoft VOLT
  -h   print help message

=head1 DESCRIPTION

Here is an excerpt from the output of ttfprintot showing the GPOS table of DoulosSIL Regular:

	GPOS:
	  Scripts:
	    <latn> Latin
	      <DEFAULT>
	        <kern> Kerning
	        <mark> Mark Positioning
	        <mkmk> Mark to Mark Positioning
	      <IPA >  -> 'DEFAULT'
	  Features:
	    <kern> Kerning -> 4
	    <mark> Mark Positioning -> 0,1
	    <mkmk> Mark to Mark Positioning -> 2,3

This shows that there is one script (with tag "latn") and that contains both the DEFAULT language and a 
language with tag "IPA ". The "->" beside the IPA language indicates that internally the DEFAULT and IPA languages
use the same language table.  The sequences of numbers beside the Features entries give the indicies 
of lookups that are assigned to the features. Thus the Mark Positioning feature uses lookups 0 and 1.

If -l is provided, the lookups are also enumerated, e.g:

  Lookups:
    0: Name = LamAlefConnection
        Type = 3 (Cursive) Flag = 9 (RightToLeft IgnoreMarks)
        Subtable 0: Format = 1 Number of rules = 38
    1: Name = MarksAbove
        Type = 4 (Mark to base) Flag = 1 (RightToLeft)
        Subtable 0: Format = 1 Number of rules = 828
    2: Name = DaggerOnLam
        Type = 6 (Mark to mark) Flag = 1 (RightToLeft)
        Subtable 0: Format = 1 Number of rules = 57

Note that lookup names will be output only if the VOLT source project is included in the font
or supplied by -t parameter.

When a font has been compiled, but not shipped, by Microsoft VOLT, the OpenType tables contain
additional languages and features used by VOLT's Proofing Tool. These are not included
in the output from ttfprintot unless the -v option is provided.

=cut