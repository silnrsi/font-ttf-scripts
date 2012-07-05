#! /usr/bin/perl
use strict;
use Font::TTF::Font;
use Font::TTF::OTTags qw( %tttags %ttnames readtagsfile );
use Getopt::Std;
use Pod::Usage;

my $debug=0;

our ($opt_c, $opt_h, $opt_v);
getopts('chv');

unless (defined $ARGV[0] || defined $opt_h)
{
    pod2usage(1);
    exit;
}

if ($opt_h)
{
    pod2usage( -verbose => 2, -noperldoc => 1);
    exit;
}

my %aliases;	# Hash indexed by alias identifier; holds alias value
my %langrules;	# Hash indexed by language tag; holds array of TypeTuner rules

foreach my $input_font (@ARGV)
{
	my $font = Font::TTF::Font->open($input_font);
	unless ($font)
	{
		warn "Unable to open font file '$input_font': $!\n";
		next;
	}
	
	my $output_file = $input_font;
	$output_file =~ s/(\.[^.]*)/_all_feat.xml/o;
	
	unless (open (OUT, ">:encoding(UTF-8)", "$output_file"))
	{
		warn "Cannot open '$output_file': $!\n";
		next;
	}
	
	print OUT << 'EOT' ;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE all_features SYSTEM "feat_all.dtd">
<all_features version="1.0">
EOT

	# Process GSUB and GPOS tables
	foreach my $t (qw(GSUB GPOS))
	{
		next unless exists $font->{$t};
		my $g = $font->{$t}->read;
		
		# Process Scripts in this table
		
		printf STDERR "  Scripts:\n" if $debug;
		foreach my $s_tag ( keys (%{$g->{'SCRIPTS'}}))
		{
			my $s_name = $ttnames{'SCRIPT'}{$s_tag};
			printf STDERR "    <$s_tag> ", $s_name if $debug;
			
			my $s = $g->{'SCRIPTS'}{$s_tag};
			next unless defined $s;
			$s = $g->{'SCRIPTS'}{$s->{' REFTAG'}} if defined $s->{' REFTAG'};
			next unless defined $s;
			
			# Find and remember the default language
			my $dflt = $s->{'DEFAULT'};
			$dflt = $g->{'SCRIPTS'}{$dflt->{' REFTAG'}} if (defined $dflt && defined $dflt->{' REFTAG'});
			$dflt = {FEATURES => [] } unless defined $dflt;   # No default?  Hm...
			
			# Remember all the default features:
			my %dflt_feats;
			map {$dflt_feats{substr($_,0,4)} = $_} (@{$dflt->{'FEATURES'}});
			
			# Process each language in this script
			
			foreach my $l_tag (@{$s->{'LANG_TAGS'}})
			{
				next if $l_tag =~ /^zz\d\d$/ && !$opt_v;
				my $l_name = $ttnames{'LANGUAGE'}{$l_tag};

				my $l = $s->{$l_tag};
				next unless defined $l;
				$l = $s->{$l->{' REFTAG'}} if defined $l->{' REFTAG'};
				next unless defined $l;
				
				my %processed;	# A place to record what features we've processed
				foreach my $f_tag (@{$l->{'FEATURES'}})
				{
					if (exists $dflt_feats{substr($f_tag,0,4)})
					{
						# This feature also exists in both DEFAULT 
						# Is it exactly the same feature? 

						my $df_tag = $dflt_feats{substr($f_tag,0,4)};

						if ($df_tag ne $f_tag)
						{
							# Not exactly the same feature.
							# So now we'll have to add/subtract lookups
							my @d = (sort {$a cmp $b} @{$g->{'FEATURES'}{$df_tag}{'LOOKUPS'}}); # List of lookups in the default feature
							my @l = (sort {$a cmp $b} @{$g->{'FEATURES'}{$f_tag}{'LOOKUPS'}});  # List of lookups in the language-specific feature
							my $d = shift @d;	# Get first ones
							my $l = shift @l;
							while (defined ($d) or defined ($l))
							{
								if (defined $d)
								{
									if (defined $l)
									{
										if ($d < $l)
										{
											# Need to delete a feature from the default
											my $alias = add_feat_alias('dflt', $df_tag);
											push @{$langrules{$l_tag}}, "cmd name=\"lookup_del\" args=\"$t {$alias} $d\"";
											$d = shift @d;
										}
										elsif ($l < $d)
										{
											# Need to add a feature to the default
											my $alias = add_feat_alias('dflt', $df_tag);
											push @{$langrules{$l_tag}}, "cmd name=\"lookup_add\" args=\"$t {$alias} $l\"";
											$l = shift @l;
										}
										else
										{
											# Same lookup number... bump over it
											$l = shift @l;
											$d = shift @d;
										}
									}
									else
									{
										#Need to delete a feature from the default
										my $alias = add_feat_alias('dflt', $df_tag);
										push @{$langrules{$l_tag}}, "cmd name=\"lookup_del\" args=\"$t {$alias} $d\"";
										$d = shift @d;
									}
								}
								else
								{
									# Need to add a feature to the default
									my $alias = add_feat_alias('dflt', $df_tag);
									push @{$langrules{$l_tag}}, "name=\"lookup_add\" args=\"$t {$alias} $l\"";
									$l = shift @l;
								}
							}
						}
					}
					else
					{
						# This feature does not exist in DEFAULT, so configure TT to add it
						my $feat_alias = add_feat_alias($l_tag, $f_tag);
						push @{$langrules{$l_tag}}, "name=\"feat_add\" args=\"$t $s_tag DEFAULT {$feat_alias} 0\"";
					}
					$processed{substr($f_tag,0,4)} = $f_tag;
				}
				
				# Remove any unwanted features from DEFAULT
				foreach my $f_tag (keys %dflt_feats)
				{
					unless (exists ($processed{substr($f_tag,0,4)}))
					{
						# This feature is no longer needed, so remove it...
						my $feat_alias = add_feat_alias('dflt', $f_tag);
						push @{$langrules{$l_tag}}, "name=\"feat_del\" args=\"$t $s_tag DEFAULT {$feat_alias}\"";
					}
				}
			}
		}
	}

	# Construct Language feature
	
	print OUT << 'EOT' ;
	<feature name="Language" value="Default" tag="Lng">
		<value name="Default" tag="Def">
			<cmd name="null" args="null"/>
		</value>
EOT

	for my $l_tag (keys %langrules)
	{
		my $l_name = exists ($ttnames{'LANGUAGE'}{$l_tag}) ? $ttnames{'LANGUAGE'}{$l_tag} : $l_tag;
		my $tag = $l_tag;
		$tag =~ s/\s+//g;
		print OUT "\t\t<value name=\"$l_name\" tag=\"$tag\">\n";
		map {print OUT "\t\t\t<cmd $_/>\n" } (sort @{$langrules{$l_tag}});
		print OUT "\t\t</value>\n";
	}
	print OUT "\t</feature>\n";

	# Construct aliases
	
	print OUT "\t<aliases>\n";
	map {print OUT "\t\t<alias $_/>\n" } (sort values %aliases);
	print OUT "\t</aliases>\n";

	# Close
	
	print OUT "</all_features>\n";
	
	$font->release;

	# Go ahead and compile in the xml if requested:
	if ($opt_c)
	{
		system ("TypeTuner add \"$output_file\" \"$input_font\"");
		if ($? == -1) 
		{
	        warn "failed to execute TypeTuner: $!\n";
	    }
	    elsif ($? & 127) 
	    {
	        warn sprintf ("TypeTuner died with signal %d, %s coredump\n", ($? & 127),  ($? & 128) ? 'with' : 'without');
	    }
	    else 
	    {
	        warn sprintf ("TypeTuner exited with value %d\n", $? >> 8) if ($? >> 8) != 0;
	    }
	}
}

sub add_feat_alias
{
	my ($l_tag, $f_tag) = @_;
	my $alias = substr($f_tag, 0, 4) . "_" . (exists ($ttnames{'LANGUAGE'}{$l_tag}) ? $ttnames{'LANGUAGE'}{$l_tag} : $l_tag);
	$alias =~ s/\s//g;	# No whitespace allowed
	
	$aliases{$alias} = "name=\"$alias\" value=\"$f_tag\"" unless exists $aliases{$alias};
	return $alias;
}
	

=head1 TITLE

ttflang2tuner - Convert OpenType lang systems to TypeTuner configuration file

=head1 SYNOPSIS

  ttflang2tuner [-c] [-v] infile.ttf ...
  ttflang2tuner -h

Builds TypeTuner features configuration file(s) from the script and language tags contained in the GPOS and GSUB tables of OpenType font(s).

=head1 OPTIONS

  -c   Invoke TypeTuner to compile the TT control file into the font
  -v   include debugging entries added by Microsoft VOLT
  -h   print help message

=head1 DESCRIPTION

ttflang2tuner analyzes the various language-specific rendering within each supplied OpenType file and 
writes a TypeTuner features file for each font.
If -c is supplied, ttflang2tuner invokes TypeTuner directly for each font to create the Tuner-ready font(s).
For this to work the TypeTuner program must be on your PATH some place.

When a font has been compiled, but not shipped, by Microsoft VOLT, the OpenType tables contain
additional languages and features used by the VOLT Proofing Tool. These are ignored
by ttflang2tuner unless the -v option is provided.

=cut