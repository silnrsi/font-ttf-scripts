package Font::Scripts::Volt;

use Font::TTF::Font;
use Font::Scripts::AP;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Font::Scripts::AP);

$VERSION = "0.01";  # MJPH  26-APR-2004     Original based on existing code
*read_font = \&Font::Scripts::AP::read_font;

sub out_volt
{
    my ($self) = @_;
    my ($res);
    
    $res = $self->out_volt_glyphs;
    $res .= $self->out_volt_classes;
    $res .= $self->out_volt_lookups;
    $res .= $self->out_volt_anchors;
    $res .= $self->out_volt_final;
    $res;
}

sub out_volt_glyphs
{
    my ($self) = @_;
    my ($c) = $self->{'font'}{'cmap'}->read->find_ms;
    my ($g, $res, $i, $type, @revmap, $u);

    foreach $u (keys %{$c->{'val'}})
    { push(@{$revmap[$c->{'val'}{$u}]}, $u); }
    
    for ($i = 0; $i < $self->{'font'}{'maxp'}{'numGlyphs'}; $i++)
    {
        $g = $self->{'glyphs'}[$i];
        $res .= "DEF_GLYPH \"$g->{'name'}\" ID $i";
        if (defined $revmap[$i])
        {
            if (scalar @{$revmap[$i]} > 1)
            { $res .= " UNICODEVALUES \"" . join(",", map {sprintf("U+%04X", $_)}
                    sort {$a <=> $b} @{$revmap[$i]}) . '"'; }
            elsif (scalar @{$revmap[$i]} == 1)
            { $res .= " UNICODE $revmap[$i][0]"; }
        }
        
        if (defined $g->{'props'}{'type'})
        { $type = $g->{'props'}{'type'}; }
        elsif (defined $g->{'points'})
        { $type = 'BASE'; }
        
        $res .= " TYPE $type" if ($type);
        $res .= " END_GLYPH\n";
    }
    $res;
}


sub out_volt_classes
{
    my ($self) = @_;
    my ($f) = $self->{'font'};
    my ($lists) = $self->{'lists'};
    my ($classes) = $self->{'classes'};
    my ($vecs) = $self->{'vecs'};
    my ($glyphs) = $self->{'glyphs'};
    my ($l, $name, $count, $sep, $psname, $cl, $i, $c);
    my ($res);
    
    foreach $l (sort keys %{$lists})
    {
        my ($name) = $l;
        
        if ($name !~ m/^_(.*)$/o)
        { $name = "Takes$name"; }
        else
        { $name =~ s/^_//o; }
        
        $res .= "DEF_GROUP \"c${name}Dia\"\n  ENUM";
        
        $count = 0; $sep = '';
        foreach $cl (@{$lists->{$l}})
        { $res .= " GLYPH \"$glyphs->[$cl]{'name'}\""; }
        $res .= " END_ENUM\nEND_GROUP\n\n";
    }
    

    foreach $cl (sort keys %{$classes})
    {
        $res .= "DEF_GROUP \"c$cl\"\n  ENUM";
        for ($i = 0; $i <= $#{$classes->{$cl}}; $i++)
        { 
            $res .= " GLYPH \"$glyphs->[$classes->{$cl}[$i]]{'name'}\"";
            $res .= "\n" if ($i % 8 == 7);
        }
        $res .= " END_ENUM\nEND_GROUP\n\n";
    }
    $res;
}


sub out_volt_lookups
{
    my ($self) = @_;
    my ($glyphs) = $self->{'glyphs'};
    my ($res, $c, $i);
    
    foreach $c (sort keys %{$self->{'classes'}})
    {
        next if ($c =~ m/^no_/o);
        
        $res .= "DEF_LOOKUP \"$c\" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR\n";
        $res .= "IN_CONTEXT\nEND_CONTEXT\nAS_SUBSTITUTION\n";
        for ($i = 0; $i < scalar @{$self->{'classes'}{$c}}; $i++)
        {
            $res .= "SUB GLYPH \"" .($glyphs->[$self->{'classes'}{"no_$c"}[$i]]{'name'}) . "\"\n";
            $res .= "WITH GLYPH \"$glyphs->[$self->{'classes'}{$c}[$i]]{'name'}\"\n";
            $res .= "END_SUB\n";
        }
        $res .= "END_SUBSTITUTION\n";
    }
    
    foreach $c (sort keys %{$self->{'lists'}})
    {
        next if ($c =~ m/^_/o);
        
        $res .= "DEF_LOOKUP \"base_$c\" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR\n";
        $res .= "IN_CONTEXT\nEND_CONTEXT\nAS_POSITION\n";
        $res .= "ATTACH GROUP \"cTakes${c}Dia\"\n";
        $res .= "TO GROUP \"c_${c}Dia\" AT ANCHOR \"$c\"\n";
        $res .= "END_ATTACH\nEND_POSITION\n";
    }
    $res;
}


sub out_volt_anchors
{
    my ($self) = @_;
    my ($res, $glyph, $k, $i);
    
    foreach $glyph (@{$self->{'glyphs'}})
    {
        $k = $glyph->{'name'};
        foreach $i (sort keys %{$glyph->{'points'}})
        {
            $res .= "DEF_ANCHOR \"$i\" ON $glyph->{'gnum'} GLYPH $k COMPONENT 1 " .
                    "AT POS DX $glyph->{'points'}{$i}{'x'} DY $glyph->{'points'}{$i}{'y'} END_POS " .
                    "END_ANCHOR\n";
        }
    }
    $res;
}

sub out_volt_final
{
    my ($self) = @_;
    my ($res);

    $res .= <<'EOT';
GRID_PPEM 20
PRESENTATION_PPEM 72
PPOSITIONING_PPEM 144
CMAP_FORMAT 1 0 0
CMAP_FORMAT 3 1 4
END
EOT
    $res;
}
    
sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;
    
    if (defined $glyph->{'props'}{'VOLT_id'})
    { return $glyph->{'props'}{'VOLT_id'}; }
    else
    { $gname =~ s/[.;\-\"\'&$#\/]//og; }
    $gname;
}

sub make_point
{
    my ($self, $p, $glyph) = @_;
    
    $glyph->{'props'}{'type'} = 'MARK' if ($p =~ m/^_/o);
    return $p;
}
