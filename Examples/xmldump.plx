#!/usr/bin/perl

use Font::TTF::Font;
use Getopt::Std;

getopts('n');

$f = Font::TTF::Font->open($ARGV[0]);
$f->{'loca'}->read unless ($opt_n);
$f->out_xml($ARGV[1]);

