#! perl
foreach $f (qw(Addfont check_attach eurofix fret hackos2 make_gdl make_volt make_volt.bak psfix thai2gdl thai2ot thai2volt ttfbuilder ttfenc ttfname ttfremap volt2xml))
{
    if ($ARGV[0] eq '-r')
    {
        unlink "$ARGV[1]\\$f.bat";
    }
    else
    {
        open(FH, "> $ARGV[0]\\$f.bat") || die $@;
        print FH "@\"$ARGV[0]\\parl.exe\" \"$ARGV[0]\\fontutils.par\" $f %1 %2 %3 %4 %5 %6 %7 %8 %9\n";
        close(FH);
    }
}
