package Font::TTF::Scripts::Name;

require Exporter;
use Encode;

@ISA = qw(Exporter);
@EXPORT = qw(ttfname);
@EXPORT_OK = (@EXPORT);

sub ttfname
{
    my ($font, %opts) = @_;
    my ($name) = $font->{'name'}->read;
    my (@cover);

    if (defined $opts{'r'})
    {
        delete $name->{'strings'}[$opts{'r'}];
        return $font;
    }

    foreach $k (qw(n f))
    {
        $opts{$k} = decode('utf-8', $opts{$k}) if (defined $opts{$k});
    }

    if (defined $opts{'s'})
    {
        my ($fh) = IO::File->new("< $opts{'s'}") || die "Can't open $opts{'s'}";
        local ($/);
        $opts{'n'} = join('', <$fh>);
        $fh->close();
    }

    if (defined $opts{'l'} || ($opts{'t'} && !scalar @{$name->{'strings'}[$opts{'t'}]}))
    {
        ## my ($cmap) = $font->{'cmap'}->read;
        ## @cover = map {[$_->{'Platform'}, $_->{'Encoding'}]} @{$cmap->{'Tables'}};
    	@cover = $name->pe_list();
        $opts{'l'} ||= 'en-US';
    }

    if (defined $opts{'t'})
    {
        $name->set_name($opts{'t'}, $opts{'n'}, $opts{'l'}, @cover);
    }
    else
    {
        my ($subfamily) = $opts{'w'} || $name->find_name(2);
        my ($family, $full, $post, $unique, @time);

        if ($opts{'f'})
        {
            $full = $opts{'f'};
            $family = $opts{'f'};
            
            unless (lc($subfamily) eq 'regular' || lc($subfamily) eq 'standard')
            {
                unless ($family =~ s/\s+$subfamily$//i)
                {
                    $family =~ s/\s+(.*?)$//oi;
                    $subfamily = $1;
                }
            }
        }
        else
        {
            $family = $opts{'n'};
            if (lc($subfamily) eq 'regular' || lc($subfamily) eq 'standard')
            { $full = $family; }
            else
            { $full = "$family $subfamily"; }
        }

        @time = gmtime($font->{'head'}->getdate);
        $unique = sprintf('%s:%04d-%02d-%02d', $name->find_name(8) . $full, $time[5]+1900, $time[4]+1, $time[3]);
        $post = $family;
        $post .= "-$subfamily" if ($subfamily);
        $post =~ s/[\s\[\](){}<>\/%]//og;

# make sure post name set
        unless ($opts{'p'})
        {
            $name->{'strings'}[6][1][0]{0} = $post;
            $name->{'strings'}[6][3][1]{1033} = $post;
            $name->set_name(6, $post, $opts{'l'}, @cover);
        }

# now update all the interesting name fields
        $name->set_name(1, $family, $opts{'l'}, @cover);
        $name->set_name(2, $subfamily, $opts{'l'}, @cover);
        $name->set_name(3, $unique, $opts{'l'}, @cover);
        $name->set_name(4, $full, $opts{'l'}, @cover);
        $name->set_name(16, $family, $opts{'l'}, @cover);
        $name->set_name(17, $subfamily, $opts{'l'}, @cover);
        $name->set_name(18, $full, $opts{'l'}, @cover);
    }
    return $font;
}
