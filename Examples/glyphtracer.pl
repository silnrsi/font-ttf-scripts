#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Getopt::Std;
use Pod::Usage;

our $VERSION = 0.1;

our ($opt_h);
getopts('h');


=head1 NAME

glyphtracer - find glyph usage in a TrueType font

=head1 SYNOPSIS

  glyphtracer glyph infont
  glyphtracer -h

Find uses within the infont of the designated glyph. Glyphs may can be identified
by decimal numeric ID or, if the font has a post table, by postscript glyph name.

=head1 OPTIONS

  -h  Verbose help

=head1 DESCRIPTION

Glyphtracer searches internal font tables infont for references to the specified glyph and, if found, prints
messages to STDOUT indicating where the glyph is referenced.

Searches the following font tables:

=over

=cut

our ($opt_h); 
# getopts('hlt:vx');

unless (defined $ARGV[1] || defined $opt_h)
{
    pod2usage(1);
    exit;
}

if ($opt_h)
{
    pod2usage( -verbose => 2, -noperldoc => 1);
    exit;
}

# Open the source font
my $f = Font::TTF::Font->open($ARGV[1]) || die "Cannot open TrueType font '$ARGV[1]' for reading.\n";

# Read required tables:
for my $t (qw(cmap maxp post))
{
	die "Required '$t' table is missing from font\n" unless exists $f->{$t};
	$f->{$t}->read;
}

my $numGlyphs = $f->{'maxp'}{'numGlyphs'};

# Allow glyphid to be decimal numeric or a postscript name
my ($gid, $gname);

if ($ARGV[0] =~ /^\d+$/)
{
	# Validate numeric ID
	$gid = $ARGV[0];
	die "Numeric glyph ID '$gid' is out of range\n" if $gid >= $numGlyphs;
	$gname = $f->{'post'}{'VAL'}[$gid];
}
else
{
	# Lookup postscript name
	$gname = $ARGV[0];
	die "Glyph '$gname' not found\n" unless exists $f->{'post'}{'STRINGS'}{$gname};
	$gid = $f->{'post'}{'STRINGS'}{$gname};
}

print "Tracing glyph number $gid ", length($gname) ? "named '$gname' " : "(no glyph name available)) ", "in font file '$ARGV[1]'\n";

=item cmap

cmap subtables are searched for references to the specified glyph. 

=cut

for my $t (@{$f->{'cmap'}{'Tables'}})
{
	my (@codes, $c, $g);
	while (($c, $g) = each %{$t->{'val'}})
	{ push (@codes, $c) if $g == $gid;}
	next unless scalar(@codes);
	print "cmap: $t->{'Platform'} $t->{'Encoding'} $t->{'Format'}:  ", join(',', map {sprintf ("%04X", $_)} @codes), "\n"; 
}

=item loca/glyf

If present (that is, if this a TrueType and not a CFF font), the loca and glyf tables are searched
to identify composite glyph definitions that reference the specified glyph.

=cut

# For TTF fonts: look through composite glyphs for references

if (exists $f->{'loca'})
{

	my @refs;
	
	sub checkGlyph
	{
		my ($glyph, $g) = @_;
		return if $g == $gid || $glyph->{' done'};		# No need to look at target or re-process a glyph
		$glyph->read->{' done'} = 1;					# Assume doesn't reference me
		return if $glyph->{'numberOfContours'} >= 0;	# Ignore non-composites.
		$glyph->read_dat;
		foreach my $comp (@{$glyph->{'comps'}})
		{
			my $g2 = $comp->{'glyph'};
			next if $g2 < 0 || $g2 >= $numGlyphs;	# Bad font structure
			if ($g2 == $gid)
			{
				# Found a direct reference to me!
				$glyph->{' done'} = 2;
				$glyph->{' ref'} = glyphName($g) . ' -> ' . glyphName($gid);
				last;
			}
			my $glyph2 = $f->{'loca'}{'glyphs'}[$g2];
			next unless defined $glyph2;
			checkGlyph($glyph2, $g2) unless $glyph2->{' done'};	#Recurse
			if ($glyph2->{' done'} > 1)
			{
				# Found indirect reference to target
				# print STDERR "INDIRECT Ref: $g2\n";
				$glyph->{' done'} = 2;
				$glyph->{' ref'} = glyphName($g) . ' -> ' . glyphName($g2);
				last;
			}
		}
		push (@refs, $g) if $glyph->{' done'} > 1;
	}
	
	# TrueType outlines
	$f->{'loca'}->read->glyphs_do(\&checkGlyph);

	map {print "glyph $f->{'loca'}{'glyphs'}[$_]{' ref'}\n"}  @refs ;
}

=item GDEF

For fonts that include OpenType smarts, the GDEF table is scanned for references to the specified
glyph in the GlyphClassDef, AttachList, LigatureCarretList, MarkAttachClassDef and MarkGlyphSets structures.

=cut

my (%MarkFilterSets, $MarkAttachClass);

if ($f->{'GDEF'})
{
	my $t = $f->{'GDEF'}->read;
	print "GDEF GlyphClassDef = $t->{'GLYPH'}{'val'}{$gid}\n" if exists $t->{'GLYPH'}{'val'}{$gid};
	print "GDEF MarkAttachList is defined\n" if exists $t->{'ATTACH'}{'COVERAGE'}{'val'}{$gid};
	print "GDEF LigatureCarretList is defined\n" if exists $t->{'LIG'}{'COVERAGE'}{'val'}{$gid};
	if (exists $t->{'MARKS'}{'val'}{$gid})
	{
		$MarkAttachClass = $t->{'MARKS'}{'val'}{$gid};
		print "GDEF MarkAttachClassDef = $MarkAttachClass\n";
	}
	if ($t->{'MARKSETS'})
	{
		foreach my $i (0 .. $#{$t->{'MARKSETS'}})
		{
			if (exists $t->{'MARKSETS'}[$i]{'val'}{$gid})
			{
				$MarkFilterSets{$i} = $t->{'MARKSETS'}[$i]{'val'}{$gid};	# Remmeber which filtersets refer to target glyph
				print "GDEF MarkGlyphSets[$i] = $t->{'MARKSETS'}[$i]{'val'}{$gid}\n";
			}
		}
	} 
}

=item GSUB/GPOS

The GSUB and GPOS tables are scanned for any lookups that reference the target glyph
in coverage tables, class definitions, or input/output sequences. For such lookups, the lookup index 
and additional information about lookup is printed
along with all the script/lang/feature tag combinations that use that lookup.

=cut

foreach my $tag (qw(GSUB GPOS))
{
	next unless $f->{$tag};
	my %lmap;	#mapping of referenced lookups to their parent (contextual chaining)
	my @found;	# List of lookups that directly reference the target glyph
	my $t = $f->{$tag}->read;
	foreach my $li (0 .. $#{$t->{'LOOKUP'}})
	{
		#print "Processing $tag lookup $li...\n";
		my $l = $t->{'LOOKUP'}[$li];
		my $found = 0;
		if ($l->{'FLAG'} & 0x0010 && exists ($MarkFilterSets{$l->{'FILTER'}}))
		{ print "$tag lookup[$li] MarkFilterSet\n"; $found = 1; }
		if ($MarkAttachClass && ($l->{'FLAG'} >> 8) == $MarkAttachClass)
		{ print "$tag lookup[$li] MarkAttachmentClass\n"; $found = 1; }
		foreach my $si (0 .. $#{$l->{'SUB'}})
		{
			my $s = $l->{'SUB'}[$si];
			if (exists $s->{'COVERAGE'} && exists $s->{'COVERAGE'}{'val'}{$gid})
			{print "$tag lookup[$li.$si] Coverage\n"; $found = 1; }   
			foreach my $ctxt (qw (CLASS PRE_CLASS POST_CLASS))
			{
				if (exists $s->{$ctxt} && $s->{$ctxt}{'val'}{$gid} > 0)
				{print "$tag lookup[$li.$si] $ctxt\n"; $found = 1; }
			}
			foreach my $ci (0 .. $#{$s->{'RULES'}})
			{
				for my $r (@{$s->{'RULES'}[$ci]})
				{
					if (exists $r->{'ACTION'})
					{
						if ($s->{'ACTION_TYPE'} =~ /[agr]/ && $tag eq 'GSUB')
						{
							if (scalar(grep($gid == $_, @{$r->{'ACTION'}})))
							{print "$tag lookup[$li.$si.$ci] Action\n"; $found = 1; }
						}
						elsif ($s->{'ACTION_TYPE'} eq 'l')
						{
							# Map referenced lookups to this one
							map { $lmap{$_->[1]}{$li} = 1 if $_ > 0} @{$r->{'ACTION'}};
						}
					}
					for my $ctxt (qw (MATCH PRE POST))
					{
						next unless exists $r->{$ctxt};
						if ($s->{'MATCH_TYPE'} eq 'g')
						{
							if (scalar(grep($gid == $_, @{$r->{$ctxt}})))
							{print "$tag lookup[$li.$si.$ci] ", ucfirst(lc($ctxt)), "\n"; $found = 1; }
						}
						elsif ($s->{'MATCH_TYPE'} eq 'c')
						{
						}
						elsif ($s->{'MATCH_TYPE'} eq 'o')
						{
							foreach my $c (@{$r->{$ctxt}})
							{
								if (defined($c) && exists $c->{'val'}{$gid})
								{print "$tag lookup[$li.$si.$ci] ", ucfirst(lc($ctxt)), "\n"; $found = 1; }
							}
						}
					}
				}
			}
			if ($s->{'ACTION_TYPE'} eq 'o' && $tag eq 'GSUB' && exists $s->{'COVERAGE'}{'val'}{$gid - $s->{'ADJUST'}})
			{print "$tag lookup[$li.$si] DeltaID\n"; $found = 1; }
		}
		
		push @found, $li if $found;	# For now just keep a list of direct references.
	}
	
	foreach my $li (@found)
	{
		# Some lookups referenced the glyph -- find out where the lookups are used:
		my @where;
		for my $stag (sort {$a cmp $b}keys $t->{'SCRIPTS'})
		{
			my $s = $t->{'SCRIPTS'}{$stag};
			for my $ltag ('DEFAULT', @{$s->{'LANG_TAGS'}})
			{
				my $lang = $s->{$ltag};
				foreach my $ftag (@{$lang->{'FEATURES'}})
				{
					#print "$stag/$ltag/$ftag lookups: ", join(',', @{$t->{'FEATURES'}{$ftag}{'LOOKUPS'}}), "\n";
					#print "  found ", scalar(grep($l == $_, @{$t->{'FEATURES'}{$ftag}{'LOOKUPS'}})), "\n";
					my $where = $ftag;
					$where =~ s/ .*$//;
					$where = "$stag/$ltag/$where";
					$where =~ s/ //g;
					foreach my $from (@{$t->{'FEATURES'}{$ftag}{'LOOKUPS'}})
					{
						my $route = lookupRoute ($from, $li);
						push @where, "$where -> lookup $route" if $route;
					}
				}
			}
		}
		if (scalar(@where))
		{	map {print "$tag $_\n"} @where;	}
		else
		{	print "$tag lookup[$li] UNUSED!\n";	}
	}

	# recursively identify route through chained lookups
	sub lookupRoute
	{
		my ($from, $to) = @_;
		return "$to" if $from == $to;
		foreach my $parent (keys %{$lmap{$to}})
		{
			my $route = lookupRoute($from, $parent);
			return "$route->$to" if $route;
		}
		return undef;
	}
}


# Done

print "Done.\n";

sub glyphName
{
	my $gid = shift;
	my $gname = $f->{'post'}{'VAL'}[$gid];
	return defined $gname ? "$gid/$gname" : $gid;
}

=back

=head1 BUGS

Does not understand CFF (Postscript-flavored) glyph outlines, and does not 
process all font tables that might be of interest.

=head1 AUTHOR

Bob Hallissy, SIL International.


=head1 LICENSING

Copyright (c) 1998-2014, SIL International (http://www.sil.org) 

This module is released under the terms of the Artistic License 2.0. 
For details, see the full text of the license in the file LICENSE.

=cut