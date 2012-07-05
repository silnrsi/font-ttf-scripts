#! /usr/bin/perl
use Font::TTF::Font;
use IO::File;
use Getopt::Std;

getopts('e:i:l:n:p:');

unless (defined $ARGV[1] && defined $opt_p && defined $opt_n && defined $opt_l)
{
    die <<'EOT';
    TTFADDNAME -n num -l lang -p platform -e enc infile outfile < text
Adds a name of given number, language and platform to the font. Text is
assumed to be in UTF8.
EOT
}

$in = IO::File->new("<$opt_i");

$f = Font::TTF::Font->open($ARGV[0]) || die "Can't open $ARGV[0]";
$f->{'name'}->read;

while(<$in>)
{
    print ":$_:";
    use UTF8;
    s/^\x{FEFF}//o if ($. == 1);
    $t .= $_;
}

$f->{'name'}{'strings'}[$opt_n][$opt_p][$opt_e]{$opt_l} = $t;

$f->out($ARGV[1]);

