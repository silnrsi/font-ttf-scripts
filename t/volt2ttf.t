#!/usr/bin/perl

use Test::Simple tests => 4;
use File::Compare;

$volt2ttf = "scripts/volt2ttf";

if (!-f $volt2ttf)
{
    $volt2ttf = "/usr/bin/volt2ttf";
}

$res = system($^X, $volt2ttf, '-t', 't/schtest.vtp', 't/schtest.ttf', 't/compiled.ttf');
ok (!($res>>8), "exit code");
$res = compare("t/compiled.ttf", "t/base/compiled.ttf");
ok(!$res, "compiled.ttf");
unlink "t/compiled.ttf" unless ($res);

$res = system($^X, $volt2ttf, '-t', 't/lamalefliga.vtp', 't/schtest.ttf', 't/lamalefliga.ttf');
ok (!($res>>8), "exit code");
$res = compare("t/lamalefliga.ttf", "t/base/lamalefliga.ttf");
ok(!$res, "lamalefliga.ttf");
unlink "t/lamalefliga.ttf" unless ($res);

