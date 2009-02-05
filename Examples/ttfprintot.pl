#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Font::TTF::OTTags qw( %tttags %ttnames readtagsfile );
use Getopt::Std;
use Pod::Usage;

our ($opt_h, $opt_v);
getopts('hv');

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

foreach (@ARGV)
{
	my $font = Font::TTF::Font->open($_);
	unless ($font)
	{
		print STDERR "Unable to open font file '$_'\n";
		next;
	}
	print "Font file: '$_'\n" if $#ARGV > 0;
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
	}
	
	$font->release;
}

=head1 TITLE

ttfprintot - prints the Script/Language/Feat hierarchy of OpenType files

=head1 SYNOPSIS

  ttfprintot [-v] infile.ttf ...
  ttfprintot -h

Prints to STDOUT information about the Script, Language, and Feature structure of one or more OpenType font files.

=head1 OPTIONS

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

When a font has been compiled, but not shipped, by Microsoft VOLT, the OpenType tables contain
additional languages and features used by VOLT's Proofing Tool. These are not included
in the output from ttfprintot unless the -v option is provided.

=cut