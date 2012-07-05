#! /usr/bin/perl

# 0.3	RMH  2003-11-05	Incorporated MH's improvements of 2002-10-08 including -q
# 0.2	RMH  2002-10-07	Only ligature components after 1 get index added to AP names
# 0.1   RMH  2002-07-11 Export VOLT anchor definitions to XML

use strict;

use Font::TTF::Font;
use Getopt::Std;

our ($opt_f, $opt_p, $opt_q);
getopts('fpq');

unless ($#ARGV == 1)
{
    die <<'EOT';

    VoltExportAnchors [-f] [-p] [-q] ( inVolt.vtp | inVolt.ttf ) outAnchors.xml

Exports VOLT anchor definitions to XML in TTFBuilder syntax.
Input can be either a VOLT project file or a TTF font file.

    -f maps VOLT's mark naming convention to FontLabs
    -p assumes VOLT's glyph names are same as font's PS names.
	-q quiet. Don't generate unnecessary noise.

For components (other than the first) of ligatures, anchor names
will have a component index appended to them.

Version 0.3, 2003-11-05
EOT
}

my ($warningCount);

# Sub to print warning messages to console and log. 1st parm is the message.
# 2nd param, if supplied, is a line number (from the volt source).

sub MyWarn {
	my ($msg, $line) = @_;
	$warningCount++;
	if (defined $line) {
		print LOG "line $line: " . $msg;
		warn "line $line: " . $msg;
	} else {
		print LOG $msg;
		warn $msg;
	}
}


my ($inSrc, $outXML);

($inSrc, $outXML) = @ARGV;

my ($Src, $SrcLine);	# Input VOLT source (slurped in as one long string), and line number counter


# For each GDEF record in the VOLT source, a structure
# is created using an anonymous hash. Gdef structures have these elements:
#
#    'NAME'
#    'ID'
#    '@UNICODES'    a referemce to an array of Unicode values
#				NB: for Glyph structures, these are Unicode values for the new font (i.e., from the cmap)
#				and for Gdef structures these are Unicode values from the old font (i.e., from the VOLT source)
#    'UNICODE' or 'UNICODEVALUES'  string values from the GDEF line (sans quote marks)
#    'TYPE'			string value from GDEF line
#    'COMPONENTS'	string value from GDEF line
#    'LINE'       linenumber from source
#
# When processing the Anchor defs, we add:
#	'attachmentpoints' a reference to a hash, keyed by anchor point name, containing
#		an array, one per ligature component, of references to hashes containing:
#			'x'			x location of attachment
#			'y'			y location of attachment
#			'line'		VOLT source line
#
my (%GdefFromID, %GdefFromName, %GdefFromGdefUnicode);	

my $f;		# TTF font instance
my $g;		# Reference to glyph structure
my $d;		# Reference to GDEF structure

my ($gid, $gname, $u);	# Glyph ID, Glyph name, and Unicode
my ($anchor, $anchorName);	# Anchor structure, anchor name
my ($component, $x, $y);	# Anchor attributes

my $xx;		# Temp variable

# Open logfile:
open (LOG, "> VoltExportAnchor.log") or die "Couldn't open 'VoltExportAnchor.log' for writing, stopping at";
print LOG "STARTING VoltExportAnchor $inSrc $outXML\n\n";

# Open output XML file:
open (OUT, ">" . $outXML) or die "Couldn't open '$outXML' for writing, stopping at";

# Open and slurp VOLT source into $Src:

if ($inSrc =~ /\.ttf$/i) {
	# VOLT source should be extracted from an existing font:
	my $f = Font::TTF::Font->open($inSrc) or die("Unable to open file '$inSrc' as a TrueType font\n");
	exists $f->{'TSIV'} or die "Cannot find VOLT source table in file '$inSrc'.\n";
	$f->{'TSIV'}->read_dat;
	$Src = $f->{'TSIV'}{' dat'};
	$f->release;
} else {
	# VOLT source is in a plain text file:
	open(IN, $inSrc) or die "Couldn't open '$inSrc' for reading, stopping at";
	$/ = undef;		# slurp mode for read:
	$Src = <IN>;
	close IN;
	$/ = "\n";
}

sub GetSrcLine {
	# Returns one line of text from the source, or undef if nothing left.
	# If the source was extracted from VOLT, the separators will be \r
	# If the source was read from CRLF delimited file, the separator will be \n
	# Need to allow either separator, but we don't return the terminator:
	return undef if $Src eq "";
	$SrcLine++;		# Keep track of line number in source.
	my $res;
	($res, $Src) = split (/\r|\n/, $Src, 2);
	return $res;
}


my $state;	# 0 = no GDEFS yet; 1 = reading GDEFS; 2 = finished GDEFS

 

$state = 0;
SRCLOOP: while (defined ($_ = GetSrcLine)) {

	if (/^DEF_GLYPH/) {

		# PROCESS GDEF LINE:
		
		# GDEF information is accumulated until
		# we have it all. 

		if ($state == 2) {
			MyWarn "Unexpected DEF_GLYPH\n", $SrcLine;
			next SRCLOOP;
		}

		$state = 1;	# remember we are doing GDEFS now.
		
		# Extract important info from GDEF. Note the text lines are essentially in hash form already, e.g.:
		# DEF_GLYPH "U062bU062cIsol" ID 1097 UNICODE 64529 TYPE LIGATURE COMPONENTS 2 END_GLYPH
		# or
		# DEF_GLYPH "middot" ID 167 UNICODEVALUES "U+00B7,U+2219" TYPE BASE END_GLYPH
		# so it is easy to construct a hash:

		($xx = $_) =~ s/ END_GLYPH.*//;	# Remove end line sequence
		$xx =~ s/DEF_GLYPH/NAME/;		# Change DEF_GLYPH to NAME so we get correct structure variables
		$d = {split(' ', $xx)};			# Create GDEF structure
		$d->{'LINE'} = $SrcLine;

		# members of the hash at this point are:
		#	NAME	name of glyph
		#	ID		glyph ID
		#	UNICODE	decimal unicode value (optional), or
		#	UNICODEVALUES comma-separated list of Unicode values in U+nnnn string format
		#	TYPE	one of SIMPLE, MARK, or LIGATURE (optional)
		#	COMPONENTS	number of components in ligature (optional)
		#	LINE		line number from source


		if (not (exists $d->{'NAME'} and exists $d->{'ID'})) {
			MyWarn "Incomprehensible DEF_GLYPH\n", $SrcLine;
			next SRCLOOP;
		}
			
		# Some beta versions of VOLT didn't quote the glyph names, so let's make the quotes optional:
		$d->{'NAME'} =~ s/^\"(.*)\"$/$1/;

		$gname = $d->{'NAME'};
		$gid = $d->{'ID'};

		if (exists $GdefFromID{$gid}) {
			MyWarn "Glyph # $gid defined more than once in source -- second definition ignored\n", $SrcLine; 
			next SRCLOOP;
		};

 		# Coalesce UNICODE or UNICODEVALUES, if present, into @UNICODES array
		if (exists $d->{'UNICODE'}) {
			# Create array with one element:
			$d->{'@UNICODES'} = [ $d->{'UNICODE'} ];		
		} elsif (exists $d->{'UNICODEVALUES'}) {
			# Have to parse comma-separate list such as "U+00AF,U+02C9". But first get rid of quotes:
			$d->{'UNICODEVALUES'} =~ s/^\"(.*)\"$/$1/;
			$d->{'@UNICODES'} = [ map { hex (substr($_,2))} split (",", $d->{'UNICODEVALUES'})]; 
		}

		if ($gname =~ /^glyph\d+$/) {
			# GDEF includes a generic name -- we can only do so much at this point:
			$GdefFromID{$gid} = $d;							# Able to look up by GID
			if (exists $d->{'@UNICODES'}) {					# Able to lookup by Unicode
				foreach $u (@{$d->{'@UNICODES'}}) { $GdefFromGdefUnicode{$u} = $d;}
			}
			
			delete $d->{'NAME'};		# discard the generic name
			next SRCLOOP;
		}

		if (exists $GdefFromName{$gname}) {
			MyWarn "Glyph '$gname' defined more than once in source -- second definition ignored\n", $SrcLine;
			next SRCLOOP;
		}

		# Finally ... we can save this GDEF information
		$GdefFromID{$gid} = $d;								# Able to look up by GID
		$GdefFromName{$gname} = $d;							# Able to look up non-generic names only
		if (exists $d->{'@UNICODES'}) {						# Able to lookup by Unicode
			foreach $u (@{$d->{'@UNICODES'}}) { $GdefFromGdefUnicode{$u} = $d;}
		}		
		next SRCLOOP;
	} 

	# PROCESS ALL OTHER KINDS OF LINES:

	if ($state == 1) {
		$state = 2;	# remember we are done with GDEFS now.
	}

	# Throw away any null bytes (typically at the end of the table):
	next SRCLOOP if /^\0+$/;
	
	if (/^DEF_ANCHOR (\S+).* ON (\d+) /) {
		# need to convert anchordefs to XML. A typical definition is:

		# DEF_ANCHOR Below ON 553 COMPONENT 1 LOCKED AT  POS DX 312 DY -540 END_POS END_ANCHOR

		# Note: Newer versions of VOLT include a glyph name and put name in quotes:

		# DEF_ANCHOR "Below" ON 553 GLYPH gname COMPONENT 1 LOCKED AT  POS DX 312 DY -540 END_POS END_ANCHOR

		# Glyph name is not (currently) in quotes, but probably should be. This glyph name and the "ON"
		# glyph ID are mutually redundant with the DEF_GLYPH records, so why both? And what happens if
		# they disagree? Currently, the ON field is required (if it is absent, even if the GLYPH field
		# is present, VOLT resets the Anchor data to empty), so rather than risk an inconsistency I'm 
		# going to strip out the GLYPH field:
		
		# pull out the name and glyph number from anchor definition
		$anchorName = $1;
		$gid = $2; 
		
		# Some versions of VOLT don't quote the anchor names, so let's make the quotes optional:
		$anchorName =~ s/^\"(.*)\"$/$1/;

		# Unlike the GDEF lines, the anchor lines don't parse into a nice hash. And 
		# I don't know if DX and DY have to be in that order,so pick them off individually:
		($x) = m/\s+DX\s+([+-]?\d+)\s+/o; 
		($y) = m/\s+DY\s+([+-]?\d+)\s+/o;
		$x ||= '0';
		$y ||= '0';
		($component) = m/ COMPONENT (\d+) /o;
		if (exists $GdefFromID{$gid}{'attachmentpoints'}{$anchorName}[$component]) {
			MyWarn "Duplicate anchor '$anchorName' defined for component $component of GID $gid \"$GdefFromID{$gid}{'NAME'}\"; second ignored.\n", $SrcLine;
			next SRCLOOP;
		}
		if ($component > 1 and $component > $GdefFromID{$gid}{'COMPONENTS'}) {
			MyWarn "Anchor defined for nonexistent component $component of GID $gid \"$GdefFromID{$gid}{'NAME'}\"; GDEF modified\n", $SrcLine;; 
			$GdefFromID{$gid}{'COMPONENTS'} = $component;
		}
		
		# Save this anchor:
		$GdefFromID{$gid}->{'attachmentpoints'}{$anchorName}[$component] = {name => $anchorName, x => $x, y => $y, line => $SrcLine};
		next SRCLOOP;
	} 	
}			

# OK, now we can emit the XML:

print OUT "<font>\n";
for $gid (sort {$a <=> $b} keys(%GdefFromID)) {
	next if not exists $GdefFromID{$gid}{'attachmentpoints'};
	print OUT "  <glyph";
	if ($opt_p and exists $GdefFromID{$gid}{'NAME'})
    { print OUT " PSName=\"$GdefFromID{$gid}{'NAME'}\""; }
    if (exists $GdefFromID{$gid}{'@UNICODES'}[0])
    { printf OUT (" UID=\"%04X\"", $GdefFromID{$gid}{'@UNICODES'}[0]); }
    print OUT " GID=\"$gid\">\n";
	while (($anchorName, $anchor) = each %{$GdefFromID{$gid}{'attachmentpoints'}}) {
		# get name and, if desired, map to Fontlab convention:
		my $newName = $anchorName;
		$newName =~ s/^MARK// if $opt_f;
		# Loop through all components:
		for $component (1 .. ($GdefFromID{$gid}{'COMPONENTS'} || 1)) {
			next if not defined $anchor->[$component];
			printf OUT "        <point type=\"%s\"><location x=\"%s\" y=\"%s\"%s/></point>\n",
				$newName . ($component > 1 ? $component : ""), $anchor->[$component]{'x'}, $anchor->[$component]{'y'},
				    $opt_q ? '' : " VOLTsrc=\"$anchor->[$component]{'line'}\"";
		}
	}
	print OUT "  </glyph>\n";
}
print OUT "</font>\n";

close OUT;

my $xx = "\nFINISHED. ";
$xx .= ($warningCount > 0 ? $warningCount : "No") . " warning(s) issued. ";
print LOG $xx;
close LOG;

printf "%s%s\n", $xx, ($warningCount > 0) ? " See VoltExportAnchor.log for details." : "" unless $opt_q;

__END__

=head1 TITLE

VoltExportAnchors - 

=head1 SYNOPSIS

  VoltExportAnchors [-f] [-p] [-q] ( inVolt.vtp | inVolt.ttf ) outAnchors.xml

=head1 OPTIONS

  -f maps VOLT's mark naming convention to FontLabs
  -p assumes VOLT's glyph names are same as font's PS names.
  -q quiet. Don't generate unnecessary noise.

=head1 DESCRIPTION

Exports VOLT anchor definitions to XML in TTFBuilder syntax.
Input can be either a VOLT project file or a TTF font file.

For components (other than the first) of ligatures, anchor names
will have a component index appended to them.

=head1 SEE ALSO

ttfbuilder, make_volt, volt2xml

=cut
