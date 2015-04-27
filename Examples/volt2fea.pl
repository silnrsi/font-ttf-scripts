#!/usr/bin/perl

use strict;
use Font::TTF::Scripts::Volt;
use Getopt::Std;
use Pod::Usage;

our $VERSION = 0.1;     #   

our %opts;

pod2usage(-verbose => 1) unless getopts('a:d:ht:', \%opts) && ($#ARGV == 1 || $opts{'h'});

pod2usage( -verbose => 2, -noperldoc => 1) if $opts{'h'};

my $if = Font::TTF::Scripts::Volt->read_font($ARGV[0], $opts{'a'}) || die "Can't read font $ARGV[0]";

my $fh = IO::File->new("> $ARGV[1]") || die "Can't open $ARGV[1] for writing";

Font::TTF::Scripts::Volt::VoltToFEA($if, $fh, %opts);

die $if->{'WARNINGS'} if $if->{'cWARNINGS'};

package Font::TTF::Scripts::Volt;
use Font::TTF::Scripts::Fea;
use Text::Wrap;

#indents
our ($indent0, $indent1, $indent2, $indent3);

sub VoltToFEA
{
    my ($fv, $fh, %opts) = @_;
    
    my ($volt_text, $font, $post);
	local($Text::Wrap::columns) = 132;
	local($Text::Wrap::tabstop) = 0;
    
    $font = $fv->{'font'};
    
    if ($opts{'t'})
    {
        my ($inf) = IO::File->new("< $opts{'t'}") || die "Can't open file $opts{'t'}";
        while (<$inf>)
        { $volt_text .= $_; }
        $inf->close;
    }
    elsif (defined $font->{'TSIV'})
    { $volt_text = $font->{'TSIV'}->read->{' dat'}; }
    else
    { $fv->error("No VOLT table in the font, nothing to do\n"); return; }

    if ($opts{'d'})
    {
        $::RD_HINT = 1;
        $::RD_TRACE = $opts{'d'} if ($opts{'d'} > 1);
    }

    $fv->{'voltdat'} = $fv->parse_volt($volt_text);

	$indent0 = "";        # Firstline flush
	$indent1 = ' ' x 4;    # Subsequent lines indented
	$indent2 = $indent1 x 2;
	$indent3 = $indent1 x 3;
	
	$fv->out_fea_glyphs($fh);
	$fv->out_fea_groups($fh);
	$fv->out_fea_lookups($fh);
	$fv->out_fea_features($fh);
}

sub out_fea_glyphs
{
	my ($self, $fh) = @_;
	my $dat = $self->{'voltdat'};

	my (@bases, @marks, @ligatures, @components, $markClasses);
    startsection ($fh, "Glyphs");
    
    for my $gname (sort keys $dat->{'glyph_names'})
    {
    	next if $gname =~ /^(\.|nonmarkingreturn|tab)/;	# ignore .null, .notdef, etc.
    	my $gid = $dat->{'glyph_names'}{$gname};
    	$gname = $self->make_feaname($gid);
	    my $g = $dat->{'glyphs'}[$gid];
    	
    	push @bases,      $gname if $g->{'type'} eq 'BASE';
    	push @marks,      $gname if $g->{'type'} eq 'MARK';
    	push @ligatures,  $gname if $g->{'type'} eq 'LIGATURE';
    	push @components, $gname if $g->{'type'} eq 'COMPONENT';
    	if (defined $g->{'anchors'})
    	{
    		foreach my $ap (sort grep { /^MARK_/} keys %{$g->{'anchors'}})
    		{
    			$markClasses .= "${indent1}markClass $gname " 
    				. $self->get_fea_anchor($g->{'anchors'}{$ap}[0]{'pos'})
    				. " \@$ap ;\n";
 		   		$self->error("Glyph $gname has $ap anchor but isn't classed as a mark\n") unless $g->{'type'} eq 'MARK';
 	
    		}
    	}
    }

	# While here, output the GDEF classes:
	my $res;
	my %c = ( base => \@bases, ligature => \@ligatures, mark => \@marks, component => \@components);
	foreach (qw(base ligature mark component))
	{
		my $sep = $_ eq 'component' ? ';' : ',';
		if ($#{$c{$_}} >= 0)
		{
			$fh->print("\n", wrap($indent0, $indent1, "\@GDEF_${_}s = [ " . join(' ', @{$c{$_}}) . " ] ;\n"));
			$res .= "${indent1}\@GDEF_${_}s$sep # $_ glyphs\n";
		}
		else
		{
			$res .= "${indent1}$sep     # no $_ glyphs\n";
		}
	}
 
    	
	$fh->print("\ntable GDEF {\n${indent0}GlyphClassDef\n$res } GDEF;\n");
	
    startsection ($fh, "Mark Classes");
	$fh->print($markClasses);
}


sub out_fea_groups
{
    my ($self, $fh) = @_;
    my ($dat) = $self->{'voltdat'};
    my ($font) = $self->{'font'};
    
    startsection ($fh, "Glyph classes");
    $self->{'completed'} = {};
    
    my (@grps);
    @grps = sort keys %{$dat->{'groups'}};

	# I'd like to just output the groups in alpha order, but ADFKO requires groups to be 
	# defined before they are used (for example, within other groups). So we start working through
	# the list of groups, and when we successfully output one we delete it from the sorted list
	# and start over from the begining.
	
    while (scalar(@grps))
    {
    	foreach my $grp (0 .. $#grps)
    	{
    		my $grpName = $grps[$grp];
 			my $res = $self->get_fea_ctx($dat->{'groups'}{$grpName});
 			next unless defined $res;			# Can't output this one yet... so try the next one.
 			$fh->print("\n", wrap($indent0, $indent1, "\@$grpName = [ $res ] ;\n"));	# Success! output it.
 			$self->{'completed'}{$grpName} = 1;	# Remember that this one is done
 			splice @grps, $grp, 1;				# Remove from list of remaining work
 			last;								# Start from the start of the list again
 		}
 	}
 	
 	$self->error("Groups appear to have a circular definition. Review ", join(',', @grps), "\n") if scalar(@grps);
}

sub out_fea_lookups
{
    my ($self, $fh) = @_;
    my ($dat) = $self->{'voltdat'};
    my ($font) = $self->{'font'};
    
    startsection ($fh, "Lookups");

    my ($res, $prevname, $subindex);

    for (my $i = 0; $i <= scalar(@{$dat->{'lookups'}}); $i++)   # Yes, this loops one extra time so we can close the final lookup
    {
    	my ($l, $lname, $subname);
    	if ($i < scalar(@{$dat->{'lookups'}}))
    	{
    		$l = $dat->{'lookups'}[$i];
    		
    		# print STDERR "Starting lookup $l->{'id'}\n";
	    	
	    	# parse lookup name and subtable
	    	($lname, $subname) = split(/\\/, $l->{'id'});
	    	unless (length($lname))
	    	{
	    		$self->error("Can't parse lookup name \"$l->{'id'}\" on lookup $i\n");
	    		next;
	    	}
	    }
    	if ($i == scalar(@{$dat->{'lookups'}}) || $lname ne $prevname)
    	{
    		# Close previous lookup, if any:
    		$res .= "} $prevname;\n" if defined $prevname;

   	    	# Here is the actual loop exit -- we're done!
			last if $i == scalar(@{$dat->{'lookups'}});
    		
    		if (isChaining($l))
    		{
    			# Start of chaining context lookup -- output the targets first
    			for (my $i2 = $i; $i2 < scalar(@{$dat->{'lookups'}}); $i2++)
    			{
    				my ($l2, $lname2, $subname2);
 		    		$l2 = $dat->{'lookups'}[$i2];
			    	($lname2, $subname2) = split(/\\/, $l2->{'id'});
			    	unless (length($lname2))
			    	{
			    		$self->error("Can't parse lookup name \"$l2->{'id'}\" on lookup $i2\n");
			    		next;
			    	}
			    	last if $lname2 ne $lname;	# End of chaining lookup
			    	my $fullname = $lname2 . (defined($subname2) ? "_$subname2" : '') . '_target'; 
   	    			$res .= "\nlookup $fullname {" . ($l2->{'comment'} ? " # $l2->{'comment'}" : '') . "\n  lookupflag " . $self->get_fea_lookupflag($l2) . ";\n";
   	    			$res .= $self->get_fea_simple_lookup($l2);
   	    			$res .= "} $fullname ;\n";
   	    			# Remember target lookup:
   	    			$l2->{'_target'} = $fullname;
   	    		}
   	    	}
   	    
   	    	# Ok, start next lookup

			$res .= "\nlookup $lname {\n  lookupflag " . $self->get_fea_lookupflag($l) . ";\n"; 
    		$prevname = $lname;
    		$subindex = 0;		# Which subtable we're on, starting with 0.
   	    	
   	    }

    	$res .= "  # Subtable: $l->{'id'}\n" if $subname;
    	$res .= "  # $l->{'comment'}\n" if $l->{'comment'};
    	
    	if (isChaining($l))
    	{
    		unless (defined $l->{'_target'})
    		{
    			$self->error("Lookup $l->{'id'} is chaining context without target\n");  
    			next;
    		}
    		
	    	foreach my $context (@{$l->{'contexts'}})
	    	{
	    		$res .= $indent1;
	    		$res .= 'ignore ' if $context->[0] eq 'EXCEPT_CONTEXT';
	    		$res .= "$l->{'lookup'}[0] ";	# Type of lookup (sub or pos)  [AFDKO doc seems to suggest this always 'sub' ?]
	    		my (@backtrack, @lookahead, $notGlyph);
	    		for my $i (1 .. $#{$context})
	    		{
	    			my $c = $self->get_fea_ctx_as_class( [ $context->[$i][1] ]);
	    			if ($context->[$i][0] eq 'LEFT')
	    			{ push @backtrack, $c;}
	    			else
	    			{ push @lookahead, $c; }
	    			# Because of a bug in Fontforge (as of v1:2.0.201412), we need to know whether any of
	    			# the context items are something other than simple glyphs:
	    			$notGlyph++ if $c =~ m'^[[@]';
	    		}
	    		# Ok, this is to work around fontforge failing to get the backtrack order right for glyph-based contextuals:
	    		$backtrack[0] = "[ $backtrack[0]]" if $#backtrack > 0 && $notGlyph == 0;	# Force it to be class-based if needed.
				$res .= join('', @backtrack);
				if ($l->{'lookup'}[0] eq 'sub')
				{
					# Apparently all "input" strings have to be the same length
					# and we synthesize classes that match each position, but
					# mark only the first such with the target lookup.
					my $lastRule  = $#{$l->{'lookup'}[1]};
					my $lastInput = $#{$l->{'lookup'}[1][0][0]};
					
					foreach my $i (0 .. $lastInput)
					{
						my @input = map {$l->{'lookup'}[1][$_][0][$i] } (0 .. $lastRule);
						$res .= $self->get_fea_ctx_as_class (\@input, $i == 0 && $context->[0] ne 'EXCEPT_CONTEXT' ? "lookup $l->{'_target'}" : '');
					}
	    		}
	    		else
	    		{
	    			if (exists $l->{'lookup'}[1][0]{'to'})
	    			{
	    				# Mark attach
	    				# The glyph to mark as "input" is the mark, not base or base+mark
	    				my @input = map {$_->[0]} (@{$l->{'lookup'}[1][0]{'to'}});
	    				$res .= $self->get_fea_ctx_as_class (\@input, $context->[0] ne 'EXCEPT_CONTEXT' ? "lookup $l->{'_target'}" : '');
	    			}
	    			elsif (exists $l->{'lookup'}[1][0]{'context'})
	    			{
	    				# Single adjust
	    				$res .= $self->get_fea_ctx_as_class ($l->{'lookup'}[1][0]{'context'}, $context->[0] ne 'EXCEPT_CONTEXT' ? "lookup $l->{'_target'}" : '');
	    			}
	    			else
	    			{
	    				$res .= "# TODO: Chaining positioning rule target goes here # ";
	    			}
	    		}
				$res .= join('', @lookahead);
				$res .= ";\n";
	    	}
    	}
    	else
    	{
    		# emit subtable separator for all but first:
    		$res .= "  subtable ;\n" if $subindex++;
    		$res .= $self->get_fea_simple_lookup($l);
    	}
	}
    
    $fh->print($res);
}


sub get_fea_simple_lookup
{
	my ($self, $l) = @_;
	my $dat = $self->{'voltdat'};

	
	my $res;
	if ($l->{'lookup'}[0] eq 'sub')
	{
		# Detect and rewrite Type 3 Alternate lookups
		#   lhs of all rules have 1 element; same lhs appears more than once
		#   if isalternate
		#      for each rule
		#         flatten lhs & rhs into glyphlists
		#         build list of rhs glyphs associated with each lhs
		#      for each lhs glyph, output fea rule
		
		
		my ($maxi, $maxo);
		foreach my $rule (@{$l->{'lookup'}[1]})
		{
			my ($lgt) = scalar(@{$rule->[0]});
			$maxi = $lgt if $lgt > $maxi;
			$lgt = scalar(@{$rule->[1]});
			$maxo = $lgt if $lgt > $maxo;
			last if $maxi > 1 || $maxo > 1; # shortcircuit since VOLT doesn't support many-to-many 
		}
		
		if ($maxi == 1 && $maxo == 1)
		{
			# Need to figure whether this is 1-to-1 or alternation
			my (%alts, $isAlternation);
			
			foreach my $rule (@{$l->{'lookup'}[1]})
			{
				my $lhs = $self->get_ctx_flat($rule->[0]);
				my $rhs = $self->get_ctx_flat($rule->[1]);
				unless ($lhs && $rhs && $#{$lhs} == $#{$rhs})
				{ $self->error("trouble understanding lookup $l->{'id'} at line ", __LINE__, "\n"); return undef }
				for my $i (0 .. $#{$lhs})
				{
					push @{$alts{$lhs->[$i]}}, $rhs->[$i];
					$isAlternation = 1 if scalar(@{$alts{$lhs->[$i]}}) > 1;
				}
			}
			
			if ($isAlternation)
			{
				# Special form for alternation lookups:
				foreach my $gid (sort {$dat->{'glyphs'}[$a]{'name'} cmp $dat->{'glyphs'}[$b]{'name'}} keys(%alts))
				{
					$res .= "${indent1}sub " . $self->make_feaname($gid) . " from [ " 
						. join(' ', map {$self->make_feaname($_)} @{$alts{$gid}}) . " ] ;\n";
				}
				return $res;
			}
			else
			{
				# If 1-1 and not alternation then the rules can be put out verbatim, including groups
				foreach my $rule (@{$l->{'lookup'}[1]})
				{
					next unless $#{$rule->[0]} >= 0;	# Silently ignore empty rules
					$res .= "${indent1}sub " . $self->get_fea_ctx($rule->[0]) . "by " . $self->get_fea_ctx($rule->[1]) . ";\n";
				}
				return $res;
			}
 		}
 		
 		# Sadly, Adobe doesn't permit compact notation using groups in 1-to-many (decomposition) rules e.g:
 		#     sub @AlefPlusMark by absAlef @AlefMark ;
 		# or many-to-1 (ligature) rules, e.g.:
 		#     sub @ShaddaKasraMarks absShadda by @ShaddaKasraLigatures ;

 		# so such rules have to expanded out, making maintenance a pain
 		
		foreach my $rule (@{$l->{'lookup'}[1]})
		{
			
			# Get lists of LHS and RHS terms:
			my @lhs = $self->get_fea_ctx($rule->[0]);
			next unless $#lhs >= 0;	# Silently ignore empty rules
			my @rhs = $self->get_fea_ctx($rule->[1]);
			my ($lhsIndex, $rhsIndex);	
			for (0 .. $#lhs)
			{  $lhsIndex = $_ if $lhs[$_] =~ /^@/; }
			for (0 .. $#rhs)
			{  $rhsIndex = $_ if $rhs[$_] =~ /^@/; }
			if (defined $lhsIndex)
			{
				unless (defined $rhsIndex)
				{
					$self->error("rhs has no matching group in lookup $l->{'id'}\n");
					next;
				}
			}
			elsif (defined $rhsIndex)
			{
				$self->error("lhs has no matching group in lookup $l->{'id'}\n");
				next;
			}
			else
			{
				# No groups -- take the short cut:
				$res .= "${indent1}sub " . $self->get_fea_ctx($rule->[0]) . "by " . $self->get_fea_ctx($rule->[1]) . ";\n";
				next;
			}
			# This is what we'd like to do:
			$res .= "${indent1}# sub " . $self->get_fea_ctx($rule->[0]) . "by " . $self->get_fea_ctx($rule->[1]) . ";\n";

			# but this is what we have to do:
			my $lhsgroup = $self->get_ctx_flat($self->{'voltdat'}{'groups'}{substr($lhs[$lhsIndex], 1)});
			my $rhsgroup = $self->get_ctx_flat($self->{'voltdat'}{'groups'}{substr($rhs[$rhsIndex], 1)});
			for $_ (0 .. $#{$lhsgroup})
			{
				$lhs[$lhsIndex] = $self->make_feaname($lhsgroup->[$_]);
				$rhs[$rhsIndex] = $self->make_feaname($rhsgroup->[$_]);
				$res .= "${indent2}sub " . join(' ', @lhs) . ' by ' . join(' ', @rhs) . " ;\n";
			}
			
		}
	}
	else
	{
		foreach my $rule (@{$l->{'lookup'}[1]})
		{
			$res .= "    #  subrule of type $rule->{'type'}\n";
			if ($rule->{'type'} eq 'ADJUST_SINGLE')
			{
				# GPOS Type 1: single adjust
				foreach my $i (0 .. $#{$rule->{'context'}})
				{
					$res .= "${indent1}pos " 
						. $self->get_fea_ctx( [ $rule->{'context'}[$i] ] ) 
						. ' ' 
						. $self->get_fea_valuerecord($rule->{'adj'}[$i]) 
						. ";\n";
				}
			}
			elsif ($rule->{'type'} eq 'ADJUST_PAIR')
			{
				# GPOS Type 2: pair adjust
				...;
			}
			elsif ($rule->{'type'} eq 'ATTACH_CURSIVE')
			{
				# GPOS Type 3: cursive attach
				my %anchors;
				foreach my $gid (@{$self->get_ctx_flat($rule->{'enters'})})
				{
					next unless exists $dat->{'glyphs'}[$gid]{'anchors'}{'entry'};
					$anchors{$gid}{'entry'} = $self->get_fea_anchor($dat->{'glyphs'}[$gid]{'anchors'}{'entry'}[0]{pos});
				}
				foreach my $gid (@{$self->get_ctx_flat($rule->{'exits'})})
				{
					next unless exists $dat->{'glyphs'}[$gid]{'anchors'}{'exit'};
					$anchors{$gid}{'exit'} = $self->get_fea_anchor($dat->{'glyphs'}[$gid]{'anchors'}{'exit'}[0]{pos});
				}
				
				foreach my $gid (sort {$dat->{'glyphs'}[$a]{'name'} cmp $dat->{'glyphs'}[$b]{'name'}} keys(%anchors))
				{
					$res .= "${indent1}pos cursive " . $self->make_feaname($gid);
					$res .= defined $anchors{$gid}{'entry'} ? " $anchors{$gid}{'entry'}" : " <anchor NULL>";
					$res .= defined $anchors{$gid}{'exit'}  ? " $anchors{$gid}{'exit'}"  : " <anchor NULL>";
					$res .= ";\n";
				}
			}
			elsif ($rule->{'type'} eq 'ATTACH')
			{
				# GPOS Type 4, 5, or 6: anchor attach
				
				# volt2fea makes a simplifying assumption: That anchor attachment don't really need to
				# accurately translate the VOLT code in regard to the marks that are being attached. 
				# Specifically, VOLT lets you specify a subset of all the marks with a given AP, but 
				# to do that in FEA syntax requires separate markClass definitions for each lookup.
				# I'm going to assume that the only reason a VOLT author might have given a subset 
				# is that the others shouldn't / wouldn't occur so the author just omitted them
				#
				# Rather than build separate marClass definitions for each lookup I'm going to use the
				# previously derived from the mark anchors (see outFeaGlyphs()).
				#
				# But I will emit a warning.
				
				# List of APs mentioned in the "to" part of this lookup
				my @aps = map {$_->[1]} @{$rule->{'to'}} ;
				@aps = sort(uniq(@aps));
				# Non fatal warning message:
				print STDERR "GPOS lookup $l->{'id'} will attach all marks with anchor(s) " . join(', ', @aps) . ".\n";
				
				# Unfortunately the FEA syntax is very clunky and the stationary glyphs have to be enumerated
				foreach my $gid ( uniq(@{$self->get_ctx_flat($rule->{'context'})}) )
				{
					my $g = $dat->{'glyphs'}[$gid];
					my $gname = $self->make_feaname($gid);
					if ($g->{'component_num'} > 1)
					{
						# Must be a ligature glyph... confirm it!
						$self->error("Glyph $gname has multiple components but is not a LIGATURE\n") unless $g->{'type'} eq 'LIGATURE';
					}
					else
					{
						# Must not be a ligature glyph... confirm it!
						$self->error("Glyph $gname has only one component but is declared to be a LIGATURE\n") if $g->{'type'} eq 'LIGATURE';
					}
					
					$res .= "${indent1}pos " . lc(defined $g->{'type'} ? $g->{'type'} : 'base'). " $gname";
					foreach my $comp (0 .. ($g->{'component_num'} || 1) - 1)
					{
						$res .= "\n${indent2}ligComponent\n" if $comp > 0;
						my $needNullAnchor = 1;
						foreach my $ap (@aps)
						{
							if (defined($g->{'anchors'}{$ap}[$comp]))
							{
								$needNullAnchor = 0;
								$res .= "\n$indent2 " . $self->get_fea_anchor($g->{'anchors'}{$ap}[$comp]{'pos'}) . " mark \@MARK_$ap";
							}
						}
						$res .= "\n$indent2 <anchor NULL>\n" if $needNullAnchor;
					}
					$res .= " ;\n";
				}
			}
				

		}
	}
	return $res;
}
    	
#################################
# method get_fea_lookupflag ($lookup)
#
#
# returns text for the value of the lookupFlag of the supplied lookup

sub get_fea_lookupflag
{
	my ($self, $l) = @_;
	my @res;
	push @res, 'RightToLeft' if $l->{'dir'} eq 'RTL' && $l->{'lookup'}[0] eq 'pos' && $l->{'lookup'}[1][0]{'type'} eq 'ATTACH_CURSIVE';
	push @res, 'IgnoreBaseGlyphs' if $l->{'base'} eq 'SKIP_BASE';
	push @res, 'IgnoreMarks' if $l->{'marks'} eq 'SKIP_MARKS';
  # push @res, 'IgnoreLigatures' if 0;  # Don't think VOLT supports this
	push @res, "MarkAttachmentType \@$l->{'all'}" if $l->{'marks'} eq 'PROCESS_MARKS' && $l->{'all'} ne 'ALL';
	push @res, "UseMarkFilteringSet \@$l->{'all'}" if $l->{'marks'} eq 'MARK_GLYPH_SET';
	return scalar(@res) == 0 ? '0 ' :  join(' ', @res) . ' ';
}

#################################
# method get_fea_valuerecord ($pos)
#
# return fea valuerecord string correspoinding to Volt.pm pos element

sub get_fea_valuerecord
{
	my ($self, $p) = @_;
	# Note: VOLT doesn't support y-advance as far as I know, so I use
	# the non-existing key 'ady' as a place-holder -- should end up zero value1
	return $self->get_fea_pos($p, '', qw(x y adv ady));
}

#################################
# method get_fea_anchor ($pos)
#
# return fea ancor string correspoinding to Volt.pm pos element

sub get_fea_anchor
{
	my ($self, $p) = @_;
	return $self->get_fea_pos($p, 'anchor', qw(x y));
}

#################################
# method get_fea_pos ($pos, @keys)
#
# return fea position record containing keys named as params

sub get_fea_pos
{
	my ($self, $p, $term, @keys) = @_;
	my ($res, $hasDevice);

	$res = "<$term";
	
	# Basic value record 
	foreach ( @keys ) 
	{
		if (exists $p->{$_})
		{
			$res .= ' ' unless $res eq '<';
			$res .= $p->{$_}[0];
			$hasDevice = 1 if $#{$p->{$_}[1]} >= 0;
		}
		else
		{	$res .= ' 0'; }
	}
	
	if ($hasDevice)
	{
		# More complicated... at least one has a device record
		# so we need to output device records for all
		foreach ( @keys )
		{
			$res .= "\n        <device ";
			if (exists ($p->{$_}) && $#{$p->{$_}[1]} >= 0)
			{
				$res .= join(', ', map {"$_->[1] $_->[2]"} (@{$p->{$_}[1]}));
				$res .= '>';
			}
			else
			{	$res .= 'NULL>'; }
		}
	}
	$res .= '>';
	return $res;
}


#################################
# method get_fea_ctx_as_class ($ctx, $mark)
#
# Same as get_fea_ctx execept it insures that the result string is a single 
# fea item by surrounding with [ ] if needed.
#
# If $mark is defined, the the entire class is marked, not individual terms within. I.e.
# the quote is after the closing square brace if braces are needed.

sub get_fea_ctx_as_class
{
	# Same as get_fea_ctx, but puts brackets around result if more than one item
	my ($self, $ctxs, $mark) = @_;
	my @res = $self->get_fea_ctx($ctxs);
	return undef unless defined $res[0];
	# Since this is a class, no need to have duplicate values
	@res = uniq(@res);
	my $res;
	$res = join(' ', @res);
	$res = "[ $res ]" if $res =~ / /;
	$res .= "' $mark" if defined($mark);
	return "$res ";
}

#################################
# method get_fea_ctx ($ctx, $mark)
#
# Returns a string or list representation of an array of VOLT context items (e.g. one of pre, input, post).
# VOLT has concept of ENUMs and RANGEs but AFDKO does not so these items are flattened, thus the
# result consists of only glyphs and groups.
#
# $ctx is a pointer to an array of contexts.
#
# If $mark is defined, the context is assumed to represent the "input" string for a chaining context rule.
# In this case each term of the result is marked by a single quote and the first term is additionally followed 
# by whatever is in the $mark parameter, normally the name of a target lookup for the contextual rule.
#
# If a group is included and that group has not [yet] been defined, returns an error indication.
#
# In scalar context returns a fea-syntax string or undef for error.
# In list context returns returns a list of the glyphs or groups. Returns empty list if an error.
#
 
sub get_fea_ctx
{
	my ($self, $ctxs, $mark) = @_;
	my (@res);
	
	foreach my $ctx (@{$ctxs})
	{
		if ($ctx->[0] eq 'GLYPH' || $ctx->[0] eq 'RANGE')
		{
			for my $gid ($ctx->[1] .. $ctx->[0] eq 'GLYPH' ? $ctx->[1] : $ctx->[2]) 
			{
				push @res, $self->make_feaname($gid) . (defined($mark) ? "'" : '');
			}
		}
		elsif ($ctx->[0] eq 'ENUM')
		{
			my $r = $self->get_fea_ctx($ctx->[1]);
			return (wantarray ? ( ) : undef) unless defined $r;
			$r =~ s/ $//;  # Don't need the extra space here.
			push @res, $r;
		}
		elsif ($ctx->[0] eq 'GROUP')
		{
			return (wantarray ? ( ) : undef) unless $self->{'completed'}{$ctx->[1]};
			push @res, "\@$ctx->[1]" . (defined($mark) ? "'" : '');
		}
	}
	$res[0] .= " $mark" if defined($mark);	
	return wantarray ? @res :  join(' ', @res) . ' ';
}

#################################
# method get_ctx_flat ($ctx)
#
# Flattens an array of context items into an array of glyph ids
#
# $ctx is a pointer to an array of contexts.
#
# Return value: normally a pointer to an array of glyph ids
# However, returns undef If the context sequence references a group that is not yet defined


sub get_ctx_flat
{
	my ($self, $ctxs) = @_;
	my $res = [];
	
	foreach my $ctx (@{$ctxs})
	{
		if ($ctx->[0] eq 'GLYPH' || $ctx->[0] eq 'RANGE')
		{
			for my $gid ($ctx->[1] .. $ctx->[0] eq 'GLYPH' ? $ctx->[1] : $ctx->[2]) 
			{
				push $res, $gid;
			}
		}
		else  # ENUM and GROUP are similar:
		{
			return undef if $ctx->[0] eq 'GROUP' && !defined($self->{'completed'}{$ctx->[1]});
			my $res2 = $self->get_ctx_flat($ctx->[0] eq 'GROUP' ? $self->{'voltdat'}{'groups'}{$ctx->[1]} : $ctx->[1]);
			return undef unless defined $res2;
			push $res, @{$res2};
		}
	}
	return $res;
}

sub make_feaname
{
    my ($self, $gid) = @_;

	my $gname = $self->{'font'}{'post'}{'VAL'}[$gid];
	return Font::TTF::Scripts::Fea->make_name($gname);
}
	

# Sort function to sort OT tags such that dflt or DFLT is first, otherwise alpha order

sub dfltFirst
{
	if (lc($a) eq "dflt")
	{ return lc($a) eq 'dflt' ? 0 : -1;	}
	return lc($b) eq "dflt" ? +1 : $a cmp $b;
}


sub out_fea_features
{
	my ($self, $fh) = @_;
	my $dat = $self->{'voltdat'};

    startsection ($fh, "Features");
    
    # First, gotta turn the structure inside out for Adobe.
    # While doing this, emit the language system records
    # (thus the need to sort script and lang tags)
    
	my (%features);
    $fh->print("\n");
    foreach my $stag (sort dfltFirst keys %{$dat->{'scripts'}})
    {
    	my $s = $dat->{'scripts'}{$stag};
    	my $sname = $s->{'name'};
    	
    	# Because langs are an array we'll just accumulate tags for the moment
    	# and sort them later:
    	my @langs;
		foreach my $l (@{$s->{'langs'}})
    	{
			my $ltag = $l->{'tag'};
			my $lname = $l->{'name'};
			push @langs, $ltag;
			
    		foreach my $f (values (%{$l->{'features'}}))
    		{
    			my $ftag = $f->{'tag'};
    			my $fname = $f->{'name'};
    			$features{$ftag}{'tag'} = $ftag;
    			$features{$ftag}{'name'} = $fname;
    			$features{$ftag}{'scripts'}{$stag}{'tag'} = $stag;
    			$features{$ftag}{'scripts'}{$stag}{'name'} = $sname;
    			$features{$ftag}{'scripts'}{$stag}{'langs'}{$ltag}{'tag'} = $ltag;
    			$features{$ftag}{'scripts'}{$stag}{'langs'}{$ltag}{'name'} = $lname;
    			$features{$ftag}{'scripts'}{$stag}{'langs'}{$ltag}{'lookups'} = $f->{'lookups'};
    		}
    	}
    	foreach my $ltag (sort dfltFirst @langs)
    	{
			$fh->print("languagesystem $stag $ltag ;\n");
		}
    }

	# Create a lookup name to index mapping for sorting lookup names:
	my %lmap;
	foreach my $n (0 .. $#{$dat->{'lookups'}})
	{ $lmap{$dat->{'lookups'}[$n]{'id'}} = $n; }
    
    # Now we can emit them:
    for my $ftag (sort keys %features)
    {
    	$fh->print("\nfeature $ftag {  # $features{$ftag}{'name'}\n");
    	
    	for my $stag (sort dfltFirst keys %{$features{$ftag}{'scripts'}})
    	{
    		$fh->print("${indent1}script $stag;  # $features{$ftag}{'scripts'}{$stag}{'name'}\n");
    		
    		foreach my $ltag (sort dfltFirst keys %{$features{$ftag}{'scripts'}{$stag}{'langs'}})
    		{
    			$fh->print("${indent2}language $ltag", $ltag ne 'dflt' ? ' exclude_dflt' : '', ";  # $features{$ftag}{'scripts'}{$stag}{'langs'}{$ltag}{'name'}\n");
    			my %seen;
    			foreach my $lkup (sort {$lmap{$a} <=> $lmap{$b} } @{$features{$ftag}{'scripts'}{$stag}{'langs'}{$ltag}{'lookups'}})
    			{
    				# Finally got lookup name -- except it might be a multi-subtable name
    				$lkup =~ s/\\.*$//;
    				next if $seen{$lkup};
    				$fh->print("${indent3}lookup $lkup;\n");
    				$seen{$lkup}=1;
    			}
    		}
    	}
  		
    	$fh->print("} $ftag ;\n");
    }
}

# The following are not methods:

sub isChaining
{
	my ($l) = shift;
	return $#{$l->{'contexts'}} > 0 || $#{$l->{'contexts'}[0]} > 0;
}

sub startsection
{
	my ($fh) = shift;
	$fh->print ("\n\n#**********************************\n");
	map {$fh->print ("#  $_\n")} @_;
	$fh->print ("#**********************************\n");
}

# Find uniq elements of list (in original order order)
# (from http://perlmaven.com/unique-values-in-an-array-in-perl)

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

1;

__END__


=head1 TITLE

volt2fea - generates Adobe FEA file representing a VOLT project

=head1 SYNOPSIS

volt2fea [options] infont outfea

Opens VOLT project (a .ttf file) then writes an equivalent FEA file

=head1 OPTIONS

  -t file     Volt source as text file to use instead of what is in the font
  -h          Help

=head1 DESCRIPTION

volt2fea attempts to convert a VOLT project to an AFDKO feature file.

=head1 BUGS

For anchor attachment lookups this code assumes that any time a rule references
a particular anchor point that all mark glyphs of that class may be included in the 
rule. VOLT authors may have included only the marks that the rule is likely to "see"
but limiting the feature file to such subsets requires lookup-specific markClasses.

This is early code and there are bugs. It understands everything in my Arabic font but does not
yet genereate fully operational FEA code. I would certainly appreciate any examples of
results where you can identify why the FEA file is incorrect.

=head1 AUTHOR

Bob Hallissy <http://scripts.sil.org/FontUtils>. 
(see CONTRIBUTORS for other authors).

=head1 LICENSING

Copyright (c) 1998-2015, SIL International (http://www.sil.org)

This script is released under the terms of the Artistic License 2.0. 
For details, see the full text of the license in the file LICENSE.
    
=cut


