#!/usr/bin/perl

use Test::Simple tests => 3;
use File::Compare;

system($^X, "scripts/ttfbuilder", "-d", "1", "-c", "t/testfont_1.xml", "-z", "t/temp.xml", "t/testfont.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/test_builder.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);
$res = compare("t/temp.xml", "t/base/test_builder.xml");
ok(!$res);
system($^X, "scripts/add_classes", "-c", "t/testclasses.xml", "t/temp.xml", "t/temp1.xml");
$res = compare("t/temp1.xml", "t/base/test_classes.xml");
ok(!$res);
unlink "t/temp.ttf", "t/temp1.ttf" unless ($res);
