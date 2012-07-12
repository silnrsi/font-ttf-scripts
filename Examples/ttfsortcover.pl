#! /usr/bin/perl
use Font::TTF::Font;

unless (defined $ARGV[1])
{
    die <<'EOT';
    ttfsortcover infile outfile
Corrects all OT lookups and GDEF for unsorted coverage tables
EOT
}

$f = Font::TTF::Font->open($ARGV[0]) || die "Unable to open font file $ARGV[0]";
$f->{' noharmony'} = 1;		# Don't bother harmonizing script and language tags

foreach my $tag (qw(GPOS GSUB GDEF))
{
	next unless exists $f->{$tag};
	$f->{$tag}->read->dirty;
}

$f->update;
$f->out($ARGV[1]);
exit;