use Font::TTF::Font;
use Getopt::Std;

getopts('t:');

$f = Font::TTF::Font->open($ARGV[0]);

# Remove tables the user doesn't want:
for (split(/,\s*/, $opt_t)) { delete $f->{$_} };

$f->out($ARGV[1]);

