#!/usr/bin/perl

use Font::TTF::Font;
use Getopt::Std;

getopts('f');

$font = Font::TTF::Font->open($ARGV[0]);
$font->tables_do(sub { $_[0]->read; });
if ($opt_f)
{ $font->{'loca'}->glyphs_do(sub { $_[0]->read_dat; }); }
else
{ $font->{'loca'}->glyphs_do(sub { $_[0]->read; }); }
$font->out($ARGV[1]);
