use ExtUtils::MakeMaker 5.16, qw(prompt &WriteMakefile $Verbose);
use Config;
use strict;

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

my $inc = "-I$ENV{XALANCROOT}/src -I$ENV{XERCESCROOT}/include ";
my $libs =<< "LIBS";
-lc -L$ENV{XALANCROOT}/lib -lxalan-c1_2  -L/usr/lib
-L/usr/local/lib
LIBS

WriteMakefile(
    'NAME'	=> 'XML::Xalan::Transformer',
	'AUTHOR'	=> 'Edwin Pratomo (ed.pratomo@computer.org)',
	'ABSTRACT'	=> 'Perl interface to XalanTransformer class',
    'VERSION_FROM' => 'Transformer.pm', # finds $VERSION
    'CC'    => 'c++', 
	'LD'    => 'g++',
    'OPTIMIZE'  => '-O2',
	'CCFLAGS'	=> '-instances=static',
    'LIBS'	=> [$libs],   # e.g., '-lm' 
    'DEFINE'	=> '-DLINUX -D_REENTRANT -DNDEBUG',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $inc,     # e.g., '-I/usr/include/other' 
#	'TEST_FILES' => 't/*.t',
);
