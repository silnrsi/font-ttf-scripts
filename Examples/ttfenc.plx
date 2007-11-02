#! /usr/bin/perl
use Font::TTF::Font;
use Getopt::Std;
use IO::File;
use Math::Trig;
use Pod::Usage;

if ($ARGV[0] =~ /^\-@/oi)
{
    $cfgname = $';      #'
    shift (ARGV);
    open(CFGFILE, "$cfgname") || die "Unable to open config file $cfgname";
    while (<CFGFILE>)
    { chomp; unshift (ARGV, $_); }
}
getopts("d:e:hm:o:p:t:xz:");

$VERSION = 1.0;     # MJPH  26-DEB-1999     Original

unless (defined $ARGV[0] || $opt_h)
{
    pod2usage(1);
    exit;
}
elsif ($opt_h)
{
    pod2usage(verbose => 2);
    exit;
}

%texCorrect = (
    'mu1' => 'mu',
    'summation' => 'Sigma',
    'product' => 'Pi',
    'increment' => 'Delta',
    'middot' => 'periodcentered',
    'overscore' => 'macron',
    'dslash' => 'dmacron'
    );

%texcatcodes = (
    "\\" => 16, "{" => 1, "}" => 2, "\$" => 3, "&" => 4, "\n" => 5, "#" => 6,
    "^" => 7, "_" => 8, " " => 10, "~" => 13, "%" => 14);

map {$texcatcodes{$_} = 11} ('a' .. 'z', 'A' .. 'Z');

# %texescapes = (map{$_ = 1} (qw(39 96)));

$base = $ARGV[0];
$base =~ s/(.*[\\\/])?(.*)\.ttf/$2/oi;

$font = Font::TTF::Font->open("$ARGV[0]");
$lchar = $font->{'OS/2'}->read->{'usFirstCharIndex'};
if ($lchar < 0xF000 || $lchar > 0xF100)             # a Windows symbol font?
{
    die "No mapping file" unless defined $opt_m;
    $map = read_UniMap($opt_m);         # no? then use mapping file
} else
{
    $map = [];
    for ($i = 0; $i < 256; $i++)
    { $map->[$i] = $i + 0xf000; }
}
$font->{'post'}->read;
$font->{'cmap'}->read;
$font->{'name'}->read;

$mypost = [@{$font->{'post'}{'val'}}];
$psname = $font->{'name'}->find_name(6);

if ($opt_e)
{
    open(OUTFILE, ">$opt_e") || die "Unable to open $opt_e";
    binmode OUTFILE;                # need Unix file format!
    select OUTFILE;
    
    print "/TeXBase1Encoding [\n";
    
    for ($i = 0; $i < 256; $i++)
    {
        my ($name, $gid);
        
        printf "%% 0x%02X\n", $i unless ($i & 15);
        $gid = $font->{'cmap'}->ms_lookup($map->[$i]);
        $name = $font->{'post'}{'VAL'}[$gid];
        $name = $texCorrect{$name} if ($opt_x && defined $texCorrect{$name});
        while ($font->{'post'}{'STRINGS'}{$name} != 0 && $font->{'post'}{'STRINGS'}{$name} != $gid)
        {
            print STDERR "multiple occurrences of $name. Use -o to fix font\n" unless ($opt_o);
            $name =~ s/([0-9])*$/$1 + 1/oe;
        }
        $mypost->[$gid] = $name;
        print "    /$name";
        print "\n" if ($i & 3) == 3;
    }
    
    print "] def\n";
    
    select STDOUT;
    close (OUTFILE);
}

if ($opt_o)
{
    $font->{'post'}{'VAL'} = $mypost;
    $font->out($opt_o) || warn "Can't write font to $opt_o";
}

if ($opt_d)
{
    open(OUTFILE, ">$opt_d") || die "Unable to open $opt_d";
    select OUTFILE;
    
    $font->{'hmtx'}->read;
    print <<'EOT';
\def\basechar#1{\nobreak\hskip 0pt plus .05em minus .003em \char#1 \relax}
\catcode1=\active
\def^^A{}
EOT
    print "\\def\\$psname\{" . '%' . "\n\%\\frenchspacing\n";
    $min = 128;
    $min = 32 if ($opt_z & 1);
        
    for ($i = $min; $i < 256; $i++)
    {
        next unless ($map->[$i]);
        next if (($opt_z & 2) && pack('C', $i) =~ m/[0-9\-:]/o);
        my ($gid) = $font->{'cmap'}->ms_lookup($map->[$i]);
        my ($lsb, $adv) = ($font->{'hmtx'}{'lsb'}[$gid], $font->{'hmtx'}{'advance'}[$gid]);
        
        if (-$lsb <= $adv && $lsb != 0)
        { 
#            printf "\\catcode%d=\\active\\uccode1=%d \\uppercase{\\xdef^^A{\\noexpand\\basechar{%s}}}%%\n", $i, $i, chr($i);
#            printf "\\catcode%d=\\active\\uccode1=%d \\expandafter\\gdef\\uppercase{^^A}{\\basechar{%s}}%%\n", $i, $i, chr($i);
            printf "\\catcode%d=\\active\\uccode1=%d \\uppercase{\\edef^^A{\\noexpand\\basechar{%d}}}%%\n", $i, $i, $i;
            push (@list, $i);
        }
    }
    print "}\n";
    
    print "\\def\\un$psname\{".'%'."\n";
    foreach (@list)
    { 
        if ($texcatcodes{chr($_)})
        { print "\\catcode$_=" . $texcatcodes{chr($_)} . '%' . "\n"; }
        else
        { print "\\catcode$_=12".'%'."\n"; }
    }
    print "}\n";
    print <<'EOT';
\catcode1=12
EOT
    
    select STDOUT;
    close(OUTFILE);
}

exit unless defined $opt_t;

$tfmname = $opt_t;
$tfmname =~ s/(.*[\\\/])?(.*)\.tfm/$2/oi;
$encname = $opt_e;
$encname =~ s/(.*[\\\/])?(.*)\.enc/$2/oi;

if (0)
{
    system("ttf2afm -e $opt_e -o $tfmname.afm $ARGV[0] > $base.log");
    open(INFILE, "afm2tfm $tfmname.afm |") || die "Can't run afm2tfm";
    $mapline = <INFILE>;
    close(INFILE);
    (undef, $psname) = split(' ', $mapline);
    if ($opt_t !~ /^$tfmname\.tfm/i)
    {
        open (INFILE, "$tfmname.tfm") || die "Can't open $tfmname.tfm";
        binmode INFILE;
        unlink ("$opt_t") || goto getout;
        open (OUTFILE, ">$opt_t") || goto doneit;
        binmode OUTFILE;
        while (read(INFILE, $dat, 4096))
        { print OUTFILE $dat; }
        close (OUTFILE);
    doneit:
        close (INFILE);
    }
}
else
{
    make_tfm($font, $map, $psname, $opt_t);
}

if (defined $opt_p)
{
    open(OUTFILE, ">>$opt_p") || die "Can't open $opt_p for appending";
    print OUTFILE "$tfmname $psname <$base.ttf $encname.enc\n";
    close(OUTFILE);
}


getout:
print STDERR "\n";




sub read_UniMap
{
    my ($fname) = @_;
    my ($res) = [];

    open(INFILE, "$fname") || return undef;
    while (<INFILE>)
    {
        s/\#.*$//oi;
        $res->[hex($1)] = hex($2) if (m/^\s*((?:0x)?[0-9a-f]+)\s*((?:0x)?[0-9a-f]+)/oi);
    }
    close(INFILE);

    $res;
}

sub make_tfm
{
    my ($font, $map, $fontname, $tfmname) = @_;
    my ($upem) = $font->{'head'}->read->{'unitsPerEm'};
    my ($xheight, $bc, $ec, $i, $j, $nw, @widths, $nd, @depths, @unsrt, $csum, $s2);
    my (@gids) = map {{'gid' => $font->{'cmap'}->ms_lookup($_)}} @{$map};
    my ($outfh) = IO::File->new("> $tfmname") || die "Can't open $tfmname for writing";
    binmode $outfh;
    
    $font->{'OS/2'}->read;
    $font->{'hmtx'}->read;
    $font->{'loca'}->read;
    $xheight = $font->{'OS/2'}{'xHeight'} || .4 * $upem;
    
    @tparam = (
        int((1 << 20) * tan($font->{'post'}{'italicAngle'} * 3.1415926535/180) + .5),
        scale($font->{'hmtx'}{'advance'}[$gids[32]{'gid'}], $upem),
        $font->{'post'}{'isFixedPitch'} ? 0 : 300,
        $font->{'post'}{'isFixedPitch'} ? 0 : 100,
        scale($xheight, $upem),
        scale(1000, 1000)
        );

    for ($i = 0; $i < 256; $i++)
    { last if $gids[$i]{'gid'}; }
    $bc = $i;
    for ($i = 255; $i >= 0; $i--)
    { last if $gids[$i]{'gid'}; }
    $ec = $i;

    for ($i = $bc; $i <= $ec; $i++)
    {
        my ($name) = $font->{'post'}{'VAL'}[$gids[$i]{'gid'}];
        $name = $texCorrect{$name} if ($opt_x && defined $texCorrect{$name});
        $csum = ($csum << 1) ^ ($csum >> 31) ^ scale($font->{'hmtx'}{'advance'}[$gids[$i]{'gid'}], $upem);
        $csum = $csum & 0xffffffff;
        foreach $j (unpack('C*', $name))
        { $s2 = ($s2 * 3) + $j; }
    }
    $csum = ($csum << 1) ^ $s2;

    $widths[0] = 0;
    $nw = proc_gids($bc, $ec, \@gids, \@widths, 'wid', 256, $upem,
            sub {$font->{'hmtx'}{'advance'}[$_[0]]});

    $depths[0] = 0;
    $nd = proc_gids($bc, $ec, \@gids, \@depths, 'depth', 16, $upem,
            sub {$font->{'loca'}{'glyphs'}[$_[0]]->read->{'yMin'} if ($font->{'loca'}{'glyphs'}[$_[0]]); });
    
    $heights[0] = 0;
    $nh = proc_gids($bc, $ec, \@gids, \@heights, 'height', 16, $upem,
            sub {$font->{'loca'}{'glyphs'}[$_[0]]{'yMax'} if ($font->{'loca'}{'glyphs'}[$_[0]]); });
    
    $italics[0] = 0;
    $ni = proc_gids($bc, $ec, \@gids, \@italics, 'italicc', 64, $upem,
            sub {$font->{'loca'}{'glyphs'}[$_[0]]{'xMax'} - $font->{'hmtx'}{'advance'}[$_[0]]});
    
    $outfh->print(pack('n12 N2Ca39Ca19', 29 + $ec - $bc + 1 + $nw + $nh + $nd + $ni,
        17, $bc, $ec, $nw, $nh, $nd, $ni, 0, 0, 0, 6,
        $csum, 0xa00000, 11, "Unspecified", length($fontname), $fontname));
    for ($i = $bc; $i <= $ec; $i++)
    { 
        $g = $gids[$i];
        $outfh->print(pack('C4', $g->{'wid'}, ($g->{'height'} << 4) + $g->{'depth'}, 
                $g->{'italicc'} << 2, 0));
    }
    $outfh->print(pack('N*', @widths[0..$nw-1], @heights[0..$nh-1], @depths[0..$nd-1], 
            @italics[0..$ni-1], @tparam));
    $outfh->close();
}


sub scale
{
    my ($val, $upem) = @_;
    
    return int((($val / $upem) << 20) + ((($val % $upem) << 20) + 500) / 1000);
}


sub proc_gids
{
    my ($bc, $ec, $gids, $vals, $id, $max, $upem, $proc_sub) = @_;
    my ($res, $i, $j, @unsrt, $g);
    
    $res = 1;
    for ($i = $bc; $i <= $ec; $i++)
    {
        next unless ($gids->[$i]{'gid'});
        my ($val) = scale(&{$proc_sub}($gids->[$i]{'gid'}), $upem);
        $vals->[$res] = $val;
        for ($j = 1; $vals->[$j] != $val; $j++) { }
        $gids->[$i]{$id} = $j;
        $res++ if ($j == $res);
    }
    
    if ($res > $max)
    {
        my ($unsrt, $fix) = remap($vals, $res, $max);
        @$vals = (@$fix);
        foreach $g (@$gids)
        {
            next unless (defined $g->{$id});
            $g->{$id} = $unsrt->[$g->{$id}];
        }
        $res = $max;
    }
    $res;
}


sub remap
{
    my ($what, $oldn, $newn) = @_;
    my (@src) = sort {$what->[$a] <=> $what->[$b]} (0 .. $oldn - 1);
    my (@fix) = (sort {$a <=> $b} @$what, 0x7fffffff);
    my (@unsrt, $i, $j, $l);
    my ($i, $nextd) = mincover(0, @fix);
    my ($d) = $nextd;
    
    while ($i > $newn)
    { 
        ($i, $nextd) = mincover(2 * $d, @fix); 
        $d *= 2 if ($i > $newn);
    }
    while ($i > $newn)
    { 
        ($i, $nextd) = mincover($d, @fix);
        $d = $nextd if ($i > $newn);
    }

    $j = 0;
    for ($i = 1; $i < $oldn; )
    {
        $j++;
        $l = $fix[$i];
        $unsrt[$src[$i]] = $j;
        while ($fix[++$i] <= $l + $d)
        {
            $unsrt[$src[$i]] = $j;
            $d = 0 if ($i - $j == $oldn - $newn);
        }
        $fix[$j] = ($l + $fix[$i - 1]) / 2;
    }
    
    return (\@unsrt, \@fix);
}

sub mincover
{
    my ($d, @what) = @_;
    my ($nextd) = 0x7fffffff;
    my ($m, $l, $p);
    
    for ($m = 1, $p = 1; $p < scalar @what - 1; )
    {
        $m++;
        $l = $what[$p];
        while ($what[++$p] <= $l + $d) { }
        $nextd = $what[$p] - $l if ($what[$p] - $l < $nextd);
    }
    return ($m, $nextd);
}

__END__

=head1 TITLE

ttfenc - Create TeX font metrics for a font

=head1 SYNOPSIS

    ttfenc [-e enc_file] [-m mapping_file] [-p map_file] [-t tfm_file]
           [-x] [-d tex_file] [-o font_file] font.ttf
    ttfenc -@config_file font.ttf

=head1 OPTIONS

    -d tex_file         Make TeX definitions for glue in this file
    -e enc_file         Filename of encoding file (including where to store it)
    -m mapping_file     Unicode mapping description file (e.g. cp1252.txt)
    -o font_file        Output a font with fixed names
    -p map_file         The PDFTeX .map file in which to add an entry for this
                        font [OPTIONAL - absent, no entry added]
    -t tfm_file         The name and where to store the .tfm file
    -x                  Enable TeX postscript name correction
    -z flags            bitfield of flags
                        0 - produce tex_file for codes 32-255, default 128-255
                        1 - ignore a-z & 0-9 when making tex_file
    -@config_file       Specifies a file to read command line parameters from

=head1 DESCRIPTION

Creates a Postscript mapping file for the given font according to the 8-bit
to Unicode mapping given in mapping_file. If the font is a Windows symbol font
then no mapping_file is required. If no tfm file is requested, then no map_file
entry is made, either. Requires ttf2afm and afm2tfm to run.

=head1 EXAMPLE USAGE

    ttfenc -e ipa93.enc -m cp1252.txt ipa93sr.ttf

Just creates ipa93.enc from the POST table of ipa93sr.ttf

    ttfenc -e %texmf%\pdftex\base\ipa93.enc -m cp1252.txt -p %texmf%\pdftex\bas
e\ttfmap.map -t %texmf%\fonts\tfm\ttf\ipa93sr.tfm ipa93sr.ttf

Create .tfm, .afm, .enc and install the files in the appropriate places. (The
.afm is left with ipa93sr.log in the current directory)

=cut
