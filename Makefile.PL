use strict;
use ExtUtils::MakeMaker;
use Config;
use IO::File;
use Getopt::Std;

our ($opt_d, $opt_r, $opt_v);
getopts('d:rv:');
$opt_v ||= 1;

my ($VERSION, $fversion, @extras, @scripts, @theselibs, $fhi, $fho, $perlbin);

$VERSION = "1.04_92";

# Fix up inno script by substituting {perl: $var}

$fversion = $VERSION;
$fversion =~ s/\./_/og;
$perlbin = $Config{'sitebin'};

@scripts = grep {-f && !m/\./o && !m/~$/o } glob("scripts/*");
@scripts = grep {!m|/add[^_]|oi} @scripts unless ($^O eq 'MSWin32');

@theselibs = grep {-f } glob("lib/Font/Scripts/*");


if ($^O eq 'MSWin32') {
	
	# incantation to enable MY::pm_to_blib later on
	push(@ExtUtils::MakeMaker::Overridable, qw(pm_to_blib));
	@extras = (dist => { 'TO_UNIX' => 'perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"' });
	
	# incantation to solve the problem of everyone's $Config{make} being 'nmake'
	# when we want 'pmake'. And $Config{} is read only.
	# actually, this is just a copy of the code from ExtUtiles::MM_Win32 tidied
	# up (to expose tabs) and the dependency on Config removed
	
	*MY::pm_to_blib = sub
	{
	    my $self = shift;
	    my($autodir) = $self->catdir('$(INST_LIB)','auto');
	    return <<"EOT";

pm_to_blib: \$(TO_INST_PM)
\t$self->{NOECHO}\$(PERL) \"-I\$(INST_ARCHLINE)\" \"-I\$(INST_LIB)\" \\
\t\"-I\$(PERL_ARCHLIB)\" \"-I\$(PERL_LIB)\" -MExtUtils::Install \\
\t-e \"pm_to_blib({ qw[\$(PM_TO_BLIB)] }, '$autodir')
\t$self->{NOECHO}\$(TOUCH) \$@

EOT
	};
	
	*MY::postamble = sub
	{
	    my (@files) = map {m|scripts/(.*)$|o; $1;} @scripts;
	    my ($res, $fh, $files, $compile);
	    
	    $files = join (' ', grep {$_ ne 'addpath'} @files);
	    $files =~ s/addpath\.bat\s*//o;     # remove addpath since don't need a .bat
	    $fh = IO::File->new("> addbats.pl") || die "Can't create addbats.pl";
	    
	    $fh->print(<<"EOT");
#! perl
foreach \$f (qw($files))
{
    if (\$ARGV[0] eq '-r')
    {
        unlink "\$ARGV[1]\\\\\$f.bat";
    }
    else
    {
        open(FH, "> \$ARGV[0]\\\\\$f.bat") || die \$@;
        print FH <<\"EOB\";
\\\@echo off
if "%OS%" == "Windows_NT" goto WinNT
"\$ARGV[0]\\\\parl.exe" "\$ARGV[0]\\\\fontutils.par" \$f %1 %2 %3 %4 %5 %6 %7 %8 %9
goto end
:WinNT
"\$ARGV[0]\\\\parl.exe" "\$ARGV[0]\\\\fontutils.par" \$f %*
:end
EOB
        close(FH);
    }
}
EOT
	    $fh->close();
	    
	    push (@scripts, "addbats.pl");
	
		my $Registry;
		require Win32::TieRegistry;
		Win32::TieRegistry->import (Delimiter=>"/") ;
		$compile = $Registry->{'Classes/InnoSetupScriptFile/shell/Compile/command//'};
		$compile =~ s/\s*"?%1"?.*$//;
		$compile = "start \"compile\" /wait $compile";
	
	    $res .= "exe : TTFontUtils_$fversion.exe\n\n";
	
	    $res .= "TTFontUtils_$fversion.exe : scripts\\fontutils.par\n";
	    $res .= "\tiscc.exe \"/dMyVer=$VERSION\" \"/dParlPath=$perlbin\" FontUtils.iss\n\n";
	    
	    $res .= "scripts\\fontutils.par : ";
	    $res .= join(' ', @scripts);
	    $res .= "\n\tpp -B -p -c -o scripts\\fontutils.par -M Font::TTF::Useall " . join(' ', @scripts);
	    $res .= "\n\n";
	    
	    $res;
	};
}
elsif ($^O eq 'linux')
{

	*MY::postamble = sub
	{
	    my ($self) = @_;
	    my ($res);
	    my ($package) = lc($self->{'NAME'});
		my ($pversion) = $self->{'VERSION'};
	    my ($svn) = `svnversion`;
		my ($sign) = '--auto-debsign' if ($opt_r);
	    my ($fpackage);
	
        $svn =~ s/\s+$//o;
        if ($svn and $svn ne "exported")
        {
    	    $svn =~ s/[0-9]*://og;
        }
        else
        {
            $svn = `hg identify -n`;
            $svn =~ s/\+?\s+$//o;
        }
	    $package =~ s/::/-/g;
	    $package = "lib${package}-perl";
	    $pversion .= "+$svn" unless ($opt_r);
	    $fpackage = "$package-$pversion";
	
	    $res = <<"EOT";
debsrc: dist
	rm -fr $self->{'DISTVNAME'}
	rm -fr $package
	rm -fr $fpackage
	tar xvzf $self->{'DISTVNAME'}.tar.gz
	cp -r $self->{'DISTVNAME'} $package
	tar cvzf ${package}_${pversion}.orig.tar.gz $package
	cp -r $package $fpackage
	cp -a debian $fpackage
	cd $fpackage && dch -v $pversion "interim dev release" && dpkg-buildpackage -S

# make deb builds an interim deb from svn source for release
deb: debsrc
EOT

	    foreach my $d (split(' ', $opt_d))
	    {
	    	$res .= <<"EOT";
	mkdir -p dists/$d	
	#dch -D $d -v $pversion-$opt_v -m -b -c $fpackage/debian/changelog "Auto build from perl for $d"
	#cd $fpackage && pdebuild --buildresult ../dists/$d -- --basetgz /var/cache/pbuilder/base-$d.tgz \$pbuilderopts{$d}
EOT
	    }
	
	    return $res;
	};

}

    
WriteMakefile (
        NAME => "Font::TTF::Scripts",
        VERSION => $VERSION,
        EXE_FILES => \@scripts,
#        HTMLLIBPODS => {map {my $t = $_; $t=~s/\..*?$/.html/o; $t='blib/Html/'.$t; $_ => $t;} @theselibs},
#        HTMLSCRIPTPODS => {map {my $t=$_; $t=~s/\..*?$/.html/o; $t='blib/Html/'.$t; $_ => $t;} @scripts},
        AUTHOR => "martin_hosken\@sil.org",
        ABSTRACT => "TTF font support scripts for Perl",
        LICENSE => "artistic_2",
		PREREQ_PM => {
			'Algorithm::Diff' => 0,
            'IO::String' => 0,
			'Font::TTF' => '1.04_90',
			'Text::PDF::File' => 0,
            'Text::Unicode::Equivalents' => 0,
            'XML::Parser' => 0
			},
        @extras
    );
