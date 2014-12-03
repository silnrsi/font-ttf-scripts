package Font::TTF::Scripts::Fea;

use Font::TTF::Font;
use Font::TTF::Scripts::AP;
use Unicode::Normalize;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Font::TTF::Scripts::AP);

$VERSION = "0.01";  # MJPH   30-APR-2014    Original

*read_font = \&Font::TTF::Scripts::AP::read_font;

sub start_afdko
{
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

    $fh->print("\n# Classes\n");

    foreach $l (sort keys %{$lists})
    {
        my ($name) = $l;

        if ($name !~ m/^_/o)
        { $name = "Takes$name"; }
        else
        { $name =~ s/^_//o; }

        $fh->print("\@c${name}Dia = [");
        $count = 0; $sep = '';
        foreach $cl (@{$lists->{$l}})
        {
    #        next if ($l eq 'LS' && $cl =~ m/g101b.*_med/o);      # special since no - op in GDL
            $fh->print("$sep$glyphs->[$cl]{'name'}");
            if (++$count % 8 == 0)
            { $sep = "\n    "; }
            else
            { $sep = " "; }
        }
        $fh->print("];\n\n");

        next unless defined $vecs->{$l};

        $fh->print("\@cn${name}Dia = [");
        $count = 0; $sep = '';
        for ($c = 0; $c < $f->{'maxp'}{'numGlyphs'}; $c++)
        {
            $psname = $f->{'post'}{'VAL'}[$c];
            next if ($psname eq '' || $psname eq '.notdef');
            next if (vec($vecs->{$l}, $c, 1));
            next if (!(substr($l, 0, 1) eq "_") and vec($vecs->{"_$l"}, $c, 1));
            next if (defined $glyphs->[$c]{'props'}{'GDL_order'} && $glyphs->[$c]{'props'}{'GDL_order'} <= 1);
            next unless (vec($self->{'ismarks'}, $c, 1));
            $fh->print("$sep$glyphs->[$c]{'name'}");
            if (++$count % 8 == 0)
            { $sep = "\n    "; }
            else
            { $sep = " "; }
        }
        $fh->print("];\n\n");
    }


    foreach $cl (sort {classcmp($a, $b)} keys %{$classes})
    {
        $fh->print("\@c$cl = [$glyphs->[$classes->{$cl}[0]]{'name'}");
        for ($i = 1; $i <= $#{$classes->{$cl}}; $i++)
        { $fh->print($i % 8 ? " $glyphs->[$classes->{$cl}[$i]]{'name'}" : "\n    $glyphs->[$classes->{$cl}[$i]]{'name'}"); }
        $fh->print("];\n\n");
    }

    foreach $cl (sort {classcmp($a, $b)} keys %{$ligclasses})
    {
        $fh->print("\@clig$cl = [$glyphs->[$ligclasses->{$cl}[0]]{'name'}");
        for ($i = 1; $i <= $#{$ligclasses->{$cl}}; $i++)
        { $fh->print($i % 8 ? " $glyphs->[$ligclasses->{$cl}[$i]]{'name'}" : "\n    $glyphs->[$ligclasses->{$cl}[$i]]{'name'}"); }
        $fh->print("];\n\n");
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

sub out_pos_lookups
{
    my ($self, $fh, %opts) = @_;
    my ($f) = $self->{'font'};
    my ($vecs) = $self->{'vecs'};
    my ($marks) = $self->{'ismarks'};
    my ($glyphs) = $self->{'glyphs'};
    my ($lists) = $self->{'lists'};
    my ($l, $c, $mode);

    foreach $l (sort keys %{$lists})
    {
        next if (substr($l, 0, 1) eq "_");
        my @bases = ();
        my @mbases = ();
        my @marks = ();
        for ($c = 0; $c < $f->{'maxp'}{'numGlyphs'}; $c++)
        {
            if (vec($vecs->{$l}, $c, 1))
            {
                if (vec($marks, $c, 1))
                { push (@mbases, $c); }
                else
                { push (@bases, $c); }
            }
            if (vec($vecs->{"_$l"}, $c, 1))
            { push (@marks, $c); }
        }

        foreach $mode (0 .. 1)
        {
            my $b = \@bases;
            $b = \@mbases if ($mode);
            next if (!scalar @{$b});
            my ($name) = "base_${l}_" . ($mode ? "mark" : "base");
            $fh->print("lookup $name {\n");
            $fh->print("  lookupflag 0;\n");
            foreach $c (@marks)
            {
                my ($g) = $glyphs->[$c];
                my ($p) = $g->{'points'}{"_$l"};
                $fh->print("  markClass [$g->{'name'}] <anchor $p->{'x'} $p->{'y'}> \@$l;\n");
            }
            foreach $c (@{$b})
            {
                my ($g) = $glyphs->[$c];
                my ($p) = $g->{'points'}{$l};
                $fh->print("  pos base [$g->{'name'}] <anchor $p->{'x'} $p->{'y'}> mark \@$l;\n");
            }
            $fh->print("} $name;\n\n");
        }
    }
}

sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;
    return "\\$gname";
}

sub end_out
{
    my ($self, $fh, $includes) = @_;

    foreach (@{$includes})
    { $fh->print("include($_);\n"); }
}

1;

=head1 See also

L<Font::TTF::Scripts::AP>

=cut

=head1 AUTHOR

Martin Hosken L<http://scripts.sil.org/FontUtils>. 

=head1 LICENSING

Copyright (c) 1998-2014, SIL International (http://www.sil.org)

This module is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.


=cut