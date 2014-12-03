package Font::TTF::Scripts::GDL;

use Font::TTF::Font;
use Font::TTF::Scripts::AP;
use Unicode::Normalize;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Font::TTF::Scripts::AP);

$VERSION = "0.04";  # MJPH   19-APR-2006     Add +left_right ap support for compounds
# $VERSION = "0.03";  # MJPH   9-AUG-2005     Support glyph alternates naming (A/u0410), normalization
# $VERSION = "0.02";  # MJPH  26-APR-2004     Add to Font::Scripts::AP hierarchy
# $VERSION = "0.01";  # MJPH   8-OCT-2002     Original based on existing code

*read_font = \&Font::TTF::Scripts::AP::read_font;

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
    my ($self, $fh, %opts) = @_;
    my ($f) = $self->{'font'};
    my (%lists, %glyph_names);
    my ($i, $sep, $p, $k, $glyph);

    for ($i = 0; $i < $f->{'maxp'}{'numGlyphs'}; $i++)
    {
        $glyph = $self->{'glyphs'}[$i];
        $fh->print("$glyph->{'name'} = ");
        if ($opts{'-psnames'} && $glyph->{'post'} && $glyph->{'post'} ne '.notdef')
        { $fh->print("postscript(\"$glyph->{'post'}\")"); }
        else
        { $fh->print("glyphid($i)"); }

        my ($ytop) = $f->{'hhea'}->read->{'Ascender'};
        my ($adv) = $f->{'hmtx'}->read->{'advance'}[$i];
        $sep = ' {';
        foreach $p (keys %{$glyph->{'points'}})
        {
            my ($pname) = $p;
            my ($pt) = $glyph->{'points'}{$p};

            if ($pname =~ s/^\+//o)
            {
                my ($pl, $pr) = ($pname =~ m/^([^_]+)(?:_([^_]+))/og);

                if ($opts{'-split_ligs'})
                {
                    if (defined $glyph->{'compunds'}{$pl})
                    { $glyph->{'compounds'}{$pl}[3] = $pt->{'x'}; }
                    else
                    { $glyph->{'compounds'}{$pl} = [0, 0, $pt->{'x'}, $ytop]; }
                    if ($pr)
                    {
                        if (defined $glyph->{'compounds'}{$pr})
                        { $glyph->{'compounds'}{$pr}[0] = $pt->{'x'}; }
                        else
                        { $glyph->{'compounds'}{$pr} = [$pt->{'x'}, 0, $adv, $ytop]; }
                    }
                }
                next;
            }
            $pname .= 'S' unless ($pname =~ s/^_(.*)/${1}M/o);
            $fh->print("$sep$pname = ");
            if (defined $pt->{'cont'})
            { $fh->print("gpath($pt->{'cont'})"); }
            else
            { $fh->print("point($pt->{'x'}m, $pt->{'y'}m)"); }
            $sep = '; ';
        }
        if ($opts{'-split_ligs'})
        {
            my ($oldx) = 0; my ($min) = 0;

            foreach $k (sort grep {m/^component\./o} keys %{$glyph->{'props'}})
            {
                my ($n) = $k;
                $n =~ s/^component\.//o;
                $glyph->{'compounds'}{$n} = [0, 0, $glyph->{'props'}{$k}, $ytop];
            }
            foreach $k (sort {$glyph->{'compounds'}{$a}[2] <=> $glyph->{'compounds'}{$b}[2]} keys %{$glyph->{'compounds'}})
            {
                $glyph->{'compounds'}{$k} = [$oldx, 0, $glyph->{'compounds'}{$k}[2], $glyph->{'compounds'}{$k}[3]];
                $oldx = $glyph->{'compounds'}{$k}[2];
                $min = $k if ($k > $min);
            }
            if (scalar %{$glyph->{'compounds'}} && $oldx < $adv)
            {
                my ($maxx) = $f->{'loca'}->read->{'glyphs'}[$i]{'xMax'};
                if ($oldx < $maxx)          # only add magic compound if some outline not covered
                {
                    $min++;
                    $glyph->{'compounds'}{$min} = [$oldx, 0, $adv, $ytop];
                }
            }
        }
        foreach $k (keys %{$glyph->{'compounds'}})
        {
            $fh->print("${sep}component.$k = box(" . join(", ", map {"${_}m"} @{$glyph->{'compounds'}{$k}}) . ")");
            $sep = '; ';
        }
        foreach $k (keys %{$glyph->{'props'}})
        {
            my ($n) = $k;
            next unless ($n =~ s/^GDL(?:_)?//o);
            $fh->print("$sep$n=$glyph->{'props'}{$k}");
            $sep = '; ';
        }
        $fh->print("}") if ($sep ne ' {');
        $fh->print(";\n");
    }
}

sub out_classes
{
    my ($self, $fh, %opts) = @_;
    my ($f) = $self->{'font'};
    my ($lists) = $self->{'lists'};
    my ($classes) = $self->{'classes'};
    my ($ligclasses) = $self->{'ligclasses'};
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

        $fh->print("#define HAS_c${name}Dia 1\n") if ($opts{'-defines'} && $name !~ m/^Takes/o);
        $fh->print("c${name}Dia = (");
        $count = 0; $sep = '';
        foreach $cl (@{$lists->{$l}})
        {
    #        next if ($l eq 'LS' && $cl =~ m/g101b.*_med/o);      # special since no - op in GDL
            $fh->print("$sep$glyphs->[$cl]{'name'}");
            if (++$count % 8 == 0)
            { $sep = ",\n    "; }
            else
            { $sep = ", "; }
        }
        $fh->print(");\n\n");

        next unless defined $vecs->{$l};

        $fh->print("cn${name}Dia = (");
        $count = 0; $sep = '';
        $self->{'hasnclass'}{$l} = 0;
        for ($c = 0; $c < $f->{'maxp'}{'numGlyphs'}; $c++)
        {
            $psname = $f->{'post'}{'VAL'}[$c];
            next if ($psname eq '' || $psname eq '.notdef');
            next if (vec($vecs->{$l}, $c, 1));
            next if (!(substr($l, 0, 1) eq "_") and vec($vecs->{"_$l"}, $c, 1));
            next if (defined $glyphs->[$c]{'props'}{'GDL_order'} && $glyphs->[$c]{'props'}{'GDL_order'} <= 1);
            next unless (vec($self->{'ismarks'}, $c, 1));
            $fh->print("$sep$glyphs->[$c]{'name'}");
            $self->{'hasnclass'}{$l} = 1;
            if (++$count % 8 == 0)
            { $sep = ",\n    "; }
            else
            { $sep = ", "; }
        }
        $fh->print(");\n\n");
    }


    foreach $cl (sort {classcmp($a, $b)} keys %{$classes})
    {
        $fh->print("#define HAS_c$cl 1\n") if ($opts{'-defines'} && $cl !~ m/^no_/o);
        $fh->print("c$cl = ($glyphs->[$classes->{$cl}[0]]{'name'}");
        for ($i = 1; $i <= $#{$classes->{$cl}}; $i++)
        { $fh->print($i % 8 ? ", $glyphs->[$classes->{$cl}[$i]]{'name'}" : ",\n    $glyphs->[$classes->{$cl}[$i]]{'name'}"); }
        $fh->print(");\n\n");
    }

    foreach $cl (sort {classcmp($a, $b)} keys %{$ligclasses})
    {
        $fh->print("#define HAS_clig$cl 1\n") if ($opts{'-defines'} && $cl !~ m/^no_/o);
        $fh->print("clig$cl = ($glyphs->[$ligclasses->{$cl}[0]]{'name'}");
        for ($i = 1; $i <= $#{$ligclasses->{$cl}}; $i++)
        { $fh->print($i % 8 ? ", $glyphs->[$ligclasses->{$cl}[$i]]{'name'}" : ",\n    $glyphs->[$ligclasses->{$cl}[$i]]{'name'}"); }
        $fh->print(");\n\n");
    }

    $self;
}

sub classcmp
{
    my ($x, $y) = @_;
    my ($v, $w) = ($x, $y);
    $v =~ s/^no_//o;
    $w =~ s/^no_//o;
    return ($v cmp $w || $x cmp $y);
}

sub endtable
{
    my ($self, $fh) = @_;

    $fh->print("endtable;\n");
}


sub end_gdl
{
    my ($self, $fh, $include, $defines) = @_;
    my ($k, $v);

    while (($k, $v) = each %$defines)
    {
        $fh->print("\n#define $k $v");
    }
    $fh->print("\n#define MAXGLYPH " . ($self->{'font'}{'maxp'}{'numGlyphs'} - 1) . "\n");
    foreach (@$include)
    {
        $fh->print("\n#include \"$_\"\n");
    }
}

sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;
    $gname =~ s/[:\(\)\{\}]//g;
    $gname =~ s{/.*$}{}o;
    $gname =~ s/\.(.)/'_'.lc($1)/oge;
    if ($gname =~ m/^u(?:[0-9A-Fa-f]{4,6})/oi)
    { 
        $gname = "g" . lc($gname);
        $gname =~ s/^gu/g/o;
        $gname =~ s/_u/_/og;
    }
    elsif ($gname =~ s/^uni(?=[0-9A-Fa-f]{4})//oi)
    {
        my (@nums) = $gname =~ m/([0-9A-Fa-f]{4})/og;
        $gname =~ s/[0-9A-Fa-f]{4}//og;
        $gname = 'g' . join('_', map {lc($_)} @nums) . $gname;
    }
    else
    {
        $gname = "g_" . $gname;
        $gname =~ s/([A-Z])/"_".lc($1)/oge;
    }
    $gname;
}

sub make_point
{
    my ($self, $p, $glyph, $opts) = @_;

    if ($p =~ m/^%([a-z0-9]+)_([a-z0-9]+)$/oi)
    {
        my ($left, $right) = ($1, $2);
        my ($top) = $self->{'font'}{'head'}{'ascent'};
        my ($bot) = $self->{'font'}{'head'}{'descent'};
        my ($adv) = $self->{'font'}{'hmtx'}->read->{'advances'}[$glyph->{'gnum'}];
        my ($split) = $glyph->{'points'}{$p}{'x'};

        $glyph->{'compounds'}{$left} = [0, $bot, $split, $top];
        $glyph->{'compounds'}{$right} = [$split, $bot, $adv, $top];
        return undef;
    }

    return undef if ($opts->{'-ignoredAPs'} and $opts->{'-ignoredAPs'} =~ m/\b$p\b/);
    return $p;
}

sub normal_rules
{
    my ($self, $fh, $pnum, $ndrawn) = @_;
    my ($g, $struni, $seq, $dseq, $dcomb, @decomp, $d);
    my ($c) = $self->{'cmap'};
    my ($glyphs) = $self->{'glyphs'};

    $fh->print("\ntable(substitution);\npass($pnum);\n");
    foreach $g (@{$self->{'glyphs'}})
    {
        next unless ($ndrawn || $g->{'props'}{'drawn'});
# TODO: should really handle multiple unicode values correctly
        next unless ($c->{$g->{'uni'}[0]} == $g->{'gnum'});
        $struni = pack('U', $g->{'uni'}[0]);
        $seq = NFD($struni);
        next if ($seq eq $struni);
        @decomp = unpack('U*', $seq);
        my ($dok) = 1;
        foreach $d (@decomp)
        { $dok = 0 unless $c->{$d}; }
        next unless $dok;

        $fh->print(join(' ', map {$glyphs->[$c->{$_}]{'name'}} @decomp) . " > $g->{'name'}:(" . join(' ', 1 .. scalar @decomp) . ") " . ("_ " x (scalar @decomp - 1)) . ";\n");

        if (scalar @decomp > 2)
        {
            $fh->print(join(' ', map {$glyphs->[$c->{$_}]{'name'}} @decomp[0, 2, 1]) . " > $g->{'name'}:(1 2 3) _ _;\n");
            $dseq = pack('U*', @decomp[0, 1]);
            $dcomb = NFC($dseq);
            if ($dcomb ne $dseq)
            { $fh->print($glyphs->[$c->{unpack('U', $dcomb)}]{'name'} . " " . $glyphs->[$c->{$decomp[2]}]{'name'} . " > $g->{'name'}:(1 2) _;\n"); }

            $dseq = pack('U*', @decomp[0, 2]);
            $dcomb = NFC($dseq);
            if ($dcomb ne $dseq)
            { $fh->print($glyphs->[$c->{unpack('U', $dcomb)}]{'name'} . " " . $glyphs->[$c->{$decomp[1]}]{'name'} . " > $g->{'name'}:(1 2) _;\n"); }
        }
    }
    $fh->print("endpass;\nendtable;\n");
}

sub lig_rules
{
    my ($self, $fh, $pnum, $type) = @_;
    my ($ligclasses) = $self->{'ligclasses'};
    my ($c, %namemap, $glyph, $name);

    return unless (defined $pnum);
    $fh->print("\ntable(substitution);\npass($pnum);\n");
    if (scalar %$ligclasses)
    {
        foreach $c (grep {!m/^no_/o} keys %{$ligclasses})
        {
            my ($gnum) = $self->{'ligmap'}{$c};
            my ($gname) = $self->{'glyphs'}[$gnum]{'name'};
            my ($compstr);

            if ($self->{'glyphs'}[$ligclasses->{$c}[0]]{'compounds'}{'0'})
            { $compstr = ' {component.0.reference = @1; component.1.reference = @2}'; }

            if ($type eq 'first')
            { $fh->print("$gname cligno_$c > _ clig$c:(1 2)$compstr / _ ^ _;\n"); }
            else
            { $fh->print("cligno_$c $gname > clig$c:(1 2)$compstr _ / ^ _ _;\n"); }

        }
    }

    foreach $glyph (@{$self->{'glyphs'}})
    {
        foreach $name (split('/', $glyph->{'post'}))
        { $namemap{$name} = $glyph; }
    }
    foreach $glyph (@{$self->{'glyphs'}})
    {
        foreach $name (split('/', $glyph->{'post'}))
        {
            my ($ext, $base, @elem) = $self->split_lig($name, $type, '');
            next if ($ext || scalar @elem < 3);
            my ($islig) = 1;
            my (@parts, $e, $g);
            my ($class, $oglyph);
            if ($type eq 'first')
            { $class = $elem[0]; }
            else
            {
                $class = $elem[-1];
                $class =~ s/^_//g;
            }
            $class =~ s/\./_/g;
            $oglyph = $namemap{$base};

            foreach $e (@elem)
            {
                my ($n) = $e;
                my ($g);
                $n =~ s/_//g;
                foreach ($n, "uni$n", "u$n")
                {
                    if ($g = $namemap{$_})
                    { last; }
                }
                if (!$g)
                {
                    $islig = 0;
                    last;
                }
                else
                {
                    push(@parts, $g->{'name'});
                }
            }
            next if (!$islig);
            $fh->print(join(" ", @parts) . " > " . $glyph->{'name'} . ":(" . join(" ", 1 .. ($#parts + 1)) . ") " . join(" ", ("_") x (@parts - 1)) . ";\n");
        }
    }
    $fh->print("endpass;\nendtable;\n");
}

sub pos_rules
{
    my ($self, $fh, $pnum) = @_;
    my ($lists) = $self->{'lists'};
    my ($p);

    return unless (keys %$lists);
    $fh->print(<<'EOT');

#ifndef opt2
#define opt(x)      [x]?
#define opt2(x)     [opt(x) x]?
#define opt3(x)     [opt2(x) x]?
#define opt4(x)     [opt3(x) x]?
#endif
EOT
    $fh->print("\ntable(positioning);\npass($pnum);\n");
    foreach $p (keys %{$lists})
    {
        next if ($p =~ m/^_/o);
        $fh->print("cTakes${p}Dia c${p}Dia {attach {to = \@1; at = ${p}S; with = ${p}M}; user1 = 1} / ^ _ " . ($self->{'hasnclass'}{$p} ? "opt4(cnTakes${p}Dia) " : "") . "_ {user1 == 0};\n");
    }
    $fh->print("endpass;\nendtable;\n");
}

sub has
{
    my ($cls, $val) = @_;
    foreach (@{$cls})
    { return 1 if ($_ == $val); }
    return 0;
}

1;

=head1 AUTHOR

Martin Hosken L<http://scripts.sil.org/FontUtils>. 

=head1 LICENSING

Copyright (c) 1998-2014, SIL International (http://www.sil.org)

This module is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.

=cut
