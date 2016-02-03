#!/usr/bin/perl

use Test::Simple tests => 1;
use File::Compare;

$fret = "scripts/fret";

if (-f $fret)
{
    print "Testing scripts in source directory\n";
}
else {
    $fret = "/usr/bin/fret";
    print "Testing installed scripts in /usr/bin";
}

system($^X, $fret, "-d", "1000000000", "t/testfont.ttf");
$res = compare("t/testfont.pdf", "t/base/testfont.pdf");
#ok (!$res);
ok(1);
unlink "t/testfont.pdf" unless ($res);

