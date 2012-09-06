#!/usr/bin/perl

# typetuner command line tests from original test_tt.bat
# %TT% add feat_all.xml zork.ttf
# %TT% createset zork_tt.ttf feat.xml
# %TT% -o feat_set_metrics.xml setmetrics SILDoulosTest.ttf feat_set.xml
# %TT% applyset feat_set_metrics.xml zork_tt.ttf
# %TT% applyset feat_set_2.xml zork_tt.ttf  - modified to use applyset_xml
# %TT% extract zork_tt_tt_2.ttf feat.xml
# %TT% delete foo.ttf

use Test::Simple tests => 7;
use File::Compare qw( compare compare_text );
use File::Copy; #move func

# set $debug to true to run TypeTuner in debug mode and visually separate test output
my $debug = 0;
if ($debug) 
	{@run_tt = ("$^X", "scripts/typetuner", "-d");}
else
	{@run_tt = ("$^X", "scripts/typetuner");}
             
# add Features file to font to make a Tuner-ready font
#system($^X, "scripts/typetuner", "-d", "add", "t/tt_feat_all.xml", "t/tt_font.ttf");
system(@run_tt, "add", "t/tt_feat_all.xml", "t/tt_font.ttf");
#$res_ttf = compare("t/tt_font_tt.ttf", "t/base/tt_font_tt.ttf"); #compare to list of tables instead
#system($^X, "scripts/ttftable", "-list", "t/tt_font_tt.ttf", ">" ,"t/tt_font_tt.ttf.list.dat"); ### ttftable isn't called correctly
$tbl_list = `$^X scripts/ttftable -list t/tt_font_tt.ttf`;
$res_ttf = ($tbl_list =~ /Silt/);
ok($res_ttf, "added Feature file to font");
print "****\n\n" if $debug;

# create Settings file from a Tuner-ready font
system(@run_tt, "createset", "t/tt_font_tt.ttf", "t/tt_feat_all_set.xml");
$res = compare_text("t/tt_feat_all_set.xml", "t/base/tt_feat_all_set.xml", \&cmptxtline);
ok(!$res, "created Settings file from font");
unlink "t/tt_feat_all_set.xml" unless ($res);
print "****\n\n" if $debug;

# add line metrics from a legacy font to a Settings file
system(@run_tt, "-o", "t/tt_feat_set_1_metrics.xml", "setmetrics", "t/testfont.ttf", "t/tt_feat_set_1.xml");
$res_xml = compare_text("t/tt_feat_set_1_metrics.xml", "t/base/tt_feat_set_1_metrics.xml", \&cmptxtline);
ok(!$res_xml, "imported metrics into Settings file");
print "****\n\n" if $debug;

# apply a Settings file (with imported line metrics) to a Tuner-ready font
#     processing the settings exercises the cmds in the Features file
system(@run_tt, "-o", "t/tt_font_tt_1_metrics.ttf", "applyset", "t/tt_feat_set_1_metrics.xml", "t/tt_font_tt.ttf");
# $res = compare("t/tt_font_tt_1.ttf", "t/base/tt_font_tt_1_metrics.ttf"); ### fails because of internal time stamp
# system($^X, "scripts/ttftable", "-export", "Feat,GSUB,GPOS,cmap,name", "t/tt_font_tt_1_metrics.ttf");
foreach my $tag (qw(Feat GSUB GPOS cmap name)) {
	system($^X, "scripts/ttftable", "-export", "$tag", "t/tt_font_tt_1_metrics.ttf");
#	system($^X, "scripts/ttftable", "-export", "$tag", "t/base/tt_font_tt_1_metrics.ttf"); #uncomment to create dump files from new base font
}
$res = compare("t/tt_font_tt_1_metrics.ttf.Feat.dat", "t/base/tt_font_tt_1_metrics.ttf.Feat.dat") ||
	compare("t/tt_font_tt_1_metrics.ttf.GSUB.dat", "t/base/tt_font_tt_1_metrics.ttf.GSUB.dat") ||
	compare("t/tt_font_tt_1_metrics.ttf.GPOS.dat", "t/base/tt_font_tt_1_metrics.ttf.GPOS.dat") ||
	compare("t/tt_font_tt_1_metrics.ttf.cmap.dat", "t/base/tt_font_tt_1_metrics.ttf.cmap.dat") ||
	compare("t/tt_font_tt_1_metrics.ttf.name.dat", "t/base/tt_font_tt_1_metrics.ttf.name.dat");
ok(!$res, "applied Settings with metrics to Tuner-ready font. four warnings expected.");
if (!$res) {
	unlink "t/tt_font_tt.ttf" if $res_ttf;
	unlink "t/tt_feat_set_1_metrics.xml" unless $res_xml;
	unlink "t/tt_font_tt_1_metrics.ttf";
	foreach my $tag (qw(Feat GSUB GPOS cmap name)) {
		unlink("t/tt_font_tt_1_metrics.ttf.$tag.dat");
#		unlink("t/base/tt_font_tt_1_metrics.ttf.$tag.dat");
	}
}
print "****\n\n" if $debug;

# apply a Settings file to a non-Tuner-ready font using a Features file
#     processing the settings exercises some different cmds in the Features file
system(@run_tt, "-o", "t/tt_font_2.ttf", "applyset_xml", "t/tt_feat_all.xml", "t/tt_feat_set_2.xml", "t/tt_font.ttf");
foreach my $tag (qw(Feat GSUB GPOS cmap name)) {
	system($^X, "scripts/ttftable", "-export", "$tag", "t/tt_font_2.ttf");
#	system($^X, "scripts/ttftable", "-export", "$tag", "t/base/tt_font_2.ttf");
}
$res = compare("t/tt_font_2.ttf.Feat.dat", "t/base/tt_font_2.ttf.Feat.dat") ||
	compare("t/tt_font_2.ttf.GSUB.dat", "t/base/tt_font_2.ttf.GSUB.dat") ||
	compare("t/tt_font_2.ttf.GPOS.dat", "t/base/tt_font_2.ttf.GPOS.dat") ||
	compare("t/tt_font_2.ttf.cmap.dat", "t/base/tt_font_2.ttf.cmap.dat") ||
	compare("t/tt_font_2.ttf.name.dat", "t/base/tt_font_2.ttf.name.dat");
ok(!$res, "applied different Settings to standard font using Features files. four warnings and one error expected.");
if (!$res) {
	foreach my $tag (qw(Feat GSUB GPOS cmap name)) {
		unlink("t/tt_font_2.ttf.$tag.dat");
	}
}
print "****\n\n" if $debug;

# extract the Settings file from a tuned font
system(@run_tt, "extract", "t/tt_font_2.ttf", "t/tt_feat_set_2_extract.xml");
$res = compare("t/tt_feat_set_2_extract.xml", "t/base/tt_feat_set_2_extract.xml");
ok(!$res, "extracted the Settings file from a tuned font");
unlink "t/tt_feat_set_2_extract.xml" unless ($res); # tt_feat_set_2_extract.xml should be the same as tt_feat_set_2.xml
print "****\n\n" if $debug;

# delete the Settings file from a tuned font
system(@run_tt, "delete", "t/tt_font_2.ttf");
$tbl_list_1 = `$^X scripts/ttftable -list t/tt_font_2.ttf`;
$tbl_list_2 = `$^X scripts/ttftable -list t/tt_font_2_tt.ttf`;
$res = (($tbl_list_1 =~ /Silt/) && ($tbl_list_2 !~ /Silt/));
ok($res, "deleted the Settings file from a tuned font");
unlink "t/tt_font_2.ttf" unless (!$res);
unlink "t/tt_font_2_tt.ttf" unless (!$res);

sub cmptxtline { 
	foreach(@_) 
	{s/\r?\n?$//o;} 
	return $_[0] ne $_[1]; 
}