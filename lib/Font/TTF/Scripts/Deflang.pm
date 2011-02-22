package Font::TTF::Scripts::Deflang;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ttfdeflang);
@EXPORT_OK = (@EXPORT);

sub ttfdeflang
{
    my ($font, %opts) = @_;
    my ($f, $t);

    my ($ltag) = lc($opts{'d'});
    if (defined $font->{'Sill'} and defined $font->{'Feat'} and $t = $font->{'Sill'}->read and $f = $font->{'Feat'}->read)
    {
        if (defined $t->{'langs'}{$ltag})
        {
            my %change;
            foreach my $s (@{$t->{'langs'}{$ltag}})
            { $change{$s->[0]} = $s->[1]; }

            foreach my $g (@{$f->{'features'}})
            { $g->{'default'} = $change{$g->{'feature'}} if (defined $change{$g->{'feature'}}); }
        }
        else
        { warn "No language '$ltag' found in Sill table"; }
    }

    my ($lang) = uc($opts{'d'});
    $lang .= " " x (4 - length($lang));

    foreach my $tk (qw(GSUB GPOS))
    {
        my ($found) = 0;
        next unless (defined $font->{$tk});
        if ($t = $font->{$tk}->read)
        {
            foreach $s (keys %{$t->{'SCRIPTS'}})
            {
                if (defined ($l = $t->{'SCRIPTS'}{$s}{$lang}) || defined ($l = $t->{'SCRIPTS'}{$s}{lc($lang)}))
                {
                    my ($ttag);
                    $found = 1;
                    for ($ttag = 'DEFAULT'; $ttag; )
                    {
                        last if (defined $l->{' REFTAG'} && $l->{' REFTAG'} eq $ttag);
                        ($ttag, $t->{'SCRIPTS'}{$s}{$ttag}{' REFTAG'}) = 
                        ((defined $t->{'SCRIPTS'}{$s}{$ttag}{' REFTAG'} ? $t->{'SCRIPTS'}{$s}{$ttag}{' REFTAG'} : ''), defined $t->{'SCRIPTS'}{$s}{$lang} ? $lang : uc($lang));
                    }
                    last;
                }
            }
        }
        warn ("No language '$lang' found in $tk table") unless ($found);
    }

    return $font;
}
