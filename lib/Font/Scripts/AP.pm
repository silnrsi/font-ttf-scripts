package Font::Scripts::AP;

use Font::TTF::Font;
use XML::Parser::Expat;

use strict;
use vars qw($VERSION);

$VERSION = "0.01";  # MJPH  26-APR-2004     Original based on existing code

# $Font::Post::base_set[2] = 'CR';

sub read_font
{
    my ($class, $fname, $xml_file, %opts) = @_;
    my (@glyphs, $f, $t, $xml, $cur_glyph, $cur_pt);
    my ($self) = {};
    bless $self, ref $class || $class;

    $f = Font::TTF::Font->open($fname) || die "Can't open font $fname";
    foreach $t (qw(post cmap loca name))
    { $f->{$t}->read; }

    $self->{'font'} = $f;
    $self->{'cmap'} = $f->{'cmap'}->find_ms->{'val'} || die "Can't find Unicode table in font $fname";

    $xml = XML::Parser::Expat->new();
    $xml->setHandlers('Start' => sub {
        my ($xml, $tag, %attrs) = @_;
    
        if ($tag eq 'glyph')
        {
            my ($ug, $pg, $ig, $glyph);
            $cur_glyph = {%attrs};
            undef $cur_pt;
    
            if (defined $attrs{'UID'})
            {
                my ($uni) = hex($attrs{'UID'});
                $ug = $self->{'cmap'}{$uni};
                error($xml, $cur_glyph, undef, "No glyph associated with UID $attrs{'UID'}") unless (defined $ug);
                $cur_glyph->{'gnum'} = $ug;
                $cur_glyph->{'uni'} = $uni;
                delete $attrs{'UID'};
            }
            if (defined $attrs{'PSName'})
            {
                $pg = $f->{'post'}{'STRINGS'}{$attrs{'PSName'}};
                error($xml, $cur_glyph, undef, "No glyph associated with postscript name $attrs{'PSName'}") unless (defined $pg);
                error($xml, $cur_glyph, undef, "Postscript name: $attrs{'PSName'} resolves to different glyph to Unicode ID: $attrs{'UID'}")
                        if (defined $attrs{'UID'} && $pg != $ug);
                $cur_glyph->{'gnum'} ||= $pg;
                delete $attrs{'PSName'};
            }
            if (defined $attrs{'GID'})
            {
                $ig = $attrs{'GID'};
                error($xml, $cur_glyph, undef, "Specified glyph id $attrs{'GID'} different to glyph of Unicode ID: $attrs{'UID'}")
                        if (defined $attrs{'UID'} && $ug != $ig);
                error($xml, $cur_glyph, undef, "Specified glyph id $attrs{'GID'} different to glyph of postscript name $attrs{'PSName'}")
                        if (defined $attrs{'PSName'} && $pg != $ig);
                $cur_glyph->{'gnum'} ||= $ig;
                delete $attrs{'GID'};
            }
    
            if ($glyph = $f->{'loca'}{'glyphs'}[$cur_glyph->{'gnum'}])
            {
                $cur_glyph->{'glyph'} = $glyph;
                $cur_glyph->{'glyph'}->read_dat;
                if ($cur_glyph->{'glyph'}{'numberOfContours'} > 0)
                { $cur_glyph->{'props'}{'drawn'} = 1; }
                $cur_glyph->{'glyph'}->get_points;
            }
            $cur_glyph->{'post'} = $f->{'post'}{'VAL'}[$cur_glyph->{'gnum'}];
            $self->{'glyphs'}[$cur_glyph->{'gnum'}] = $cur_glyph;
            foreach (keys %attrs)
            { $cur_glyph->{$_} = $attrs{$_}; }
        } elsif ($tag eq 'point')
        {
            $cur_pt = {'name' => $attrs{'type'}};
            $cur_glyph->{'points'}{$attrs{'type'}} = $cur_pt;
        } elsif ($tag eq 'contour')
        {
            my ($cont) = $attrs{'num'};
            my ($g) = $cur_glyph->{'glyph'} || return;
            
            error($xml, $cur_glyph, $cur_pt, "Specified contour of $cont different from calculated contour of $cur_pt->{'cont'}")
                    if (defined $cur_pt->{'cont'} && $cur_pt->{'cont'} != $attrs{'num'});
                 
            if (($cont == 0 && $g->{'endPoints'}[0] != 0)
                || ($cont > 0 && $g->{'endPoints'}[$cont-1] + 1 != $g->{'endPoints'}[$cont]))
            { error($xml, $cur_glyph, $cur_pt, "Contour $cont not a single point path"); }
            else
            { $cur_pt->{'cont'} = $cont; }
            
            $cur_pt->{'x'} = $g->{'x'}[$g->{'endPoints'}[$cont]];
            $cur_pt->{'y'} = $g->{'y'}[$g->{'endPoints'}[$cont]];
        } elsif ($tag eq 'location')
        {
            my ($x) = $attrs{'x'};
            my ($y) = $attrs{'y'};
            my ($g) = $cur_glyph->{'glyph'};
            my ($cont, $i);
    
            error($xml, $cur_glyph, $cur_pt, "Specified location of ($x, $y) different from calculated location ($cur_pt->{'x'}, $cur_pt->{'y'})")
                    if (defined $cur_pt->{'x'} && ($cur_pt->{'x'} != $x || $cur_pt->{'y'} != $y));
            
            if ($g)
            {
                for ($i = 0; $i < $g->{'numPoints'}; $i++)
                {
                    if ($g->{'x'}[$i] == $x && $g->{'y'}[$i] == $y)
                    {
                        for ($cont = 0; $cont <= $#{$g->{'endPoints'}}; $cont++)
                        {
                            last if ($g->{'endPoints'}[$cont] > $i);
                        }
                    }
                }
                if ($g->{'x'}[$i] != $x || $g->{'y'}[$i] != $y)
                { error($xml, $cur_glyph, $cur_pt, "No glyph point at specified location ($x, $y)") if ($opts{'-strictap'}); }
                if (($cont == 0 && $g->{'endPoints'}[0] != 0)
                    || $g->{'endPoints'}[$cont-1] + 1 != $g->{'endPoints'}[$cont])
                { error($xml, $cur_glyph, $cur_pt, "Calculated contour $cont not a single point path") if ($opts{'-strictap'}); }
                else
                { $cur_pt->{'cont'} = $cont; }
            }
            
            $cur_pt->{'x'} = $x unless defined $cur_pt->{'x'};
            $cur_pt->{'y'} = $y unless defined $cur_pt->{'y'};
        } elsif ($tag eq 'property')
        {
            $cur_glyph->{'props'}{$attrs{'name'}} = $attrs{'value'};
        }
    });

    $xml->parsefile($xml_file) || return warn "Can't open $xml_file";
    $self;
}


sub make_classes
{
    my ($self) = @_;
    my ($f) = $self->{'font'};
    my (%classes);
    my ($g, $gname, $i, $glyph, %used, $p);
    
    for ($i = 0; $i < $f->{'maxp'}{'numGlyphs'}; $i++)
    {
        $glyph = $self->{'glyphs'}[$i];
        $gname = $self->make_name($glyph->{'post'}, $glyph->{'uni'}, $glyph);

        if (defined $used{$gname})
        { $gname .= "_1"; }
        $gname++ while (defined $used{$gname});
        $used{$gname}++;
        $glyph->{'name'} = $gname;

        
        foreach $p (keys %{$glyph->{'points'}})
        {
            my ($pname) = $self->make_point($p, $glyph);
            next unless ($pname);                           # allow for point deletion, in effect.
            if ($p ne $pname)
            {
                $glyph->{'points'}{$pname} = $glyph->{'points'}{$p};
                delete $glyph->{'points'}{$p};
            }
            push (@{$self->{'lists'}{$pname}}, $i);
            vec($self->{'vecs'}{$pname}, $i, 1) = 1 if ($self->{'vecs'});
        }
    }
    
    # need a separate loop since using other glyphs' names
    foreach $glyph (@{$self->{'glyphs'}})
    {
        if ($glyph->{'post'} =~ m/\.([^_.]+)$/o)
        {
            my ($base, $ext) = ($` , $1);
            next unless ($i = $f->{'post'}{'STRINGS'}{$base});
            push (@{$classes{$ext}}, $glyph->{'gnum'});
            push (@{$classes{"no_$ext"}}, $self->{'glyphs'}[$i]{'gnum'});
        }
    }
    $self->{'classes'} = \%classes;
}


sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;
    $gname;
}

sub make_point
{
    my ($self, $p, $glyph) = @_;
    return $p;
}

sub error
{
    my ($xml, $cur_glyph, $cur_pt, $str) = @_;

    if (defined $cur_glyph->{'UID'})
    { print "U+$cur_glyph->{'UID'}: "; }
    elsif (defined $cur_glyph->{'PSName'})
    { print "$cur_glyph->{'PSName'}: "; }
    elsif (defined $cur_glyph->{'GID'})
    { print "$cur_glyph->{'GID'}: "; }
    else
    { print "Undefined: "; }

    print $str;

    if (defined $cur_pt)
    { print " in point $cur_pt->{'name'}"; }

    print " at line " . $xml->current_line . ".\n";
}
