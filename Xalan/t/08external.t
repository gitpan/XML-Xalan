use Test;
use strict;
use POSIX qw(strftime pow);

BEGIN { plan tests => 4 }
use XML::Xalan::Transformer;

my @files = (
    '../samples/docs/foo.xml', 
    '../samples/docs/external.xsl',
    '../samples/docs/external.out');

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc>
  <area value="397" units="mm"/>
  <now/>
</doc>
XML
ok($parsed);

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

for (keys %functions) {
    $tr->install_external_function($namespace, $_, $functions{$_});
}

my $res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res) or print STDERR $tr->errstr;

# now, uninstall 'asctime' function..

$tr->uninstall_external_function($namespace, 'asctime');
$res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res) or print STDERR $tr->errstr;
