
#
#   Copyright (c) 2001-2002 Edwin Pratomo
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#

use 5.005;
use ExtUtils::MakeMaker 5.16, qw(prompt &WriteMakefile $Verbose);
use Config;
use strict;
use vars qw($Registry);

my %config;
my $vc_dir;
my $os = $Config{osname};

if ($os eq 'MSWin32') {

    # try to find Microsoft Visual C++ compiler
    # (borrow Peter F. Wilkinson's code in DBD::InterBase's Makefile.PL)
    eval 
    {
        require Win32::TieRegistry;
        Win32::TieRegistry->import('$Registry');
        $Registry->Delimiter("/");

        my $sw = $Registry->{"LMachine/Software/"};

        # We have to check more than one keys, because different
        # releases of Visual C++ have used different key hierarchies.
        my $key = 
            $sw->{"Microsoft/VisualStudio/6.0/Setup/Microsoft Visual C++"} ||
            $sw->{"Microsoft/VisualStudio/7.0/Setup/VC"};

        if (defined($key)) 
        { 
            $vc_dir = $key->{"/ProductDir"}; 
        }
    };

    $vc_dir = prompt("MSVC++ directory: ", $vc_dir);
    unless (-x $vc_dir){
        die "I can't find your MS VC++ installation.\nUnable to build XML::Xalan.\n";
    }

    my $vc_lib = $vc_dir . '\lib'; 

    my $cur_libs = $Config{'libs'};
    my $cur_lddlflags = $Config{'lddlflags'};

    my $xalan_lib = 'C:\xml-xalan\c\Build\Win32\VC6\Release';
    my $xalan_inc = 'C:\xml-xalan\c\src';
    my $xerces_lib = 'C:\xml-xerces\c\Build\Win32\VC6\Release';
    my $xerces_inc = 'C:\xml-xerces\c\src';
    
    $xalan_lib = prompt("Xalan C++ LIBS directory: ", $xalan_lib);
    $xalan_inc = prompt("Xalan C++ INC directory: ", $xalan_inc);
    
    $xerces_lib = prompt("Xerces C++ LIBS directory: ", $xerces_lib);
    $xerces_inc = prompt("Xerces C++ INC directory: ", $xerces_inc);
    
    $config{INC}        = "-I$xalan_inc -I$xerces_inc ";
    $config{DEFINE}     = '-D_WINDOWS -D_MBCS -D_REENTRANT -D_EXPERIMENTAL';
    $config{CCFLAGS}    = '/W1 /GR /GX /Ob2 '.$Config{ccflags};

    eval qq[
sub MY::const_loadlibs {
    '
LDLOADLIBS = $xalan_lib\\XalanTransformer.lib \\
    $xalan_lib\\DOMSupport.lib \\
    $xalan_lib\\XercesParserLiaison.lib \\
    $xalan_lib\\PlatformSupport.lib \\
    $xalan_lib\\XPath.lib \\
    $xalan_lib\\XSLT.lib \\
    $xalan_lib\\XalanDOM.lib \\
    $xalan_lib\\XMLSupport.lib \\
    $xalan_lib\\XalanSourceTree.lib \\
    $xerces_lib\\xerces-c_1.lib \\
    $xalan_lib\\XalanExtensions.lib \\
    $cur_libs
LDDLFLAGS = /LIBPATH:\"$vc_lib\" $cur_lddlflags msvcprt.lib
    '
}
];

} elsif ($os eq 'linux') {

    die <<'DEATH' unless $ENV{XALANCROOT};
$ENV{XALANCROOT} not found. 
This env var should point to directoy where Xalan installed, ie. 
which contains the src and lib subdirectories of Xalan

DEATH

    die <<'DEATH' unless $ENV{XERCESCROOT};
$ENV{XERCESCROOT} not found. 
This env var should point to directoy where Xerces installed, ie. 
which contains include and lib subdirectories of Xerces

DEATH

    $config{INC}        = "-I$ENV{XALANCROOT}/src -I$ENV{XERCESCROOT}/include ";
    $config{LIBS}       =<< "LIBS";
-lc -L$ENV{XALANCROOT}/lib -lxalan-c1_3  -L/usr/lib
-L/usr/local/lib
LIBS
    $config{DEFINE}     = '-DLINUX -D_REENTRANT -DNDEBUG -D_EXPERIMENTAL';
    $config{CC}         = 'c++';
    $config{LD}         = 'g++';
    $config{CCFLAGS}    = '-instances=static',

} else {
    die <<"MSG";
Building XML::Xalan on $os isn't yet supported. 
MSG
}

WriteMakefile(
    'NAME'  => 'XML::Xalan',
    'AUTHOR'    => 'Edwin Pratomo (edwin@poskanzer.org)',
    'ABSTRACT'  => 'Perl interface to Xalan C++',
    'VERSION_FROM' => 'Xalan.pm', # finds $VERSION
    'OBJECT'    => '$(O_FILES)',
     'clean'    => {FILES => "Xalan.cpp samples/docs/*.out"},
    %config,
);

# overriden MakeMaker methods:
sub MY::manifypods {
    package MY;
    my $str = shift->SUPER::manifypods(@_);
}


sub MY::perldepend {
    package MY;
    my $str = shift->SUPER::perldepend(@_);
    $str =~ s/Xalan\.c\b/Xalan.cpp/mg;
    return $str;
}

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
    '
}

__END__
