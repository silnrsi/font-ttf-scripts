use Font::TTF::Font;

$f = Font::TTF::Font->open($ARGV[0]);
$f->{'loca'}->read;
$Font::TTF::Name::utf8 = 1;
$Font::TTF::GDEF::new_gdef = 1;
$f->out_xml($ARGV[1]);

