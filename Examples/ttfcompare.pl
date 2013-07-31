#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Getopt::Std;

our ($opt_a,$opt_f,$opt_o,$opt_t,$VERSION);

getopts('aft:o:');
$VERSION = '0.2'; # original 

unless ($#ARGV == 1)
{
    die <<"EOT";

ttfcompare [-a] [-f] [-o outputfile] [-t table] fontfile1 fontfile2

Compares all values in the specified table between the two fonts and displays 
differences on screen. Currently works for name, cmap and post tables only.  

If no table is specified, compares checksums and lengths of all tables.

With the name table, by default it shows just one per Name ID and the 
first 100 characters of each string

Options:

 -a    Show all occurences per Name ID (name table only)
 -f    Display the full string instead of just 100 characters (name table only)
 -o    Output to file instead of screen
 
Version $VERSION
EOT
}

my %subs_table = ( name => \&namesub, post => \&postsub, cmap => \&cmapsub, x => \&csumsub );

my ($font1, $font2) = @ARGV;
if ($opt_o) {
	unless (open (STDOUT, ">$opt_o")) {die ("Could not open $opt_o for output")} ;
}

$opt_t ||= 'x';	# If not supplied, just do table checksum/length
unless ($subs_table{$opt_t}) {die "Invalid table name"}

# Open fonts and read the tables
my $f1 = Font::TTF::Font->open($font1) || die ("Couldn't open TTF '$font1'\n");
my $table1 = $f1->{$opt_t}->read unless $opt_t eq 'x';
my $f2 = Font::TTF::Font->open($font2) || die ("Couldn't open TTF '$font2'\n");
my $table2 = $f2->{$opt_t}->read unless $opt_t eq 'x';

# Produce output versions of font names without .ttf and padded to same length
my $if1 = index( $font1, ".ttf");
$if1 = $if1==-1 ? 0 : $if1;
my $if2 = index( $font2, ".ttf");
$if2 = $if2==-1 ? 0 : $if2;
my $maxif = $if1>=$if2 ? $if1 : $if2;
my $fname1 = substr ( $font1, 0, $if1 );
my $fname2 = substr ( $font2, 0, $if2 );
my $fpad1 = $fname1 . substr( "                ",0,$maxif-$if1);  
my $fpad2 = $fname2 . substr( "                ",0,$maxif-$if2);

# Run the subroutine based on the table name

$subs_table{$opt_t}->();

# Main subroutines - one for each table

sub namesub {

  my @namedesc = setnamedesc();
  my ($nid,$pid,$eid,$lid,$maxid1,$maxid2,$maxnid,$maxpid,$maxeid,@lkeys,$prevlid,$n1,$n2);
  
  # Loop round comparing values, allowing for some values only being in one of the name tables
  $maxid1 = $#{$table1->{'strings'}};
  $maxid2 = $#{$table2->{'strings'}};
  $maxnid = $maxid1 >= $maxid2 ? $maxid1 : $maxid2;
  
  NID: foreach $nid(0 .. $maxnid) {
  	$maxid1 = $#{$table1->{'strings'}[$nid]};
  	$maxid2 = $#{$table2->{'strings'}[$nid]};
  	$maxpid = $maxid1 >= $maxid2 ? $maxid1 : $maxid2;
  	foreach $pid (0 .. $maxpid) {
  		$maxid1 = $#{$table1->{'strings'}[$nid][$pid]};
  		$maxid2 = $#{$table2->{'strings'}[$nid][$pid]};
  		$maxeid = $maxid1 >= $maxid2 ? $maxid1 : $maxid2;
   		foreach $eid (0 .. $maxeid) {
   			@lkeys = sort (  keys %{$table1->{'strings'}[$nid][$pid][$eid]},  keys %{$table2->{'strings'}[$nid][$pid][$eid]}  );
   			$prevlid="";
   			foreach $lid (@lkeys) {
   				next if ($lid eq $prevlid); # @keys will have two copies of all keys that are in both name tables
   				$prevlid = $lid;
  				$n1 = $table1->{'strings'}[$nid][$pid][$eid]{$lid};
  				$n2 = $table2->{'strings'}[$nid][$pid][$eid]{$lid};
  				if ($n1 ne $n2) {
  					print "Name ID: $nid";
  					if ($namedesc[$nid]) {print " ($namedesc[$nid])";}
  					print ", Platform ID: $pid, Encoding ID: $eid, Language ID: $lid \n";
  					if (not $opt_f) {
  						if (length($n1) > 100) {$n1 = substr ($n1,0,100)."...";}
  						if (length($n2) > 100) {$n2 = substr ($n2,0,100)."...";}
  					}	
  					print "  $fpad1: $n1 \n";
  					print "  $fpad2: $n2 \n\n";
  					next NID if (not $opt_a);
  				}
  			}
  		}
  	}
  }
}

sub cmapsub {
  	
  my @tables1 = $table1->{'Tables'};
  my $num1 = $table1->{'Num'};
  my @tables2 = $table2->{'Tables'};
  my $num2 = $table2->{'Num'};
  
  # Loop round to find matching tables, reporting any tables in only one of the fonts
  
  my $tab1 = 0;
  my $tab2 = 0;
  
  while ( $tab1<$num1 || $tab2 < $num2 ) {
  	my $subt1 = @tables1[0]->[$tab1];
  	my $subtest1 = &cmapsubtest($subt1); # Get value to check sub-tables are for same platform etc
  	my $subt2 = @tables2[0]->[$tab2];
  	my $subtest2 = &cmapsubtest($subt2);
  	if ($subtest1 < $subtest2) {
  		print "Sub-table only found in $fname1:\n";
  		print "  Platform: $subt1->{'Platform'}, Encoding: $subt1->{'Encoding'}, Format: $subt1->{'Format'}\n";
  		++$tab1;
  		next;
  	}
  	elsif ($subtest2 < $subtest1) {
  	  print "Sub-table only found in $fname2:\n";
  		print "  Platform: $subt2->{'Platform'}, Encoding: $subt2->{'Encoding'}, Format: $subt2->{'Format'}\n";
  		++$tab2;
  		next;
  	}	
  	print "Comparing sub-tables for:";
  	print "  Platform: $subt1->{'Platform'}, Encoding: $subt1->{'Encoding'}, Format: $subt1->{'Format'}\n";
  	my $val1 = $subt1->{'val'};
  	my $val2 = $subt2->{'val'};
  	my @codes = sort ( keys %{$val1},  keys %{$val2} );
  	my $prevcode=0;
  	my $difffound=0;
  	my ($code,$g1,$g2);
  	foreach $code (@codes) {
  		next if ($code eq $prevcode); # @keys will have two copies of all keys that are in both name tables
  		$prevcode = $code;
  		$g1 = $val1->{$code};
  		$g2 = $val2->{$code};
  		if ($g1 ne $g2) {
  			++$difffound;
  			#print ">$g1<\n";
  			#print ">$g2<\n";
  			$code = sprintf("%*X",6, $code);
  			$g1 = $g1 eq "" ? "      " : sprintf ("%*d",6, $g1);
  			$g2 = $g2 eq "" ? "      " : sprintf ("%*d",6, $g2);
  			print "Code: $code,   $fname1 glyph: $g1,   $fname2 glyph: $g2\n";
  		}
  	}
  	print "  $difffound differences found\n\n";
  	++$tab1;
  	++$tab2;
  }
}

sub postsub {

  my @pval1 = @{$table1->{'VAL'}};
  my @pval2 = @{$table2->{'VAL'}};
  
  my $difffound=0;
  my ($gnum,$gshow,$p1,$p2);
  foreach $gnum (0 .. 10) {
  	$p1 = $pval1[$gnum];
  	$p2 = $pval2[$gnum];
  	if ($p1 ne $p2) {
  		++$difffound;
  		$gshow = sprintf("%6d", $gnum);
  		$p1 = $p1 eq "" ? "      " : sprintf ("%20s", $p1);
  		$p2 = $p2 eq "" ? "      " : sprintf ("%20s", $p2);
  		print "Glyph: $gshow,   $fname1: $p1,   $fname2: $p2\n";
  	}
  }	
  print "  $difffound differences found\n\n";
}

sub csumsub {
	my %alltags;
	map { $alltags{$_}=1 } grep { length($_) == 4 } (keys(%{$f1}), keys(%{$f2}));
	my $difffound = 0;
	foreach my $tag (sort keys(%alltags))
	{
		if (!exists $f1->{$tag})
		{
			print "$tag  missing\n";
		}
		elsif (!exists $f2->{$tag})
		{
			print "$tag                   missing\n";
		}
		elsif ($f1->{$tag}{' CSUM'} != $f2->{$tag}{' CSUM'} || $f1->{$tag}{' LENGTH'} != $f2->{$tag}{' LENGTH'})
		{
			printf "%s  %8X / %-6d %8X / %-6d\n", $tag, $f1->{$tag}{' CSUM'}, $f1->{$tag}{' LENGTH'}, $f2->{$tag}{' CSUM'}, $f2->{$tag}{' LENGTH'};
		}
		else
		{
			next;
		}
		$difffound++;
	}
  print "  $difffound differences found\n\n";
}


# Other subroutines, called by main subroutines

sub cmapsubtest {
	# Creates value to compare cmap sub-tables to see if Platform, encoding and format match
	my $subtable = @_[0];
	my $p = $subtable->{'Platform'};
	my $e = $subtable->{'Encoding'};
	my $f = $subtable->{'Format'};
	my $ret = $p * 10000 + $e * 100 + $f;
	return $ret == 0 ? 999999 : $ret;
}

sub setnamedesc {
	my @namedesc;
  $namedesc[0] = "Copyright";
  $namedesc[1] = "Font Family";
  $namedesc[2] = "Font Subfamily";
  $namedesc[3] = "Unique identifier";
  $namedesc[4] = "Full font name";
  $namedesc[5] = "Version";
  $namedesc[6] = "Postscript name";
  $namedesc[7] = "Trademark";
  $namedesc[8] = "Manufacturer";
  $namedesc[9] = "Designer";
  $namedesc[10] = "Description";
  $namedesc[11] = "Vendor URL";
  $namedesc[12] = "Designer URL";
  $namedesc[13] = "License Description";
  $namedesc[14] = "License URL";
  $namedesc[15] = "Reserved";
  $namedesc[16] = "Preferred Family";
  $namedesc[17] = "Preferred Subfamily";
  $namedesc[18] = "Compatible Full";
  $namedesc[19] = "Sample text";
  $namedesc[20] = "PostScript CID findfont name";
  $namedesc[21] = "WWS Family Name";
  $namedesc[22] = "WWS Subfamily Name";
  return @namedesc;
  # The above could be simplified, but this self-documents the mapping from ID to string!
}