
#   Title:          MAKEMONO.BAT
#   Author:         M. Hosken
#   Description:
# MJPH  1.0.0   25-MAR-1998     Original

require 'ttfmod.pl';
require 'getopts.pl';
&Getopts("d:z");

if ((defined $opt_d && !defined $ARGV[0]) || (!defined $opt_d && !defined $ARGV[1]))
{
    die 'MAKEMONO [-d dir] [-z] <infile> <outfile>

v1.0.0, 25-Mar-1998  (c) Martin_Hosken@sil.org

Converts a font to be a monospaced font based on the maximum advance width.
    -d      specifies output directory for processing multiple files. In which
            case <outfile> is not used and <infile> may be a list including
            wildcards.
    -z      debug
';
}

$fns{"post"} = "post";
$fns{"hmtx"} = "hmtx";
$fns{"OS/2"} = "os2";

if (defined $opt_d)
    {
    foreach $f (@ARGV)
        {
        print STDERR "$f -> $opt_d/$f\n" unless (defined $opt_q);
        &ttfmod($f, "$opt_d/$f", *fns);
        }
    }
else
    {
    &ttfmod($ARGV[0], $ARGV[1], *fns);
    }

sub post
{
    local(*INFILE, *OUTFILE, $len) = @_;
    local($csum);

    read(INFILE, $dat, 32);     # read header
    substr($dat, 12, 4) = pack("N", 1);     # mark as monospaced
    $csum = unpack("%32N*", $dat);
    print OUTFILE $dat;
    ($len, $csum) = &ttfmod'copytab(*INFILE, *OUTFILE, $len-32, $csum);
    ($len + 32, $csum);
}

sub hmtx
{
    local(*INFILE, *OUTFILE, $len) = @_;
    local($csum);

    $mylen = $len;
    ($numhmet, $maxadv) = &getinfo(*INFILE);
    print STDERR "$numhmet, $maxadv\n" if defined $opt_z;
    for ($i = 0; $i < $numhmet; $i++)
    {
        read(INFILE, $dat, 4);
        substr($dat, 0, 2) = pack("n", $maxadv);
        print OUTFILE $dat;
        $csum += unpack("%32N*", $dat);
        if ($csum > 0xffffffff) { $csum -= 0xffffffff; $csum--; }        
        $mylen -= 4;
    }
    ($mylen, $csum) = &ttfmod'copytab(*INFILE, *OUTFILE, $mylen, $csum);
    ($len, $csum);
}

sub os2
{
    local(*INFILE, *OUTFILE, $len) = @_;
    local($csum);

    ($numhmet, $maxadv) = &getinfo(*INFILE);
    read(INFILE, $dat, $len);
    substr($dat, 2, 2) = pack("n", $maxadv);
    substr($dat, 35, 1) = pack("c", 9);         # magic does the trick in Windows
    $csum = unpack("%32N*", $dat);
    print OUTFILE $dat;
    ($len, $csum);
}

sub getinfo
{
    local(*INFILE) = @_;

    $loc = tell(INFILE);
    $off = (split(':', $ttfmod'dir{'hhea'}))[2];
    seek(INFILE, $off, 0);
    read(INFILE, $dat, 36);
    ($maxadv, $numhmet) = unpack("x10nx22n", $dat);
    seek(INFILE, $loc, 0);
    ($numhmet, $maxadv);
}


