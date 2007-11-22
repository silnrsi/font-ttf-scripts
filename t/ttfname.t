#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

$cmd = "scripts/ttfname";
$cmd =~ s{/}{\\}og if ($^O eq 'MSWin32');

system($cmd, "-n", "Tested FontUtils", "t/testfont.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/ttfnamed.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);


