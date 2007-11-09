package Font::TTF::Scripts::Volt;

=head1 NAME

Font::TTF::Scripts::Volt - Memory representation of a Volt based font

=head1 SYNOPSIS

 use Font::TTF::Scripts::Volt;
 $fv = Font::TTF::Scripts::Volt->read_font($ttf_file, $ap_file, %opts);
 $dat = $fv->parse_volt;
 @map = $fv->align_glyphs($dat);
 $fv->merge_volt($dat, \@map);
 $fv->make_anchors;
 $fv->make_groups;
 $fv->make_lookups;
 $res = $fv->out_volt;

=head1 DESCRIPTION

C<Font::TTF::Scripts::Volt> is based on and inherits from C<Font::TTF::Scripts::AP>
and as such contains all the information in such an object. The read method does
little beyond calling the corresponding AP method.

The real power in this module is in the Volt parser that can parse Volt source code.
It does it rather slowly, but it does do it and reads it into an internal format.
This format can be output and can be merged into an existing font using C<merge_volt>.
From there it can be output as Volt source. The data structures added represent the
Volt source.

=over 4

=item glyphs

This is shared with the glyphs array from AP but adds a few Volt specific sub values

=over 4

=item uni

May be an array of values as well as a single value

=item type

MARK, BASE, etc.

=item component_num

Number of components in a ligature

=item name

Volt name in the source

=back

=item scripts

This is a hash of script structures keyed off the script name as used in Volt it contains

=over 4

=item tag

Four letter script tag

=item langs

An array of language structures consisting of (nearly there)

=over 4

=item name

Language name as in Volt

=item tag

Language tag that ends up in the font

=item <feature name>

Hash of features by name each containing (last one)

=over 4

=item name

Name of the feature as used to reference it

=item tag

Feature tag that ends up in the font

=item lookups

Array of names of lookups associated with this feature

=back

=back

=item anchors

This is a hash by anchor name that contains a sub hash with the following elements:

=over 4

=item pos

A C<pos> type containing the actual position of the anchor point

=item locked

Contains LOCKED if the anchor point is locked

=item component

Contains the component number for a ligature or 1 normally.

=back

=back

=item groups

A hash of group definitions by name. The contents is an array of <context> corresponding
to each element in the group's defining enum.

=item lookups

An array of lookups in the order they appear in the Volt source. Each lookup consists of

=over 4

=item id

Lookup name

=item base

Contains PROCESS_BASE if that is in the lookup

=item marks

Contains either PROCESS_MARKS or SKIP_MARKS

=item all

Contains a group name or ALL according to what is to be processed

=item dir

Contains LTR or RTL

=item contexts

Contains an array of contexts as per IN_CONTEXT. Each element of the array is itself
an array corresponding to the elements in a context. In turn each of these elements
consists of an array with two elements: A string LEFT or RIGHT and a C<context>

=item lookup

This is an array of subactions within the lookup. Each element of this array is itself
an array with a first element giving the lookup type: C<sub> or C<pos> and the second
element being the content of the lookup.

For a C<sub> lookup the second element is an array each item of which is a substitution
pair held in an array. The first element of this substitution pair is an array of
C<context>s to be substituted and the second element is an array of C<context>s that
the subsitutition is substituted with.

For a C<pos> lookup, the second element is an array hashes, one per sublookup. The
elements in the hash are dependent on the type of positioning but have consistent
meaning:

=over 4

=item type

The type of positioning. May be ATTACH, ATTACH_CURSIVE, ADJUST_SINGLE, ADJUST_PAIR.

=item context

Gives the context glyph for ATTACH and ADJUST_SINGLE lookups and consists of a
single C<context>

=item context1

The first context glyph for an ADJUST_PAIR. It consists of an array of C<context>s
which are referenced by number according to their index (starting at 1) in the
positioning.

=item context2

The second context glyph for an ADJUST_PAIR. It consists of an array of C<contexts>s
which correspond to the second number in a position.

=item exits

An array of C<context>s one for each glyph with an C<exit> anchor. Used only in
ATTACH_CURSIVE

=item enters

An array of C<context>s one for each glyph with an C<entry> anchor. Used only in
ATTACH_CURSIVE

=item to

Used in an ATTACH to specify which glyphs the C<context> glyphs are attached to and
with which anchor point. Each element of this array is an array with two elements:
a C<context> to specify the glyph moving (the base glyph is specified by the
C<context> hash entry) and the name of the anchor point used to link the two. The
base glyph has an anchor with the anchor name and the second glyph has an anchor
with the anchor named prefixed by MARK_

=item adj

An adjustment is used in a ADJUST_SINGLE as an array of positioning elements of type
C<pos> each one corresponding to a C<context> in the context array.

For an ADJUST_PAIR the adj is an array of arrays. Each sub array has 3 elements:
first index into the context1 array (starting at 1), second index into the context2
array (starting at 1) and a C<pos> to specify the actual adjustment of those two
glyphs.

=back

=back

=item info

The info hash contains some global information for the whole font with the following
hash elements:

=over 4

=item ppos

Specifies the pixesl per em for positioning purpsoes

=item grid

Specifies the pixels per em for the grid

=item pres

Specifies the presentation pixels per em

=item cmap

This is an array of cmap entries, each of which is an array of 3 numbers.

=back

In addition to extra entries in the main object there are two types that are used
in various places:

=head2 Context

A context consists of an array with two elements. The first element gives the type
of the context item and the second the value. The context types are:

=over 4

=item GLYPH

The second array element contains a glyph id. Note it does not contain a glyph name.
The name is resolved to an id in the parser and converted back to a name during output.

=item GROUP

The second array element is a string holding the name of the group being referenced

=item RANGE

The second two array elements are the first and last glyph id for the range. Ranges
are particularly difficult to work with when merging different glyph arrays so should
be avoided

=item ENUM

An enum is a way of embedding a list of contexts within a context. The remaining
elements in the array are C<context>s

=back

=head2 Pos

A positioning element is a glorious animal. You would think that it could just be
an C<x> and C<y> co-ordinate. You would be so wrong! A C<pos> is a hash with
three elements: C<x>, C<y> and C<adv>. C<adv> specifies changes to the advance
width of a glyph in ADJUST_PAIR.

Each of these hash entries is an array. The first element of the array is the
actual co-ordinate value. The second is an optionally empty array of adjustments
to that co-ordinate. Each element of that array is a two element array of the
adjust value and the ppem value at which the adjustment occurs.

=cut

#use Parse::RecDescent;
use Algorithm::Diff qw(sdiff);
use Font::TTF::Font;
use Font::TTF::Scripts::AP;

use strict;
use vars qw($VERSION @ISA %dat $volt_grammar $volt_parser);
@ISA = qw(Font::TTF::Scripts::AP);

$VERSION = "0.02";  # MJPH   9-AUG-2005     Add support for glyph alternates
# $VERSION = "0.01";  # MJPH  26-APR-2004     Original based on existing code
# *read_font = \&Font::TTF::Scripts::AP::read_font;

sub read_font
{
    my ($self) = Font::TTF::Scripts::AP::read_font(@_);

    $self->{'glyphs'}[0]{'post'} = 'glyph0';        # hack to make volt happy, not sure why
    $self;
}


sub out_volt
{
    my ($self, %opts) = @_;
    my ($res);
    
    $res = $self->out_volt_glyphs;
    $res .= $self->out_volt_scripts;
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
        if (defined $g->{'uni'})
        {
            if (scalar @{$g->{'uni'}} > 1)
            { $res .= " UNICODEVALUES \"" . join(",", map {sprintf("U+%04X", $_)}
                    sort {$a <=> $b} @{$g->{'uni'}}) . '"'; }
            elsif (scalar @{$g->{'uni'}} == 1)
            { $res .= " UNICODE $g->{'uni'}[0]"; }
        }
        
        if (defined $g->{'props'}{'type'})
        { $type = $g->{'props'}{'type'} || $g->{'type'}; }
        elsif (defined $g->{'anchors'})
        { $type = $g->{'type'} || 'BASE'; }
        
        $res .= " TYPE $type" if ($type);
        $res .= " COMPONENTS " . $g->{'component_num'} if ($g->{'component_num'});
        $res .= " END_GLYPH\n";
    }
    $res;
}


sub out_volt_classes
{
    my ($self) = @_;
    my ($cl, $res);

    foreach $cl (sort keys %{$self->{'groups'}})
    {
        my ($e);
        my ($t) = $cl;

        $res .= "DEF_GROUP \"$cl\"\n ENUM";
        foreach $e (@{$self->{'groups'}{$cl}})
        { $res .= " " . out_context($e, $self); }
        $res .= " END_ENUM\nEND_GROUP\n";
    }
    $res;
}

sub out_volt_scripts
{
    my ($self) = @_;
    my ($res, $lk, $s, $f, $l);

    foreach $s (sort keys %{$self->{'scripts'}})
    {
        my ($t) = $self->{'scripts'}{$s};
        $res .= "DEF_SCRIPT NAME \"$s\" TAG \"$t->{'tag'}\"\n";
        foreach $l (@{$t->{'lang'}})
        {
            $res .= "DEF_LANGSYS NAME \"$l->{'name'}\" TAG \"$l->{'tag'}\"\n";
            foreach $f (sort grep {$_ ne 'name' && $_ ne 'tag'} keys %{$l})
            {
                $res .= "DEF_FEATURE NAME \"$f\" TAG \"$l->{$f}{'tag'}\"\n";
                foreach $lk (@{$l->{$f}{'lookups'}})
                { $res .= " LOOKUP \"$lk\""; }
                $res .= "\nEND_FEATURE\n";
            }
            $res .= "END_LANGSYS\n";
        }
        $res .= "END_SCRIPT\n";
    }
    $res;
}

sub out_volt_lookups
{
    my ($self, $ligtype) = @_;
    my ($glyphs) = $self->{'glyphs'};
    my ($res, $c, $i, $l);
    my (%output);

    foreach $l (@{$self->{'lookups'}})
    {
        my ($q, $t, $s);
        my ($id) = $l->{'id'};
        next if ($output{$id});
#        next if ((defined $self->{'lists'}{$id} && $id !~ m/^_/o)
#            || (defined $self->{'classes'}{$id} && $id !~ m/^no_/o));

        my ($t) = $id;
#        next if ($t =~ s/^l//o && defined $self->{'ligclasses'}{$t});
        $res .= "DEF_LOOKUP \"$id\"";
        foreach $q (qw(base marks all dir))
        {
            if ($q eq 'all' && $l->{$q} && $l->{$q} ne 'ALL')
            { $res .= " \"$l->{$q}\""; }
            elsif ($q eq 'dir')
            { $res .= " DIRECTION $l->{$q}"; }
            else
            { $res .= " $l->{$q}" if ($l->{$q}); }
        }
        $res .= "\n";
        if (scalar @{$l->{'contexts'}})
        {
            foreach $q (@{$l->{'contexts'}})
            {
                $res .= "IN_CONTEXT";
                foreach $c (@{$q})
                {
                    $res .= "\n $c->[0]";
                    foreach $t (@{$c}[1..$#{$c}])
                    { $res .= " ". out_context($t, $self); }
                }
                $res .= "\nEND_CONTEXT\n";
            }
        }
        else
        { $res .= "IN_CONTEXT\nEND_CONTEXT\n"; }
        if ($l->{'lookup'}[0] eq 'sub')
        {
            $res .= "AS_SUBSTITUTION\n";
            foreach $s (@{$l->{'lookup'}[1]})
            {
                $res .= "SUB";
                foreach $c (@{$s->[0]})
                { $res .= " " . out_context($c, $self); }
                if ($s->[1])
                {
                    $res .= "\nWITH";
                    foreach $c (@{$s->[1]})
                    { $res .= " " . out_context($c, $self); }
                }
                $res .= "\nEND_SUB\n";
            }
            $res .= "END_SUBSTITUTION\n";
        }
        elsif ($l->{'lookup'}[0] eq 'pos')
        {
            $res .= "AS_POSITION\n";
            foreach $s (@{$l->{'lookup'}[1]})
            {
                $res .= "$s->{'type'}";
                if ($s->{'type'} eq 'ATTACH')
                {
                    my ($c);
                    foreach $c (@{$s->{'context'}})
                    { $res .= " " . out_context($c, $self); }
                    $res .= "\nTO";
                    foreach $c (@{$s->{'to'}})
                    { $res .= " " . out_context($c->[0], $self) . " AT ANCHOR \"$c->[1]\""; }
                    $res .= "\nEND_ATTACH\n";
                }
                elsif ($s->{'type'} eq 'ATTACH_CURSIVE')
                {
                    my ($c);
                    foreach $c (@{$s->{'exits'}})
                    { $res .= "\nEXIT " . out_context($c, $self); }
                    foreach $c (@{$s->{'enters'}})
                    { $res .= "\nENTER " . out_context($c, $self); }
                }
                elsif ($s->{'type'} eq 'ADJUST_PAIR')
                {
                    my ($c);
                    $res .= "\n";
                    foreach $c (@{$s->{'context1'}})
                    { $res .= " FIRST  " . out_context($c, $self); }
                    $res .= "\n";
                    foreach $c (@{$s->{'context2'}})
                    { $res .= " SECOND  " . out_context($c, $self); }
                    foreach $c (@{$s->{'adj'}})
                    {
                        my ($d);
                        $res .= "\n $c->[0] $c->[1] BY";
                        foreach $d (@{$c->[2]})
                        { $res .= " " . out_pos($d); }
                    }
                    $res .= "\nEND_ADJUST\n";
                }
                elsif ($s->{'type'} eq 'ADJUST_SINGLE')
                {
                    my ($i);
                    for ($i = 0; $i < @{$s->{'context'}}; $i++)
                    { $res .= " " . out_context($s->{'context'}[$i], $self) . " BY " . out_pos($s->{'adj'}[$i]); }
                    $res .= "\nEND_ADJUST\n";
                }
            }
            $res .= "END_POSITION\n";
        }
#        $res .= "END_LOOKUP\n";
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
        foreach $i (sort keys %{$glyph->{'anchors'}})
        {
            $res .= "DEF_ANCHOR \"$i\" ON $glyph->{'gnum'} GLYPH $k COMPONENT 1 " .
                    "AT POS DX $glyph->{'anchors'}{$i}{'pos'}{'x'}[0] DY $glyph->{'anchors'}{$i}{'pos'}{'y'}[0] END_POS " .
                    "END_ANCHOR\n";
        }
    }
    $res;
}

sub out_volt_final
{
    my ($self) = @_;
    my ($res, $c);
    my (%labels) = ('grid' => 'GRID_PPEM', 'present' => 'PRESENTATION_PPEM', 'ppos' => 'PPOSITIONING_PPEM');

    if (defined $self->{'info'})
    {
        foreach $c (qw(grid present ppos))
        {
            if ($self->{'info'}{$c})
            { $res .= "$labels{$c} $self->{'info'}{$c}\n"; }
        }
        foreach $c (@{$self->{'info'}{'cmap'}})
        { $res .= "CMAP_FORMAT $c->[0] $c->[1] $c->[2]\n"; }
        $res .= "END\n";
    }
    else
    {
        $res .= <<'EOT';
GRID_PPEM 20
PRESENTATION_PPEM 72
PPOSITIONING_PPEM 144
CMAP_FORMAT 1 0 0
CMAP_FORMAT 3 1 4
END
EOT
    }
    $res;
}

sub out_context
{
    my ($cont, $dat) = @_;
    my ($res, $c);

    if ($cont->[0] eq 'GLYPH')
    { $res = "$cont->[0] \"$dat->{'glyphs'}[$cont->[1]]{'name'}\""; }
    elsif ($cont->[0] eq 'GROUP')
    { $res = "$cont->[0] \"$cont->[1]\""; }
    elsif ($cont->[0] eq 'RANGE')
    { $res = "$cont->[0] \"$dat->{'glyphs'}[$cont->[1]]{'name'}\" TO \"$dat->{'glyphs'}[$cont->[2]]{'name'}\""; }
    elsif ($cont->[0] eq 'ENUM')
    {
        $res = "ENUM";
        foreach $c (@{$cont}[1 .. $#{$cont}])
        { $res .= " " . context($c); }
        $res .= " END_ENUM";
    }
    $res;
}

sub out_pos
{
    my ($pos) = @_;
    my ($res, $c);
    my (%labels) = ('adv' => 'ADV', 'x' => 'DX', 'y' => 'DY');

    $res = "POS";
    foreach $c (qw(adv x y))
    {
        my ($d);
        if ($pos->{$c})
        {
            $res .= " ". $labels{$c} . " " . $pos->{$c}[0];
            foreach $d (@{$pos->{$c}[1]})
            { $res .= " ADJUST_BY $d->[0] AT $d->[1]"; }
        }
    }
    $res .= " END_POS";
    $res;
}
sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;

    if (defined $glyph->{'props'}{'VOLT_id'})
    { return $glyph->{'props'}{'VOLT_id'}; }
    else
    { 
        $gname =~ s{/.*$}{}o;
        $gname =~ s/[.;\-\"\'&$#\/]//og;
    }
    $gname;
}

sub make_point
{
    my ($self, $p, $glyph, %opts) = @_;
    
    $glyph->{'props'}{'type'} ||= 'MARK' if ($p =~ m/^_/o && $opts{'-notmark'} !~ m/\b$p\b/);
    return $p;
}

if (0)
{
# VOLT parsing code

%dat = ();

$volt_grammar = <<'EOG';

    { my (%dat, $c); }
    
    start : statement 'END'
            { $return = {%dat}; }
        | <error>
    
    statement : glyph(s?) script(s?) group(s?) lookup(s?) anchor(s?) info(?)

    glyph : 'DEF_GLYPH' <commit> qid 'ID' num glyph_unicode(?) glyph_type(?) glyph_component(?) 'END_GLYPH'
            { 
                $dat{'glyphs'}[$item[5]] = {'uni' => $item[6][0], 'type' => $item[7][0], 'name' => $item[3], 'component_num' => $item[8][0], 'gnum' => $item[5]};
                $dat{'glyph_names'}{$item[3]} = $item[5];
                1;
            }

    glyph_unicode : 'UNICODEVALUES' <commit> '"' uni_list '"' 
            { $return = [map {s/^U+//oi; hex($_);} split(/\s*,\s*/, $item[-2])]; }
                  | 'UNICODE' num
            { $return = [$item[-1]]; }

    glyph_type : 'TYPE' /MARK|BASE|LIGATURE/
            { $return = $item[2]; }

    glyph_component : 'COMPONENTS' num
            { $return = $item[-1]; }

    script : 'DEF_SCRIPT' <commit> name tag langsys(s?) 'END_SCRIPT'
            { $dat{'scripts'}{$item[3]} = {'tag' => $item[4], 'lang' => $item[5]}; }

    langsys : 'DEF_LANGSYS' name tag feature(s?) 'END_LANGSYS'
            { $return = { 'name' => $item[2], 'tag' => $item[3], map {$_->{'name'} => $_} @{$item[4]}}; }

    feature : 'DEF_FEATURE' name tag lookup_ref(s?) 'END_FEATURE'
            { $return = { 'name' => $item[2], 'tag' => $item[3], 'lookups' => $item[4]}; }

    group : 'DEF_GROUP' <commit> qid enum(?) 'END_GROUP'
            { $dat{'groups'}{$item[3]} = $item[4][0]; }

    enum : 'ENUM' context(s?) 'END_ENUM'
            { $return = [@{$item[2]}]; }

    lookup : 'DEF_LOOKUP' <commit> qid lk_procbase(?) lk_procmarks(?) lk_all(?) lk_direction(?) lk_context(s) lk_content
            { push (@{$dat{'lookups'}}, { 'id' => $item[3],
                                          'base' => $item[4][0],
                                          'marks' => $item[5][0],
                                          'all' => $item[6][0],
                                          'dir' => $item[7][0],
                                          'contexts' => [@{$item[8]}],
                                          'lookup' => $item[9] }); }

    lk_context : 'IN_CONTEXT' lk_context_lt(s?) 'END_CONTEXT'
            { $return = [@{$item[2]}]; }

    lk_context_lt : /LEFT|RIGHT/ context(s)
            { $return = [$item[1], @{$item[-1]}]; }

    context : 'GLYPH' <commit> gid   { $return = [$item[1], $item[3]]; }
             | 'GROUP' <commit> qid  { $return = [$item[1], $item[3]]; }
             | 'RANGE' <commit> gid 'TO' gid   { $return = [$item[1], $item[3], $item[5]]; }
             | enum                 { $return = ['ENUM', @{$item[1]}]; }

    lk_content : lk_subst | lk_pos
            { $return = $item[1] || $item[2]; }

    lk_subst : 'AS_SUBSTITUTION' subst(s) 'END_SUBSTITUTION'
            { $return = ['sub', $item[2]]; }

    lk_pos : 'AS_POSITION' post(s) 'END_POSITION'
            { $return = ['pos', $item[2]]; }

    subst : 'SUB' context(s?) 'WITH' context(s?) 'END_SUB'
            { $return = [$item[2], $item[4]]; }

    post : 'ATTACH_CURSIVE' <commit> exit_con(s) enter_con(s) 'END_ATTACH'
            { $return = {'type' => $item[1], 'exits' => $item[3], 'enters' => $item[4] }; }
        | 'ATTACH' <commit> context(s) 'TO' attach(s) 'END_ATTACH'
            { $return = {'type' => $item[1], 'context' => $item[3], 'to' => $item[5] }; }
        | 'ADJUST_PAIR' <commit> post_first(s) post_second(s) post_adj(s) 'END_ADJUST'
            { $return = {'type' => $item[1], 'context1' => $item[3], 'context2' => $item[4], 'adj' => $item[5]}; }
        | 'ADJUST_SINGLE' <commit> post_single(s) 'END_ADJUST'
            { $return = {'type' => $item[1], 'context' => [map {$_->[0]} @{$item[3]}], 'adj' => [map {$_->[1]} @{$item[3]}]}; }

    attach : context 'AT' 'ANCHOR' qid
            { $return = [$item[1], $item[-1]]; }

    exit_con : 'EXIT' context
            { $return = $item[-1]; }

    enter_con : 'ENTER' context
            { $return = $item[-1]; }

    post_first : 'FIRST' context
            { $return = $item[-1]; }

    post_second : 'SECOND' context
            { $return = $item[-1]; }

    post_adj : num num 'BY' pos(s)
            { $return = [$item[1], $item[2], $item[4]]; }

    post_single : context 'BY' pos
            { $return = [$item[1], $item[3]]; }

    anchor : 'DEF_ANCHOR' <commit> qid 'ON' num 'GLYPH' gid 'COMPONENT' num anchor_locked(?) 'AT' pos 'END_ANCHOR'
            { $dat{'glyphs'}[$item[5]]{'anchors'}{$item[3]} = {'pos' => $item[-2], 'component' => $item[9], 'locked' => $item[10][0]}; 1; }
    
    anchor_locked : 'LOCKED'

    pos : 'POS' pos_adv(?) pos_dx(?) pos_dy(?) 'END_POS'
            { $return = {
                    'adv' => $item[2][0],
                    'x' => $item[3][0],
                    'y' => $item[4][0] }; }
    
    pos_dx : 'DX' <commit> num pos_adj(s?)
            { $return = [$item[3], $item[4]]; }
    
    pos_dy : 'DY' <commit> num pos_adj(s?)
            { $return = [$item[3], $item[4]]; }
    
    pos_adv : 'ADV' <commit> num pos_adj(s?)
            { $return = [$item[3], $item[4]]; }

    pos_adj : 'ADJUST_BY' <commit> num 'AT' num
            { $return = [$item[3], $item[5]]; }

    lk_procbase : /SKIP_BASE|PROCESS_BASE/

    lk_procmarks : /PROCESS_MARKS|SKIP_MARKS/

    lk_all : 'ALL' | qid
            { $return = $item[1] || $item[2]; }

    lk_direction : 'DIRECTION' /LTR|RTL/            # what about RTL here?
            { $return = $item[2]; }

    info : i_grid(?) i_pres(?) i_ppos(?) i_cmap(s?)
            { $dat{'info'} = {
                    grid => $item[1][0],
                    present => $item[2][0],
                    ppos => $item[3][0],
                    cmap => $item[4] };
            }
    
    i_grid : 'GRID_PPEM' num
    
    i_pres : 'PRESENTATION_PPEM' num
    
    i_ppos : 'PPOSITIONING_PPEM' num
    
    i_cmap : 'CMAP_FORMAT' num num num
            { $return = [$item[2], $item[3], $item[4]]; }

    lookup_ref : 'LOOKUP' qid
        { $return = $item[2]; }
    
    name : 'NAME' qid
        { $return = $item[2]; }
    
    tag : 'TAG' qid
        { $return = $item[2]; }
                  
    uni_list : /[0-9a-fA-F,U+\s]+/o
        { $return = $item[1]; }
    
    qid : /"[^"]+"/o
        { $return = substr($item[1], 1, -1); }
    
    gid : /"[^"]+"/o
        { $return = $dat{'glyph_names'}{substr($item[1], 1, -1)}; }
        | /\S+/
        { $return = $dat{'glyph_names'}{$item[1]}; }
        
    num : /-?\d+/
        { $return = $item[1]; }
EOG

#" to keep editors happy

=head2 $f->parse_volt([$vtext])

Parses volt source. If no C<$vtext> then take it from the C<TSIV> table in the font.

=cut

sub parse_volt_old
{
    my ($self, $vtext) = @_;
    my ($font) = $self->{'font'} if (ref $self);

    $vtext = $font->{'TSIV'}->read->{' dat'} unless ($vtext);
    $volt_parser = new Parse::RecDescent ($volt_grammar) unless ($volt_parser);
    return $volt_parser->start($vtext);
}
}

sub parse_volt
{
    my ($self, $str) = @_;
    my ($font) = $self->{'font'} if (ref $self);
    my ($res);

    $str = $font->{'TSIV'}->read->{' dat'} unless ($str);
    $str .= " ";        # ensure final space to match
    $str =~ s/\r\n?/\n/og;

    # DON'T MAKE ANY CHANGES TO $str AFTER THIS LINE
    $str =~ m/^\x{FEFF}?\s*/ogcs;

#    glyph : 'DEF_GLYPH' <commit> qid 'ID' num glyph_unicode(?) glyph_type(?) glyph_component(?) 'END_GLYPH'
#            { 
#                $dat{'glyphs'}[$item[5]] = {'uni' => $item[6][0], 'type' => $item[7][0], 'name' => $item[3], #'component_num' => $item[8][0], 'gnum' => $item[5]};
#                $dat{'glyph_names'}{$item[3]} = $item[5];
#                1;
#            }
#
#    glyph_unicode : 'UNICODEVALUES' <commit> '"' uni_list '"' 
#            { $return = [map {s/^U+//oi; hex($_);} split(/\s*,\s*/, $item[-2])]; }
#                  | 'UNICODE' num
#            { $return = [$item[-1]]; }
#
#    glyph_type : 'TYPE' /MARK|BASE|LIGATURE/
#            { $return = $item[2]; }
#
#    glyph_component : 'COMPONENTS' num
#            { $return = $item[-1]; }
#
    while ($str =~ m/\GDEF_GLYPH\s+"([^"]+)"\s+ID\s+(\d+)\s+(?:(?:UNICODEVALUES\s+"([^"]+)"\s+)|(?:UNICODE\s+(\d+))\s+)?(?:TYPE\s+(MARK|BASE|LIGATURE)\s+)?(?:COMPONENTS\s+(\d+)\s+)?END_GLYPH\s+/ogc)
    {
        my ($name, $gnum, $uni_list, $uni, $type, $comp) = ($1, $2, $3, $4, $5, $6);
        
        $res->{'glyphs'}[$gnum] = {'name' => $name, 
                'gnum' => $gnum,
                'component_num' => $comp,
                'type' => $type};
        if ($uni_list)
        { $res->{'glyphs'}[$gnum]{'uni'} = [map {s/^U+//oi; hex($_);} split(/\s*,\s*/, $uni_list)]; }
        else
        { $res->{'glyphs'}[$gnum]{'uni'} = [$uni]; }
        $res->{'glyph_names'}{$name} = $gnum;
    }

#    script : 'DEF_SCRIPT' <commit> name tag langsys(s?) 'END_SCRIPT'
#            { $dat{'scripts'}{$item[3]} = {'tag' => $item[4], 'lang' => $item[5]}; }
    while ($str =~ m/\GDEF_SCRIPT\s+NAME\s+"([^"]+)"\s+TAG\s+"([^"]+)"\s+/ogc)
    {
        my ($name, $tag) = ($1, $2);
        my (@langs);

#    langsys : 'DEF_LANGSYS' name tag feature(s?) 'END_LANGSYS'
#            { $return = { 'name' => $item[2], 'tag' => $item[3], map {$_->{'name'} => $_} @{$item[4]}}; }
        while ($str =~ m/\GDEF_LANGSYS\s+NAME\s+"([^"]+)"\s+TAG\s+"([^"]+)"\s+/ogc)
        {
            my ($lname, $ltag) = ($1, $2);
            my (%feats);

#    feature : 'DEF_FEATURE' name tag lookup_ref(s?) 'END_FEATURE'
#            { $return = { 'name' => $item[2], 'tag' => $item[3], 'lookups' => $item[4]}; }
            while ($str =~ m/\GDEF_FEATURE\s+NAME\s+"([^"]+)"\s+TAG\s+"([^"]+)"\s+/ogc)
            {
                my ($fname, $ftag) = ($1, $2);
                my (@lkups);

#    lookup_ref : 'LOOKUP' qid
#        { $return = $item[2]; }
                while ($str =~ m/\GLOOKUP\s+"([^"]+)"\s+/ogc)
                {
                    my ($kname) = ($1);
                    push (@lkups, $kname);
                }
                $feats{$fname} = {'name' => $fname, 'tag' => $ftag, 'lookups' => [@lkups]};

                unless ($str =~ m/\GEND_FEATURE\s+/ogc)
                { die "Expected END_FEATURE, found: " . substr($str, pos($str), 20); }
            }
            push (@langs, {'name' => $lname, 'tag' => $ltag, %feats});

            unless ($str =~ m/\GEND_LANGSYS\s+/ogc)
            { die "Expected END_LANGSYS, found: " . substr($str, pos($str), 20); }
        }

        $res->{'scripts'}{$name} = {'tag' => $tag, 'lang' => [@langs]};
        unless ($str =~ m/\GEND_SCRIPT\s+/ogc)
        { die "Expected END_SCRIPT, found: " . substr($str, pos($str), 20); }
    }

#    group : 'DEF_GROUP' <commit> qid enum(?) 'END_GROUP'
#            { $dat{'groups'}{$item[3]} = $item[4][0]; }
    while ($str =~ m/\GDEF_GROUP\s+"([^"]+)"\s+(?:ENUM\s+)?/ogc)
    {
        my ($name) = ($1);
        my (@entries) = parse_enum(\$str, $res);
        $res->{'groups'}{$name} = [@entries];
        unless ($str =~ m/\G(?:END_ENUM\s+)?END_GROUP\s+/ogc)
        { die "Expected END_GROUP, found: " . substr($str, pos($str), 20); }
    }

#    lookup : 'DEF_LOOKUP' <commit> qid lk_procbase(?) lk_procmarks(?) lk_all(?) lk_direction(?) lk_context(s) # lk_content
#            { push (@{$dat{'lookups'}}, { 'id' => $item[3],
#                                          'base' => $item[4][0],
#                                          'marks' => $item[5][0],
#                                          'all' => $item[6][0],
#                                          'dir' => $item[7][0],
#                                          'contexts' => [@{$item[8]}],
#                                          'lookup' => $item[9] }); }
#    lk_procbase : /SKIP_BASE|PROCESS_BASE/
#
#    lk_procmarks : /PROCESS_MARKS|SKIP_MARKS/
#
#    lk_all : 'ALL' | qid
#            { $return = $item[1] || $item[2]; }
#
#    lk_direction : 'DIRECTION' /LTR|RTL/            # what about RTL here?
#            { $return = $item[2]; }
#
    while ($str =~ m/\GDEF_LOOKUP\s+"([^"]+)"\s+(?:(SKIP_BASE|PROCESS_BASE)\s+)?(?:(SKIP_MARKS|PROCESS_MARKS)\s+)?(?:(?:(ALL)|"([^"]+)")\s+)?(?:DIRECTION\s+(LTR|RTL)\s+)?/ogc)
    {
        my ($name) = $1;
        push (@{$res->{'lookups'}}, {'id' => $1,
                'base' => $2,
                'marks' => $3,
                'all' => $4 || $5,
                'dir' => $6});

#    lk_context : 'IN_CONTEXT' lk_context_lt(s?) 'END_CONTEXT'
#            { $return = [@{$item[2]}]; }
        while ($str =~ m/\GIN_CONTEXT\s+/ogc)
        {
            my (@context);

#    lk_context_lt : /LEFT|RIGHT/ context(s)
#            { $return = [$item[1], @{$item[-1]}]; }
            while ($str =~ m/\G(RIGHT|LEFT)\s+/ogc)
            { push (@context, [$1, parse_enum(\$str, $res)]); }

            unless ($str =~ m/\GEND_CONTEXT\s+/ogc)
            { die "Expected END_CONTEXT, found: " . substr($str, pos($str), 20); }

            push (@{$res->{'lookups'}[-1]{'contexts'}}, [@context]);
        }

#    lk_content : lk_subst | lk_pos
#            { $return = $item[1] || $item[2]; }
#
#    lk_subst : 'AS_SUBSTITUTION' subst(s) 'END_SUBSTITUTION'
#            { $return = ['sub', $item[2]]; }
#
#    lk_pos : 'AS_POSITION' post(s) 'END_POSITION'
#            { $return = ['pos', $item[2]]; }
        while ($str =~ m/\G(AS_SUBSTITUTION|AS_POSITION)\s+/ogc)
        {
            my ($type) = $1;
            my (@content);

            if ($type eq 'AS_SUBSTITUTION')
            {
#    subst : 'SUB' context(s?) 'WITH' context(s?) 'END_SUB'
#            { $return = [$item[2], $item[4]]; }
                while ($str =~ m/\GSUB\s+/ogc)
                {
                    my (@in) = parse_enum(\$str, $res);
                    my (@out);
                    unless ($str =~ m/\GWITH\s+/ogc)
                    { die "Expected WITH in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    @out = parse_enum(\$str, $res);
                    unless ($str =~ m/\GEND_SUB\s+/ogc)
                    { die "Expected END_SUB in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    push (@content, [[@in], [@out]]);
                }
                $res->{'lookups'}[-1]{'lookup'} = ['sub', [@content]];

                unless ($str =~ m/\GEND_SUBSTITUTION\s+/ogc)
                { die "Expected END_SUBSTITUION in LOOKUP $name, found: " . substr($str, pos($str), 20); }
            }
            else        # presume pos
            {
                while (1)
                {
#    post : 'ATTACH_CURSIVE' <commit> exit_con(s) enter_con(s) 'END_ATTACH'
#            { $return = {'type' => $item[1], 'exits' => $item[3], 'enters' => $item[4] }; }
                    if ($str =~ m/\GATTACH_CURSIVE\s+/ogc)
                    {
                        my (@exits, @enters);
#    exit_con : 'EXIT' context
#            { $return = $item[-1]; }
                        while ($str =~ m/\GEXIT\s+/ogc)
                        {
                            my (@e) = parse_enum(\$str, $res);
                            push (@exits, $e[0]);
                        }
#    enter_con : 'ENTER' context
#            { $return = $item[-1]; }
                        while ($str =~ m/\GENTER\s+/ogc)
                        {
                            my (@e) = parse_enum(\$str, $res);
                            push (@enters, $e[0]);
                        }
                        push (@content, {'type' => 'ATTACH_CURSIVE', 'exits' => [@exits], 'enters' => [@enters]});
                        unless ($str =~ m/\GEND_ATTACH\s+/ogc)
                        { die "Expected END_ATTACH in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    }
#        | 'ATTACH' <commit> context(s) 'TO' attach(s) 'END_ATTACH'
#            { $return = {'type' => $item[1], 'context' => $item[3], 'to' => $item[5] }; }
                    elsif ($str =~ m/\GATTACH\s+/ogc)
                    {
                        my (@anchors);
                        my (@cont) = parse_enum(\$str, $res);
                        unless ($str =~ m/\GTO\s+/ogc)
                        { die "Expected TO in LOOKUP $name, found: " . substr($str, pos($str), 20); }
#    attach : context 'AT' 'ANCHOR' qid
#            { $return = [$item[1], $item[-1]]; }
                        while (1)
                        {
                            my (@acont) = parse_enum(\$str, $res);
                            last unless (@acont);
                            if ($str =~ m/\GAT\s+ANCHOR\s+"([^"]+)"\s+/ogc)
                            { push (@anchors, [$acont[0], $1]); }
                            else
                            { die "Expected AT ANCHOR in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                        }
                        push (@content, {'type' => 'ATTACH', 'context' => [@cont], 'to' => [@anchors]});
                        unless ($str =~ m/\GEND_ATTACH\s+/ogc)
                        { die "Expected END_ATTACH in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    }
#        | 'ADJUST_PAIR' <commit> post_first(s) post_second(s) post_adj(s) 'END_ADJUST'
#            { $return = {'type' => $item[1], 'context1' => $item[3], 'context2' => $item[4], 'adj' => $item[5]}; }
                    elsif ($str =~ m/\GADJUST_PAIR\s+/ogc)
                    {
                        my (@firsts, @seconds, @adjs);

#    post_first : 'FIRST' context
#            { $return = $item[-1]; }
                        while ($str =~ m/\GFIRST\s+/ogc)
                        {
                            my (@e) = parse_enum(\$str, $res);
                            push (@firsts, $e[0]);
                        }

#    post_second : 'SECOND' context
#            { $return = $item[-1]; }
                        while ($str =~ m/\GSECOND\s+/ogc)
                        {
                            my (@e) = parse_enum(\$str, $res);
                            push (@seconds, $e[0]);
                        }

#    post_adj : num num 'BY' pos(s)
#            { $return = [$item[1], $item[2], $item[4]]; }
                        while ($str =~ m/\G(\d+)\s+(\d+)\s+BY\s+/ogc)
                        {
                            my ($l, $r) = ($1, $2);
                            my ($pos, @poses);
                            while ($pos = parse_pos(\$str))
                            { push (@poses, $pos); }
                            push (@adjs, [$l, $r, [@poses]]);
                        }
                        push (@content, {'type' => 'ADJUST_PAIR',
                                'context1' => [@firsts],
                                'context2' => [@seconds],
                                'adj' => [@adjs]});
                        unless ($str =~ m/\GEND_ADJUST\s+/ogc)
                        { die "Expected END_ADJUST in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    }
#        | 'ADJUST_SINGLE' <commit> post_single(s) 'END_ADJUST'
#            { $return = {'type' => $item[1], 'context' => [map {$_->[0]} @{$item[3]}], 'adj' => [map {$_->[1]} @{$item[3]}]}; }
                    elsif ($str =~ m/\GADJUST_SINGLE\s+/ogc)
                    {
                        my (@contexts, @adjs, @e);

#    post_single : context 'BY' pos
#            { $return = [$item[1], $item[3]]; }
                        while (@e = parse_enum(\$str, $res))
                        {
                            my ($pos);

                            push (@contexts, $e[0]);
                            unless ($str =~ m/\GBY\s+/ogc)
                            { die "Expected BY in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                            if ($pos = parse_pos(\$str))
                            { push (@adjs, $pos); }
                            else
                            { die "Expected POS in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                        }
                        push (@content, {'type' => 'ADJUST_SINGLE', 'context' => [@contexts],
                                        'adj' => [@adjs]});
                        unless ($str =~ m/\GEND_ADJUST\s+/ogc)
                        { die "Expected END_ADJUST in LOOKUP $name, found: " . substr($str, pos($str), 20); }
                    }
                    else
                    { last; }
                }
                $res->{'lookups'}[-1]{'lookup'} = ['pos', [@content]];
                unless ($str =~ m/\GEND_POSITION\s+/ogc)
                { die "Expected END_POSITION in LOOKUP $name, found: " . substr($str, pos($str), 20); }
            }
        }
    }

#    anchor : 'DEF_ANCHOR' <commit> qid 'ON' num 'GLYPH' gid 'COMPONENT' num anchor_locked(?) 'AT' pos 'END_ANCHOR'
#            { $dat{'glyphs'}[$item[5]]{'anchors'}{$item[3]} = {'pos' => $item[-2], 'component' => $item[9], 'locked' => $item[10][0]}; 1; }
#    
#    anchor_locked : 'LOCKED'
    while ($str =~ m/\GDEF_ANCHOR\s+"([^"]+)"\s+ON\s+(\d+)\s+GLYPH\s+(?:(?:"([^"]+)")|(\S+))\s+COMPONENT\s+(\d+)\s+(?:(LOCKED)\s+)?AT\s+/ogc)
    {
        my ($name, $gnum, $gname, $comp, $locked) = ($1, $2, $3 || $4, $5, $6);
        my ($pos) = parse_pos(\$str);

        unless ($pos)
        { die "Expected POS in ANCHOR $name on $gname, found: " . substr($str, pos($str), 20); }
        unless ($str =~ m/\GEND_ANCHOR\s+/ogc)
        { die "Expected END_ANCHOR in ANCHOR $name on $gname, found: " . substr($str, pos($str), 20); }
        $res->{'glyphs'}[$gnum]{'anchors'}{$name} = {'pos' => $pos, 'component' => $comp, 'locked' => $locked};
    }

#    info : i_grid(?) i_pres(?) i_ppos(?) i_cmap(s?)
#            { $dat{'info'} = {
#                    grid => $item[1][0],
#                    present => $item[2][0],
#                    ppos => $item[3][0],
#                    cmap => $item[4] };
#            }
#    
#    i_grid : 'GRID_PPEM' num
#    
#    i_pres : 'PRESENTATION_PPEM' num
#    
#    i_ppos : 'PPOSITIONING_PPEM' num
#    
#    i_cmap : 'CMAP_FORMAT' num num num
#            { $return = [$item[2], $item[3], $item[4]]; }

    if ($str =~ m/\GGRID_PPEM\s+(\d+)\s+/ogc)
    { $res->{'info'}{'grid'} = $1; }

    if ($str =~ m/\GPRESENTATION_PPEM\s+(\d+)\s+/ogc)
    { $res->{'info'}{'present'} = $1; }

    if ($str =~ m/\GPPOSITIONING_PPEM\s+(\d+)\s+/ogc)
    { $res->{'info'}{'ppos'} = $1; }

    while ($str =~ m/\GCMAP_FORMAT\s+(\d+)\s+(\d+)\s+(\d+)\s+/ogc)
    { push (@{$res->{'info'}{'cmap'}}, [$1, $2, $3]); }

    unless ($str =~ m/\GEND/ogcs)
    { die "Unable to parse: " . substr($str, pos($str), 20); }

    return $res;
}

sub parse_enum
{
    my ($str, $dat) = @_;
    my (@res);

#    context : 'GLYPH' <commit> gid   { $return = [$item[1], $item[3]]; }
#             | 'GROUP' <commit> qid  { $return = [$item[1], $item[3]]; }
#             | 'RANGE' <commit> gid 'TO' gid   { $return = [$item[1], $item[3], $item[5]]; }
#             | enum                 { $return = ['ENUM', @{$item[1]}]; }
    while (1)
    {
        if ($$str =~ m/\GGLYPH\s+(?:"([^"]+)"|(\S+))\s+/ogc)
        { push (@res, ['GLYPH', $dat->{'glyph_names'}{$1 || $2}]); }
        elsif ($$str =~ m/\GGROUP\s+"([^"]+)"\s+/ogc )
        { push (@res, ['GROUP', $1]); }
        elsif ($$str =~ m/\GRANGE\s+(?:"([^"]+)"|(\S+))\s+TO\s+(?:"([^"]+)"|(\S+))\s+/ogc)
        { push (@res, ['RANGE', $dat->{'glyph_names'}{$1 || $2}, $dat->{'glyph_names'}{$3 || $4}]); }
        elsif ($$str =~ m/\GENUM\s+/ogc)
        {
            push (@res, ['ENUM', [parse_enum($$str, $dat)]]);
            unless ($$str =~ m/\GEND_ENUM\s+/ogc)
            { die "Expected END_ENUM, found: " . substr($$str, pos($$str), 20); }
        }
        else
        { last; }
    }
    @res;
}

sub parse_pos
{
    my ($str) = @_;
    my ($res) = {};

#    pos : 'POS' pos_adv(?) pos_dx(?) pos_dy(?) 'END_POS'
#            { $return = {
#                    'adv' => $item[2][0],
#                    'x' => $item[3][0],
#                    'y' => $item[4][0] }; }
#

    return undef unless ($$str =~ m/\GPOS\s+/ogc);

#    pos_adv : 'ADV' <commit> num pos_adj(s?)
#            { $return = [$item[3], $item[4]]; }
    if ($$str =~ m/\GADV\s+(-?\d+)\s+/ogc)
    {
        my ($val) = $1;
        my (@adjs) = parse_adjs($str);
        $res->{'adv'} = [$val, [@adjs]];
    }

#    pos_dx : 'DX' <commit> num pos_adj(s?)
#            { $return = [$item[3], $item[4]]; }
    if ($$str =~ m/\GDX\s+(-?\d+)\s+/ogc)
    {
        my ($val) = $1;
        my (@adjs) = parse_adjs($str);
        $res->{'x'} = [$val, [@adjs]];
    }

#    pos_dy : 'DY' <commit> num pos_adj(s?)
#            { $return = [$item[3], $item[4]]; }
    if ($$str =~ m/\GDY\s+(-?\d+)\s+/ogc)
    {
        my ($val) = $1;
        my (@adjs) = parse_adjs($str);
        $res->{'y'} = [$val, [@adjs]];
    }

    unless ($$str =~ m/\GEND_POS\s+/ogc)
    { return warn "Expected END_POS\n"; }

    return $res;
}

sub parse_adjs
{
    my ($str) = @_;
    my (@res);

#    pos_adj : 'ADJUST_BY' <commit> num 'AT' num
#            { $return = [$item[3], $item[5]]; }

    while ($$str =~ m/\GADJUST_BY\s+(-?\d+)\s+AT\s+(\d+)\s+/ogc)
    { push (@res, [$1, $2]); }
    return @res;
}

sub align_glyphs
{
    my ($self, $data) = @_;
    my (@map, @revmap, @old, @new, @diff, $s, $g, $u);

    @new = map {$_->{'name'}} @{$self->{'glyphs'}};
    @old = map {$_->{'name'}} @{$data->{'glyphs'}};
    @diff = sdiff(\@old, \@new);

# first find solid alignments
    foreach $s (@diff)
    {
        if ($s->[0] eq 'u')
        {
            $map[$data->{'glyph_names'}{$s->[1]}] = $self->{'glyph_names'}{$s->[2]};
            $revmap[$self->{'glyph_names'}{$s->[2]}] = $data->{'glyph_names'}{$s->[1]};
        }
    }

# now deal with the rest
    foreach $s (@diff)
    {
        if ($s->[0] eq '-' || $s->[0] eq 'c')
        {
            my ($gnum) = $data->{'glyph_names'}{$s->[1]};
            my ($uni) = $data->{'glyphs'}[$gnum]{'uni'};
            my ($gnew);
    # anything with the same name not already used?
            if ($g = $self->{'glyph_names'}{$s->[1]} and !defined $revmap[$g])
            {
                $map[$gnum] = $g;
                $revmap[$g] = $gnum;
            }
    # anything spare with the same unicode (any unicode the same)?
            else
            {
                foreach $u (@{$uni})
                {
                    foreach $g (@{$self->{'glyphs'}})
                    {
                        if (ref $g->{'uni'} && grep {$_ == $u} @{$g->{'uni'}} && !defined $revmap[$g->{'gnum'}])
                        {
                            $gnew = $g->{'gnum'};
                            last;
                        }
                    }
                    if ($gnew)
                    {
                        $map[$gnum] = $gnew;
                        $revmap[$gnew] = $gnum;
                    }
                }
            }
    # make it a deletion (i.e. in old but not in new)
        }
        elsif ($s->[0] eq '+')
        {
            # nothing to do since only really interested in old->new mapping
        }
    }

# deal with unaligned conflicts and simply align them
    foreach $s (@diff)
    {
        if ($s->[0] eq 'c')
        {
            my ($gnum) = $data->{'glyph_names'}{$s->[1]};
            my ($nnum) = $self->{'glyph_names'}{$s->[2]};
            next if ($map[$gnum] || $revmap[$nnum]);
            $map[$gnum] = $nnum;
            $revmap[$nnum] = $gnum;
        }
    }
    return (@map);
}

sub merge_volt
{
    my ($self, $data, $map) = @_;
    my ($g, $k);

    $self->{'map'} = $map;
    foreach (qw(groups lookups scripts info))
    { $self->{$_} = $data->{$_}; }

    foreach $g (@{$data->{'glyphs'}})
    {
        my ($n) = $self->{'glyphs'}[$map->[$g->{'gnum'}]];
        next unless defined $n;

        $n->{'component_num'} ||= $g->{'component_num'};
        $n->{'type'} ||= $g->{'type'};

        foreach $k (keys %{$g->{'anchors'}})
        {
            my ($p) = $g->{'anchors'}{$k};
            my ($np) = $n->{'anchors'}{$k};

            if (defined $np)
            {
                $np->{'component'} ||= $p->{'component'};
                $np->{'locked'} ||= $p->{'locked'};
                $np->{'pos'} ||= $p->{'pos'};
                if ($np->{'pos'})
                {
                    $np->{'pos'}{'x'} = $np->{'x'};
                    $np->{'pos'}{'y'} = $np->{'y'};
                }
            }
            else
            { $n->{'anchors'}{$k} = $p; }
        }
    }

    foreach $g (values %{$data->{'groups'}})
    { map_enum($map, @{$g}); }

    foreach $g (@{$data->{'lookups'}})
    {
        my ($c);

        foreach $c (@{$g->{'contexts'}})
        {
            foreach (@{$c})
            { map_enum($map, $_->[1]); }
        }
        if ($g->{'lookup'}[0] eq 'sub')
        {
            foreach $c (@{$g->{'lookup'}[1]})
            {
                map_enum($map, @{$c->[0]});
                map_enum($map, @{$c->[1]});
            }
        }
        else
        {
            foreach $c (@{$g->{'lookup'}[1]})
            {
                foreach (qw(context context1 context2 enters exits))
                { map_enum($map, @{$c->{$_}}) if (defined $c->{$_}); }
            }
        }
    }
        
    $self;
}

sub map_enum
{
    my ($map) = shift;
    my ($c);

    foreach $c (@_)
    {
        if (ref $c->[0])
        { map_enum($map, @{$c}); }
        if ($c->[0] eq 'GLYPH')
        { $c->[1] = $map->[$c->[1]]; }
        elsif ($c->[0] eq 'RANGE')      # yukky we'll do it simply - don't use ranges
        {
            $c->[1] = $map->[$c->[1]];
            $c->[2] = $map->[$c->[2]];
        }
        elsif ($c->[0] eq 'ENUM')
        { map_enum($map, @{$c->[1]}); }
    }
}

sub make_lookups
{
    my ($self, $ligtype, $opts) = @_;
    my ($c);

    foreach $c (sort keys %{$self->{'classes'}})
    {
        next if ($c =~ m/^no_/o);
        if ($opts->{'-force'})
        { $self->{'lookups'} = [grep {$_->{'id'} ne $c} @{$self->{'lookups'}}]; }
        else
        { next if (grep {$_->{'id'} eq $c} @{$self->{'lookups'}}); }

        my ($l) = {'id' => $c, 'base' => 'PROCESS_BASE', 'marks' => 'PROCESS_MARKS',
                     'all' => 'ALL', 'dir' => 'LTR', 'contexts' => [],
                      'lookup' => ['sub', [[[['GROUP', "cno_$c"]], [['GROUP', "c$c"]]]]]};
        unshift(@{$self->{'lookups'}}, $l);

#        $res .= "DEF_LOOKUP \"$c\" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR\n";
#        $res .= "IN_CONTEXT\nEND_CONTEXT\nAS_SUBSTITUTION\n";

#        $res .= "SUB GROUP \"cno_$c\"\n";
#        $res .= "WITH GROUP \"c$c\"\n";
#        $res .= "END_SUB\n";
#        $res .= "END_SUBSTITUTION\n";
    }

    foreach $c (sort keys %{$self->{'ligclasses'}})
    {
        next if ($c =~ m/^no_/o);
        if ($opts->{'-force'})
        { $self->{'lookups'} = [grep {$_->{'id'} ne "l$c"} @{$self->{'lookups'}}]; }
        else
        { next if (grep {$_->{'id'} eq "l$c"} @{$self->{'lookups'}}); }

        my ($bnum) = $self->{'ligmap'}{$c};

        my ($l) = {'id' => "l$c", 'base' => 'PROCESS_BASE', 'marks' => 'PROCESS_MARKS',
                     'all' => 'ALL', 'dir' => 'LTR', 'contexts' => []};

#        $res .= "DEF_LOOKUP \"l$c\" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR\n";
#        $res .= "IN_CONTEXT\nEND_CONTEXT\nAS_SUBSTITUTION\n";
        if ($ligtype eq 'first')
        { $l->{'lookup'} = ['sub', [[[['GLYPH', $bnum], ['GROUP', "clno_$c"]], [['GROUP', "cl$c"]]]]]; }
#        { $res .= "SUB GLYPH \"$glyphs->[$bnum]{'name'}\" GROUP \"no_$c\"\n"; }
        else
        { $l->{'lookup'} = ['sub', [[[['GROUP', "clno_$c"], ['GLYPH', $bnum]], [['GROUP', "cl$c"]]]]]; }
#        { $res .= "SUB GROUP \"clno_$c\" GLYPH \"$glyphs->[$bnum]{'name'}\"\n"; }
#        $res .= "WITH GROUP \"cl$c\"\n";
#        $res .= "END_SUB\n";
#        $res .= "END_SUBSTITUTION\n";
        unshift(@{$self->{'lookups'}}, $l);
    }

    foreach $c (sort keys %{$self->{'lists'}})
    {
#        print STDERR "$c: ";
        next if ($c =~ m/^_/o);
        next unless (defined $self->{'lists'}{"_$c"});
        if ($opts->{'-force'})
        { $self->{'lookups'} = [grep {$_->{'id'} ne "base_$c"} @{$self->{'lookups'}}]; }
        else
        { next if (grep {$_->{'id'} eq "base_$c"} @{$self->{'lookups'}}); }
        next if (defined $opts->{'-notmark'} && $opts->{'-notmark'} =~ m/\b_$c\b/);

        my ($l) = {'id' => "base_$c", 'base' => 'PROCESS_BASE', 'marks' => 'PROCESS_MARKS',
                     'all' => 'ALL', 'dir' => 'LTR', 'contexts' => [],
                      'lookup' => ['pos', [{'type' => 'ATTACH', 'context' => [['GROUP', "cTakes${c}Dia"]],
                                'to' => [[['GROUP', "c${c}Dia"], $c]]}]]};
        push(@{$self->{'lookups'}}, $l);
#        print STDERR join(",", map {$_->{'id'}} @{$self->{'lookups'}}) . "\n";

#        $res .= "DEF_LOOKUP \"base_$c\" PROCESS_BASE PROCESS_MARKS ALL DIRECTION LTR\n";
#        $res .= "IN_CONTEXT\nEND_CONTEXT\nAS_POSITION\n";
#        $res .= "ATTACH GROUP \"cTakes${c}Dia\"\n";
#        $res .= "TO GROUP \"c${c}Dia\" AT ANCHOR \"$c\"\n";
#        $res .= "END_ATTACH\nEND_POSITION\n";
    }
}

sub make_groups
{
    my ($self) = @_;
    my ($lists) = $self->{'lists'};
    my ($classes) = $self->{'classes'};
    my ($ligclasses) = $self->{'ligclasses'};
    my ($l);
    
    foreach $l (sort keys %{$lists})
    {
        my ($name) = $l;

        if ($name !~ m/^_(.*)$/o)
        { $name = "Takes$name"; }
        else
        { $name =~ s/^_//o; }
        $self->{'groups'}{"c${name}Dia"} = [map {['GLYPH', $_]} @{$lists->{$l}}];
    }
    

    foreach $l (sort keys %{$classes})
    {
        $self->{'groups'}{"c$l"} = [map {['GLYPH', $_]} @{$classes->{$l}}];
    }

    foreach $l (sort keys %{$ligclasses})
    {
        $self->{'groups'}{"cl$l"} = [map {['GLYPH', $_]} @{$ligclasses->{$l}}];
    }
}

sub make_anchors
{
    my ($self) = @_;
    my ($g, $p, $k);

    foreach $g (@{$self->{'glyphs'}})
    {
        if (defined $g->{'points'})
        {
            foreach $p (keys %{$g->{'points'}})
            {
                $k = ($p =~ m/^_/o) ? "MARK$p" : $p;
                $g->{'anchors'}{$k}{'pos'}{'x'}[0] = $g->{'points'}{$p}{'x'};
                $g->{'anchors'}{$k}{'pos'}{'y'}[0] = $g->{'points'}{$p}{'y'};
            }
        }
    }
}

1;

