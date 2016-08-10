#!/usr/bin/perl

use Test::Simple tests => 2;
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
unlink 't/testfont.pdf';
ok(!-f 't/testfont.pdf', 'pdf should not exist');

system($^X, $fret, "-d", "1000000000", "t/testfont.ttf");

# Unfortunately the PDFs won't ever compare exactly, so we can't really do this:
$res = compare("t/testfont.pdf", "t/base/testfont.pdf");

# Rather, we'll just make sure the files are similar length:
$lgt = ((stat('t/testfont.pdf'))[7]);
$lgtref = ((stat('t/base/testfont.pdf'))[7]);
$res = (abs($lgt - $lgtref) < 4);
ok($res, "PDF length should be $lgtref is $lgt");
unlink "t/testfont.pdf" if ($res);

