use Test;
use strict;
use Data::Dumper;

BEGIN { plan tests => 3 }
use XML::Xalan;

my $file = './samples/docs/external_err.out';

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

my $compiled = $tr->compile_stylesheet_string(<<'XSL');
<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:ext="http://ExternalFunction.xalan-c++.xml.apache.org"
        exclude-result-prefixes="ext">
  <xsl:template match="area">
    <result>
    The length of each side is <xsl:value-of select="ext:square-root(@value,'foo')"/>.
    </result>
  </xsl:template>
</xsl:stylesheet>
XSL


my $namespace = "http://ExternalFunction.xalan-c++.xml.apache.org";
my %functions = (
    'square-root' => sub {
        my ($context, $context_node, @args) = @_;

        if (@args != 1) {
            warn "square-root accepts exactly one arg!";
            return undef;
        } else {
            my $num = $args[0]->num;

            #print STDERR "Post converted xobj type: ". Dumper($num);
            #print STDERR "Name of context node: ", $context_node->getNodeName() . "\n";

            my $obj_factory = $context->get_xobject_factory;
            return $obj_factory->create_number(sqrt($num)); 
        }
    },
);

for (keys %functions) {
    $tr->install_external_function(
        $namespace, 
        $_, 
        $functions{$_}, 
        {Context => 1});
}

my $res = $tr->transform_to_file($parsed, $compiled, $file);
ok($res); # expected failure

