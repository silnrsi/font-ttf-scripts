#! /usr/bin perl
use strict;
use Font::TTF::Font;
use Font::TTF::Scripts::Name;
use Getopt::Std;
use Pod::Usage;

our $CHAIN_CALL;
our %opts;
our $f;

unless($CHAIN_CALL)
{
    getopts('h', \%opts);

    pod2usage( -verbose => 2, -noperldoc => 1) if $opts{'h'};

    pod2usage(-verbose => 1) unless defined $ARGV[0];

    $f = Font::TTF::Font->open($ARGV[0]) || die "Can't open file $ARGV[0]";
}

my $name = $f->{'name'}->read;
my $family = $name->find_name(1);
my $subfamily = $name->find_name(2);
if ($subfamily =~ /^(regular|bold|italic|oblique|slant)/oi)
{
	# Do nothing but force all family and subfamily records to match (fixes problem with Glyphs-generated files)
}
elsif ($subfamily =~ /^(\S+)\s+(\S.*)$/)
{
	# Subfamly has more than one word -- append the first to the family
	$family .= " $1";
	$subfamily = $2;
}
else
{
	# Subfamily consists of only one word -- append it to the family and set subfamily to Regular
	$family .= " $subfamily";
	$subfamily = "Regular";
}

$name->set_name(1, $family);
$name->set_name(2, $subfamily);

# Construct appropriate postscript font name:
my $post = "$family-$subfamily";
$post =~ s/[\s\[\](){}<>\/%]//og;
# make sure only 2 such names are in the font:
$name->remove_name(6);
$name->set_name(6, $post, 'en', [1,0], [3,1]);

# Remove perfered family and subfamily strings as no longer needed:
$name->remove_name(16);
$name->remove_name(17);

# Mark name table dirty:
$name->dirty();

# Update macStyle in head table for new subfamily:
my $head = $f->{'head'}->read;
if ($subfamily =~ /bold/oi)
{
	# Set weight to bold:
	$head->{'macStyle'} |= 1;
}
else
{
	# Set weight to regular:
	$head->{'macStyle'} &= ~1;
}
# Mark head table dirty:
$head->dirty();

# Update OS/2 table if it exists
if (exists ($f->{'OS/2'}))
{
	my $os2 = $f->{'OS/2'}->read;
	if ($head->{'macStyle'} & 1)
	{
		$os2->{'usWeightClass'} = 700;
		$os2->{'bWeight'} = 8;
	}
	else
	{
		$os2->{'usWeightClass'} = 400;
		$os2->{'bWeight'} = 5;
	}
	# Mark OS/2 table dirty:
	$os2->dirty();
}

unless ($CHAIN_CALL)
{ $f->out($ARGV[1]) || die "Can't write to font file $ARGV[1]. Do you have it installed?"; }


__END__

=head1 NAME

ttffixweight -- normalizes members of irregularly named font families

=head1 SYNOPSIS

  ttffixweight infont outfont
  ttffixweight -h

Normalizes name, head, and OS/2 tables of irregularly named fonts.

Specify -h for additional help

=head1 DESCRIPTION

Some operating environments do not cope well with font families that contain fonts with subfamily
names other than the four standard "Regular", "Bold", "Italic", and "Bold Italic".

This tool revises the names and weights of such fonts to put the irregularly-named
fonts into their own family with standard subfamily names, as follows:

=over

If the current subfamily starts with the word 'Regular', 'Bold', 'Italic', 'Oblique', or "Slant", outfont will be 
the same as infont (except see note about Glyphs App, below).

Otherwise, if current subfamily consists of a single word, this word is appended to the family 
name, the subfamily is changed to 'Regular', and the weight of the font is set to 400.

Otherwise the first word of the subfamily will be appended to the family name and the subsequent words 
become the new subfamily. The weight of the font is set to 700 if the new subfamily contains the word "bold", 
otherwise 400. 

=back

=head1 EXAMPLES

Given infont with family name "My Font", ttffixweight will create outfont as follows:

 If subfamily is "Light", outfont will have:
   family "My Font Light", subfamily "Regular", weight 400

 If subfamily is "Book", outfont will have:
   family "My Font Book", subfamily "Regular", weight 400

 If subfamily is "Book Bold", outfont will have:
   family "My Font Book", subfamily "Bold", weight 700
 
 if subfamily is "Book Italic", outfont will have:
   family "My Font Book", subfamily "Italic", weight 400

Presently the Glyphs App generates inconsistent Mac and Windows name. ttffixweight forces
the names to agree. 

=head1 AUTHOR

Bob Hallissy L<http://scripts.sil.org/FontUtils>.
(see CONTRIBUTORS for other authors).

=head1 LICENSING

Copyright (c) 2017, SIL International (http://www.sil.org)

This script is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.

=cut
