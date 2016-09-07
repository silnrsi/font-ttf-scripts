use strict;
use File::Spec::Functions;
use Pod::Usage;
use Getopt::Std;

# And to retrieve version info:
use Font::TTF;
use Font::TTF::Scripts;

our ($opt_l);
getopts('l') || pod2usage(2);

my $which;

if ($opt_l)
{
	# List available scripts:
	print "Available commands:\n";
	my $d = $ENV{'PAR_TEMP'} ? catfile($ENV{'PAR_TEMP'}, 'inc', 'script') : 'scripts';
	foreach my $f (glob catfile($d, '*'))
	{
		(undef,undef,$which) = File::Spec->splitpath($f);
		next if $which =~/^(?:fontutils|main|addpath|addbats)/oi;
		print "    $which\n" if $which;
	}
	exit 0;
}
	
my $which = shift @ARGV;

unless ($which)
{
	pod2usage( -verbose => 2, -noperldoc => 1 , -exitval => 'NOEXIT');
	print "HISTORY\n\n    This instance is using following module versions:\n";
	print "      Font::TTF          v", $Font::TTF::VERSION, "\n";
	print "      Font::TTF::Scripts v", $Font::TTF::Scripts::VERSION, "\n";
	exit (1);
}

#retrieve only the filename part, stripping out any path info:
(undef,undef,$which) = File::Spec->splitpath( $which );

# allow execution from PAR-packaged exe or from source:
my $script = catfile($ENV{'PAR_TEMP'} ? catfile($ENV{'PAR_TEMP'}, 'inc', 'script') : 'scripts', $which);

pod2usage("'$which' is not a recognized FontUtils script") unless -f $script && -r $script;

# Update $0 and, if necessary, PAR::Packer's record of it so that pod2usage works:
$0 = $script;
$ENV{'PAR_0'} = $script if $ENV{'PAR_TEMP'};

# Now invoke the target script
my $rc = do $script;

# Note about return value from do, from perldoc:
#   If do can read the file but cannot compile it, it returns undef and sets 
#   an error message in $@ . If do cannot read the file, it returns undef and 
#   sets $! to the error. Always check $@ first, as compilation could fail in 
#   a way that also sets $! . If the file is successfully compiled, do returns 
#   the value of the last expression evaluated.
# Because it is possible that the "last expression evaluated" resulted in undef,
# we can't assume and undef result means error, but must also test $@ and $!

die $@ ? "$@\n" : "$!\n" if !defined $rc && ($@ || $!);  # script not found, failed to compile etc

exit(0);                   # in case script didn't call exit() itself

=head1 NAME

fontutils - Font::TTF::Scripts master program for Windows binary

=head1 SYNOPSIS

  fontutils command [arguments...]
  fontutils -l

Executes named command with provided arguments. With -l, lists available commands.

=head1 EXAMPLES

  % fontutils ttf2woff -m meta.xml in.ttf out.woff          # run ttf2woff
  % fontutils ttftable -l -v font.ttf                       # run ttftable
  % fontutils make_gdl -a attach.xml infont.ttf out.gdl     # run make_gdl

=head1 DESCRIPTION

When packaged as a Windows binary along with the other scripts and dependencies from 
Font::TTF::Scripts, this file serves as the master program and its sole function is 
to launch one of the other scripts.

=head1 AUTHOR

Bob Hallissy L<http://scripts.sil.org/FontUtils>.
(see CONTRIBUTORS for other authors).

=head1 LICENSING

Copyright (c) 2016, SIL International (http://www.sil.org)

This script is released under the terms of the Artistic License 2.0.
For details, see the full text of the license in the file LICENSE.

=cut
