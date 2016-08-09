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

# Rather, we'll just make sure the files are the same length:

$res = ((stat('t/testfont.pdf'))[7]) == ((stat('t/base/testfont.pdf'))[7]);
ok($res, 'PDFs should be same length');
unlink "t/testfont.pdf" if ($res);

