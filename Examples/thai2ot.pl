#! /usr/bin/perl
use Font::TTF::Scripts::Thai;
use Getopt::Std;
use Font::TTF::GDEF;
use Font::TTF::GPOS;
use Font::TTF::GSUB;
use Font::TTF::Coverage;
use Font::TTF::Anchor;
use Pod::Usage;

getopts('a:chk:x:z');

unless (defined $ARGV[1] || $opt_h)
{
    pod2usage(1);
    exit;
}
elsif ($opt_h)
{
    pod2usage(verbose => 2);
    exit;
}

$font = Font::TTF::Scripts::Thai->new($ARGV[0], $opt_c, $opt_z, $opt_a, $opt_x) || die "Can't open $ARGV[0]";
$classes = $font->{'class'}{'groups'};

# GDEF

$gdef = Font::TTF::GDEF->new('read' => 1);
$font->{'font'}{'GDEF'} = $gdef;
$gdc = Font::TTF::Coverage->new(0);
$gdef->{'Version'} = 1.0;
$gdef->{'GLYPH'} = $gdc;

foreach $k (@{$classes->{'udia'}}, @{$classes->{'ldia'}})
{ $gdc->{'val'}{$font->{'glyphs'}{$k}{'gid'}} = 3; }

foreach $k (@{$classes->{'base_cons'}}, @{$classes->{'base_tall'}})
{ $gdc->{'val'}{$font->{'glyphs'}{$k}{'gid'}} = 1; }


# GPOS
$gpos = Font::TTF::GPOS->new('read' => 1);
$font->{'font'}{'GPOS'} = $gpos;
$gpos->{'Version'} = 1.0;
$gpos->{'SCRIPTS'} = {'thai' => {
    'DEFAULT' => {' REFTAG' => 'dflt'},
    'LANG_TAGS' => ['dflt', 'thai'],
    'thai' => {' REFTAG' => 'dflt'},
    'dflt' => {
        'DEFAULT' => -1,
        'FEATURES' => ['mark', 'mkmk']}}};

$gpos->{'FEATURES'} = {
    'FEAT_TAGS' => ['mark', 'mkmk'],
    'mark' => {
        'LOOKUPS' => [0],
        'INDEX' => 0},
    'mkmk' => {
        'LOOKUPS' => [1, 2],
        'INDEX' => 1}
    };

$mcover = Font::TTF::Coverage->new(1); $mcount = 0;
$bcover = Font::TTF::Coverage->new(1); $bcount = 0;
$ucover = Font::TTF::Coverage->new(1); $ucover_i = 0;
$lcover = Font::TTF::Coverage->new(1); $lcover_i = 0;

for ($i = 0; $i <= $#{$font->{'all_glyphs'}}; $i++)
{
    $name = $font->{'all_glyphs'}[$i]{'name'};
    $glyph = $font->{'glyphs'}{$name};
    if ($glyph->{'anchor'}{'U'} || $glyph->{'anchor'}{'L'})
    {
        my (@rule);
        $bcover->{'val'}{$i} = $bcount++;
        if ($glyph->{'anchor'}{'U'})
        { $rule[0] = Font::TTF::Anchor->new('x' => $glyph->{'anchor'}{'U'}[0],
                                            'y' => $glyph->{'anchor'}{'U'}[1]); }
        if ($glyph->{'anchor'}{'L'})
        { $rule[1] = Font::TTF::Anchor->new('x' => $glyph->{'anchor'}{'L'}[0],
                                            'y' => $glyph->{'anchor'}{'L'}[1]); }
        push (@rules, [{'ACTION' => \@rule}]);
    }
    elsif ($glyph->{'anchor'}{'MARK_U'})
    {
        my ($anchor);
        $mcover->{'val'}{$i} = $mcount++;
        $ucover->{'val'}{$i} = $ucount++;
        $anchor = Font::TTF::Anchor->new('x' => $glyph->{'anchor'}{'MARK_U'}[0],
                                         'y' => $glyph->{'anchor'}{'MARK_U'}[1]);
        push (@marks, [0, $anchor]);
        push (@umarks, [0, $anchor]);
        push (@ubase, [{'ACTION' => [Font::TTF::Anchor->new(
                'x' => $glyph->{'anchor'}{'U1'}[0], 'y' => $glyph->{'anchor'}{'U1'}[1])]}]);
    }
    elsif ($glyph->{'anchor'}{'MARK_L'})
    {
        my ($anchor);
        $mcover->{'val'}{$i} = $mcount++;
        $lcover->{'val'}{$i} = $lcount++;
        $anchor = Font::TTF::Anchor->new('x' => $glyph->{'anchor'}{'MARK_L'}[0],
                                         'y' => $glyph->{'anchor'}{'MARK_L'}[1]);
        push (@marks, [1, $anchor]);
        push (@lmarks, [0, $anchor]);
        push (@lbase, [{'ACTION' => [Font::TTF::Anchor->new(
                'x' => $glyph->{'anchor'}{'L1'}[0], 'y' => $glyph->{'anchor'}{'L1'}[1])]}]);
    }
}

$lookup = {
    'TYPE' => 4,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 1,
        'COVERAGE' => $bcover,
        'MATCH' => [$mcover],
        'ACTION_TYPE' => 'a',
        'MARKS' => \@marks,
        'RULES' => \@rules}]};
push (@{$gpos->{'LOOKUP'}}, $lookup);

$lookup = {
    'TYPE' => 6,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 1,
        'COVERAGE' => $ucover,
        'MATCH' => [$ucover],
        'ACTION_TYPE' => 'a',
        'MARKS' => \@umarks,
        'RULES' => \@ubase}]};
push (@{$gpos->{'LOOKUP'}}, $lookup);

$lookup = {
    'TYPE' => 6,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 1,
        'COVERAGE' => $lcover,
        'MATCH' => [$lcover],
        'ACTION_TYPE' => 'a',
        'MARKS' => \@lmarks,
        'RULES' => \@lbase}]};
push (@{$gpos->{'LOOKUP'}}, $lookup);

$lookup_count = 3;

if ($opt_k & 1)
{
    $kcover = Font::TTF::Coverage->new(1); $kcount = 0;
    $pcover = Font::TTF::Coverage->new(1); $pcount = 0;
    foreach $k (@{$classes->{'base_cons'}})
    {
        my ($gid) = $font->{'glyphs'}{$k}{'gid'};
        $pcover->{'val'}{$gid} = $pcount++;
    }
    foreach $k (@{$classes->{'base_kern'}})
    {
        my ($gid) = $font->{'glyphs'}{$k}{'gid'};
        $kcover->{'val'}{$gid} = $kcount++ if ($font->{'glyphs'}{$k}{'kern'}{'stem'});
    }

    if ($kcount > 0)
    {
        push (@{$gpos->{'SCRIPTS'}{'thai'}{'dflt'}{'FEATURES'}}, 'kern');
        $gpos->{'FEATURES'}{'kern'} = {
            'LOOKUPS' => [$lookup_count],
            'INDEX' => 2};
        $lookup = {
            'TYPE' => 7,
            'FLAG' => 0,
            'SUB' => [{
                'FORMAT' => 3,
                'ACTION_TYPE' => 'l',
                'MATCH_TYPE' => 'o',
                'RULES' => [[{'MATCH' => [$pcover, $kcover], 'ACTION' => [[1, $lookup_count + 1]]}]]
                }]};
        push (@{$gpos->{'LOOKUP'}}, $lookup);
        $lookup_count++;
        $lookup = {
            'TYPE' => 1,
            'FLAG' => 0,
            'SUB' => [{
                'FORMAT' => 2,
                'ACTION_TYPE' => 'v',
                'COVERAGE' => $kcover,
                'RULES' => [] }]};
                
        foreach $g (sort {$a <=> $b} keys %{$kcover->{'val'}})
        {
            my ($kern) = $font->{'glyphs'}{$font->{'all_glyphs'}[$g]{'name'}}{'kern'}{'stem'};
            push (@{$lookup->{'SUB'}[0]{'RULES'}},
                    [{'ACTION' => [{'XAdvance' => -$kern, 'XPlacement' => -$kern}]}]);
        }
        push (@{$gpos->{'LOOKUP'}}, $lookup);
        $lookup_count++;
    }
}

if ($opt_k & 2)
{
    $kcover = Font::TTF::Coverage->new(1); $kcount = 0;
    $pcover = Font::TTF::Coverage->new(1); $pcount = 0;
    $ukcover = Font::TTF::Coverage->new(1); $ukcount = 0;
    for ($i = 0; $i <= $#{$font->{'all_glyphs'}}; $i++)
    {
        $name = $font->{'all_glyphs'}[$i]{'name'};
        $glyph = $font->{'glyphs'}{$name};
        $kcover->{'val'}{$i} = $kcount++ if ($glyph->{'kern'}{'tall-udia'});
        if ($glyph->{'anchor'}{'MARK_U'} || grep {$_ eq $name} @{$classes->{'base_tall'}})
        { $pcover->{'val'}{$i} = $pcount++; }
        if (grep {$_ eq $name} @{$classes->{'udia_kern'}})
        { $ukcover->{'val'}{$i} = $ukcount++; }
    }
    if ($kcount > 0)
    {
        if ($lookup_count == 3)
        {
            push (@{$gpos->{'SCRIPTS'}{'thai'}{'dflt'}{'FEATURES'}}, 'kern');
            $gpos->{'FEATURES'}{'kern'} = {
                'LOOKUPS' => [$lookup_count],
                'INDEX' => 2};
        }
        else
        {
            push (@{$gpos->{'FEATURES'}{'kern'}{'LOOKUPS'}}, $lookup_count);
        }
        
        $lookup = {
            'TYPE' => 7,
            'FLAG' => 0,
            'SUB' => [{
                'FORMAT' => 3,
                'ACTION_TYPE' => 'l',
                'MATCH_TYPE' => 'o',
                'RULES' => [[{'MATCH' => [$pcover, $kcover, $ukcover], 'ACTION' => [[1, $lookup_count + 1]]}]]
                }]};
        push (@{$gpos->{'LOOKUP'}}, $lookup);
        $lookup_count++;
        $lookup = {
            'TYPE' => 1,
            'FLAG' => 0,
            'SUB' => [{
                'FORMAT' => 2,
                'ACTION_TYPE' => 'v',
                'COVERAGE' => $kcover,
                'RULES' => [] }]};
                
        foreach $g (sort {$a <=> $b} keys %{$kcover->{'val'}})
        {
            my ($kern) = $font->{'glyphs'}{$font->{'all_glyphs'}[$g]{'name'}}{'kern'}{'tall-udia'};
            push (@{$lookup->{'SUB'}[0]{'RULES'}},
                    [{'ACTION' => [{'XAdvance' => $kern, 'XPlacement' => $kern}]}]);
        }
        push (@{$gpos->{'LOOKUP'}}, $lookup);
        $lookup_count++;
    }
}


#GSUB

$gsub = Font::TTF::GSUB->new('read' => 1);
$font->{'font'}{'GSUB'} = $gsub;
$gsub->{'Version'} = 1.0;
$gsub->{'SCRIPTS'} = {'thai' => {
    'DEFAULT' => {' REFTAG' => 'dflt'},
    'LANG_TAGS' => ['dflt', 'thai'],
    'thai' => {' REFTAG' => 'dflt'},
    'dflt' => {
        'DEFAULT' => -1,
        'FEATURES' => ['ccmp']}}};
$gsub->{'FEATURES'} = {
    'FEAT_TAGS' => ['ccmp'],
    'ccmp' => {
        'LOOKUPS' => [0, 1],
        'INDEX' => 0}};

$cover = Font::TTF::Coverage->new(1);
$i = 0;
foreach $p (sort {$font->{'glyphs'}{$a}{'gid'} <=> $font->{'glyphs'}{$b}{'gid'}} (qw(uni0e0d uni0e10)))
{
    $cover->{'val'}{$font->{'glyphs'}{$p}{'gid'}} = $i++;
    push (@grules, [{'ACTION' => [$font->{'glyphs'}{$p eq 'uni0e0d' ? 'unif70f' : 'unif700'}{'gid'}]}]);
}

$lclass = Font::TTF::Coverage->new(0);
foreach $l (keys %{$lcover->{'val'}})
{ $lclass->{'val'}{$l} = 1; }
foreach $l (keys %{$cover->{'val'}})
{ $lclass->{'val'}{$l} = 0; }

$lookup = {
    'TYPE' => 5,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 2,
        'ACTION_TYPE' => 'l',
        'MATCH_TYPE' => 'c',
        'COVERAGE' => $cover,
        'CLASS' => $lclass,
        'RULES' => [
            [{'MATCH' => [1], 'ACTION' => [[0, 2]]}],
            [],
            ]}]};
push (@{$gsub->{'LOOKUP'}}, $lookup);

$ncover = Font::TTF::Coverage->new(1);
$ncover->{'val'}{$font->{'glyphs'}{'uni0e33'}{'gid'}} = 0;

$lookup = {
    'TYPE' => 2,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 1,
        'ACTION_TYPE' => 'g',
        'COVERAGE' => $ncover,
        'RULES' => [[{'ACTION' => [$font->{'glyphs'}{'uni0e4d'}{'gid'},
                                   $font->{'glyphs'}{'uni0e32'}{'gid'}]}]]
        }]};
push (@{$gsub->{'LOOKUP'}}, $lookup);

$lookup = {
    'TYPE' => 1,
    'FLAG' => 0,
    'SUB' => [{
        'FORMAT' => 2,
        'ACTION_TYPE' => 'g',
        'COVERAGE' => $cover,
        'RULES' => \@grules}]};
push (@{$gsub->{'LOOKUP'}}, $lookup);

$font->{'font'}->out($ARGV[1]);

__END__

=head1 TITLE

thai2ot - Create OpenType lookups for Thai fonts

=head1 SYNOPSIS

  THAI2OT [-a angle] [-c] [-k num] [-x file] [-z] infile outfile
Copies the input font to the output font adding various tables on the way. If
the font is not already a Unicode font, it will be converted to one.

=head1 OPTIONS

  -a angle  Sets italic angle
  -c  Don't add circle glyph (U+25CC) if one not present. Adding a circle 
      glyph destroys the hmdx, VDMX & LTSH tables.
  -k  Add kerning rules. Bitfield of tables
      0 - ai moving left over consonants
      1 - wide upper diacritics moving base right following tall things
  -x  XML point file database for infile
  -z  Don't add zwsp (U+200B) if not present

=head1 DESCRIPTION

This program does a number of things:

=over 4

=item .

It creates a dotted circle glyph if one is not present and adds it to the font.
And also a blank ZWSP (U+200B) glyph if not present.

=item .

It reencodes the font to conform to Unicode encoding appropriate to OpenType
fonts and also to Win95 Thai editions

=item .

It creates attachment points for each glyph

=item .

It adds kerning rules to ensure glyphs don't clash.

=back

Since positioning is dependent on italic angle. If thai2gdl is used on an italic
font the slope of the font should be given to the program if it is not already
specified in the POST table in the font.

=head1 SEE ALSO

thai2gdl, thai2volt

=cut

