#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

system($^X, "scripts/ttfbuilder", "-d", "1", "-c", "t/testfont_1.xml", "t/testfont.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/test_builder.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);


