use Font::TTF::Font;
require 'getopts.pl';

Getopts("umws");

unless (defined $ARGV[1])
{
    die <<'EOT';

    StripCmap [-m] [-u] [-w] [-s] <infile> <outfile>

Strips the Macintosh (-m), Mac Unicode (-u), and/or Windows (-w) cmap from 
a ttf without without touching anything else. Emit no messages if -s.

EOT
}

$f = Font::TTF::Font->open($ARGV[0]) || die "Cannot open TrueType font '$ARGV[0]' for reading.\n";
$o = $f->{'cmap'}->read || die "Font '$ARGV[0]' has no cmap table.\n";

for ($i =$o->{'Num'}-1; $i >= 0; $i--)
{
	
	$pID = $o->{'Tables'}[$i]{'Platform'};
	if (($pID == 0 && $opt_u) or ($pID == 1 && $opt_m) or ($pID == 3 && $opt_w))
	{
		printf "Deleting cmap for platformID $pID\n" if !$opt_s;
		splice @{$o->{'Tables'}}, $i, 1;
		$o->{'Num'}--;
	}
}

printf "Number of cmap tables remaining = %d\n", $o->{'Num'} if !$opt_s;
$f->out($ARGV[1]);

