#! /usr/bin/perl

#   Title:      TTFWIDTH.PL
#   Author:     M. Hosken
#   Description: Write out character width, etc. information from a TTF file
#                in either SF or CSV format.
# 1.2.0     25-MAR-1998     Tidy up to package with the rest

require 'getopts.pl';
do Getopts("qsuzp:");

if (!defined $ARGV[0])
    {
    die 'TTFWIDTH [-q] [-s] [-u] [-z] [-p plat.spec] <infile> [<outfile>]

v1.2.0, 25-Mar-1998  (c) Martin_Hosken@sil.org
    
Generates character size information for each character to either Standard
Format or Comma Separated Variables format.  Essential for sorting out those
typographical variants.
    -u  unicode as key rather than calculated 8-bit code
    -q  suppress advisory output
    -s  output in standard format
    -p  plat.spec set platform and specific ids of character map
    -z  debug
';
    }

# print "TTFWIDTH v1.1: Freeware, (c) M. Hosken\n" if (!defined $opt_q);

open(INFILE, "$ARGV[0]") || die("Unable to open \"$ARGV[0]\" for reading");
binmode INFILE;
if (defined $ARGV[1])
    {
    open(OUTFILE, ">$ARGV[1]") || die "Unable to open \"$ARGV[1]\" for writing";
    }
else
    {
    open(OUTFILE, ">&STDOUT") || die "Can't dup STDOUT";
    }

# for the most part, we don't need all the information in the font, so it
# isn't parsed.  Secondly, no checks are made that all the essential tables
# are necessary.  Trivial, but then the tables are essential and the font
# would not work without them, so they will be there (famous last words).

# first read the header and directory
read(INFILE, $head, 12) == 12 || die "reading header";
($ver, $numtab) = unpack("Nn", $head);
# print "ver = $ver\nnumtab = $numtab\n";
for ($i = 0; $i < $numtab; $i++)
    {
    read(INFILE, $tab, 16) == 16 || die "reading table directory";
    ($name, $offset) = unpack("a4x4N", $tab);
#    printf "name = \"$name\", offset = %X\n", $offset;
    $dir{$name} = $offset;
    }

# trawl the world to get all those essential numbers from the various strange
# tables that they are spread around.

# process the "head" table
seek(INFILE, $dir{"head"}, 0);
read(INFILE, $h_data, 54) == 54 || die "reading head table";
($h_em, $h_longloc) = unpack("x18nx30n", $h_data);

# process the "maxp" table
seek(INFILE, $dir{"maxp"}, 0);
read(INFILE, $m_data, 6);
($m_num) = unpack("x4n", $m_data);
print "The em box is $h_em units square.\nThere are $m_num glyphs\n"
    if (!defined $opt_q);

# process the "hhea" table
seek(INFILE, $dir{"hhea"}, 0);
read(INFILE, $h_data, 36) == 36 || die "reading hhea table";
($h_numh) = unpack("x34n", $h_data);
undef $h_data;

# process the "cmap" table
# contains the mappings of unicode to glyph number
seek(INFILE, $dir{"cmap"}, 0);
read(INFILE, $head, 4) == 4 || die "reading cmap header";
($c_ver, $c_n) = unpack("nn", $head);
if (defined $opt_p && $opt_p =~ m/^([0-9]+)[.]([0-9]+)/o)
    {
    $c_tid = $1;
    $c_tenc = $2;
    }
else
    {
    $c_tid = 3;
    $c_tenc = 1;
    }
for ($i = 0; $i < $c_n; $i++)
    {
    read(INFILE, $c_info, 8) == 8 || die "reading cmap dir entry";
    ($c_id, $c_enc, $c_offset) = unpack("nnN", $c_info);
    last if ($c_id == $c_tid);       # found the encoding we want
    }
if ($i >= $c_n)
    {
    print STDERR "Can't find required encoding, using Unicode instead.\n";
    $opt_u = 1;
    }
if (!defined $opt_q)
    {
    print "font mapping Microsoft id = $c_id, encoding = $c_enc\n";
    print "    (encoding => " . ($c_enc == 1 ? "UGL coding"
            : "unknown or symbol") . ")\n";
    }

if ($c_enc == 1)
    {
# Microsoft UGL coding (8-bit to unicode mapping table)
    (@c_enc) = (32 .. 126, 0, 0, 0, 0x201a, 0x192, 0x201e, 0x2026, 0x2020,
                0x2021, 0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0, 0, 0, 0,
                0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014, 0x02dc,
                0x2122, 0x0161, 0x203a, 0x0153, 0, 0, 0x0178,
                160 .. 255);
    }
# print it all out as comma seperated variables or standard format
if (!defined $opt_s)
    {
#    print OUTFILE "\"Em box\",\"$h_em\"\n";
    if (!defined $opt_u)
        {
        print OUTFILE "Code, Char, ";
        }

    printf OUTFILE "%s, " x 8 . "%s\n",
        "Unicode", "Glyph", "AdvWidth", "LSdBearing",
        "Xmin", "Xmax", "Ymin", "Ymax", "XCentre";
    }

$big = 512;
if (defined $opt_u && $m_num > $big)
    {
    $low = 0; $c_count = $big;
    while ($c_count >= $big)
        {
        &getdata;
        &printdata;
        undef @c_uni;
        undef @l_offsets;
        undef @h_adw;
        undef @h_lsb;
        undef @g_xmin;
        undef @g_xmax;
        undef @g_ymin;
        undef @g_ymax;
        undef @map;
        }
    }
else
    {
    $low = -1;
    &getdata;
    &printdata;
    }
close(OUTFILE);
close(INFILE);


sub printdata
{
for ($i = (defined $opt_u ? $[ : 32); $i <= (defined $opt_u ? $#c_uni : 255);
        $i++)
    {
    if (defined $opt_u)
        {
        next if ($c_uni[$i] == 0);
        $j = $map[$i];
        }
    else
        {
        $j = ($c_enc == 1) ? $c_map[$c_enc[$i - 32]] : $c_map[$i];
        next if ($j == 0);
        }
    $o_cnt = $h_lsb[$j] + ($g_xmax[$j] - $g_xmin[$j]) / 2;
    $o_centre = $h_adw[$j] - $o_cnt;
    $o_centre = -$o_centre if ($o_cnt < 0);
    if (defined $opt_s)
        {
        if (!defined $opt_u)
            {
            printf OUTFILE "\\code %d\n\\char %c\n\\uni 0x%04x\n\\glyph %d\n"
                . "\\adw %d\n\\lsb %d\n",
                $i, $i, ($c_enc == 1) ? $c_enc[$i] : $i + 0xf000, $i,
                $h_adw[$j], $h_lsb[$j];
            }
        else
            {
            printf OUTFILE "\\code 0x%04x\n\\glyph %d\n\\adw %d\n\\lsb %d \n",
                $c_uni[$i], $i, $h_adw[$j], $h_lsb[$j];
            }
        printf OUTFILE "\\xmin %d\n\\xmax %d\n\\ymin %d\n\\ymax %d\n\\xcent %d\n\n",
            $g_xmin[$j], $g_xmax[$j], $g_ymin[$j], $g_ymax[$j], $o_centre;
        }
    else
        {
        if (!defined $opt_u)
            {
            if ($i == 34)
                { $o_s = "\"" x 4; }
            elsif ($i == 44)
                { $o_s = "\",\""; }
            else
                { $o_s = sprintf("%c", $i); }
            printf OUTFILE "%d,%s,0x%04X,%d,",
                $i, $o_s, ($c_enc == 1) ? $c_enc[$i - 32] : $i + 0xf000, $j;
            }
        else
            {
            printf OUTFILE "0x%04X,%d,", $c_uni[$i], $i;
            }
        printf OUTFILE "%d,%d,%d,%d,%d,%d,%d\n",
            $h_adw[$j], $h_lsb[$j], $g_xmin[$j],
            $g_xmax[$j], $g_ymin[$j], $g_ymax[$j], $o_centre;
        }
    }
}

sub getdata
{
seek(INFILE, $dir{"cmap"} + $c_offset, 0);
read(INFILE, $c_head, 6) == 6 || die "reading cmap table header";
($c_fmt, $c_len, $c_ver) = unpack("nnn", $c_head);
die "Incorrect encoding format $c_fmt, should be 4" if ($c_fmt != 4);
read(INFILE, $c_head, 8) == 8 || die "reading cmap table header part 2";
($c_segs) = unpack("n", $c_head);
$c_segs = $c_segs / 2;
# now read the real meat of the table
read(INFILE, $c_data, 2 * $c_segs) == 2 * $c_segs || die "reading cmap_end data";
(@c_ends) = unpack("n" x $c_segs, $c_data);
read(INFILE, $c_data, 2 * $c_segs + 2) == 2 * $c_segs + 2
        || die "reading cmap_start data";
(@c_starts) = unpack("xx" . "n" x $c_segs, $c_data);
read(INFILE, $c_data, 2 * $c_segs) == 2 * $c_segs || die "reading cmap_deltas";
(@c_deltas) = unpack("n" x $c_segs, $c_data);
read(INFILE, $c_data, 2 * $c_segs) == 2 * $c_segs || die "reading cmap_ranges";
(@c_ranges) = unpack("n" x $c_segs, $c_data);
undef $c_data;
$num = read(INFILE, $c_idarray, $c_len - $c_segs * 8 - 16);
(@c_idarray) = unpack("n" x ($num / 2), $c_idarray);
undef $c_idarray;
# convert range type information into per-code information.  Creates mapping
# table (@c_enc) to convert unicode to glyph
$c_count = 0;
cmap:
for ($i = 0; $i < $c_segs - 1; $i++)
    {
    for ($j = $c_starts[$i]; $j <= $c_ends[$i]; $j++)
        {
        if ($low == -1 || $j > $low)
            {
                        # calculate glyph number
            if ($c_ranges[$i] != 0)
                {
                $index = $c_idarray[($c_ranges[$i]/2 + $j -
                        $c_starts[$i] - $c_segs + $i)];
                }
            else
                {
                $index = $j + $c_deltas[$i] - ($c_deltas[$i] > 32767 ? 65536:0);
                    # can't handle 0xf000 directly as an array index, it thinks
                    # it's negative :-(
                }
            if (!defined $opt_u)
                {
                $c_map[$j - ($c_enc == 1 ? 0 : 0xf000)] = $index;
                $map[$index] = $index;
                }
            else
                {
                next if ($index == 0);
                $c_count++;
                $map[$index] = $c_count;
                }
            $c_uni[$index] = $j;
            if ($low > -1 && $c_count >= $big)
                {
                $low = $j;
                last cmap;
                }
            }
        }
    }
print STDERR "$c_count " if (defined $opt_z);
undef @c_deltas;
undef @c_ranges;
undef @c_starts;
undef @c_ends;
print STDERR "1" if (defined $opt_z);
# generate the locations of each glyph

# process the "loca" table
seek(INFILE, $dir{"loca"}, 0);
read(INFILE, $l_data, ($h_longloc == 1 ? 4 : 2) * ($m_num + 1));
(@l_offs) = unpack(($h_longloc == 1 ? "N" : "n") x ($m_num + 1), $l_data);
undef $l_data;
$lold = -1;
for ($i = 0; $i <= $m_num; $i++)
    {
    if ($c_uni[$i])
        {
        $l_offsets[$map[$i]] = $l_offs[$i];
        $l_offsets[$map[$i]] = -1
                if ($i != $m_num && $l_offs[$i] == $l_offs[$i+1]);
        $l_offsets[$map[$i]] *= 2
                if ($h_longloc == 0 && $l_offs[$i] != -1);
        }
    }
undef @l_offs;
print STDERR "2" if (defined $opt_z);
# get the horizontal metrics (advance width and left side bearing)

# process the "hmtx" table
seek(INFILE, $dir{"hmtx"}, 0);
read(INFILE, $h_data, 4 * $h_numh) == 4 * $h_numh || die "reading hmtx table";
(@h_temp) = unpack("n" x (2 * $h_numh), $h_data);
undef $h_data;
for ($i = 0; $i < $h_numh; $i++)
    {
    $h_ladw = $h_temp[$i * 2];
    if ($c_uni[$i])
        {
        $h_adw[$map[$i]] = $h_ladw;
        $h_lsb[$map[$i]] = $h_temp[$i * 2 + 1];
        }
    }
if ($h_numh != $m_num)      # for monospaced fonts
    {
    read(INFILE, $h_data, 2 * ($m_num - $h_numh));
    @h_temp = unpack("n" x ($m_num - $h_numh), $h_data);
    for ($i = $h_numh; $i < $m_num; $i++)
        {
        if ($c_uni[$i])
            {
            $h_adw[$map[$i]] = $h_ladw;
            $h_lsb[$map[$i]] = $h_temp[$i - $h_numh];
            }
        }
    }
for ($i = 0; $i <= $m_num; $i++)    # convert unsigned to signed (any easier
                                    # way?)
    {
    if ($c_uni[$i])
        {
        $j = $map[$i];
        $h_adw[$j] = $h_adw[$j] - ($h_adw[$j] > 32768 ? 65536 : 0);
        $h_lsb[$j] = $h_lsb[$j] - ($h_lsb[$j] > 32768 ? 65536 : 0);
        }
    }
undef @h_temp;
print STDERR "3" if (defined $opt_z);

# process the "glyf" table to get the character bounding box dimensions
for ($i = 0; $i <= $m_num; $i++)
    {
    $j = $map[$i];
    if ($l_offsets[$j] != -1 && $c_uni[$i])
        {
        seek(INFILE, $dir{"glyf"} + $l_offsets[$j], 0);
        read(INFILE, $g_data, 10) == 10 || die "reading glyph $i";
        ($g_xmin[$j], $g_ymin[$j], $g_xmax[$j], $g_ymax[$j])
                = unpack("x2nnnn", $g_data);
        $g_xmin[$j] = $g_xmin[$j] - ($g_xmin[$j] > 32768 ? 65536 : 0);
        $g_ymin[$j] = $g_ymin[$j] - ($g_ymin[$j] > 32768 ? 65536 : 0);
        $g_xmax[$j] = $g_xmax[$j] - ($g_xmax[$j] > 32768 ? 65536 : 0);
        $g_ymax[$j] = $g_ymax[$j] - ($g_ymax[$j] > 32768 ? 65536 : 0);
        }
    }
print STDERR "4\n" if (defined $opt_z);
}


