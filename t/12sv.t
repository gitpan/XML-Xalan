use Test;
use strict;
use Data::Dumper;

BEGIN { plan tests => 3 }
use XML::Xalan;

my @files = (
    './samples/docs/foo.xml', 
    './samples/docs/external.xsl',
    './samples/docs/sv.out');

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc/>
XML
ok($parsed);

my $namespace = "http://ExternalFunction.xalan-c++.xml.apache.org";
my %functions = (
    'create-obj'   => sub {
        return Dummy->new();
    },
    'accept-obj' => sub {
        #print STDERR Dumper(shift);
        return 1;
    },
);

for (keys %functions) {
    $tr->install_external_function($namespace, $_, $functions{$_});
}

my $compiled = $tr->compile_stylesheet_string(<<'XSLT');
<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:external="http://ExternalFunction.xalan-c++.xml.apache.org"
        exclude-result-prefixes="external">
  <xsl:template match="doc">
    <xsl:variable name="scalar" select="external:create-obj()"/>
    <xsl:value-of select="external:accept-obj($scalar)"/>
  </xsl:template>
</xsl:stylesheet>
XSLT

my $res = $tr->transform_to_file($parsed, $compiled, $files[2]);
ok($res) or print STDERR $tr->errstr;

package Dummy;

sub new { return bless {}, shift }

