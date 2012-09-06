#!/usr/bin/perl

use Test::Simple tests => 3;
use File::Compare qw( compare compare_text );

system($^X, "scripts/ttfbuilder", "-d", "1", "-c", "t/testfont_1.xml", "-z", "t/temp.xml", "t/testfont.ttf", "t/temp.ttf");
$res = compare("t/temp.ttf", "t/base/test_builder.ttf");
ok(!$res);
unlink "t/temp.ttf" unless ($res);
$res = compare_text("t/temp.xml", "t/base/test_builder.xml", \&cmptxtline);
ok(!$res);
system($^X, "scripts/add_classes", "-c", "t/testclasses.xml", "t/temp.xml", "t/temp1.xml");
$res = compare_text("t/temp1.xml", "t/base/test_classes.xml", \&cmptxtline);
ok(!$res);
unlink "t/temp.xml", "t/temp1.xml" unless ($res);

sub cmptxtline { 
	foreach(@_) 
	{s/\r?\n?$//o;} 
	return $_[0] ne $_[1]; 
}