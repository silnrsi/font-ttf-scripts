package Font::Scripts::AP;

=head1 NAME

Font::Scripts::AP - Memory representation of a L<TTFBuilder|bin::TTFBuilder> Attachment Point database (APDB)

=head1 SYNOPSIS

 use Font::Scripts::AP;
 $ap = Font::Scripts::AP->read_font($ttf_file, $ap_file, %opts);
 $ap->make_classes();

=head1 INSTANCE VARIABLES

=over 4

=item cmap

Reference to the Microsoft L<cmap|Font::TTF::cmap> within the C<font>.

=item font

Referenc to a L<font|Font::TTF::Font> structure. C<read_font> will cause at least 
the L<post|Font::TTF::Post>, L<cmap|Font::TTF::Cmap>, L<loca|Font::TTF::Loca>, and 
L<name|Font::TTF::Name> tables to be read in.


=item glyphs

An array of references to glyph data structures, indexed by glyphID. Stucture elements are:

=over 4

=item uni

Unicode scalar value, if any, as specified in the APDB. (decimal integer)

=item gnum

Actual glyph ID from font. 

=item post

Actual Postscript name from font.

=back

Note: The C<uni>, C<gnum> and C<post> values are based on the C<UID>, C<GID>, and C<PSName> fields
of the APDB. If there are descrepancies between the APDB and the font's internal tables, then 
for calcuating the above three values, priority is given first to C<UID> field, then C<PSName> field, and finally C<GID>. 

=over 4

=item glyph

Reference to L<glyph|Font::TTF::Glyph> structure read from C<font>.

=item line

Line number in APDB where glyph is defined.

=item points

A hash of references to attachment point structures for this glyph, 
keyed by attachment point type (aka name). 
Each AP structure contains

=over 4

=item name

The name (C<type> in TTFBuilder terminology) of the attachment point

=item x, y

X and Y coordinates for the attachment point

=item line

Line number in APDB where this point is defined.

=back

=item components

Present if the glyph is a composite. Is a reference to an array of component structures.
Each component structure includes:

=over 4

=item bbox

comma separated list of bounding box coordinates, i.e., C<x1, y1, x2, y2>

=item uni

Unicode scalar value, if any, of the component. (decimal integer)

=back

=back

Note: The following instance variables contain the actual text read from the
APDB. If there are descrepancies between the APDB and the font, these values
may differ from corresponding values given above. Therefore these values should
B<not> be used except for diagnostic purposes.

=over 4

=item UID

Unicode scalar value, if any, as specified in the APDB. (string of hex digits)

=item PSName

Postscript name, if any, as specified in the APDB

=item GID

Glyph id, if any, as specified in the APDB

=back

=item classes

Created by L</"make_classes">, this is a
hash keyed by class name returning an array of GIDs for glyphs that are in the class. Classes
are identified by extensions (part after a '.') on the post name of each glyph. For each 
such extension, two classes are defined. The first is the class of all glyphs that have that 
extension (class name is the extension). The second is the class of nominal glyphs 
corresponding to the glyphs with that extension (class name is the extension but with the prefix
'no_').

=item lists

Created by L</"make_classes">, this is a
hash keyed by attachmentpoint name (as modified by L</"make_point">) 
returning an array of GIDs for glyphs that have the given attachment point.

=item vecs

If defined, this variable will be updated by L</"make_classes">. It is a 
hash, keyed by attachmentpoint name (as modified by L</"make_point">) 
returning a bit L<vec> bit array, indexed by GID, 
each bit set to 1 if the corresponding glyph has the given attachment point.

=item WARNINGS

If C<-errorfh> not set, this accumulates any warning or error messages encountered.

=item cWARNINGS

Count of number fo warnings or errors encountered.

=back

=head1 METHODS

=cut

use Font::TTF::Font;
use XML::Parser::Expat;

use strict;
use vars qw($VERSION);

$VERSION = "0.04";	# BH   in progress
# Merged my AP.pm with MH's version:
#	Rename _error() to error()
#	Added -errorfh support
#	Removed 'gunis' and 'gnames' (similar functions available from the font)
#	Added make_classes method

#$VERSION = "0.03";	# BH   2004-02-02
#	Fix to process AP data even when there is no glyph outline (e.g., on space)

#$VERSION = "0.02";	# BH   2003-09-22	Added 'components' array
					#					No longer ignores blank glyphs (those with no outline)
#$VERSION = "0.01"; # BH   2003-01-06   Original extracted from GDL.PM
					#					New functionality: support for -omittedAPs option giving a comma-separated
					#					list of attachment points to be ignored.


=head2 $ap = Font::Scripts::AP->read_font ($ttf_file, $ap_file, %opts)

Reads the TrueType font file C<$ttf_file> and the attachment point database (APDB) file
C<$ap_file>, and builds a structure to represent the APDB.

Options that may be supplied throught the C<%opts> hash include:

=over 4

=item -omittedAPs

A comma-separated list of attachment point types to ignore.

=item -strictap

If true, warn about attachment points that do not correspond to appropriate
points on the outline of the glyph.

=item -knownemptyglyphs

A comma-separated list of names of glyphs that are known to have no outline 
(thus shouldn't generate warning).

=item -errorfh

A file handle to which warning messages are to be printed. If not supplied,
warning messages are accumulated in C<WARNINGS>.

=back

=cut

sub read_font
{
    my ($class, $fname, $xml_file, %opts) = @_;
    my (@glyphs, $f, $t, $xml, $cur_glyph, $cur_pt);
    my ($self) = {};
    bless $self, ref $class || $class;

    my (%omittedAPs, %known_empty_glyphs);
    map {$omittedAPs{$_} = $omittedAPs{"_$_"} = 1} split (',', $opts{'-omittedAPs'});
    map {$known_empty_glyphs{$_} = 1} split (',', $opts{'-knownemptyglyphs'});
    
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
            my ($ug, $pg, $ig);
            $cur_glyph = {%attrs};
            undef $cur_pt;
    
            if (defined $attrs{'UID'})
            {
                my ($uni) = hex($attrs{'UID'});
                $ug = $self->{'cmap'}{$uni};
                $self->error($xml, $cur_glyph, undef, "No glyph associated with UID $attrs{'UID'}") unless (defined $ug);
                $cur_glyph->{'gnum'} = $ug;
                $cur_glyph->{'uni'} = $uni;
                # delete $attrs{'UID'};  # Added in MH's version; v0.04: now believed un-needed and un-wanted.
            }
            if (defined $attrs{'PSName'})
            {
                $pg = $f->{'post'}{'STRINGS'}{$attrs{'PSName'}};
                $self->error($xml, $cur_glyph, undef, "No glyph associated with postscript name $attrs{'PSName'}") unless (defined $pg);
                $self->error($xml, $cur_glyph, undef, "Postscript name: $attrs{'PSName'} resolves to different glyph to Unicode ID: $attrs{'UID'}")
                        if (defined $attrs{'UID'} && $pg != $ug);
                $cur_glyph->{'gnum'} ||= $pg;
                # delete $attrs{'PSName'};  # Added in MH's version; v0.04: now believed un-needed and un-wanted.
            }
            if (defined $attrs{'GID'})
            {
                $ig = $attrs{'GID'};
                $self->error($xml, $cur_glyph, undef, "Specified glyph id $attrs{'GID'} different to glyph of Unicode ID: $attrs{'UID'}")
                        if (defined $attrs{'UID'} && $ug != $ig);
                $self->error($xml, $cur_glyph, undef, "Specified glyph id $attrs{'GID'} different to glyph of postscript name $attrs{'PSName'}")
                        if (defined $attrs{'PSName'} && $pg != $ig);
                $cur_glyph->{'gnum'} ||= $ig;
                # delete $attrs{'GID'}; # Added in MH's version; v0.04: now believed un-needed and un-wanted.
            }
            $cur_glyph->{'post'} = $f->{'post'}{'VAL'}[$cur_glyph->{'gnum'}];

            if ($cur_glyph->{'glyph'} = $f->{'loca'}{'glyphs'}[$cur_glyph->{'gnum'}])
            {
	            # v0.04: Slight difference in this code and MH's: this code causes
	            # $cur_glyph->{'glyph'} to be defined for all glyphs; in MH's code
	            # it was defined only for non-empty glyphs.
	            $cur_glyph->{'glyph'}->read_dat;
	            if ($cur_glyph->{'glyph'}{'numberOfContours'} > 0)
	            { $cur_glyph->{'props'}{'drawn'} = 1; }
	            $cur_glyph->{'glyph'}->get_points;
            }
            else
            {
                $self->error($xml, $cur_glyph, undef, "No glyph outline in font") unless $known_empty_glyphs{$cur_glyph->{'post'}};
            }

	        # MH's code includes the following two lines, but these are redundant with 
	        # assignment $cur_glyph = {%attrs} at start of this block
	        #foreach (keys %attrs)
            #{ $cur_glyph->{$_} = $attrs{$_}; }

            $cur_glyph->{'line'} = $xml->current_line;
            $self->{'glyphs'}[$cur_glyph->{'gnum'}] = $cur_glyph;
   
        } elsif ($tag eq 'compound')
        {
        	my $component = {%attrs};
    	    $component->{'uni'} = hex($attrs{'UID'}) if defined $attrs{'UID'};
        	push @{$cur_glyph->{'components'}}, $component;
        } elsif ($tag eq 'point')
        {
            if ($omittedAPs{$attrs{'type'}})
            {  undef $cur_pt; }
            else
            {
                $cur_pt = {'name' => $attrs{'type'}, line => $xml->current_line};
                $cur_glyph->{'points'}{$attrs{'type'}} = $cur_pt;
            }
        } elsif ($tag eq 'contour' && defined $cur_pt)
        {
            my ($cont) = $attrs{'num'};
            my ($g) = $cur_glyph->{'glyph'} || return;
            
            $self->error($xml, $cur_glyph, $cur_pt, "Specified contour of $cont different from calculated contour of $cur_pt->{'cont'}")
                    if (defined $cur_pt->{'cont'} && $cur_pt->{'cont'} != $attrs{'num'});
                 
            if (($cont == 0 && $g->{'endPoints'}[0] != 0)
                || ($cont > 0 && $g->{'endPoints'}[$cont-1] + 1 != $g->{'endPoints'}[$cont]))
            { $self->error($xml, $cur_glyph, $cur_pt, "Contour $cont not a single point path"); }
            else
            { $cur_pt->{'cont'} = $cont; }
            
            $cur_pt->{'x'} = $g->{'x'}[$g->{'endPoints'}[$cont]];
            $cur_pt->{'y'} = $g->{'y'}[$g->{'endPoints'}[$cont]];
        } elsif ($tag eq 'location' && defined $cur_pt)
        {
            my ($x) = $attrs{'x'};
            my ($y) = $attrs{'y'};
            my ($g) = $cur_glyph->{'glyph'};
            my ($cont, $i);
    
            $self->error($xml, $cur_glyph, $cur_pt, "Specified location of ($x, $y) different from calculated location ($cur_pt->{'x'}, $cur_pt->{'y'})")
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
	            { $self->error($xml, $cur_glyph, $cur_pt, "No glyph point at specified location ($x, $y)") if ($opts{'-strictap'}); }
	            if (($cont == 0 && $g->{'endPoints'}[0] != 0)
	                || $g->{'endPoints'}[$cont-1] + 1 != $g->{'endPoints'}[$cont])
	            { $self->error($xml, $cur_glyph, $cur_pt, "Calculated contour $cont not a single point path") if ($opts{'-strictap'}); }
	            else
	            { $cur_pt->{'cont'} = $cont; }
	        }
	        else
	        { $self->error($xml, $cur_glyph, $cur_pt, "No glyph point at specified location ($x, $y)") if ($opts{'-strictap'}); }
	    
            $cur_pt->{'x'} = $x unless defined $cur_pt->{'x'};
            $cur_pt->{'y'} = $y unless defined $cur_pt->{'y'};
        } elsif ($tag eq 'property')
        {
            $cur_glyph->{'props'}{$attrs{'name'}} = $attrs{'value'};
        }
    });

    $xml->parsefile($xml_file) || return warn "Can't open $xml_file";

    # Make sure to destroy the parser properly -- Otherwise Perl can generate 
    # exception violations during cleanup!
	$xml->release;
    undef $xml;
    
    $self;
}

=head2 $ap->make_classes ()

First, for every glyph record in C<glyphs>, C<make_classes> invokes C<make_name>  
followed by, for every attachment point record in C<points>, C<make_point> . This 
gives sub-classes a chance to convert the names (of glyphs and points) to an alternate form 
(e.g., as might be useful in building Graphite source.) See L<GDL.pm|Font::Scripts::GDL> for
an example.

C<make_classes> then builds the C<classes> and C<lists> instance variables, and
updates the C<vecs> instance variable (if it is defined).

=cut

sub make_classes
{
    my ($self) = @_;
    my ($f) = $self->{'font'};
    my (%classes);
    my ($g, $gname, $i, $glyph, %used, $p);
    
    for ($i = 0; $i < $f->{'maxp'}{'numGlyphs'}; $i++)
    {
        $glyph = $self->{'glyphs'}[$i];
        $gname = $self->make_name($glyph->{'post'}, $glyph->{'uni'}, $glyph);

        if (defined $used{$gname})
        { $gname .= "_1"; }
        $gname++ while (defined $used{$gname});
        $used{$gname}++;
        $glyph->{'name'} = $gname;

        
        foreach $p (keys %{$glyph->{'points'}})
        {
            my ($pname) = $self->make_point($p, $glyph);
            next unless ($pname);                           # allow for point deletion, in effect.
            if ($p ne $pname)
            {
                $glyph->{'points'}{$pname} = $glyph->{'points'}{$p};
                delete $glyph->{'points'}{$p};
            }
            push (@{$self->{'lists'}{$pname}}, $i);
            vec($self->{'vecs'}{$pname}, $i, 1) = 1 if ($self->{'vecs'});
        }
    }
    
    # need a separate loop since using other glyphs' names
    foreach $glyph (@{$self->{'glyphs'}})
    {
        if ($glyph->{'post'} =~ m/\.([^_.]+)$/o)
        {
            my ($base, $ext) = ($` , $1);
            next unless ($i = $f->{'post'}{'STRINGS'}{$base});
            push (@{$classes{$ext}}, $glyph->{'gnum'});
            push (@{$classes{"no_$ext"}}, $self->{'glyphs'}[$i]{'gnum'});
        }
    }
    $self->{'classes'} = \%classes;
}

=head2 $ap->make_name ($gname, $uni, $glyph)

Given a glyph's name, USV, and a reference to its C<glyph> structure, returns
a replacement name, e.g., one that might be an acceptable identifier in
a programming language. By default this returns $gname, but the function 
could be overridden when subclassing.

=cut

sub make_name
{
    my ($self, $gname, $uni, $glyph) = @_;
    $gname;
}

=head2 $ap->make_point ($pname, $glyph)

Given an an attachment point name and a reference to its C<glyph> structure, returns
a replacement name, e.g., one that might be an acceptable identifier in
a programming language, or undef to indicate the attachment point should be omitted.
By default this returns $pname, but the function could be overridden when subclassing.

=cut

sub make_point
{
    my ($self, $p, $glyph) = @_;
    $p;
}

# Private routine:

sub error
{
    my $self = shift;
    my ($xml, $cur_glyph, $cur_pt, $str) = @_;
    
    my $msg;

    if (defined $cur_glyph->{'UID'})
    { $msg = "U+$cur_glyph->{'UID'}: "; }
    elsif (defined $cur_glyph->{'PSName'})
    { $msg =  "$cur_glyph->{'PSName'}: "; }
    elsif (defined $cur_glyph->{'GID'})
    { $msg =  "$cur_glyph->{'GID'}: "; }
    else
    { $msg =  "Undefined: "; }

    $msg .=  $str;

    if (defined $cur_pt)
    { $msg .=  " in point $cur_pt->{'name'}"; }

    $msg .=  " at line " . $xml->current_line . ".\n";
    
	if (defined $self->{'-errorfh'})
	{	print {$self->{'-errorfh'}} $msg;	}
	else
	{   $self->{'WARNINGS'} .= $msg; }
	
    $self->{'cWARNINGS'}++;
}

=head1 See also

L<TTFBuilder|bin::TTFBuilder>, L<Font::TTF::Font>

=cut