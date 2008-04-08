#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

system($^X, 'scripts/volt2ttf', '-t', 't/schtest.vtp', 't/schtest.ttf', 't/temp.ttf');
$res = compare("t/temp.ttf", "t/base/compiled.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);


