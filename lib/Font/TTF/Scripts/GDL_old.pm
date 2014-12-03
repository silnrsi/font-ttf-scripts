package Font::TTF::Scripts::GDL;

use Font::TTF::Font;
use XML::Parser::Expat;

use strict;
use vars qw($VERSION);

$VERSION = "0.01";  # MJPH   8-OCT-2002     Original based on existing code

$Font::Post::base_set[2] = 'CR';

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

sub start_gdl
{
    my ($self, $fh) = @_;
    my ($fname) = $self->{'font'}{'name'}->find_name(4);

    $fh->print("/*\n    Glyph information for font $fname at " . localtime() . "\n*/\n\n");
    $fh->print("table(glyph) {MUnits = $self->{'font'}{'head'}{'unitsPerEm'}};\n");
    $self;
}

sub out_gdl
{
    my ($self, $fh) = @_;
    my ($f) = $self->{'font'};
    my ($glyphs) = $self->{'glyphs'};
    my (%lists, %glyph_names);
    my ($u, @revmap, $gname, $i, $sep, $p, $pname, $pt, $k);
    
#    foreach $u (keys %{$c})
#    { @revmap[$c->{$u}] = $u; }

    for ($i = 0; $i < $f->{'maxp'}{'numGlyphs'}; $i++)
    {
        $gname = make_name($f->{'post'}{'VAL'}[$i]);
    
    #    while (defined $glyph_names{$gname})
    #    { $gname =~ s/(?:_(\d{3})|)$/sprintf("%03d", $1)/oe; }
        $glyph_names{$gname} = $i;
        $fh->print("$gname = ");
    #    if ($revmap[$i])
    #    { printf OUT "unicode(0x%04X)", $revmap[$i]; }
    #    elsif ($i > 1)
    #    if ($i > 1)
    #    { $fh->print("postscript(\"$psname\")"; }
    #    else
        { $fh->print("glyphid($i)"); }
        
        $glyphs->[$i]{'gdl_name'} = $gname;
    
        $sep = ' {';
        foreach $p (keys %{$glyphs->[$i]{'points'}})
        {
            my ($pname) = $p;
            $pname .= 'S' unless ($pname =~ s/^_(.*)/${1}M/o);
            
            $pt = $glyphs->[$i]{'points'}{$p};
            $fh->print("$sep$pname = ");
            push (@{$lists{$p}}, $gname);
            vec($self->{'vecs'}{$p}, $i, 1) = 1 if ($self->{'vecs'});
            if (defined $pt->{'cont'})
            { $fh->print("gpath($pt->{'cont'})"); }
            else
            { $fh->print("point($pt->{'x'}m, $pt->{'y'}m)"); }
            $sep = '; ';
        }
    #    printf OUT ("%sorder=%d", $sep, $glyphs[$i]->{'props'}{'order'});
        foreach $k (keys %{$glyphs->[$i]{'props'}})
        {
            my ($n) = $k;
            next unless ($n =~ s/^GDL(?:_)?//o);
            $fh->print("$sep$n=$glyphs->[$i]{'props'}{$k}");
            $sep = '; ';
        }
        $fh->print("}") if ($sep ne ' {');
        $fh->print(";\n");
    }
    $self->{'lists'} = \%lists;
    $self;
}

sub make_classes
{
    my ($self) = @_;
    my ($glyphs) = $self->{'glyphs'};
    my ($f) = $self->{'font'};
    my (%classes);
    my ($g, $gname, $i);
    
    foreach $g (@{$glyphs})
    {
        $gname = $g->{'post'};
        if ($gname =~ m/\.([^_.]+)$/o)
        {
            my ($base, $ext) = ($` , $1);
            next unless ($i = $f->{'post'}{'STRINGS'}{$base});
            push (@{$classes{$ext}}, $g->{'gdl_name'});
            push (@{$classes{"no_$ext"}}, $glyphs->[$i]{'gdl_name'});
        }
    }
    $self->{'classes'} = \%classes;
}

sub out_classes
{
    my ($self, $fh) = @_;
    my ($f) = $self->{'font'};
    my ($lists) = $self->{'lists'};
    my ($classes) = $self->{'classes'};
    my ($vecs) = $self->{'vecs'};
    my ($glyphs) = $self->{'glyphs'};
    my ($l, $name, $count, $sep, $psname, $cl, $i, $c);
    
    $fh->print("\n/* Classes */\n");
    
    foreach $l (sort keys %{$lists})
    {
        my ($name) = $l;
        
        if ($name !~ m/^_/o)
        { $name = "Takes$name"; }
        else
        { $name =~ s/^_//o; }
        
        $fh->print("c${name}Dia = (");
        $count = 0; $sep = '';
        foreach $cl (@{$lists->{$l}})
        {
    #        next if ($l eq 'LS' && $cl =~ m/g101b.*_med/o);      # special since no - op in GDL
            $fh->print("$sep$cl");
            if (++$count % 8 == 0)
            { $sep = ",\n    "; }
            else
            { $sep = ", "; }
        }
        $fh->print(");\n\n");

        next unless defined $vecs->{$l};
        
        $fh->print("cn${name}Dia = (");
        $count = 0; $sep = '';
        for ($c = 0; $c < $f->{'maxp'}{'numGlyphs'}; $c++)
        {
            $psname = $f->{'post'}{'VAL'}[$c];
            next if ($psname eq '' || $psname eq '.notdef');
            next if (vec($vecs->{$l}, $c, 1));
            next if (defined $glyphs->[$c]{'props'}{'GDL_order'} && $glyphs->[$c]{'props'}{'GDL_order'} <= 1);
            $fh->print("$sep$glyphs->[$c]{'gdl_name'}");
            if (++$count % 8 == 0)
            { $sep = ",\n    "; }
            else
            { $sep = ", "; }
        }
        $fh->print(");\n\n");
    }
    

    foreach $cl (sort keys %{$classes})
    {
        $fh->print("c$cl = ($classes->{$cl}[0]");
        for ($i = 1; $i <= $#{$classes->{$cl}}; $i++)
        { $fh->print($i % 8 ? ", $classes->{$cl}[$i]" : ",\n    $classes->{$cl}[$i]"); }
        $fh->print(");\n\n");
    }
    $self;
}

sub endtable
{
    my ($self, $fh) = @_;

    $fh->print("endtable;\n");
}


sub end_gdl
{
    my ($self, $fh, $include) = @_;

    $fh->print("\n#define MAXGLYPH " . ($self->{'font'}{'maxp'}{'numGlyphs'} - 1) . "\n");
    $fh->print("\n#include \"$include\"\n") if ($include);
}

sub make_name
{
    my ($gname) = @_;
    $gname =~ s/\.(.)/'_'.lc($1)/oge;
    if ($gname =~ m/^u(?:ni)?(?:[0-9A-Fa-f]{4,6})/o)
    { 
        $gname = "g" . lc($gname);
        $gname =~ s/^gu(?:ni)?/g/o;
        $gname =~ s/_u/_/og;
    }
    else
    {
        $gname = "g_" . $gname;
        $gname =~ s/([A-Z])/"_".lc($1)/oge;
    }
    $gname;
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

1;

=head1 AUTHOR

Martin Hosken L<http://scripts.sil.org/FontUtils>. 

=head1 LICENSING

Copyright (c) 1998-2014, SIL International (http://www.sil.org)

This module is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.

=cut