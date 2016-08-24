#!/usr/bin/perl

use Test::More tests => 2;
use File::Compare;
use Text::PDF;      # We've got different tests for different versions

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

system($^X, $fret, "-d", "1000000000", "-q", "t/testfont.ttf");

# For Text::PDF prior to 0.31, PDFs are unlikely to compare exactly.
my $tpdf_ver = Text::PDF->VERSION;
if ($tpdf_ver < 0.31)
{
    # in which case just make sure the files are similar length:
    diag "Detected Text::PDF $tpdf_ver ... checking for reasonable length...\n";
    $lgt = ((stat('t/testfont.pdf'))[7]);
    $lgtref = ((stat('t/base/testfont.pdf'))[7]);
    $res = (abs($lgt - $lgtref) < 200);
    ok($res, "PDF length should be $lgtref is $lgt");
}
else
{
    $res = !compare("t/testfont.pdf", "t/base/testfont.pdf");
    ok($res, "PDF files match");
}

unlink "t/testfont.pdf" if $res; ;
