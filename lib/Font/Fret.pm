# Font::Fret::fret('', @ARGV);

package Font::Fret;

use File::stat;

use Font::TTF::Font;
use Text::PDF::File;
use Text::PDF::Page;
use Text::PDF::SFont;
use Text::PDF::TTFont0;
use Text::PDF::Utils;
# use Font::Metrics::Helvetica;
# use Font::Metrics::HelveticaBold;

use Getopt::Std;
use strict;
use vars qw(@ISA %sizes @EXPORT $pdf_helv $pdf_helvb $pdf_helvi $pdf_helvbi $VERSION
            $dots);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(fret);


BEGIN {
    $VERSION = "1.202";

    %sizes = (
        'a4' => [595, 842],
        'ledger' => [1224, 1584],
        'letter' => [612, 792],
        'ltr' => [612, 792],
        'legal' => [612, 1008]
        );
    if ($^O eq "MacOS")
    {
        require Mac::Resources;
        import Mac::Resources;
        require Mac::Memory;
        require IO::Scalar;
    }
    $dots = "0 w [.25 1.25] 0 d";
}


sub fret
{
    my ($package) = @_;
    my ($font, $maxx, $maxy, $pdf, $root);
    my (%opt);
    my ($fh, $fdat);

    getopts("fgh:m:p:qs:", \%opt);

    unless (defined $ARGV[0])
    {
        die <<'EOT';
FRET [-f] [-g] [-s size] [-p package] [-q] font_file [out_file]
Generates a report on a font according to a particular package. In some
contexts the package may be over-ridden. Paper size may also be specified.

If no out_file is given then out_file becomes font_file.pdf (removing .ttf
if present)

  -f            Don't try to save memory on large fonts (>1000 glyphs)
  -g            Add one glyph per page report following summary report
  -h            Mode for glyph per page output. Bitfield:
                1 = bit 0       don't output point positions
  -m points     Sets glyph size in the box regardless of what is calculated
                Regardless of the consequences for clashes
  -p package    Perl package specification to use for report information
  -q            quiet mode  
  -s size       paper size: a4, ltr, legal
EOT
    }

    $opt{s} = lc($opt{s}) || 'ltr';
    $opt{s} = 'ltr' unless defined $sizes{$opt{s}};
    ($maxx, $maxy) = @{$sizes{$opt{s}}};
    $package = $opt{p} || $package || 'Font::Fret::Default';

    unless (defined $ARGV[1])
    {
        $ARGV[1] = $ARGV[0];
        $ARGV[1] =~ s/\.ttf$//oig;
        $ARGV[1] .= ".pdf";
    }

    $pdf = Text::PDF::File->new;
    $pdf->{' version'} = 3;
    $root = Text::PDF::Pages->new($pdf);
    $root->proc_set('PDF', 'Text');
    $root->bbox(0, 0, $maxx, $maxy);
    $pdf_helv = Text::PDF::SFont->new($pdf, "Helvetica", "FR");
    $pdf_helvb = Text::PDF::SFont->new($pdf, "Helvetica-Bold", "FB");
    $pdf_helvi = Text::PDF::SFont->new($pdf, "Helvetica-Oblique", "FI");
    $pdf_helvbi = Text::PDF::SFont->new($pdf, "Helvetica-BoldOblique", "FBI");
    $root->add_font($pdf_helv, $pdf);
    $root->add_font($pdf_helvb, $pdf);
    $root->add_font($pdf_helvi, $pdf);
    $root->add_font($pdf_helvbi, $pdf);

    $Font::TTF::Name::utf8 = 1;

    if ($^O eq "MacOS")
    {
        $ARGV[1] =~ s/([^:]+)$/susbtr($1, length($1) - 31, 31)/oie
                if ($ARGV[1] =~ m/([^:]+)$/oi && length($1) > 31);
        my ($type, $rid, $rh, $num, $rcur);
        
        $type = MacPerl::GetFileInfo($ARGV[0]);
        if ($type eq "tfil" || $type eq "FFIL")
        {
            $rcur = CurResFile();
            $rid = OpenResFile($ARGV[0]);
#            UseResFile($rid);
#            $num = Count1Resources("sfnt");
#            while ($num-- > 0)
#            {
#                UseResFile($rid);
#                $rh = Get1IndResource("sfnt", $num + 1);
                $rh = Get1IndResource("sfnt", 1);
                UseResFile($rcur);
                LoadResource($rh) || die "Couldn't load resource";
                $fdat = $rh->get;
                $fh = IO::Scalar->new(\$fdat);
                ReleaseResource($rh);
                $font = Font::TTF::Font->open($fh) || next;
                process_font($package, $font, $pdf, $root, $maxx, $maxy, $num,
                        %opt) unless ($num == 0);
#            }
#            CloseResFile($rid);
        } else
        { $font = Font::TTF::Font->open($ARGV[0]) || die "Can't open font file $ARGV[0]"; }
    } else
    { $font = Font::TTF::Font->open($ARGV[0]) || die "Can't open font file $ARGV[0]"; }
    $pdf->create_file($ARGV[1]);
    process_font($package, $font, $pdf, $root, $maxx, $maxy, "a0", %opt);
    $pdf->close_file;
}

sub process_font
{
    my ($package, $font, $pdf, $root, $maxx, $maxy, $id, %opt) = @_;
    my (@rev, $i, $numg, $upem, $mextx, $mexty, $tsize, $gsize);
    my ($tfont, $fname, $nump, $maxg, $pnum, $page, $cpyright, $ftrleft);
    my (@rowt, @roww, @row1, @row2, $hdrlft, $hdrright, $pcpy, $hdrbox, $hdrrw);
    my ($gcount, $tr, $tr1, $ppage, @time, @boxhdr, @boxloc, @cids, $numc, $gid);
    my ($type, $rpos);
    my ($optgsize, $maxp);

#    $font->tables_do(sub { $_[0]->read; });
    @rev = $font->{'cmap'}->read->reverse;

    $numg = $font->{'maxp'}->read->{'numGlyphs'};
    $upem = $font->{'head'}->read->{'unitsPerEm'};
    $font->{'loca'}->read->glyphs_do(sub {
        $_[0]->read;
        my ($x) = ($_[0]->{'xMax'}-$_[0]->{'xMin'});
        $mextx = $x if $x > $mextx;
        $_[0]->empty if ($numg > 1000 && !$opt{f});
    });
    $mexty = ($font->{'head'}{'yMax'} - $font->{'head'}{'yMin'}) / 64;
    $mextx /= 48;
    if ($opt{g})
    {
        my ($gextx, $gexty) = ($mextx * 48, $mexty * 64);
        my ($gmextx) = ($maxx - 116) * $upem / $gextx;
        my ($gmexty) = ($maxy - 288) * $upem / $gexty;
        $optgsize = $gmextx > $gmexty ? $gmexty : $gmextx;
    }

    $tsize = $opt{m} || int ($upem / ($mextx > $mexty ? $mextx : $mexty) * 100 - .5) / 100;
    $gsize = int ($upem / $mexty * 25 - .5) / 100;
#    print "tsize = $tsize\n";

    $tfont = Text::PDF::TTFont0->new($pdf, $font, "T$id");
    $root->add_font($tfont, $pdf);
    if ($numg > 1000 && !$opt{f})
    {
        $tfont->ship_out($pdf);
        $tfont->empty;
    }

#    print "numg = $numg\n";
    ($type, @cids) = $package->make_cids($font);
    $numc = @cids;
    $maxg = (($maxy - 121) / 67) << 2;
    $nump = int (($numc + $maxg - 1) / $maxg);
#    print "maxg = $maxg\nnump = $nump\n";
    $maxp = $nump;
    $maxp += $numc if ($opt{g});

    $fname = $font->{'name'}->read->find_name(4);
    $cpyright = $font->{'name'}->find_name(0);
    $cpyright = PDFStr($pdf_helv->trim($cpyright, ($maxx - 72) / 5.6));

    # 80% compressed 7pt Helvetica
    $ARGV[0] =~ s/\\/\\/oig;
    $pcpy = "BT 1 0 0 1 36 " . ($maxy - 67) . " Tm 80 Tz /FR 7 Tf "
        . $cpyright->as_pdf . " Tj 0 8 Td " . asPDFStr("$ARGV[0]") . " Tj ET\n";
    $hdrlft = "BT 1 0 0 1 36 " . ($maxy - 48) . " Tm 80 Tz /FB 12 Tf "
        . asPDFStr($fname) . " Tj ET\n";
no strict;        
    $ftrleft = "BT 1 0 0 1 36 27 Tm 80 Tz /FR 7 Tf (FRET v$VERSION "
        . "Package $package " . ${"${package}::VERSION"} . ") Tj ET\n";
use strict;
    @time = split(/\s+/, localtime());
    $tr = "Printed at $time[3] on $time[0] $time[2] $time[1] $time[4]   Page ";
    @time = split(/\s+/, localtime($font->{'head'}->getdate));
    $hdrrw = "Modified at $time[3] on $time[0] $time[2] $time[1] $time[4]";
    $rpos = $maxx - 36 - $pdf_helv->width($hdrrw) * 5.6;
    $hdrlft .= "BT 1 0 0 1 $rpos ". ($maxy - 58) . " Tm 80 Tz /FR 7 Tf "
        . "($hdrrw) Tj ET\n";
    $tr1 = " of $maxp";
    $hdrrw = ($pdf_helv->width($tr) + $pdf_helv->width($tr1)) * 9.6;
    $hdrright = "BT 1 0 0 1 %x " . ($maxy - 48) .
        " Tm 80 Tz /FR 12 Tf ($tr) Tj /FB 12 Tf (%p) Tj /FR 12 Tf ($tr1) Tj ET\n";
    $hdrbox = ".5 w 36 " . ($maxy - 86) . " 216 16 re S " .
        "198 " . ($maxy - 86) . " m 198 " . ($maxy - 70) . " l s $dots 198 " . ($maxy - 78) .
        " m 252 " . ($maxy - 78) . " l s 225 ". ($maxy - 86) . " m 225 ". ($maxy - 70) .
        " l s [] 0 d ".
        "BT 1 0 0 1 39 " . ($maxy - 81) . " Tm 80 Tz /FI 9 Tf (Size: ) Tj /FB 9 Tf ($tsize pt   ) Tj ".
        "/FI 9 Tf (Em: ) Tj /FB 9 Tf ($upem   ) Tj /FI 9 Tf ".
        "(Type: ) Tj /FB 9 Tf ($type) Tj 225 3 Td /FR 8 Tf (Glyph) Tj ET\n";
    @boxhdr = $package->boxhdr($font);
    @boxloc = ([199, 85], [251, 85], [199, 77], [251, 77]);
    for ($i = 0; $i < 4; $i++)
    {
        my ($text) = $pdf_helv->trim($boxhdr[$i], 4.58);
        my ($x) = $boxloc[$i][0] - ($i & 1 ? $pdf_helv->width($text) * 4.8 : 0);
        
        $hdrbox .= "BT 1 0 0 1 $x " . ($maxy - $boxloc[$i][1]) . " Tm 80 Tz " .
                 "/FR 6 Tf " . asPDFStr($text) . " Tj ET\n";
    }

    $gcount = 0;
    @rowt = $package->row1hdr($font);
    @roww = widths(8, \@rowt);
# structure of @rown: array of [text strings, text widths, yorg, pt]
    push (@row1, [[@rowt], [@roww], $maxy - 77, 8]);
    @rowt = $package->row2hdr($font);
    @roww = widths(8, \@rowt);
    push (@row2, [[@rowt], [@roww], $maxy - 85, 8]);

#    if (0)
    for ($pnum = 1; $pnum <= $nump; $pnum++)
    {
        my ($rtext, $ybase, $xcentre, $row, $yorg);
        my ($glyph, $xorg, $xadv, $gxorg, $gyorg, @rowm, @xorg, @parms, $gcol);

        print STDERR "." unless ($opt{q} || $^O eq "MacOS");
        
        $ppage = Text::PDF::Page->new($pdf, $root);
        $ppage->add($hdrlft . $pcpy . $hdrbox . $ftrleft);
        $rpos = $maxx - ($hdrrw + $pdf_helvb->width($pnum) * 9.6) - 36;
        $rtext = $hdrright;
        $rtext =~ s/\%x/$rpos/oi;
        $rtext =~ s/\%p/$pnum/oi;
        $ppage->add($rtext);

        @row1 = ($row1[0]);
        @row2 = ($row2[0]);

        $ybase = $maxy - 153;
        for ($row = 0; $row < $maxg / 4; $row++)
        {
            $ppage->add(".5 w 36 $ybase 216 64 re S 90 $ybase m 90 " . ($ybase + 64)
                   . " l S 144 $ybase m 144 " . ($ybase + 64) . " l S"
                   . " 198 $ybase m 198 " . ($ybase + 64) . " l S"
                   . " $dots 264 " . ($ybase + 65.5) . " m " . ($maxx - 36) . " "
                   . ($ybase + 65.5) . " l s [] 0 d\n");
            $yorg = $ybase + 32 - ($font->{'head'}{'yMax'} + $font->{'head'}{'yMin'}) * $tsize / $upem / 2;
            $ppage->add("$dots 36 $yorg m 252 $yorg l S [] 0 d\n") if ($yorg > $ybase);
            $xcentre = 63;
            for ($i = 0; $i < 4; $i++, $xcentre += 54)
            {
                next if ($gcount + $i >= $numc);
                $gcol = "";
                $gid = $package->cid_gid($cids[$gcount + $i], $font);
                $gid =~ s/^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\|//oi
                        && ($gcol = sprintf("%.2f %.2f %.2f rg",
                                            hex($1), hex($2), hex($3)));
                $glyph = $font->{'loca'}{'glyphs'}[$gid];
                if ($glyph && $glyph->{' LEN'} != 0)
                {
                    $glyph->read;
                    $xorg = ($glyph->{'xMax'} + $glyph->{'xMin'}) * $tsize / $upem;
                    $xorg = $xcentre - $xorg / 2;
                    $xadv = $xorg + $font->{'hmtx'}{'advance'}[$gid] * $tsize / $upem;
                    $ppage->add("$dots $xadv " . ($ybase + 7) . " m $xadv "
                            . ($ybase + 57) . " l S [] 0 d\n") if ($xadv < $xcentre + 27);
                    $ppage->add("$dots $xorg " . ($ybase + 7) . " m $xorg "
                            . ($ybase + 57) . " l S [] 0 d\n") if ($xorg > $xcentre - 27
                            && $xorg < $xcentre + 27);
                    $ppage->add("BT 1 0 0 1 $xorg $yorg Tm /T$id $tsize Tf 100 Tz " .
                            $gcol . sprintf("<%04X> Tj " .
                            ($gcol ? "0 g " : "") . "ET\n", $gid));
                    $gxorg = ($glyph->{'xMax'} + $glyph->{'xMin'}) * $gsize / $upem / 2;
                    $gxorg = 274 - $gxorg;
                    $gyorg = $ybase + (3 - $i) * 16 + 8 - ($font->{'head'}{'yMax'} +
                            $font->{'head'}{'yMin'}) * $gsize / $upem / 2;;
                    $ppage->add("BT 1 0 0 1 $gxorg $gyorg Tm /T$id $gsize Tf 100 Tz " .
                            sprintf("<%04X> Tj ET\n", $gid));
                }
                @parms = ($cids[$gcount + $i], $gid, $glyph, $rev[$gid], $font);
                @rowt = $package->topdat(@parms);
                @roww = widths(6, \@rowt);
                @xorg = ([$xcentre - 26, $xcentre + 24 - $roww[1]],
                        [$xcentre + 25 - $roww[1], $xcentre + 26]);
                $ppage->add(out_row($pdf, 6, $ybase + 58, \@xorg, \@rowt));
                @rowt = $package->lowdat(@parms);
                @roww = widths(6, \@rowt);
                @xorg = ([$xcentre - 26, $xcentre + 24 - $roww[1]],
                        [$xcentre + 25 - $roww[1], $xcentre + 26]);
                $ppage->add(out_row($pdf, 6, $ybase + 2, \@xorg, \@rowt));
                @rowt = $package->row1(@parms);
                @roww = widths(8, \@rowt);
                push (@row1, [[@rowt], [@roww], $ybase + (3-$i) * 16 + 8.75, 8]);
                @rowt = $package->row2(@parms);
                @roww = widths(8, \@rowt);
                push (@row2, [[@rowt], [@roww], $ybase + (3-$i) * 16 + .75, 8]);
                $glyph->empty if ($glyph && $numg > 1000 && !$opt{f});
            }
        $gcount += 4;
        last if ($gcount >= $numc);
        $ybase -= 67;
        }
    @rowm = maxwidth(\@row1, $maxx - 330);
    putrows($pdf, \@row1, \@rowm, 294, $ppage);
    @rowm = maxwidth(\@row2, $maxx - 348);
    putrows($pdf, \@row2, \@rowm, 312, $ppage);
    $ppage->{' curstrm'}{'Filter'} = PDFArray(PDFName('FlateDecode'));
    $ppage->ship_out($pdf);
    $ppage->empty;
    }

    return unless $opt{g};
    
    my ($fxmin, $fymin) = ($font->{'head'}{'xMin'}, $font->{'head'}{'yMin'});
    my ($blob) = "q 2 w 1 J s Q";
    my ($bigblob) = "q 4 w 1 J s Q";
    my ($offblob) = "q .5 w 1 J s Q";
    my ($rtext, $glyph, $gcol, $xorg, $yorg, $xwidth);
    my ($points, $onoff, $ends, $corners, $j, @dirs, $txt, $jnext, $jprev);
    my ($p, $x, $y, $e, $cx, $cy, $x0, $y0, $xlast, $ylast, $iscurve);
    my ($tw, $tx, $ty, $ta);
    
    for ($i = 0; $i < $numc; $i++)
    {
        print STDERR "+" unless ($opt{q} || $^O eq "MacOS");

        $gid = $package->cid_gid($cids[$i], $font);
        $gid =~ s/^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\|//oi
                && ($gcol = sprintf("%.2f %.2f %.2f rg",
                                    hex($1), hex($2), hex($3)));
        $glyph = $font->{'loca'}{'glyphs'}[$gid];
        next unless $glyph;
        $glyph->read;
        $pnum = $nump + $i + 1;
        $ppage = Text::PDF::Page->new($pdf, $root);
        $ppage->add($hdrlft . $pcpy . $ftrleft);
        $rpos = $maxx - ($hdrrw + $pdf_helvb->width($pnum) * 9.6) - 36;
        $rtext = $hdrright;
        $rtext =~ s/\%x/$rpos/oi;
        $rtext =~ s/\%p/$pnum/oi;
        $ppage->add($rtext);

        $yorg = 144 - $fymin * $optgsize / $upem;
        $ppage->add("$dots 58 $yorg m " . ($maxx - 58) . " $yorg l S [] 0 d\n");
        $xorg = 58 - $fxmin * $optgsize / $upem;
        $ppage->add("$dots $xorg 144 m $xorg " . ($maxy - 144) . " l S [] 0 d\n");
        $xwidth = ($font->{'hmtx'}{'advance'}[$gid] - $fxmin) * $optgsize / $upem + 58;
        $ppage->add("$dots $xwidth 144 m $xwidth " . ($maxy - 144) . " l S [] 0 d\n");
        $ppage->add("BT 1 0 0 1 36 " . ($maxy - 132) . " Tm /T$id $tsize Tf 100 Tz " .
                $gcol . sprintf("<%04X> Tj " . ($gcol ? "0 g " : "") . "ET\n", $gid));
#        $ppage->add("BT 1 0 0 1 " . ($maxx - 36 - $pdf_helvb->width("$i") * 19.2) . " " .
#                ($maxy - 136) . " Tm 80 Tz /FB 24 Tf ($i) Tj ET\n");
        @rowt = $package->topdat($cids[$i], $gid, $glyph, $rev[$gid], $font);
        foreach (@rowt) { s/^(.*?\|)?/r,b|/o; }
        @roww = widths(24, \@rowt);
        $ppage->add(out_row($pdf, 24, $maxy - 118, [[200, $maxx - 36]], [$rowt[0]]));
        $ppage->add(out_row($pdf, 24, $maxy - 94, [[200, $maxx - 36]], [$rowt[1]]));

        $points = [];
        @dirs = ();
        ($points, $onoff, $ends, $corners) = get_points($font, $glyph, $points, 1, 0, 0, 1);
        $e = 0;
        for ($j = 0; $j <= $#{$points}; $j++)
        {
            $x = ($points->[$j][0] - $fxmin) * $optgsize / $upem + 58;
            $y = ($points->[$j][1] - $fymin) * $optgsize / $upem + 144;
            $jnext = ($j == $ends->[$e] ? ($e == 0 ? 0 : $ends->[$e-1] + 1) : $j + 1);
            $jprev = ($j == 0 || $j == $ends->[$e-1] + 1) ? $ends->[$e] : $j - 1;
            if ($j == 0 || $j == $ends->[$e - 1] + 1)
            {
                unless ($j == 0)
                {
                    $ppage->add(curveto($cx, $cy, $x0, $y0, $xlast, $ylast)) if ($iscurve);
                    $ppage->add(" s\n");
                }
                $ppage->add(sprintf("%.2f %.2f m", $x, $y));
                ($x0, $y0) = ($xlast, $ylast) = ($x, $y);
                $iscurve = 0;
            } elsif (!$onoff->[$j])
            {
                if ($iscurve)
                {
                    ($tx, $ty) = (.5 * ($cx + $x), .5 * ($cy + $y));
                    $ppage->add(curveto($cx, $cy, $tx, $ty, $xlast, $ylast));
                    ($xlast, $ylast) = ($tx, $ty);
                }
                ($cx, $cy) = ($x, $y);
                $iscurve = 1;
            } else
            {
                if ($iscurve)
                { $ppage->add(curveto($cx, $cy, $x, $y, $xlast, $ylast)); }
                else
                { $ppage->add(sprintf(" %.2f %.2f l", $x, $y)); }
                $iscurve = 0;
                ($xlast, $ylast) = ($x, $y);
            }
            push (@dirs, [($points->[$jprev][1] - $points->[$jnext][1]) / $upem,
                            ($points->[$jnext][0] - $points->[$jprev][0]) / $upem]);
            $e++ if ($j == $ends->[$e]);
        }
        if ($iscurve)
        { $ppage->add(curveto($cx, $cy, $x0, $y0, $xlast, $ylast)); }
        $ppage->add(" s\n");
        $e = 0;
        for ($j = 0; $j <= $#{$points}; $j++)
        {
            $x = ($points->[$j][0] - $fxmin) * $optgsize / $upem + 58;
            $y = ($points->[$j][1] - $fymin) * $optgsize / $upem + 144;
            $e++ if ($j == $ends->[$e] + 1);
            $txt = $package->label($glyph, $j, @{$points->[$j]}, $e, $onoff->[$j], $font);
            
            if ($onoff->[$j])
            {
                if ($j == 0 || $j == $ends->[$e-1] + 1)
                { $ppage->add(sprintf("%.2f %.2f m %s\n", $x, $y, $bigblob)); }
                else
                { $ppage->add(sprintf("%.2f %.2f m %s\n", $x, $y, $blob)); }
            } else
            { $ppage->add(sprintf("%.2f %.2f m %s\n", $x, $y, $offblob)); }
            if ($txt ne '' && $opt{'h'} & 1 == 0)
            {
                $tw = $pdf_helv->width($txt) * 4.8 + 2;         # 6pt + 2pt margin
                $tx = $x + ($dirs[$j][0] > 0 ? 0 : -$tw);
                $ty = $y + ($dirs[$j][1] > 0 ? 0 : -6);
#                $tx = $dirs[$j][0] ? $tw / $dirs->[$j][0] : 300;
#                $ty = $dirs[$j][1] ? 3 / $dirs->[$j][1] : 300;                   # centre == 2pt + 1pt margin
#                $ta = (abs($tx) > abs($ty)) ? abs($ty) : abs($tx);
#                $tx = $x + $ta * $dirs->[$j][0] * $optgsize;
#                $ty = $y + $ta * $dirs->[$j][1] * $optgsize;
                $ppage->add(sprintf("BT 1 0 0 1 %.2f %.2f Tm 80 Tz /FR 6 Tf %s Tj ET\n",
                        $tx, $ty, asPDFStr($txt)));
            }
        }

        $ppage->{' curstrm'}{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $ppage->ship_out($pdf);
        $ppage->empty;
    }
}

sub curveto
{
    my ($cx, $cy, $x, $y, $xl, $yl) = @_;
    my ($p1x, $p1y, $p2x, $p2y);

    $p1x = (2 * $cx + $xl) / 3;
    $p1y = (2 * $cy + $yl) / 3;
    $p2x = (2 * $cx + $x) / 3;
    $p2y = (2 * $cy + $y) / 3;

    sprintf(" %.2f %.2f %.2f %.2f %.2f %.2f c", $p1x, $p1y, $p2x, $p2y, $x, $y);
}
    

# Taken from Geometric Algorithms - 2D Cross product
sub clockwise
{
    my ($p0, $p1, $p2) = @_;
    return ($p2->[0] - $p0->[0]) * ($p1->[1] - $p0->[1])
        - ($p1->[0] - $p0->[0]) * ($p2->[1] - $p0->[1]);
}


sub get_points
{
    my ($font, $glyph, $points, @scale) = @_;
    my ($onoff, $ends, $corners);
    my ($comp, $g);

    $glyph->read_dat;
    if ($glyph->{'numberOfContours'} < 0)
    {
        foreach $comp (@{$glyph->{'comps'}})
        {
            my (@tcorner, $cg);
            $cg = $font->{'loca'}{'glyphs'}[$comp->{'glyph'}];
            my ($tpoints, $tonoff, $tends, $tcorners)
                    = get_points($font, $cg, $points, mat_mult($comp->{'scale'}, \@scale));
            my ($base) = $#{$points};
            $base++ if ($base != 0);
                
            push (@$points, map {[$_->[0] + $comp->{'args'}[0], $_->[1] + $comp->{'args'}[1]]}
                    @$tpoints);
            push (@$onoff, @$tonoff);
            push (@$ends, map {$_ + $base} @$tends);
            
            @tcorner = mat_mult($comp->{'flag'} & 200 ? $comp->{'scale'} : [1, 0, 0, 1],
                    [$cg->{xMin}, $g->{'yMin'}, $cg->{'xMax'}, $cg->{'yMax'}]);
            push (@$corners, [@tcorner]);
        }
        return ($points, $onoff, $ends, $corners);
    } else
    {
        my ($count) = $glyph->{'numPoints'} - 1;

        return ([map({[$glyph->{'x'}[$_], $glyph->{'y'}[$_]]} (0 .. $count))],
            [map({$glyph->{'flags'}[$_] & 1} (0 .. $count))],
            $glyph->{'endPoints'}, undef);
    }
}


sub mat_mult
{
    my ($x, $y) = @_;
    my (@res);

    $res[0] = $x->[0]*$y->[0] + $x->[1]*$y->[2];
    $res[1] = $x->[0]*$y->[1] + $x->[1]*$y->[3];
    $res[2] = $x->[2]*$y->[0] + $x->[3]*$y->[2];
    $res[3] = $x->[2]*$y->[1] + $x->[3]*$y->[4];
    (@res);
}
        

sub widths
{
    my ($pt, $row) = @_;
    my ($type, @info, $ft, $fr, $g, $f, $col, @resv, @rest, $i, $e);

    @resv = ();
    for ($i = 0; $i <= $#{$row}; $i++)
    {
        $e = $row->[$i];
        $e =~ s/^(.*[^\\])\|//oi;
        $type = $1;
        @info = split(',', $type);
        $ft = "";
        if ($info[1] =~ /b/oi)
        {
            $ft = "B";
            $fr = $pdf_helvb;
        }
        if ($info[1] =~/i/oi)
        {
            $ft .= "I";
            $fr = $ft eq "B" ? $pdf_helvbi : $pdf_helvi;
        }
        unless ($ft)
        {
            $ft = "R";
            $fr = $pdf_helv;
        }
        $info[0] = "l" unless $info[0];
        $g = $fr->width($e) * $pt * .8;
        push (@resv, $g);
    }
    (@resv);
}

sub out_row
{
    my ($pdf, $pt, $yorg, $xorg, $row) = @_;
    my ($xl, $xc, $xr, $e, $res, $i, $g, $f, $col, @info, $ft, $fr, $type);

    for ($i = 0; $i <= $#{$row}; $i++)
    {
        $xl = $xorg->[$i][0];
        $xr = $xorg->[$i][1];
        $e = $row->[$i];
        $e =~ s/^(.*[^\\])\|//oi;
        $type = $1;
        $e =~ s/\\\|/\|/oig;
        @info = split(',', $type);
        $ft = "";
        if ($info[1] =~ /b/oi)
        {
            $ft = "B";
            $fr = $pdf_helvb;
        }
        if ($info[1] =~/i/oi)
        {
            $ft .= "I";
            $fr = $ft eq "B" ? $pdf_helvbi : $pdf_helvi;
        }
        unless ($ft)
        {
            $ft = "R";
            $fr = $pdf_helv;
        }
        $g = $fr->width($e) * $pt * .8;
        if ($g > $xr - $xl)
        {
            $e = $fr->trim($e, ($xr - $xl) * 1.25 / $pt);
            $g = $fr->width($e) * $pt * .8;
        }
        $xc = ($xl + $xr - $g) / 2;
        $xr -= $g;
        $col = sprintf("%.2f %.2f %.2f rg", hex($1)/256, hex($2)/256, hex($3)/256)
                if $info[2] =~ m/([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/oi;
        $f = "BT $col 1 0 0 1 ";
        if ($info[0] =~ m/r/oi)
        { $f .= "$xr"; }
        elsif ($info[0] =~ m/c/oi)
        { $f .= "$xc"; }
        else
        { $f .= "$xl"; }
        $f .= " $yorg Tm ";
        $g = PDFStr($e);
        $f .= "/F$ft $pt Tf 80 Tz " . $g->as_pdf . " Tj ET";
        $f .= " 0 g" if ($col);
        $col = "";
        $res .= "$f\n";
    }
    $res;
}

sub maxwidth
{
    my ($row, $total) = @_;
    my ($i, @resm, $max, $j, $e);

    for ($i = 0; $i <= $#{$row}; $i++)
    {
        $e = $row->[$i][1];
        for ($j = 0; $j <= $#{$e}; $j++)
        { $resm[$j] = $e->[$j] if $e->[$j] > $resm[$j]; }
    }
    foreach (@resm)
    { $max += $_; }
    if ($max > $total && $^O ne "MacOS")
    { print STDERR "Warning overfull box. Truncating all boxes on the page!\n"; }
    $max = ($total - $max) / @resm;
    for ($i = 0; $i <= $#resm; $i++)
    { $resm[$i] += $max; }
    @resm;
}

sub putrows
{
    my ($pdf, $row, $rowm, $x, $npage) = @_;
    my ($i, $j, $rowt, @rowp);

    for ($i = 0; $i <= $#{$rowm}; $i++)
    { push (@rowp, [$x, $x + $rowm->[$i]]); $x += $rowm->[$i]; }
    
    for ($i = 0; $i <= $#{$row}; $i++)
    { $npage->add(out_row($pdf, $row->[$i][3], $row->[$i][2], \@rowp, $row->[$i][0])); }
}

1;

package Font::Fret::Default;

use strict;
use vars qw(@macrev $VERSION);

BEGIN
{
    $VERSION = "1.0";
}


=head1 NAME

Fret - Font REporting Tool

=head1 SYNOPSIS

    use Font::Fret;
    fret('', @ARGV);

or

    package myFret;
    use Font::Fret;
    @ISA = qw(Font::Fret::Default);
    fret('myFret', @ARGV);

=head1 DESCRIPTION

Fret is a font reporting tool system which allows for different reports to be
written. A report is a package on which calls are made to give specific information
for a specific report. The rest of Fret does the housekeeping of generating the
report in PDF format.

The function C<fret> which is imported when the Fret moduled is 'use'd, takes
two arguments: the name of the report package and the command line array. Fret
does all the work of parsing the command line, etc. and just makes call-backs into
the package it is asked to use.

Fret.pm comes with its own default report package (called Font::Fret::Default)
which may be subclassed to generate other reports.

The overall structure of the interaction between Fret and the reporting
package is that Fret will ask the package for a list of character ids in
the order in which those characters should appear in the report. For
each character, Fret will ask the package to create a glyph id for that
character. This allows a double layer of indirection in arriving at the list of
glyph ids to process, allowing a glyph to appear twice in the report with
different information about it each time.

There are two important areas in a report: inside the glyph box (where there are
four corners in which information may be displayed) and the report area, which
consists of two independent rows of information for each glyph. Each row type
is columnated independently across all the glyphs on a page.

In addition to where the report information is displayed, there is also a mechanism
which allows a limited level of formatting of the information. The text may be
justified left, right or centre and the font styling may be adjusted between
regular, bold, italic and bold italic and the colour of the text may be changed.
Notice that the font face may not be changed or the font size or anything else.
A formatted string consists of formatting information separated from the string
by C<|>. If a string needs to contain a C<|> it should be escaped thus:
C<\|> (notice that there is no need to escape C<\> or any other character).

The formatting is structured as a comma separated list of 3 elements: justification,
font styling and then colour.

=item justification

The values are r: right justified; c: centred and the default of l: left justified

=item font styling

The values are r: regular (by default); i: italic; b: bold; bi: bold-italic

=item colour

The colour is a string of 6 hex digits corresponding to 8-bits of Red, Green
and Blue information

=back

=head1 METHODS


=head2 make_cids

This subroutine is called to ask for a list of character ids, which will be used
to generate glyph ids and thence glyphs. The returned list is rendered in the
order of the list.

The first item on the returned list is used to display the type of report in the
box header. This string may not be formatted.

This allows a FRET report writer to generate any sequence of glyphs in their
report (e.g. Unicode based, pass/fail conditions, etc.)

=cut

sub make_cids
{
    my ($class, $font) = @_;

    return ("Glyph ID", 0 .. $font->{'maxp'}{'numGlyphs'} - 1);
}

=head2 cid_gid

This is called to convert a character id into a glyph id for rendering.

=cut

sub cid_gid
{
    my ($class, $cid, $font) = @_;

    return $cid;
}


=head2 boxhdr

This subroutine is called to ask the report for the headings for the four items
displayed in a box. The headings appear in the box header. The order of the
returned list of string is: bottom left, bottom right, top left, top right.
The strings may not be formatted in any way.

=cut

sub boxhdr
{
    my ($class, $font) = @_;

    return ("Advance", "Mac ID", "GID", "Unicode");
}


=head2 topdat

This subroutine returns the two strings that constitute what should be displayed
in the top of a glyph box. The two strings allow for per glyph formatting. Notice
that the default action is to render the right hand element (the second element)
right justified.

=cut

sub topdat
{
    my ($class, $cid, $gid, $glyph, $uid, $font) = @_;

    return ($gid, sprintf("r,r|U+%04X", $uid));
}


=head2 lowdat

This subroutine returns two elements for the two elements displayed at the bottom
of a glyph box. The elements may be formatted for colour, etc. and the second
should be right formatted.

=cut

sub lowdat
{
    my ($class, $cid, $gid, $glyph, $uid, $font) = @_;

    return ($font->{'hmtx'}{'advance'}[$gid], "r|$macrev[$gid]");
}


=head2 row1hdr

This returns the heading information for the first report row. The value returned
is a list of formatted items, which will be used to head the columns in row 1 of
the report area. These will be combined in the column width calculations.

=cut

sub row1hdr
{
    my ($class, $font) = @_;
    my ($i);

    for ($i = 0; $i < $font->{'cmap'}{'Num'}; $i++)
    {
        if ($font->{'cmap'}{'Tables'}[$i]{'Platform'} == 1)
        { @macrev = $font->{'cmap'}->reverse($i); last; }
    }

    return ('GID', 'Mac', 'UID', 'r|lsb', 'r|rsb',
            'r,b|adv', 'r,i|xmax', 'r,i|xmin', 'r,i|ymax', 'r,i|ymin');
}


=head2 row2hdr

Returns a list of formatted items corresponding to the column headers for row 2
of the report area.

=cut

sub row2hdr
{
    my ($class, $font) = @_;

    return (',,008000|PSname');
}


=head2 row1

This subroutine is called for each glyph to return the content of each column in
row 1 as a list of formatted items. The values passed in are:

    cid     character id as passed to cid_gid
    gid     glyph id as returned from cid_gid and is an index into the font
            for such tables as hmtx.
    glyph   the glyph object from the font i.e. $font->{'loca'}{glyphs}[$gid]
    uid     unicode reverse lookup of the gid. This is the lowest Unicode value
            which maps to this gid
    font    the font object corresponding to this font

Each element in the returned list corresponds to an element in the returned list
for row1hdr

=cut

sub row1
{
    my ($class, $cid, $gid, $glyph, $uid, $font) = @_;
    my ($aw) = $font->{'hmtx'}{'advance'}[$gid];
    my ($rsb) = $aw - $glyph->{'xMax'};

    return ($gid, $macrev[$gid], sprintf("x%04X", $uid),
            "r|$font->{'hmtx'}{'lsb'}[$gid]",
            $rsb >= 0 ? "r|$rsb" : "r,b,0000FF|$rsb",
            "r,b|$aw", "r,i|$glyph->{'xMax'}",
            "r,i|$glyph->{'xMin'}", "r,i|$glyph->{'yMax'}",
            "r,i|$glyph->{'yMin'}");
}


=head2 row2

As per row 1 for row 2

=cut

sub row2
{
    my ($class, $cid, $gid, $glyph, $uid, $font) = @_;

    return (",,008000|$font->{'post'}{'VAL'}[$gid]");
}


=head2 label

Given:

    Glyph
    Point number
    [x, y] point co-ordinates
    path number
    on or off point
    font

Returns a simple string for the label for the point

=cut

sub label
{
    my ($class, $glyph, $pnum, $x, $y, $path, $onoff, $font) = @_;

    if ($glyph->{'numberOfContours'} > 0 && $onoff)
    { return sprintf("%d.%d(%d,%d)", $pnum, $path, $x, $y); }
    return '';
}

