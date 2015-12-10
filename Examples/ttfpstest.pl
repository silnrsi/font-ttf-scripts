use	strict;
use	Font::TTF::Font;
use	Font::TTF::PSNames qw(parse);
use Getopt::Std;
use Pod::Usage;

our ($opt_c, $opt_h, $opt_v);

getopts('chv');

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

foreach my $filename (@ARGV)
{
	my $f	=	Font::TTF::Font->open($filename);
	unless ($f)
	{
		warn "Can't open font '$filename'";
		next;
	}
	
	print "Processing font file: '$filename'...\n" if $#ARGV > 0;

	unless ($f->{'post'}) 
	{
		warn "No post table\n";
		next;
	}
	unless (!($opt_c || $opt_v) || $f->{'cmap'} && $f->{'cmap'}->read->find_ms) 
	{
		warn "No suitable cmap table\n";
		next;
	}
	my $post = $f->{'post'}->read->{'VAL'}; # Array of	pname	index	by gid 
	my $cmap = $f->{'cmap'}->find_ms->{'val'} if $opt_c || $opt_v;
	
	for	my $gid (0	.. $f->{'maxp'}{'numGlyphs'}-1)
	{
		my $psname = $post->[$gid];
		if (length($psname) > 0)
		{
			my ($uids, $exts);
			($uids,	$exts) = parse ($psname);
			my $n_uids = scalar(@{$uids});
			my $n_exts = scalar(@{$exts});
			if ($n_uids > 0)
			{
				#	Name is	OK -- make sure cmap agrees
				my $uid = $uids->[0];
				if ($opt_c && $n_uids == 1 && $n_exts == 0 && $cmap->{$uid} != $gid) {
					my $usv = sprintf("U+%04X", $uid);
					print "$gid '$psname' maps to $usv, but cmap says $usv points to $post->[$cmap->{$uid}]\n";
				}
				elsif ($opt_v)
				{
					print "$gid '$psname' maps to U+", join("+", map {sprintf "%04X", $_} @{$uids}), "\n";
				}
			}
			elsif ($psname =~ /^(.notdef|.null|nonmarkingreturn)$/)
			{
				# These glyph names are automatically OK though they don't usually get encoded so
				# they don't have USVs 
				print "$gid '$psname' is valid\n" if $opt_v;
			}
			else
			{
				print	"$gid '$psname' is not a recognized Adobe Glyph List name\n";
			}
		}
		else
		{
			print "$gid has no postscript name\n";
		}
	}
	$f->release;
}

=head1 TITLE

ttfpstest - verifies all glyph names are AGL-conforming

=head1 SYNOPSIS

  ttfpstest [-c] [-v] infile.ttf ...
  ttfprintot -h

Writes to STDOUT information about any glyphs whose names would not be recognized
by a Postscript interpreter (because they are non-conforming or aren't in Adobe's
official list of registered glyph names.

=head1 OPTIONS

  -c   verify cmap encoding
  -v   include all glyphs in output
  -h   print full help message

=head1 DESCRIPTION

For each font file supplied on the command line, ttfpstest scans the post table
looking for potential glyph naming problems.

Each glyph name is tested to see if it conforms to the AGLFN (Adobe Glyph Naming for New Fonts) standard. 

With the -c option, then for glyph names that have no extensions (such as ".ss04") and represent a 
single Unicode character (i.e. not a ligature), the program verifies that the cmap entry for that 
Unicode character is, in fact, that glyph. 

All descrepancies are written to STDOUT.

The -v option causes something to be written to STDOUT for every glyph.

=head1 AUTHOR

Bob Hallissy L<http://scripts.sil.org/FontUtils>.
(see CONTRIBUTORS for other authors).

=head1 LICENSING

Copyright (c) 2015, SIL International (http://www.sil.org)

This script is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.

=cut