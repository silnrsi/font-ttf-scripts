use Mac::Resources;
use Mac::Memory;

$type = MacPerl::GetFileInfo($ARGV[0]);

if ($ARGV[0] =~ m/^(.*)\.(.*)$/oi) {
    $head = $1; $tail = $2;
} else {
    $head = $ARGV[0]; $tail = "";
}

$head .= " 000";
if ($type eq "tfil" || $type eq "FFIL")
{
    $rid = OpenResFile($ARGV[0]);
    $num = Count1Resources("sfnt");
    while ($num-- > 0)
    {
        $fh = Get1IndResource("sfnt", $num + 1);
        LoadResource($fh) or next;
        $fdat = $fh->get;
        open (OUTFILE, ">$head.$tail") || die "Can't open $head.$tail";
        binmode(OUTFILE);
        print OUTFILE $fdat;
        close(OUTFILE);
        ReleaseResource($fh);
        $head++;
    }
CloseResFile $rid;
}

__END__

=head1 NAME

ttunadopter - unpack Mac suitcase fonts into TTF fonts

=head1 DESCRIPTION

Dropping a suitcase file onto ttundaptor will result in a file being created for
each font in the suitcase.

=cut