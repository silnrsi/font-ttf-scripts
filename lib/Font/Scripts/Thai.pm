package Font::Scripts::Thai;

use strict;
use vars qw(%class);
use IO::File;
use Font::TTF::Font;
use Font::TTF::Glyph;
use XML::Parser;

BEGIN
{
    my ($i) = 0;
    my (@unis) = (0x0e01 .. 0x0e3a, 0x0e3f .. 0x0e5b, 0xf700 .. 0xf71a, 0x25cc, 0x200b);

    %class = (
    'unis' => [@unis],
    'symb' => [0xf0a1 .. 0xf0da, 0xf0df .. 0xf0fb, 0xf080 .. 0xf084, 0xf086 .. 0xf090,
                0xf098 .. 0xf09f, 0xf0fc .. 0xf0fe, 0x25cc, 0x200b],
    'ansi' => [0x00a1 .. 0x00da, 0x00df .. 0x00fb, 0x20ac, 0x0081, 0x201a, 0x0192, 0x201e,
         0x2020, 0x2021, 0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008d, 0x017d,
         0x008f, 0x0090, 0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, 0x009d, 0x017e,
         0x0178, 0x00fc .. 0x00fe, 0x25cc, 0x200b],
    'ansi95' => [0x00a1 .. 0x00da, 0x00df .. 0x00fb, 0x0080, 0x0081, 0x201a, 0x0192, 0x201e,
         0x2020, 0x2021, 0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008d, 0x008e,
         0x008f, 0x0090, 0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, 0x009d, 0x009e,
         0x0178, 0x00fc .. 0x00fe, 0x25cc, 0x200b],

    'names' => {map {sprintf("uni%04x", $_) => $i++} @unis},

    'base_names' => [qw(space exclam quotedbl numbersign dollar percent ampersand quotesingle
     parenleft parenright asterisk plus comma hyphen period slash zero one two three four
     five six seven eight nine colon semicolon less equal greater question at A B C D E F
     G H I J K L M N O P Q R S T U V W X Y Z bracketleft backslash bracketright asciicircum
     underscore grave a b c d e f g h i j k l m n o p q r s t u v w x y z braceleft bar
     braceright asciitilde)],

     'upper_names' => [qw(space exclamdown cent sterling currency yen brokenbar section
     dieresis copyright ordfeminine guillemotleft logicalnot dash registered macron
     degree plusminus twosuperior threesuperior acute mu paragraph periodcentered
     cedilla onesuperior ordmasculine guillemotright onequarter onehalf threequarters
     questiondown Agrave Aacute Acircumflex Atilde Adieresis Aring AE Ccedilla Egrave
     Eacute Ecircumflex Edieresis Igrave Iacute Icircumflex Idieresis Eth Ntilde Ograve
     Oacute Ocircumflex Otilde Odieresis multiply Oslash Ugrave Uacute Ucircumflex Udieresis
     Yacute Thorn germandbls agrave aacute acircumflex atilde adieresis aring ae ccedilla
     egrave eacute ecircumflex edieresis igrave iacute icircumflex idieresis eth ntilde
     ograve oacute ocircumflex otilde odieresis divide oslash ugrave uacute ucircumflex
     udieresis yacute thorn ydieresis)],

    'groups' => {
        'base_cons' => [map{sprintf("uni%04x", $_)} (0x0e01 .. 0x0e1a, 0x0e1c,
                    0x0e1e, 0x0e20 .. 0x0e2e, 0xf700, 0xf70f, 0x25cc)],
        'base_tall' => [qw(uni0e1b uni0e1d uni0e1f)],
        'base_low' => [qw(uni0e0d uni0e0e uni0e0f uni0e10 uni0e24 uni0e26)],
        'base_vowel' => [qw(uni0e30 uni0e32 uni0e40 uni0e41 uni0e42 uni0e43 uni0e44)],
        'base_kern' => [qw(uni0e42 uni0e43 uni0e44)],
        'udia' => [map{sprintf("uni%04x", $_)} (0x0e34 .. 0x0e37, 0x0e47 .. 0x0e4e, 0x0e31)],
        'udia_kern' => [qw(uni0e34 uni0e35 uni0e36 uni0e37)],
        'tones' => [qw(uni0e48 uni0e49 uni0e4a uni0e4b uni0e4c)],
        'ldia' => [qw(uni0e38 uni0e39 uni0e3a)],
        'am' => ['uni0e33'],
    }
    );
}

sub new
{
    my ($class, $fname, $opt_c, $opt_z, $opt_m, $xml_file) = @_;
    my ($self) = {};
    my ($font, $cmap, $k);

    bless $self, ref $class || $class;

    $font = $self->{'font'} = Font::TTF::Font->open($fname) || return warn "Can't open font $fname";
    $self->{'class'} = \%class;

    $cmap = $font->{'cmap'}->read->find_ms;

    unless (defined $cmap->{'val'}{0x0e01})
    {
        if (defined $cmap->{'val'}{0xf0a1})
        { $self->remap($cmap, $class->{'symb'}, $class->{'unis'}); }
        elsif (defined $cmap->{'val'}{0x0080})              # pre Win98 font
        { $self->remap($cmap, $class->{'ansi95'}, $class->{'unis'}); }
        else
        { $self->remap($cmap, $class->{'ansi'}, $class->{'unis'}); }
    }

    $font->{'hmtx'}->read;
    $font->{'loca'}->read;
    $font->{'post'}->read;
    
    fixps($font->{'post'}, $cmap);

    foreach $k (keys %{$class{'names'}})
    {
        my ($gid) = $cmap->{'val'}{$class{'unis'}[$class{'names'}{$k}]};
        $self->{'glyphs'}{$k} = {'gid' => $gid};
        $self->{'all_glyphs'}[$gid] = {'name' => $k,
                                       'unicode' => [$class{'unis'}[$class{'names'}{$k}]]} 
                if ($gid && !defined $self->{'all_glyphs'}[$gid]);
    }

    if ($opt_m)
    { $self->{'slant'} = sin($opt_m * 3.141592535 / 180) / cos($opt_m * 3.1415926535 / 180); }
    else
    { $self->{'slant'} = $self->get_slant(); }
#    print "Slant is " . atan2(1., $self->{'slant'}) * 180 / 3.1415926535 . "\n" if ($self->{'slant'});

    unless ($opt_c || $self->{'glyphs'}{'uni25cc'}{'gid'} != 0)
    { 
        my ($tgid) = $self->make_circle($cmap, $self->{'glyphs'}{'uni0e01'}{'gid'});
        
        $self->{'glyphs'}{'uni25cc'}{'gid'} = $tgid;
        $self->{'font'}{'post'}{'VAL'}[$tgid] = 'uni25cc';
        $self->{'all_glyphs'}[$tgid] = {'name' => 'uni25cc', 'unicode' => [0x25cc]};
    }

    unless ($opt_z || $self->{'glyphs'}{'uni200b'}{'gid'} != 0)
    {
        my ($tgid) = $self->{'font'}{'maxp'}->read->{'numGlyphs'}++;
        
        $self->{'font'}{'hmtx'}{'advance'}[$tgid] = 0;
        $self->{'font'}{'hmtx'}{'lsb'}[$tgid] = 0;
        $cmap->{'val'}{0x200b} = $tgid;
        $self->{'font'}{'post'}{'VAL'}[$tgid] = 'uni200b';
        $self->{'all_glyphs'}[$tgid] = {'name' => 'uni200b', 'unicode' => [0x200b]};
    }

    foreach $k (sort keys %{$cmap->{'val'}})
    {
        my ($gid) = $cmap->{'val'}{$k};
        if ($self->{'all_glyphs'}[$gid])
        { push (@{$self->{'all_glyphs'}[$gid]{'unicode'}}, $k)
                unless ($k eq $self->{'all_glyphs'}[$gid]{'unicode'}[0]); }
        elsif ($k < 127 && $k > 31)
        { $self->{'all_glyphs'}[$gid] = {'name' => $class{'base_names'}[$k - 32], 'unicode' => [$k]}; }
        elsif ($k > 160 && $k < 256)
        { $self->{'all_glyphs'}[$gid] = {'name' => $class{'upper_names'}[$k - 160], 'unicode' => [$k]}; }
        else
        { $self->{'all_glyphs'}[$gid] = {'name' => sprintf("uni%04x", $k), 'unicode' => [$k]}; }
    }
    
    for ($k = 0; $k < $font->{'maxp'}{'numGlyphs'}; $k++)
    { $self->{'all_glyphs'}[$k] = {'name' => sprintf("glyph%03d", $k)} unless ($self->{'all_glyphs'}[$k]); }

    foreach $k (@{$class{'groups'}{'udia'}}, @{$class{'groups'}{'ldia'}})
    { $self->{'all_glyphs'}[$self->{'glyphs'}{$k}{'gid'}]{'type'} = 'MARK'; }

    if ($xml_file)
    { $self->get_attach($xml_file); }
    else
    { $self->make_attach; }
    $self->make_kern;
    $self;
}

sub get_slant
{
    my ($self) = @_;
    my ($maiek) = $self->{'font'}{'loca'}{'glyphs'}[$self->{'glyphs'}{'uni0e48'}{'gid'}]->read;
    my ($maiekn) = $self->{'font'}{'loca'}{'glyphs'}[$self->{'glyphs'}{'unif70a'}{'gid'}]->read;

    if ($self->{'font'}{'hhea'}->read->{'caretSlopeRise'})
    { return $self->{'font'}{'hhea'}{'caretSlopeRun'} / $self->{'font'}{'hhea'}{'caretSlopeRise'}; }
    
    return ($maiek->{'xMax'} - $maiekn->{'xMax'}) / ($maiek->{'yMax'} - $maiekn->{'yMax'});
}


sub make_attach
{
    my ($self) = @_;
    my ($locas) = $self->{'font'}{'loca'}{'glyphs'};
    my ($hmtx) = $self->{'font'}{'hmtx'};
    my ($class) = $self->{'class'};
    my ($glyphs) = $self->{'glyphs'};
    my ($maiekn) = $locas->[$glyphs->{'unif70a'}{'gid'}]->read->{'yMin'};
    my ($maieknx) = $locas->[$glyphs->{'unif70a'}{'gid'}]->read->{'xMax'};
    my ($maieklx) = $locas->[$glyphs->{'unif705'}{'gid'}]->read->{'xMax'};
    my ($maiek) = $locas->[$glyphs->{'uni0e48'}{'gid'}]->read->{'yMin'};
    my ($sarau) = $locas->[$glyphs->{'uni0e38'}{'gid'}]->read->{'yMax'};
    my ($saraul) = $locas->[$glyphs->{'unif718'}{'gid'}]->read->{'yMax'};
    my ($m) = $self->{'slant'};
    my ($k, $uadv, $ladv, $gid, $upper, $lower);

    foreach $k (@{$class->{'groups'}{'base_cons'}}, @{$class->{'groups'}{'base_tall'}},
                @{$class->{'groups'}{'base_vowel'}})
    {
        $gid = $glyphs->{$k}{'gid'};
        if (grep {$_ eq $k} @{$class->{'groups'}{'base_tall'}})
        { $uadv = $hmtx->{'advance'}[$gid] + $maieklx - $maieknx; }
        else
        { $uadv = $hmtx->{'advance'}[$gid]; }

        if (grep {$_ eq $k} @{$class->{'groups'}{'base_low'}})
        { $ladv = $saraul - $sarau; }
        else
        { $ladv = 0; }

        $glyphs->{$k}{'anchor'} = {
            'U' => [$uadv, $maiekn],
            'L' => [int($hmtx->{'advance'}[$gid] + $m * $ladv), $ladv]};
    }

    foreach $k (@{$class->{'groups'}{'udia'}})
    {
        my ($xl, $xu);
        if (grep {$_ eq $k} @{$class->{'groups'}{'tones'}})
        { 
            $lower = $maiek; $upper = 2 * $maiek - $maiekn; 
            $xl = int($m * ($maiek - $maiekn)); $xu = 2 * $xl;
        }
        else
        { 
            $lower = $maiekn; $upper = $maiek; 
            $xl = 0; $xu = int($m * ($maiek - $maiekn));
        }
        $glyphs->{$k}{'anchor'} = {
            'MARK_U' => [$xl, $lower],
            'MARK_U1' => [$xl, $lower],
            'U1' => [$xu, $upper]};
    }

    foreach $k (@{$class->{'groups'}{'ldia'}})
    {
        $glyphs->{$k}{'anchor'} = {
            'MARK_L' => [0, 0],
            'MARK_L1' => [0, 0],
            'L1' => [int($m * ($saraul - $sarau)), $saraul - $sarau]};
    }
    $self->{'slant'} = $m;
}


sub make_kern
{
    my ($self) = @_;
    my ($locas) = $self->{'font'}{'loca'}{'glyphs'};
    my ($hmtx) = $self->{'font'}{'hmtx'};
    my ($class) = $self->{'class'};
    my ($glyphs) = $self->{'glyphs'};
    my ($maieklx) = $locas->[$glyphs->{'unif705'}{'gid'}]->read->{'xMax'};
    my ($maieknx) = $locas->[$glyphs->{'unif70a'}{'gid'}]->read->{'xMax'};
    my ($saraim) = $locas->[$glyphs->{'uni0e35'}{'gid'}]->read->{'xMin'};
    my ($widi) = $hmtx->{'advance'}[$glyphs->{'uni0e35'}{'gid'}] - $saraim;
    my ($rsb) = $hmtx->{'advance'}[$glyphs->{'uni0e1b'}{'gid'}] -
        $locas->[$glyphs->{'uni0e1b'}{'gid'}]->read->{'xMax'};
    my ($rsbm) = $hmtx->{'advance'}[$glyphs->{'uni0e31'}{'gid'}] -
        $locas->[$glyphs->{'uni0e31'}{'gid'}]->read->{'xMax'};
    my ($m) = $self->{'slant'};
    my ($maiekn) = $locas->[$glyphs->{'unif70a'}{'gid'}]{'yMin'};
    my ($k, $gid, $uadv);

    $rsbm = ($rsbm < 0) ? -$rsbm : 0;
    foreach $k (@{$class->{'groups'}{'base_cons'}}, @{$class->{'groups'}{'base_tall'}})
    {
        $gid = $glyphs->{$k}{'gid'};
        if (grep {$_ eq $k} @{$class->{'groups'}{'base_tall'}})
        { $uadv = $hmtx->{'advance'}[$gid] + $maieklx - $maieknx; }
        else
        { $uadv = $hmtx->{'advance'}[$gid]; }
        $uadv += int($m * $maiekn);
#        $glyphs->{$k}{'kern'}{'tall-udia'} = int(($hmtx->{'lsb'}[$gid] - $rsb) / 2 - $uadv - $saraim)
#            if ($uadv + $saraim <= -$rsb);
        $glyphs->{$k}{'kern'}{'tall-udia'} = ($widi + $rsbm - $uadv) if ($widi + $rsbm > $uadv);
    }
    
    foreach $k (@{$class->{'groups'}{'base_kern'}})
    {
        my ($cuts, $dirs, $adv, $trsb, $xmin, $xmax, $i, $ytest, $glyph);
        
        $gid = $glyphs->{$k}{'gid'};
        $glyph = $locas->[$gid]->read;
        $ytest = ($glyph->{'yMax'} + $glyph->{'yMin'}) * .5;
        $adv = $hmtx->{'advance'}[$gid];
        $xmin = int($adv + $m * $ytest);
        ($cuts, $dirs) = $self->cut($gid, 0.5);
        for ($i = 0; $i < scalar @{$cuts}; $i++)
        {
            $xmin = int($cuts->[$i]) if ($dirs->[$i] && $cuts->[$i] < $xmin);
            $xmax = int($cuts->[$i]) if (!$dirs->[$i] && $cuts->[$i] > $xmax);
        }
        $glyphs->{$k}{'kern'}{'stem'} = int($xmin - $adv + $xmax - $m * $ytest);   #  - 2 * $m * $ytest;
    }
    
    foreach $k (@{$class->{'groups'}{'udia'}})
    {
        my ($glyph, $adv);
        
        $gid = $glyphs->{$k}{'gid'};
        $glyph = $locas->[$gid]->read;
        $adv = int($hmtx->{'advance'}[$gid] + $m * $glyph->{'xMin'});        # guess! take the smallest gap (xMax for biggest kern)
        if ($glyph->{'xMax'} > $adv)
        {
            $glyphs->{$k}{'kern'}{'udia'} = $glyph->{'xMax'} - $adv;
        }
    }
}


sub make_circle
{
    my ($self, $cmap, $kid) = @_;
    my ($font) = $self->{'font'};
    my ($dia) = $font->{'loca'}{'glyphs'}[$kid]->read->{'yMax'} * .95;
    my ($upem) = $font->{'head'}{'unitsPerEm'};
    my ($glyph) = Font::TTF::Glyph->new('PARENT' => $font, 'read' => 2);
    my ($PI) = 3.1415926535;
    my ($R) = $dia / 2;
    my ($r) = $R * 0.1;
    my ($xorg, $yorg) = ($dia / 2 + $r, $dia / 2);
    my ($cwidth) = $font->{'hmtx'}->read->{'advance'}[$kid]
            - $font->{'loca'}{'glyphs'}[$kid]{'xMax'};
    my ($numcirc) = 16;
    my ($numcpt) = 8;
    my ($coutr) = 1. / cos($PI / $numcpt);
    my ($m) = $self->{'slant'};
    my ($i, $j, $numg, $maxp);

    $xorg += $cwidth;
    $font->{'post'}->read;
    $font->{'glyf'}->read;
    for ($i = 0; $i < $numcirc; $i++)
    {
        my ($pxorg, $pyorg) = ($xorg + $R * cos($PI * $i * 2. / $numcirc),
                               $yorg + $R * sin($PI * $i * 2. / $numcirc));
        $pxorg += $m * $pyorg;
        push (@{$glyph->{'x'}}, int($pxorg + $r));
        push (@{$glyph->{'y'}}, $pyorg);
        push (@{$glyph->{'flags'}}, 1);
        for ($j = 0; $j < $numcpt; $j++)
        {
#            push (@{$glyph->{'x'}}, int ($pxorg + ($j & 1 ? 1.414 : 1) * $r * cos($PI * $j * 2. / $numcpt)));
#            push (@{$glyph->{'y'}}, int ($pyorg + ($j & 1 ? 1.414 : 1) * $r * sin($PI * $j * 2. / $numcpt)));
#            push (@{$glyph->{'flags'}}, $j & 1 ? 0 : 1);
            push(@{$glyph->{'x'}}, int($pxorg + $coutr * $r * cos($PI * ($j + .5) * 2. / $numcpt)));
            push(@{$glyph->{'y'}}, int($pyorg + $coutr * $r * sin($PI * ($j + .5) * 2. / $numcpt)));
            push(@{$glyph->{'flags'}}, 0);
        }
        push (@{$glyph->{'endPoints'}}, $#{$glyph->{'x'}});
    }
    $glyph->{'numberOfContours'} = $#{$glyph->{'endPoints'}} + 1;
    $glyph->{'numPoints'} = $#{$glyph->{'x'}} + 1;
    $glyph->update;
    $font->{'maxp'}->read->{'numGlyphs'}++;
    $numg = $font->{'maxp'}{'numGlyphs'};

    $font->{'hmtx'}{'advance'}[$numg - 1] = int($xorg + $R + $r + $cwidth + .5);
    $font->{'hmtx'}{'lsb'}[$numg - 1] = int($xorg - $R - $r + .5);
    $font->{'loca'}{'glyphs'}[$numg - 1] = $glyph;
    $cmap->{'val'}{0x25CC} = $#{$font->{'loca'}{'glyphs'}};
    delete $font->{'hdmx'};
    delete $font->{'VDMX'};
    delete $font->{'LTSH'};
    
#    $maxp = $font->{'maxp'}->read;
#    $maxp->{'maxPoints'} = 128 unless ($maxp->{'maxPoints'} > 128);
#    $maxp->{'maxContours'} = 16 unless ($maxp->{'maxContours'} > 16);
#    $maxp->{'maxCompositePoints'} = 128 unless ($maxp->{'maxCompositePoints'} > 128);
#    $maxp->{'maxCompositeContours'} = 16 unless ($maxp->{'maxCompositeContours'} > 16);
    
    $font->tables_do(sub {$_[0]->dirty;});
    $font->update;
    return ($numg - 1);
}


sub get_attach
{
    my ($self, $xml_file) = @_;
    my ($font) = $self->{'font'};
    my ($cmap) = $font->{'cmap'}->find_ms;
    my ($post) = $font->{'post'}->read;
    my ($cur_glyph, $cur_point, $xml);
    
    $xml = XML::Parser->new(Handlers => {Start => sub {
        my ($xml, $tag, %attrs) = @_;
        my ($gid);
        
        if ($tag eq 'glyph')
        {
            $gid = $cmap->{'val'}{hex($attrs{'UID'})} || $post->{'STRINGS'}{$attrs{'PSName'}}
                    || $attrs{'GID'};
            $xml->xpcarp("Unknown glyph") unless $gid;
            $cur_glyph = $self->{'glyphs'}{$self->{'all_glyphs'}[$gid]{'name'}};
        }
        elsif ($tag eq 'point')
        { $cur_point = $attrs{'type'}; }
        elsif ($tag eq 'location')
        { $cur_glyph->{'anchor'}{$cur_point} = [$attrs{'x'}, $attrs{'y'}]; }
    }});
    
    $xml->parsefile($xml_file);
}


sub remap
{
    my ($self, $cmap, $from, $to) = @_;
    my ($font) = $self->{'font'};
    my ($k, $temp, $c);

    for ($k = 0; $k <= $#{$from}; $k++)
    {
        $temp = delete $cmap->{'val'}{$from->[$k]};
        $cmap->{'val'}{$to->[$k]} = $temp;
    }
    
    foreach $c (@{$font->{'cmap'}{'Tables'}})
    {
        $c->{'val'} = $cmap->{'val'} if ($c->{'Platform'} == 0 || $c->{'Platform'} == 3
            || ($c->{'Platform'} == 2 && $c->{'Encoding'} == 1));
        $c->{'Encoding'} = 1 if ($c->{'Platform'} == 3);
    }
}

sub fixps
{
    my ($self, $post, $cmap) = @_;
    my ($k, $newname, $oldname, $gid);
    
    foreach $k (keys %{$cmap->{'val'}})
    {
        $oldname = $post->{'VAL'}[$k];
        $newname = Font::TTF::PSNames::lookup($k);
        $gid = $cmap->{'val'}{$k};
        if ($oldname ne $newname)
        {
            if ($post->{'STRINGS'}{$oldname} == $gid)
            { 
                delete $post->{'STRINGS'}{$oldname};
                $post->{'STRINGS'}{$newname} = $gid;
            }
            $post->{'VAL'}[$k] = $newname;
        }
    }
}

sub cut
{
    my ($self, $gid, $yrat) = @_;
    my ($font) = $self->{'font'};
    my ($glyph) = $font->{'loca'}{'glyphs'}[$gid]->read_dat;
    my ($ytest) = ($glyph->{'yMax'} - $glyph->{'yMin'}) * $yrat + $glyph->{'yMin'};
    my ($x, $y, $xprev, $yprev, $i, $ei);
    my (@res, @dir);
    
    $glyph->get_points;
    for ($i = 0; $i < $glyph->{'numPoints'}; $i++)
    {
        if ($i == $glyph->{'endPoints'}[$ei] + 1)
        { 
            undef $y; undef $x;
            $ei++; 
        }
        else
        { 
            ($xprev, $yprev) = ($x, $y);
            ($x, $y) = ($glyph->{'x'}[$i], $glyph->{'y'}[$i]);
            if (defined $yprev && $yprev <= $ytest && $y >= $ytest)
            {
                my ($rat) = ($ytest - $yprev) / ($y - $yprev);
                push(@res, ($x - $xprev) * $rat + $xprev);
                push(@dir, 1);
            }
            elsif (defined $yprev && $yprev >= $ytest && $y <= $ytest)
            {
                my ($rat) = ($ytest - $y) / ($yprev - $y);
                push(@res, ($xprev - $x) * $rat + $x);
                push(@dir, 0);
            }
        }
    }
    return (\@res, \@dir);
}

1;

