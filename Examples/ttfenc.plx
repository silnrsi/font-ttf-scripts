use Font::TTF::Font;
require 'getopt.pl';

if ($ARGV[0] =~ /^\-@/oi)
{
    $cfgname = $';
    shift (ARGV);
    open(CFGFILE, "$cfgname") || die "Unable to open config file $cfgname";
    while (<CFGFILE>)
    { chomp; unshift (ARGV, $_); }
}
Getopt("e:m:p:t:x");

$VERSION = 1.0;     # MJPH  26-DEB-1999     Original

unless (defined $ARGV[0] && defined $opt_e)
{
    die <<'EOT';
    ttfenc [-e enc_file] [-m mapping_file] [-p map_file] [-t tfm_file]
           [-x] font.ttf
    ttfenc -@config_file font.ttf
    
Creates a Postscript mapping file for the given font according to the 8-bit
to Unicode mapping given in mapping_file. If the font is a Windows symbol font
then no mapping_file is required. If no tfm file is requested, then no map_file
entry is made, either. Requires ttf2afm and afm2tfm to run.

    -e enc_file         Filename of encoding file (including where to store it)
    -m mapping_file     Unicode mapping description file (e.g. cp1252.txt)
    -p map_file         The PDFTeX .map file in which to add an entry for this
                        font [OPTIONAL - absent, no entry added]
    -t tfm_file         The name and where to store the .tfm file
    -x                  Disable TeX postscript name correction
    -@config_file       Specifies a file to read command line parameters from

E.g.
    ttfenc -e ipa93.enc -m cp1252.txt ipa93sr.ttf

Just creates ipa93.enc from the POST table of ipa93sr.ttf

    ttfenc -e %texmf%\pdftex\base\ipa93.enc -m cp1252.txt -p %texmf%\pdftex\bas
e\ttfmap.map -t %texmf%\fonts\tfm\ttf\ipa93sr.tfm ipa93sr.ttf

Create .tfm, .afm, .enc and install the files in the appropriate places. (The
.afm is left with ipa93sr.log in the current directory)

EOT
}

%texCorrect = (
    'mu1' => 'mu',
    'summation' => 'Sigma',
    'product' => 'Pi',
    'increment' => 'Delta',
    'middot' => 'periodcentered',
    'overscore' => 'macron',
    'dslash' => 'dmacron'
    );

$base = $ARGV[0];
$base =~ s/(.*[\\\/])?(.*)\.ttf/$2/oi;

$font = Font::TTF::Font->open("$ARGV[0]");
$lchar = $font->{'OS/2'}->read->{'usFirstCharIndex'};
if ($lchar < 0xF000 || $lchar > 0xF100)             # a Windows symbol font?
{
    die "No mapping file" unless defined $opt_m;
    $map = read_UniMap($opt_m);         # no? then use mapping file
} else
{
    $map = [];
    for ($i = 0; $i < 256; $i++)
    { $map->[$i] = $i + 0xf000; }
}
$font->{'post'}->read;
$font->{'cmap'}->read;

open(OUTFILE, ">$opt_e") || die "Unable to open $opt_e";
binmode OUTFILE;                # need Unix file format!
select OUTFILE;

print "/TeXBase1Encoding [\n";

for ($i = 0; $i < 256; $i++)
{
    my ($name);
    
    printf "%% 0x%02X\n", $i unless ($i & 15);
    $name = $font->{'post'}{'VAL'}[$font->{'cmap'}->ms_lookup($map->[$i])];
    $name = $texCorrect{$name} if (!$opt_x && defined $texCorrect{$name});
    print "    /$name";
    print "\n" if ($i & 3) == 3;
}

print "] def\n";

close (OUTFILE);

exit unless defined $opt_t;

$tfmname = $opt_t;
$tfmname =~ s/(.*[\\\/])?(.*)\.tfm/$2/oi;
$encname = $opt_e;
$encname =~ s/(.*[\\\/])?(.*)\.enc/$2/oi;

system("ttf2afm -e $opt_e -o $tfmname.afm $ARGV[0] > $base.log");
open(INFILE, "afm2tfm $tfmname.afm |") || die "Can't run afm2tfm";
$mapline = <INFILE>;
close(INFILE);
(undef, $psname) = split(' ', $mapline);

if (defined $opt_p)
{
    open(OUTFILE, ">>$opt_p") || die "Can't open $opt_p for appending";
    print OUTFILE "$tfmname $psname <$base.ttf $encname.enc\n";
    close(OUTFILE);
}

if ($opt_t !~ /^$tfmname\.tfm/i)
{
    open (INFILE, "$tfmname.tfm") || die "Can't open $tfmname.tfm";
    binmode INFILE;
    unlink ("$opt_t") || goto getout;
    open (OUTFILE, ">$opt_t") || goto doneit;
    binmode OUTFILE;
    while (read(INFILE, $dat, 4096))
    { print OUTFILE $dat; }
    close (OUTFILE);
doneit:
    close (INFILE);
}

getout:
print STDERR "\n";

sub read_UniMap
{
    my ($fname) = @_;
    my ($res) = [];

    open(INFILE, "$fname") || return undef;
    while (<INFILE>)
    {
        s/\#.*$//oi;
        $res->[hex($1)] = hex($2) if (m/^\s*((?:0x)?[0-9a-f]+)\s*((?:0x)?[0-9a-f]+)/oi);
    }
    close(INFILE);

    $res;
}


