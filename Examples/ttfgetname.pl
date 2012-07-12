#! /usr/bin/perl
use strict;
use open OUT=>':utf8'; 
use Font::TTF::Font;
use Getopt::Std;

our ($opt_a,$opt_o,$VERSION);

getopts('ao:');
$VERSION = '0.1'; # original 

unless ($#ARGV == 1 and $ARGV[0] =~ /^\d+$/)
{
    die <<"EOT";

ttfgetname [-a][-o outputfile] number fontfile

Extracts a string from the name table in fontfile based on number supplied and displays on screen.

Options:

 -o    Output to file instead of screen
 -a    Output all values for the string with corresponding pid, eid and lid values

Version $VERSION
EOT
}

my ($number, $Font) = @ARGV;
if ($opt_o) {
	unless (open (STDOUT,">:utf8", $opt_o)) {die ("Could not open $opt_o for output");}
	binmode STDOUT;
}

# Open font and read the name table
my $f = Font::TTF::Font->open($Font) || die ("Couldn't open TTF '$Font'\n");
my $name_table = $f->{'name'}->read;

if (not $opt_a) { # Find the first copy of the string based on the find_name sub in name.pm
	my ($name);
	$name = $name_table->find_name($number);
	unless ($name) {die("Could not find string in name table for id: $number\n");}
	print $name, "\r\n";
}
else { # loop round finding all copies of the string
	my $params = $name_table->{'strings'}[$number];
	unless (ref($params)) {die("Could not find string in name table for id: $number\n");}
	my ($pid,$eid,$lid);
	foreach $pid (0 .. $#{$name_table->{'strings'}[$number]}) {
 		foreach $eid (0 .. $#{$name_table->{'strings'}[$number][$pid]}) {
			foreach $lid (sort keys %{$name_table->{'strings'}[$number][$pid][$eid]}) {
				print "Platform ID: $pid, Encoding ID: $eid, Language ID: $lid \r\n";
				print $name_table->{'strings'}[$number][$pid][$eid]{$lid},"\r\n\r\n";
			}
		}
	}
}	