#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

$ttfname = "scripts/ttfname";

if (!-f $ttfname)
{
    $ttfname = "/usr/bin/ttfname";
}

system($^X, $ttfname, "-n", "Tested FontUtils", "t/testfont.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/ttfnamed.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);


