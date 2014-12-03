#! /usr/bin/perl

# 1.2   MJPH    27-APR-2006     Restructure help to give man pages
# 1.1   MJPH    13-AUG-1999     Add U+00B7 and reverse mappings as well

use Font::TTF::Font;
use Pod::Usage;
use Getopt::Std;

getopts('m:');

unless (defined $ARGV[1])
{
    pod2usage(1);
    exit;
}

$f = Font::TTF::Font->open($ARGV[0]);
$f->{'cmap'}->read->{' isDirty'} = 1;

copy_cmap($f, $opt_m, 0x0080, 0x20AC);
copy_cmap($f, 0, 0x008E, 0x017D);
copy_cmap($f, 0, 0x009E, 0x017E);
copy_cmap($f, 0, 0x00B7, 0x2219);

$f->{'OS/2'}->read->update;

$f->out($ARGV[1]);



sub copy_cmap
{
    my ($f, $mac, @equates) = @_;
    my ($gnum, $i, $t, $u);

    foreach $u (@equates)
    { last if ($gnum = $f->{'cmap'}->ms_lookup($u)); }

    return undef unless $gnum;

    # Work through the tables hacking:
    for ($i = 0; $i < $f->{'cmap'}{'Num'}; $i++)
    {
        $t = $f->{'cmap'}{'Tables'}[$i];
        if ($mac && $t->{'Platform'} == 1 && $t->{'Encoding'} == 0)
        { $t->{'val'}{$mac} = $gnum if ($mac && !$t->{'val'}{$mac}); }  # Mac
        elsif (($t->{'Platform'} == 0 && $t->{'Encoding'} == 0)
                || ($t->{'Platform'} == 3 && $t->{'Encoding'} == 1))
        {
            foreach $u (@equates)
            { $t->{'val'}{$u} = $gnum unless $t->{'val'}{$u}; }
        }    # ISO or MS
    }
    $f;
}

__END__

=head1 TITLE

eurofix - fixes euro and other chars in cp1252 fonts

=head1 SYNOPSIS

    EUROFIX [-m num] infile outfile
Edits a font to account for the change in codepage 1252 definition in Win98,
NT5 and all things new then. -m specifies that the Mac hack should also be
done.

The following changes are made to ensure that the glyphs at the two positions
are the same, if possible:
    U+0080 and U+20AC                Euro sign
    U+008E and U+017D                Z caron
    U+009E and U+017E                z caron
    U+00B7 and U+2219                Middle dot
For more details of which glyph is used where in Windows, see the POD which
accompanies this program.

For the Mac table
    glyph at U+0080 (in MS table) copied to num             Euro sign
    (-m may be for 240 or 211 depending on Apple or MS)

Copies are only made if there is no glyph there already.    

=cut
