#!/usr/bin/perl

use Test::Simple tests => 2;
use File::Compare;

system($^X, 'scripts/volt2ttf', '-t', 't/schtest.vtp', 't/schtest.ttf', 't/compiled.ttf');
$res = compare("t/compiled.ttf", "t/base/compiled.ttf");
ok(!$res);
unlink "t/compiled.ttf" unless ($res);

system($^X, 'scripts/volt2ttf', '-t', 't/lamalefliga.vtp', 't/schtest.ttf', 't/lamalefliga.ttf');
$res = compare("t/lamalefliga.ttf", "t/base/lamalefliga.ttf");
ok(!$res);
unlink "t/lamalefliga.ttf" unless ($res);

