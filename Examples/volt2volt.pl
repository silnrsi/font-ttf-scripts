#! /usr/bin/perl
use Font::TTF::Font;
use Getopt::Std;
use Parse::RecDescent;
use Data::Dumper;

%dat = ();

$volt_grammar = <<'EOG';

    { my (%dat, $c); }
    
    start : statement 'END'
            { $return = {%dat}; }
        | <error>
    
    statement : glyph(s?) script(s?) group(s?) lookup(s?) anchor(s?) info(?)

    glyph : 'DEF_GLYPH' <commit> qid 'ID' num glyph_unicode(?) glyph_type(?) glyph_component(?) 'END_GLYPH'
            { 
                $dat{'glyphs'}[$item[5]] = {'uni' => $item[6][0], 'type' => $item[7][0], 'name' => $item[3], 'components' => $item[8][0]};
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

    script : 'DEF_SCRIPT' <commit> name tag langsys(?) 'END_SCRIPT'
            { $dat{'scripts'}{$item[3]} = {'tag' => $item[4], 'lang' => $item[5][0]}; }

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

    post : 'ATTACH' <commit> context(s) 'TO' attach(s) 'END_ATTACH'
            { $return = {'type' => $item[1], 'context' => $item[3], 'to' => $item[5] }; }
        | 'ADJUST_PAIR' <commit> post_first(s) post_second(s) post_adj(s) 'END_ADJUST'
            { $return = {'type' => $item[1], 'context1' => $item[3], 'context2' => $item[4], 'adj' => $item[5]}; }
        | 'ADJUST_SINGLE' <commit> post_single(s) 'END_ADJUST'
            { $return = {'type' => $item[1], 'context' => $item[3]}; }

    attach : context 'AT' 'ANCHOR' qid
            { $return = [$item[1], $item[-1]]; }

    post_first : 'FIRST' context
            { $return = $item[-1]; }

    post_second : 'SECOND' context
            { $return = $item[-1]; }

    post_adj : num num 'BY' pos(s)
            { $return = [$item[1], $item[2], $item[4]]; }

    post_single : context 'BY' pos
            { $return = [$item[1], $item[3]]; }

    anchor : 'DEF_ANCHOR' qid 'ON' num 'GLYPH' gid 'COMPONENT' num anchor_locked(?) 'AT' pos 'END_ANCHOR'
            { $dat{'glyphs'}[$item[4]]{'points'}{$item[2]} = [$item[-2], $item[6], $item[8], $item[9][0]]; 1; }
    
    anchor_locked : 'LOCKED'

    pos : 'POS' pos_adv(?) pos_dx(?) pos_dy(?) 'END_POS'
            { $return = {
                    'adv' => $item[2][0],
                    'x' => $item[3][0],
                    'y' => $item[4][0] }; }
    
    pos_dx : 'DX' num pos_adj(s?)
            { $return = [$item[2], $item[3]]; }
    
    pos_dy : 'DY' num pos_adj(s?)
            { $return = [$item[2], $item[3]]; }
    
    pos_adv : 'ADV' num pos_adj(s?)
            { $return = [$item[2], $item[3]]; }

    pos_adj : 'ADJUST_BY' num 'AT' num
            { $return = [$item[2], $item[4]]; }

    lk_procbase : 'PROCESS_BASE'

    lk_procmarks : /PROCESS_MARKS|SKIP_MARKS/

    lk_all : qid | 'ALL'
            { $return = $item[1] || $item[2]; }

    lk_direction : 'DIRECTION' /LTR|RTL/            # what about RTL here?
            { $return = "$item[1] $item[2]"; }

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
                  
    uni_list : /[0-9a-fA-F,U+\s]+/i
        { $return = $item[1]; }
    
    qid : '"' <commit> <skip:''> id_letters '"'
        { $return = $item[4]; }
    
    gid : '"' <commit> <skip:''> id_letters '"'
        { $return = $dat{'glyph_names'}{$item[4]}; }
        | /\S+/
        { $return = $dat{'glyph_names'}{$item[1]}; }
        
    
    id_letters : /[^"]+/i
        { $return = $item[1]; }
    
    word : /[\w._]+/
        { $return = $item[1]; }
    
    num : /-?\d+/
        { $return = $item[1]; }
EOG

getopts('z:i:');

if ($opt_i)
{
    open(INFILE, "< $opt_i") || die "Can't open $opt_i";
    $text = join('', <INFILE>);
}
else
{
    $font = Font::TTF::Font->open($ARGV[0]) || die "Can't open font file $ARGV[0]";
    $text = $font->{'TSIV'}->read->{' dat'} || die "No VOLT table in font $ARGV[0]";
    $name = $font->{'name'}->read->find_name(2);
    $upem = $font->{'head'}{'unitsPerEm'};
    $font->{'post'}->read;
}

$::RD_TRACE = 20 if (($opt_z & 1) != 0);
$parser = new Parse::RecDescent ($volt_grammar);
$data = $parser->start($text);

$res = glyphs($data);
$res .= scripts($data);
$res .= groups($data);
$res .= lookups($data);
$res .= anchors($data);
$res .= info($data);
$res .= "END\n";

print $res;

sub glyphs
{
    my ($data) = @_;
    my ($i, $g, $res);

    for ($i = 0; $i < scalar @{$data->{'glyphs'}}; $i++)
    {
        $g = $data->{'glyphs'}[$i];
        next unless $g;
        $res .= "DEF_GLYPH \"$g->{'name'}\" ID $i ";
        if (ref $g->{'uni'} && scalar @{$g->{'uni'}} > 1)
        { $res .= "UNICODEVALUES \"" . join(",", map {sprintf("U+%04X", $_)} @{$g->{'uni'}}) . "\" "; }
        elsif (ref $g->{'uni'})
        { $res .= sprintf("UNICODE %d ", $g->{'uni'}[0]); }

        if ($g->{'type'})
        { $res .= "TYPE $g->{'type'} "; }
        if ($g->{'components'})
        { $res .= "COMPONENTS $g->{'components'} "; }
        $res .= "END_GLYPH\n";
    }
    $res;
}

sub scripts
{
    my ($data) = @_;
    my ($res, $lk, $s);

    foreach $s (sort keys %{$data->{'scripts'}})
    {
        my ($t) = $data->{'scripts'}{$s};
        my ($l) = $t->{'lang'};
        $res .= "DEF_SCRIPT NAME \"$s\" TAG \"$t->{'tag'}\"\n";
        next unless $l;

        $res .= "DEF_LANGSYS NAME \"$l->{'name'}\" TAG \"$l->{'tag'}\"\n";
        foreach $f (sort grep {$_ ne 'name' && $_ ne 'tag'} keys %{$l})
        {
            $res .= "DEF_FEATURE NAME \"$f\" TAG \"$l->{$f}{'tag'}\"\n";
            foreach $lk (@{$l->{$f}{'lookups'}})
            { $res .= " LOOKUP \"$lk\""; }
            $res .= "\nEND_FEATURE\n";
        }
        $res .= "END_LANGSYS\n";
        $res .= "END_SCRIPT\n";
    }
    $res;
}

sub groups
{
    my ($data) = @_;
    my ($res, $g, $e);

    foreach $g (sort keys %{$data->{'groups'}})
    {
        $res .= "DEF_GROUP \"$g\"\n ENUM";
        foreach $e (@{$data->{'groups'}{$g}})
        { $res .= " " . context($e, $data); }
        $res .= " END_ENUM\nEND_GROUP\n";
    }
    $res;
}

sub lookups
{
    my ($data) = @_;
    my ($res, $q, $c, $s);

    foreach $l (@{$data->{'lookups'}})
    {
        $res .= "DEF_LOOKUP \"$l->{'id'}\"";
        foreach $q (qw(base marks all dir))
        {
            if ($q eq 'all' && $l->{$q} && $l->{$q} ne 'ALL')
            { $res .= " \"$l->{$q}\""; }
            else
            { $res .= " $l->{$q}" if ($l->{$q}); }
        }
        $res .= "\n";
        foreach $q (@{$l->{'contexts'}})
        {
            $res .= "IN_CONTEXT";
            foreach $c (@{$q})
            {
                $res .= "\n $c->[0]";
                foreach $t (@{$c}[1..$#{$c}])
                { $res .= " ". context($t, $data); }
            }
            $res .= "\nEND_CONTEXT\n";
        }
        if ($l->{'lookup'}[0] eq 'sub')
        {
            $res .= "AS_SUBSTITUTION\n";
            foreach $s (@{$l->{'lookup'}[1]})
            {
                $res .= "SUB";
                foreach $c (@{$s->[0]})
                { $res .= " " . context($c, $data); }
                if ($s->[1])
                {
                    $res .= "\nWITH";
                    foreach $c (@{$s->[1]})
                    { $res .= " " . context($c, $data); }
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
                    foreach $c (@{$s->{'context'}})
                    { $res .= " " . context($c, $data); }
                    $res .= "\nTO";
                    foreach $c (@{$s->{'to'}})
                    { $res .= " " . context($c->[0], $data) . " AT ANCHOR \"$c->[1]\""; }
                    $res .= "\nEND_ATTACH\n";
                }
                elsif ($s->{'type'} eq 'ADJUST_PAIR')
                {
                    $res .= "\n";
                    foreach $c (@{$s->{'context1'}})
                    { $res .= " FIRST  " . context($c, $data); }
                    $res .= "\n";
                    foreach $c (@{$s->{'context2'}})
                    { $res .= " SECOND  " . context($c, $data); }
                    $res .= "\n";
                    foreach $c (@{$s->{'adj'}})
                    {
                        my ($d);
                        $res .= " $c->[0] $c->[1] BY";
                        foreach $d (@{$c->[2]})
                        { $res .= " " . out_pos($d); }
                    }
                    $res .= "\nEND_ADJUST\n";
                }
                elsif ($s->{'type'} eq 'ADJUST_SINGLE')
                {
                    foreach $c (@{$s->{'context'}})
                    { $res .= " " . context($c->[0], $data) . " BY " . out_pos($c->[1]); }
                    $res .= "\nEND_ADJUST\n";
                }
            }
            $res .= "END_POSITION\n";
        }
#        $res .= "END_LOOKUP\n";
    }
    $res;
}

sub anchors
{
    my ($data) = @_;
    my ($res, $i, $k);

    for ($i = 0; $i < scalar @{$data->{'glyphs'}}; $i++)
    {
        foreach $k (sort keys %{$data->{'glyphs'}[$i]{'points'}})
        {
            my ($p) = $data->{'glyphs'}[$i]{'points'}{$k};
            if ($p->[3])
            { $res .= "DEF_ANCHOR \"$k\" ON $i GLYPH $data->{'glyphs'}[$p->[1]]{'name'} COMPONENT $p->[2] $p->[3] AT  " . out_pos($p->[0]) . " END_ANCHOR\n"; }
            else
            { $res .= "DEF_ANCHOR \"$k\" ON $i GLYPH $data->{'glyphs'}[$p->[1]]{'name'} COMPONENT $p->[2] AT  " . out_pos($p->[0]) . " END_ANCHOR\n"; }
        }
    }
    $res;
}

sub info
{
    my ($data) = @_;
    my ($res, $c);
    my (%labels) = ('grid' => 'GRID_PPEM', 'present' => 'PRESENTATION_PPEM', 'ppos' => 'PPOSITIONING_PPEM');

    foreach $c (qw(grid present ppos))
    {
        if ($data->{'info'}{$c})
        { $res .= "$labels{$c} $data->{'info'}{$c}\n"; }
    }
    foreach $c (@{$data->{'info'}{'cmap'}})
    {
        $res .= "CMAP_FORMAT $c->[0] $c->[1] $c->[2]\n";
    }
    $res;
}

sub context
{
    my ($cont, $dat) = @_;
    my ($res);

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

