#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

system("perl", "scripts/fret", "-d", "1000000000", "t/testfont.ttf");
$res = compare("t/testfont.pdf", "t/base/testfont.pdf");
ok (!$res);
unlink "t/testfont.pdf" unless ($res);

