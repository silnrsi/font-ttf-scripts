use Font::TTF::Font;
use Getopt::Std;

getopts('t:');

$f = Font::TTF::Font->open($ARGV[0]);
delete $f->{$opt_t};
$f->out($ARGV[1]);

