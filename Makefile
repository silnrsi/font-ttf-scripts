# This Makefile is for the Font::TTF::Scripts extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.17 (Revision: 1.133) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#
#   MakeMaker Parameters:

#     ABSTRACT => q[TTF font support scripts for Perl]
#     AUTHOR => q[martin_hosken@sil.org]
#     EXE_FILES => [q[scripts/Addfont], q[scripts/addpath], q[scripts/check_attach], q[scripts/eurofix], q[scripts/fret], q[scripts/hackos2], q[scripts/make_gdl], q[scripts/make_volt], q[scripts/make_volt.bak], q[scripts/psfix], q[scripts/thai2gdl], q[scripts/thai2ot], q[scripts/thai2volt], q[scripts/ttfbuilder], q[scripts/ttfenc], q[scripts/ttfname], q[scripts/ttfremap], q[scripts/volt2xml]]
#     NAME => q[Font::TTF::Scripts]
#     PM => { lib/Font/Scripts/Thai.pm=>q[$(INST_LIB)/Font/Scripts/Thai.pm], lib/Font/Scripts/AP.pm=>q[$(INST_LIB)/Font/Scripts/AP.pm], lib/Font/Scripts/GDL_old.pm=>q[$(INST_LIB)/Font/Scripts/GDL_old.pm], lib/Font/Scripts/GDL.pm=>q[$(INST_LIB)/Font/Scripts/GDL.pm], lib/Font/Scripts/Volt.pm=>q[$(INST_LIB)/Font/Scripts/Volt.pm] }
#     VERSION => q[0.2]
#     dist => { TO_UNIX=>q[perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via D:/Progs/perl/lib/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = lib
CC = cl
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = dll
DLSRC = dl_win32.xs
LD = link
LDDLFLAGS = -dll -nologo -nodefaultlib -debug -opt:ref,icf  -libpath:"D:\progs\perl\lib\CORE"  -machine:x86
LDFLAGS = -nologo -nodefaultlib -debug -opt:ref,icf  -libpath:"D:\progs\perl\lib\CORE"  -machine:x86
LIBC = msvcrt.lib
LIB_EXT = .lib
OBJ_EXT = .obj
OSNAME = MSWin32
OSVERS = 4.0
RANLIB = rem
SITELIBEXP = D:\progs\perl\site\lib
SITEARCHEXP = D:\progs\perl\site\lib
SO = dll
EXE_EXT = .exe
FULL_AR = 
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = ^\
NAME = Font::TTF::Scripts
NAME_SYM = Font_TTF_Scripts
VERSION = 0.2
VERSION_MACRO = VERSION
VERSION_SYM = 0_2
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.2
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib\arch
INST_SCRIPT = blib\script
INST_BIN = blib\bin
INST_LIB = blib\lib
INST_MAN1DIR = blib\man1
INST_MAN3DIR = blib\man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = 
PERLPREFIX = D:\progs\perl
SITEPREFIX = D:\progs\perl\site
VENDORPREFIX = 
INSTALLPRIVLIB = $(PERLPREFIX)\lib
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = $(SITEPREFIX)\lib
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = $(PERLPREFIX)\lib
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = $(SITEPREFIX)\lib
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(PERLPREFIX)\bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = D:\progs\perl\bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(PERLPREFIX)\bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLMAN1DIR = none
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(SITEPREFIX)\man\man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = none
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(SITEPREFIX)\man\man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = D:\progs\perl\lib
PERL_ARCHLIB = D:\progs\perl\lib
LIBPERL_A = libperl.lib
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = $(FIRST_MAKEFILE).old
MAKE_APERL_FILE = $(FIRST_MAKEFILE).aperl
PERLMAINCC = $(CC)
PERL_INC = D:\progs\perl\lib\CORE
PERL = D:\Progs\perl\bin\perl.exe
FULLPERL = D:\Progs\perl\bin\perl.exe
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = D:/Progs/perl/lib/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.17
MM_REVISION = 1.133

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Font\TTF\Scripts
BASEEXT = Scripts
PARENT_NAME = Font::TTF
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DIRFILESEP)Config.pm $(PERL_INC)$(DIRFILESEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)\Font\TTF
INST_ARCHLIBDIR  = $(INST_ARCHLIB)\Font\TTF

INST_AUTODIR     = $(INST_LIB)\auto\$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)\auto\$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = $(BASEEXT).def
PERL_ARCHIVE       = $(PERL_INC)\perl58.lib
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Font/Scripts/AP.pm \
	lib/Font/Scripts/GDL.pm \
	lib/Font/Scripts/GDL_old.pm \
	lib/Font/Scripts/Thai.pm \
	lib/Font/Scripts/Volt.pm

PM_TO_BLIB = lib/Font/Scripts/Thai.pm \
	$(INST_LIB)/Font/Scripts/Thai.pm \
	lib/Font/Scripts/AP.pm \
	$(INST_LIB)/Font/Scripts/AP.pm \
	lib/Font/Scripts/GDL_old.pm \
	$(INST_LIB)/Font/Scripts/GDL_old.pm \
	lib/Font/Scripts/GDL.pm \
	$(INST_LIB)/Font/Scripts/GDL.pm \
	lib/Font/Scripts/Volt.pm \
	$(INST_LIB)/Font/Scripts/Volt.pm


# --- MakeMaker platform_constants section:
MM_Win32_VERSION = 1.09


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERLRUN)  -e "use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)"



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
CHMOD = $(PERLRUN) -MExtUtils::Command -e chmod
CP = $(PERLRUN) -MExtUtils::Command -e cp
MV = $(PERLRUN) -MExtUtils::Command -e mv
NOOP = rem
NOECHO = @
RM_F = $(PERLRUN) -MExtUtils::Command -e rm_f
RM_RF = $(PERLRUN) -MExtUtils::Command -e rm_rf
TEST_F = $(PERLRUN) -MExtUtils::Command -e test_f
TOUCH = $(PERLRUN) -MExtUtils::Command -e touch
UMASK_NULL = umask 0
DEV_NULL = > NUL
MKPATH = $(PERLRUN) "-MExtUtils::Command" -e mkpath
EQUALIZE_TIMESTAMP = $(PERLRUN) "-MExtUtils::Command" -e eqtime
ECHO = $(PERLRUN) -l -e "print qq{@ARGV}"
ECHO_N = $(PERLRUN)  -e "print qq{@ARGV}"
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(PERLRUN) -MExtUtils::Install -e "install({@ARGV}, '$(VERBINST)', 0, '$(UNINST)');"
DOC_INSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e perllocal_install
UNINSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e uninstall
WARN_IF_OLD_PACKLIST = $(PERLRUN) "-MExtUtils::Command::MM" -e warn_if_old_packlist


# --- MakeMaker makemakerdflt section:
makemakerdflt: all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Font-TTF-Scripts
DISTVNAME = Font-TTF-Scripts-0.2


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:
PASTHRU = -nologo

# --- MakeMaker special_targets section:
.SUFFIXES: .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) $(INST_LIBDIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_ARCHAUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_AUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

$(INST_AUTODIR)\.exists :: D:\progs\perl\lib\CORE\perl.h
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) D:\progs\perl\lib\CORE\perl.h $(INST_AUTODIR)\.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_AUTODIR)

$(INST_LIBDIR)\.exists :: D:\progs\perl\lib\CORE\perl.h
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) D:\progs\perl\lib\CORE\perl.h $(INST_LIBDIR)\.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_LIBDIR)

$(INST_ARCHAUTODIR)\.exists :: D:\progs\perl\lib\CORE\perl.h
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) D:\progs\perl\lib\CORE\perl.h $(INST_ARCHAUTODIR)\.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)

help:
	perldoc ExtUtils::MakeMaker


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:

Scripts.def: Makefile.PL
	$(PERLRUN) -MExtUtils::Mksymlists \
     -e "Mksymlists('NAME'=>\"Font::TTF::Scripts\", 'DLBASE' => '$(BASEEXT)', 'DL_FUNCS' => {  }, 'FUNCLIST' => [], 'IMPORTS' => {  }, 'DL_VARS' => []);"


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all 
	$(NOECHO) $(NOOP)




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

$(INST_SCRIPT)\.exists :: D:\progs\perl\lib\CORE\perl.h
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) D:\progs\perl\lib\CORE\perl.h $(INST_SCRIPT)\.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)

EXE_FILES = scripts/Addfont scripts/addpath scripts/check_attach scripts/eurofix scripts/fret scripts/hackos2 scripts/make_gdl scripts/make_volt scripts/make_volt.bak scripts/psfix scripts/thai2gdl scripts/thai2ot scripts/thai2volt scripts/ttfbuilder scripts/ttfenc scripts/ttfname scripts/ttfremap scripts/volt2xml

FIXIN = pl2bat.bat

pure_all :: $(INST_SCRIPT)\volt2xml $(INST_SCRIPT)\make_volt $(INST_SCRIPT)\thai2volt $(INST_SCRIPT)\ttfname $(INST_SCRIPT)\thai2gdl $(INST_SCRIPT)\ttfbuilder $(INST_SCRIPT)\ttfremap $(INST_SCRIPT)\addpath $(INST_SCRIPT)\make_volt.bak $(INST_SCRIPT)\check_attach $(INST_SCRIPT)\fret $(INST_SCRIPT)\hackos2 $(INST_SCRIPT)\thai2ot $(INST_SCRIPT)\ttfenc $(INST_SCRIPT)\eurofix $(INST_SCRIPT)\Addfont $(INST_SCRIPT)\make_gdl $(INST_SCRIPT)\psfix
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) $(INST_SCRIPT)\volt2xml $(INST_SCRIPT)\make_volt $(INST_SCRIPT)\thai2volt $(INST_SCRIPT)\ttfname $(INST_SCRIPT)\thai2gdl $(INST_SCRIPT)\ttfbuilder $(INST_SCRIPT)\ttfremap $(INST_SCRIPT)\addpath $(INST_SCRIPT)\make_volt.bak $(INST_SCRIPT)\check_attach $(INST_SCRIPT)\fret $(INST_SCRIPT)\hackos2 $(INST_SCRIPT)\thai2ot $(INST_SCRIPT)\ttfenc $(INST_SCRIPT)\eurofix $(INST_SCRIPT)\Addfont $(INST_SCRIPT)\make_gdl $(INST_SCRIPT)\psfix

$(INST_SCRIPT)\volt2xml: scripts/volt2xml $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\volt2xml
	$(CP) scripts/volt2xml $(INST_SCRIPT)\volt2xml
	$(FIXIN) $(INST_SCRIPT)\volt2xml
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\volt2xml

$(INST_SCRIPT)\make_volt: scripts/make_volt $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\make_volt
	$(CP) scripts/make_volt $(INST_SCRIPT)\make_volt
	$(FIXIN) $(INST_SCRIPT)\make_volt
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\make_volt

$(INST_SCRIPT)\thai2volt: scripts/thai2volt $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\thai2volt
	$(CP) scripts/thai2volt $(INST_SCRIPT)\thai2volt
	$(FIXIN) $(INST_SCRIPT)\thai2volt
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\thai2volt

$(INST_SCRIPT)\ttfname: scripts/ttfname $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\ttfname
	$(CP) scripts/ttfname $(INST_SCRIPT)\ttfname
	$(FIXIN) $(INST_SCRIPT)\ttfname
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\ttfname

$(INST_SCRIPT)\thai2gdl: scripts/thai2gdl $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\thai2gdl
	$(CP) scripts/thai2gdl $(INST_SCRIPT)\thai2gdl
	$(FIXIN) $(INST_SCRIPT)\thai2gdl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\thai2gdl

$(INST_SCRIPT)\ttfbuilder: scripts/ttfbuilder $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\ttfbuilder
	$(CP) scripts/ttfbuilder $(INST_SCRIPT)\ttfbuilder
	$(FIXIN) $(INST_SCRIPT)\ttfbuilder
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\ttfbuilder

$(INST_SCRIPT)\ttfremap: scripts/ttfremap $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\ttfremap
	$(CP) scripts/ttfremap $(INST_SCRIPT)\ttfremap
	$(FIXIN) $(INST_SCRIPT)\ttfremap
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\ttfremap

$(INST_SCRIPT)\addpath: scripts/addpath $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\addpath
	$(CP) scripts/addpath $(INST_SCRIPT)\addpath
	$(FIXIN) $(INST_SCRIPT)\addpath
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\addpath

$(INST_SCRIPT)\make_volt.bak: scripts/make_volt.bak $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\make_volt.bak
	$(CP) scripts/make_volt.bak $(INST_SCRIPT)\make_volt.bak
	$(FIXIN) $(INST_SCRIPT)\make_volt.bak
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\make_volt.bak

$(INST_SCRIPT)\check_attach: scripts/check_attach $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\check_attach
	$(CP) scripts/check_attach $(INST_SCRIPT)\check_attach
	$(FIXIN) $(INST_SCRIPT)\check_attach
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\check_attach

$(INST_SCRIPT)\fret: scripts/fret $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\fret
	$(CP) scripts/fret $(INST_SCRIPT)\fret
	$(FIXIN) $(INST_SCRIPT)\fret
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\fret

$(INST_SCRIPT)\hackos2: scripts/hackos2 $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\hackos2
	$(CP) scripts/hackos2 $(INST_SCRIPT)\hackos2
	$(FIXIN) $(INST_SCRIPT)\hackos2
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\hackos2

$(INST_SCRIPT)\thai2ot: scripts/thai2ot $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\thai2ot
	$(CP) scripts/thai2ot $(INST_SCRIPT)\thai2ot
	$(FIXIN) $(INST_SCRIPT)\thai2ot
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\thai2ot

$(INST_SCRIPT)\ttfenc: scripts/ttfenc $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\ttfenc
	$(CP) scripts/ttfenc $(INST_SCRIPT)\ttfenc
	$(FIXIN) $(INST_SCRIPT)\ttfenc
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\ttfenc

$(INST_SCRIPT)\eurofix: scripts/eurofix $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\eurofix
	$(CP) scripts/eurofix $(INST_SCRIPT)\eurofix
	$(FIXIN) $(INST_SCRIPT)\eurofix
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\eurofix

$(INST_SCRIPT)\Addfont: scripts/Addfont $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\Addfont
	$(CP) scripts/Addfont $(INST_SCRIPT)\Addfont
	$(FIXIN) $(INST_SCRIPT)\Addfont
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\Addfont

$(INST_SCRIPT)\make_gdl: scripts/make_gdl $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\make_gdl
	$(CP) scripts/make_gdl $(INST_SCRIPT)\make_gdl
	$(FIXIN) $(INST_SCRIPT)\make_gdl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\make_gdl

$(INST_SCRIPT)\psfix: scripts/psfix $(FIRST_MAKEFILE) $(INST_SCRIPT)\.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)\psfix
	$(CP) scripts/psfix $(INST_SCRIPT)\psfix
	$(FIXIN) $(INST_SCRIPT)\psfix
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)\psfix


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	-$(RM_RF) ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all $(INST_ARCHAUTODIR)/extralibs.ld perlmain.c tmon.out mon.out so_locations pm_to_blib *$(OBJ_EXT) *$(LIB_EXT) perl.exe perl perl$(EXE_EXT) $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def lib$(BASEEXT).def $(BASEEXT).exp $(BASEEXT).x core core.*perl.*.? *perl.core core.[0-9] core.[0-9][0-9] core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9][0-9]
	-$(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)
clean ::
	-$(RM_F) *.pdb



# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean realclean_subdirs
	$(RM_RF) $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	$(RM_RF) $(DISTVNAME)
	$(RM_F)  $(INST_LIB)/Font/Scripts/AP.pm $(INST_LIB)/Font/Scripts/Volt.pm $(INST_LIB)/Font/Scripts/GDL.pm $(MAKEFILE_OLD) $(FIRST_MAKEFILE) $(INST_LIB)/Font/Scripts/GDL_old.pm $(INST_LIB)/Font/Scripts/Thai.pm


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(ECHO) "# http://module-build.sourceforge.net/META-spec.html" > META.yml
	$(NOECHO) $(ECHO) "#XXXXXXX This is a prototype!!!  It will change in the future!!! XXXXX#" >> META.yml
	$(NOECHO) $(ECHO) "name:         Font-TTF-Scripts" >> META.yml
	$(NOECHO) $(ECHO) "version:      0.2" >> META.yml
	$(NOECHO) $(ECHO) "version_from: " >> META.yml
	$(NOECHO) $(ECHO) "installdirs:  site" >> META.yml
	$(NOECHO) $(ECHO) "requires:" >> META.yml
	$(NOECHO) $(ECHO) "" >> META.yml
	$(NOECHO) $(ECHO) "distribution_type: module" >> META.yml
	$(NOECHO) $(ECHO) "generated_by: ExtUtils::MakeMaker version 6.17" >> META.yml


# --- MakeMaker metafile_addtomanifest section:
metafile_addtomanifest:
	$(NOECHO) $(PERLRUN) -MExtUtils::Manifest=maniadd -e "eval { maniadd({q{META.yml} => q{Module meta-data (added by MakeMaker)}}) } \
    or print \"Could not add META.yml to MANIFEST: $${'@'}\n\""


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ *.orig */*~ */*.orig



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(PERLRUN) -l -e "print 'Warning: Makefile possibly out of date with $(VERSION_FROM)'\
    if -e '$(VERSION_FROM)' and -M '$(VERSION_FROM)' < -M '$(FIRST_MAKEFILE)';"

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
distdir : metafile metafile_addtomanifest
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"



# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)


# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker install section:

install :: all pure_install doc_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_vendor :: all pure_vendor_install doc_vendor_install

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)\auto\$(FULLEXT)\.packlist \
		write $(DESTINSTALLARCHLIB)\auto\$(FULLEXT)\.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)\auto\$(FULLEXT)


pure_site_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)\auto\$(FULLEXT)\.packlist \
		write $(DESTINSTALLSITEARCH)\auto\$(FULLEXT)\.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)\auto\$(FULLEXT)

pure_vendor_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)\auto\$(FULLEXT)\.packlist \
		write $(DESTINSTALLVENDORARCH)\auto\$(FULLEXT)\.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)\perllocal.pod

doc_site_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)\perllocal.pod

doc_vendor_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)\perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)\auto\$(FULLEXT)\.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)\auto\$(FULLEXT)\.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)\auto\$(FULLEXT)\.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	-$(MAKE) -f $(MAKEFILE_OLD) clean $(DEV_NULL) || $(NOOP)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the make command.  <=="
	false



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = D:\Progs\perl\bin\perl.exe

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = 
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)
	$(NOECHO) $(ECHO) 'No tests defined for $(NAME) extension.'

test_dynamic :: pure_all

testdb_dynamic :: pure_all
	$(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	$(NOECHO) $(ECHO) "<SOFTPKG NAME=\"$(DISTNAME)\" VERSION=\"0,2,0,0\">" > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "    <TITLE>$(DISTNAME)</TITLE>" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "    <ABSTRACT>TTF font support scripts for Perl</ABSTRACT>" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "    <AUTHOR>martin_hosken@sil.org</AUTHOR>" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "    <IMPLEMENTATION>" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "        <OS NAME=\"$(OSNAME)\" />" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "        <ARCHITECTURE NAME=\"MSWin32-x86-multi-thread-5.8\" />" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "        <CODEBASE HREF=\"\" />" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "    </IMPLEMENTATION>" >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) "</SOFTPKG>" >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERL) "-I$(INST_ARCHLINE)" "-I$(INST_LIB)" \
	"-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Install \
	-e "pm_to_blib({ qw[$(PM_TO_BLIB)] }, '$(INST_LIB)\auto')
	@$(TOUCH) $@



# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:
exe : TTFontUtils_0_2.exe

TTFontUtils_0_2.exe : scripts\fontutils.par
	\progs\minno_setup3\compil32.exe /cc FontUtils.iss

scripts\fontutils.par : scripts/Addfont scripts/addpath scripts/check_attach scripts/eurofix scripts/fret scripts/hackos2 scripts/make_gdl scripts/make_volt scripts/make_volt.bak scripts/psfix scripts/thai2gdl scripts/thai2ot scripts/thai2volt scripts/ttfbuilder scripts/ttfenc scripts/ttfname scripts/ttfremap scripts/volt2xml addbats.pl
	pp -B -p -o scripts\fontutils.par scripts/Addfont scripts/addpath scripts/check_attach scripts/eurofix scripts/fret scripts/hackos2 scripts/make_gdl scripts/make_volt scripts/make_volt.bak scripts/psfix scripts/thai2gdl scripts/thai2ot scripts/thai2volt scripts/ttfbuilder scripts/ttfenc scripts/ttfname scripts/ttfremap scripts/volt2xml addbats.pl



# End.
