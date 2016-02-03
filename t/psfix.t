#!/usr/bin/perl

use Test::Simple tests => 2;
use File::Compare qw( compare compare_text );

$psfix = "scripts/psfix";
$dumpfont = "scripts/dumpfont";

if (!-f $psfix)
{
    $psfix = "/usr/bin/psfix";
    $dumpfont = "/usr/bin/dumpfont";
}


system($^X, $psfix, "t/schtest.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/psfix.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);

system($^X, $psfix, "-s", "t/schtest.ttf", "t/temp_s.ttf");
my $p = `"$^X" $dumpfont -t post t/temp_s.ttf`;
$res = ($p !~ /"FormatType" => 3/) || ($p !~ /"VAL" => \[]/);
ok(!$res);
unlink "t/temp_s.ttf" unless ($res);


