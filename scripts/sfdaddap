#!/usr/bin/perl

use IO::File;
use Encode::Unicode;
use Pod::Usage;
use Getopt::Std;
use Encode;
use Font::TTF::Scripts::AP;

getopts('h');

unless ($ARGV[0] || $opt_h)
{
    pod2usage(1);
    exit;
}

if ($opt_h)
{
    pod2usage(-verbose => 2, -noperldoc => 1);
    exit;
}

my ($currchar, $font);

$s = Font::TTF::Scripts::SFD->new(
    'AnchorClass2' => sub {
        my ($str) = @_;
        my (@a) = split(' ', $str);
        shift @a;
        while (@a) {
            my ($name) = shift @a;
            my ($subname) = shift @a;
            $name =~ s/^(['"])(.*?)\1/$2/o;   # "'
            $subname =~ s/^(['"])(.*?)\1/$2/o;   # "'
            $font->{'anchor_classes'}{$name} = $subname;
        }
        return undef
    }, 'StartChar' => sub {
        my ($name) = @_;
        $name =~ s/\s*$//o;

        $currchar = {'post' => $name, 'PSName' => $name};
        return $currchar;
    }, 'Encoding' => sub {
        my ($str) = @_;
        my (@vals) = split(' ', $str);
        $currchar->{'uni'} = hex($vals[1]);
        $currchar->{'gnum'} = $vals[2];
        $font->{'glyphs'}[$vals[2]] = $currchar;
        return undef;
    }, 'AnchorPoint' => sub {
        my ($str) = @_;
        my (@values) = split(' ', $str);
        my ($name) = $values[0];

        $name =~ s/^(['"])(.*?)\1/$2/o;   # "'
        $name = "_$name" if ($values[3] eq 'mark' && $name !~ m/^_/o);
        $currchar->{'points'}{$name} = {'name' => $name,
            'x' => $values[1],
            'y' => $values[2]};
        return undef;
    });

$font = bless {}, "Font::TTF::Scripts::AP";
$s->parse_file($ARGV[0], $font);

$font->make_names;
$aps = Font::TTF::Scripts::AP->read_font(undef, $ARGV[1]);
$aps->make_names;
@map = $aps->align_glyphs($font);

for ($i = 0; $i < $aps->{'numg'}; $i++)
{
    my ($str);
    next unless (defined $map[$i]);

    $g = $font->{'glyphs'}[$i];
    $gap = $aps->{'glyphs'}[$map[$i]];
    $gpoints = $g->{'points'};
    $npoints = {%{$gap->{'points'}}};
    foreach $p (keys %{$npoints})
    {
        my ($pname) = $p;
        ($npoints->{$p}{'x'}, $npoints->{$p}{'y'}) = ($gpoints->{$p}{'x'}, $gpoints->{$p}{'y'}) if defined ($gpoints->{$p});
        if ($pname =~ m/^_/o)
        {
            $pname =~ s/^_//o;
            $str .= "AnchorPoint: \"$pname\" $npoints->{$p}{'x'} $npoints->{$p}{'y'} mark 0\n";
        }
        else
        { $str .= "AnchorPoint: \"$p\" $npoints->{$p}{'x'} $npoints->{$p}{'y'} basechar 0\n"; }
        $allpoints{$p} = 1;
    }
    $g->{'points'} = $npoints;
    foreach $p (@{$g->{'commands'}{'AnchorPoint'}})
    { $g->{'lines'} = ''; }
    splice(@{$g->{'lines'}}, $g->{'commands'}{'EndChar'}, 0, $str);
    $g->{'commands'}{'EndChar'}++;
}

my ($glook, $gadd);
foreach $p (keys %allpoints)
{
    if (defined $font->{'anchor_classes'}{$p})
    {
        $allpoints{$p} = $font->{'anchor_classes'}{$p};
        $glook = 1 if ($allpoints{$p} eq '_someAnchors');
    }
    else
    { $gadd = 1; }
}

if ($gadd)
{
    unless ($glook)
    {
        $str = "Lookup: 260 0 0 \"_holdAnchors\"  {\"_someAnchors\"  } []\n";
        if (defined $font->{'commands'}{'Lookup'})
        { $font->{'lines'}[$font->{'commands'}{'Lookup'}[-1]] .= "\n$str"; }
        else
        { push (@{$font->{'lines'}}, $str); }
    }
    $str = '';
    foreach $p (keys %allpoints)
    { $str .= " \"$p\" \"_someAnchors\""; }
    if (defined $font->{'commands'}{'AnchorClass2'})
    { $font->{'command'}{'AnchorClass2'} .= $str; }
    else
    { push (@{$font->{'lines'}}, "$str\n"); }
}

if (defined $ARGV[2])
{ $fh = IO::File->new("> $ARGV[2]") || die "Can't create $ARGV[2]"; }
else
{ $fh = STDOUT; }

$s->print_font($font, $fh);

if (defined $ARGV[2])
{ $fh->close(); }


package Font::TTF::Scripts::SFD;

use IO::File;

sub new
{
    my ($class, %info) = @_;
    my ($self) = {%info};
    return bless $self, ref $class || $class;
}

sub parse_file
{
    my ($self, $fname, $base) = @_;
    my ($fh);
    my ($command, $text);
    my %modes = (
        'TtInstrs' => 'EndTTInstrs'
    );

    if (ref $fname)
    { $fh = $fname; }
    else
    { $fh = IO::File->new("< $fname") || die "Can't open $fname for reading"; }

    while (<$fh>)
    {
        my ($res);

        if ($mode)
        {
            $text .= $_;
            if ($_ =~ m/^$mode/)
            { $mode = ''; }
            next;
        }
        elsif (defined $self->{$command})
        {
            $res = &{$self->{$command}}($text);
            $base = $res if ($res);
        }
        if ($command)
        {
            my ($commstr) = $command;
            if ($text =~ m/^\s*$/o)
            { }
            elsif ($modes{$command})
            { $commstr .= ":"; }
            elsif ($text =~ m/\n.+\n/o)
            { $commstr .= "\n"; }
            else
            { $commstr .= ": "; }
            push (@{$base->{'lines'}}, "$commstr$text");
            push (@{$base->{'commands'}{$command}}, scalar @{$base->{'lines'}});
            $command = '';
            $text = '';
        }

        if (s/^([^\s:]+):\s*//o)
        {
            $command = $1;
            $text = $_ || "\n";
            $mode = $modes{$command};
        }
        else
        {
            $command = $_;
        }
    }
    if (defined $self->{$command})
    { &{$self->{$command}}($text); }
    push (@{$base->{'lines'}}, "$command$text");
    push (@{$base->{'commands'}{$command}}, scalar @{$base->{'lines'}});
}


sub print_font
{
    my ($self, $font, $fh) = @_;
    my ($g, $l);

    foreach $l (@{$font->{'lines'}})
    { $fh->print($l); }
    foreach $g (@{$font->{'glyphs'}})
    {
        foreach $l (@{$g->{'lines'}})
        { $fh->print($l); }
    }
}

__END__

=head1 TITLE

sfdaddap - adds AP information to a fontforge file

=head1 SYNOPSIS

  sfdaddap infile.sfd infile_ap.xml outfile.sfd

Reads a FontForge font file and extracts anchor point information into an XML
anchor point database.

=head1 OPTIONS

  -h            print manpage

=head1 DESCRIPTION

FontForge's has the concept of anchor points. This program extracts those and
any glyph comments into an XML anchor point database. See ttfbuilder -h for
documentation on this format.

=head1 SEE ALSO

ttfbuilder, volt2ap

=cut
