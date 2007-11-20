#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

system("scripts/fret", "-d", "1000000000", "t/testfont.ttf");
ok (!compare("t/testfont.pdf", "t/base/testfont.pdf"));

