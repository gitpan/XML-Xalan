use Test;
use strict;
use POSIX qw(strftime pow);

BEGIN { plan tests => 1 }
use XML::Xalan;

my $SKIPPED = 1;
my @files = (
    './samples/docs/foo.xml', 
    './samples/docs/external.xsl',
    './samples/docs/external.out');

my $tr = new XML::Xalan::Transformer;

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc>
  <area value="397" units="mm"/>
  <now/>
</doc>
XML

my $namespace = "http://ExternalFunction.xalan-c++.xml.apache.org";
my %functions = (
    'asctime'   => sub {
        return strftime("%a %b %e %H:%M:%S %Y", localtime); 
    },
    'square-root' => sub {
        my @args = @_;
        # print STDERR join(", ", @args)."\n";
        return sqrt $args[0];
    },
    'cube'      => sub {
        my @args = @_;
        if (@args != 1) {
            warn "square-root accepts exactly one arg!";
            return undef;
        } 
        return pow($args[0], 3);
    },
);

skip($SKIPPED, sub {

    for (1..100000) {

        print "No: $_\n";
        print "Installing ..\n";

        for (keys %functions) {
            $tr->install_external_function($namespace, $_, $functions{$_});
        }

        print "Finished installing\n";

        my $res = $tr->transform_to_data($parsed, $files[1]) or die $tr->errstr;

        print "Finished transforming\n";
        # now, uninstall 

        $tr->uninstall_external_function($namespace, 'asctime');
        $tr->uninstall_external_function($namespace, 'square-root');
        $tr->uninstall_external_function($namespace, 'cube');
    }
});
