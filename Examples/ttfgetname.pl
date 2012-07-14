#! /usr/bin/perl
use strict;
use open OUT=>':utf8'; 
use Font::TTF::Font;
use Getopt::Std;

our ($opt_a,$opt_o,$VERSION);

getopts('ao:');
$VERSION = '0.2'; # BH: Added support for multiple ID numbers
#$VERSION = '0.1'; # original 

unless ($#ARGV == 1 and $ARGV[0] =~ /^(?:\d|,|\.)+$/)
{
    die <<"EOT";

ttfgetname [-a][-o outputfile] number(s) fontfile

Extracts one or more strings from the name table in fontfile based on name ID number(s) supplied.
If a single number is supplied, program warns if the name table does not contain that string.
Ranges and/or lists of name ID numbers may be supplied, e.g. "2..5,8,10".

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

my @numbers = eval("($number,)");

# Open font and read the name table
my $f = Font::TTF::Font->open($Font) || die ("Couldn't open TTF '$Font'\n");
my $name_table = $f->{'name'}->read;

for $number (@numbers) {
	print "String ID: $number\r\n" if @numbers > 1;
	if (not $opt_a) { # Find the first copy of the string based on the find_name sub in name.pm
		my ($name);
		$name = $name_table->find_name($number);
		if ($name) {
			print $name, "\r\n";
			next;
		}
	}
	else { # loop round finding all copies of the string
		my $params = $name_table->{'strings'}[$number];
		if (ref($params)) {
			my ($pid,$eid,$lid);
			foreach $pid (0 .. $#{$name_table->{'strings'}[$number]}) {
		 		foreach $eid (0 .. $#{$name_table->{'strings'}[$number][$pid]}) {
					foreach $lid (sort keys %{$name_table->{'strings'}[$number][$pid][$eid]}) {
						print "Platform ID: $pid, Encoding ID: $eid, Language ID: $lid \r\n";
						print $name_table->{'strings'}[$number][$pid][$eid]{$lid},"\r\n\r\n";
					}
				}
			}
			next;
		}
	}
	warn("Could not find string in name table for id: $number\n") unless @numbers > 1;	
}	