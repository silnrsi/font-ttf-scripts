
#   Title:          ADDPCLT.BAT
#   Author:         M. Hosken
#   Description:
# 1.0.0 MJPH    18-MAR-1998     Original

require 'ttfmod.pl';
require 'getopts.pl';
do Getopts("d:z");

$[ = 0;
if ((defined $opt_d && !defined $ARGV[0]) || (!defined $opt_d && !defined $ARGV[1]))
    {
    die 'ADDPCLT [-d directory] [-z] <infile> <outfile>

v1.0.0, 18-Mar-1998  (c) Martin_Hosken@sil.org

Adds a PCLT table to a font which does not have one. Much of the information is
guesswork or made up from investigation made in the font.
    -d      specifies output directory for processing multiple files. In which
            case <outfile> is not used and <infile> may be a list including
            wildcards.
    -z      debug
';
}

$old = select(STDERR); $| = 1; select($old);

$fns{"PCLT"} = "make_pclt";

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
    &ttfmod($ARGV[0], $ARGV[1], *fns, "PCLT");
    }

sub make_pclt
{
    local(*INFILE, *OUTFILE, $len) = @_;
    local($csum);

    return (&ttfmod'copytab(*INFILE, *OUTFILE, $len)) if ($len != 0);

    $len = 54;
    $inf[0] = 1 << 16;      # version 1
    $inf[1] = 1 << 31;      # fontnumber (derived)
    $inf[4] = 0;            # black normal uncondensed
    $inf[5] = 6 << 12;      # derived font
    $inf[7] = 629;          # symbol set Win3.1
    $inf[8] = " " x 16;    
    $inf[9] = -1;
    $inf[10] = 0x37FFFFFE;   # character complement Windows ANSI
    $inf[12] = 0;           # normal stroke weight
    $inf[13] = 0;           # normal widthType
    $inf[14] = 0;           # normal serif style
    $inf[15] = 0;           # reserved

# Now for the tricky stuff!
# Get some glyph ids
    $off = (split(':', $ttfmod'dir{'post'}))[2];
    seek(INFILE, $off, 0);                          # go to post table
    printf "%s @ %x\n", "post", $off if defined $opt_z;
    read(INFILE, $tdat, 4);                         # get format
    ($tmaj, $tmin) = unpack("n2", $tdat);
    read(INFILE, $tdat, 28);                        # chuck the rest of the header
    print STDERR "$tmaj.$tmin " if defined $opt_z;
    if ($tmaj == 1)
    { ($sid, $hid, $xid) = (3, 43, 91); }
    elsif ($tmaj == 3 || $tmaj == 4)
    {
        warn "No effective post table";
        ($sid, $hid, $xid) = (0, 0, 0);
    }
    elsif ($tmaj == 2)
    {
        read(INFILE, $tdat, 2);
        $numglyphs = unpack("n", $tdat);
        for ($i = 0; $i < $numglyphs; $i++)
        {
            if ($tmin == 5)
            {
                read(INFILE, $tdat, 1);
                $id = unpack("c", $tdat) + $i;
            }
            else
            {
                read(INFILE, $tdat, 2);
                $id = unpack("n", $tdat);
            }
            $sid = $i if ($id == 3);
            $hid = $i if ($id == 43);
            $xid = $i if ($id == 91);
        }
    }

    print STDERR ".0." if defined $opt_z;
    if ($sid == 0)
    { $inf[2] = 0; }
    else
    {
        $off = (split(':', $ttfmod'dir{'hhea'}))[2];
        seek(INFILE, $off, 0);
        read(INFILE, $tdat, 36);
        $numhmet = unpack("x34n", $tdat);

        $off = (split(':', $ttfmod'dir{'hmtx'}))[2];
        seek(INFILE, $off, 0);
        $sid = $numhmet if ($sid > $numhmet);
        read(INFILE, $tdat, $sid * 4 - 4);
        read(INFILE, $tdat, 4);
        $inf[2] = unpack("n", $tdat);
    }

    $off = (split(':', $ttfmod'dir{'head'}))[2];
    seek(INFILE, $off+50, 0);
    read(INFILE, $tdat, 4);
    ($locfmt, $glyfmt) = (unpack("n2", $tdat));

    print STDERR "[$locfmt, $glyfmt]\n" if defined $opt_z;
    $off = (split(':', $ttfmod'dir{'loca'}))[2];
    $locfmt += 1;                                   # 0 -> 1; 1 -> 2
    if ($xid != 0)
    {
        seek(INFILE, $off + $xid * $locfmt * 2, 0);
        read(INFILE, $tdat, $locfmt * 2);
        if ($locfmt == 1)
        { ($xloc) = unpack("n", $tdat) * 2; }
        else
        { ($xloc) = unpack("N", $tdat); }
    }
    if ($hid != 0)
    {
        seek(INFILE, $off + $hid * $locfmt * 2, 0);
        read(INFILE, $tdat, $locfmt * 2);
        if ($locfmt == 1)
        { $hloc = unpack("n", $tdat) * 2; }
        else
        { $hloc = unpack("N", $tdat); }
    }

    print STDERR ".3." if defined $opt_z;
    $off = (split(':', $ttfmod'dir{'glyf'}))[2];
    if ($xid != 0)
    {
        seek(INFILE, $off + $xloc, 0);
        read(INFILE, $tdat, 10);
        ($inf[3]) = unpack("x8n", $tdat);
    } else
    { $inf[3] = 0; }
    if ($hid != 0)
    {
        seek(INFILE, $off + $hloc, 0);
        read(INFILE, $tdat, 10);
        $inf[6] = unpack("x8n", $tdat);
    } else
    { $inf[6] = 0; }
    print STDERR "s = ($sid, $sloc); h = ($hid, $hloc); x = ($xid, $xloc)\n"
            if defined $opt_z;

# Now for some names
    $off = (split(':', $ttfmod'dir{'name'}))[2];
    printf STDERR "%s @ %08x\n", "name", $off if defined $opt_z;
    seek(INFILE, $off, 0);
    read(INFILE, $tdat, 6);
    ($name_num) = unpack("x2n", $tdat);
    for ($i = 0; $i < $name_num; $i++)
        {
        read(INFILE, $tdat, 12) || die "Unable to read name entry: $off";
        ($id_p, $id_e, $id_l, $name_id, $str_len, $str_off)
                = unpack("n6", $tdat);
        ($sl, $sf) = ($str_len, $str_off)
                if ($name_id == 2 && $id_p == 3 && $id_e == 1 && $id_l == 1033);
        ($fl, $ff) = ($str_len, $str_off)
                if ($name_id == 1 && $id_p == 3 && $id_e == 1 && $id_l == 1033);
        }    
    $base = tell(INFILE);
    seek(INFILE, $base + $sf, 0);
    read(INFILE, $subfam, $sl);
    $subfam =~ s/.(.)/$1/oig;
    seek(INFILE, $base + $ff, 0);
    read(INFILE, $fam, $fl);
    $fam =~ s/.(.)/$1/oig;
    substr($inf[8], 0, 11) = substr($fam, 0, 11);
    $inf[11] = substr($fam, 0, 3) . "R00";
    $off = 0;
    if ($subfam =~ m/bold/oi)
    {
        substr($inf[8], 12 + $off, 2) = "Bd";
        substr($inf[11], 3, 1) = "B";
        $off += 2;
    }
    if ($subfam =~ m/italic/oi)
    {
        substr($inf[8], 12 + $off, 2) = "It";
        substr($inf[11], 3, 1) = $off > 0 ? "J" : "I";
    }
    $inf[11] =~ tr/[a-z]/[A-Z]/;
    
    $dat = pack("N2n6A16N2A6C4", @inf);
    $csum = unpack("%32N", $dat);
    print OUTFILE $dat;
    print STDERR "$len, $csum, $ttfmod'dir{'PCLT'}";
    ($len, $csum);
}
    

