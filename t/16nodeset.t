use Test;
use strict;
use Data::Dumper;

BEGIN { plan tests => 4 }
use XML::Xalan;

my $file = './samples/docs/proxy.out'; 

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<readings>
    <category name="software development">
        <book>
            <title>Design Patterns</title>
            <author>Gamma, et al</author>
        </book>
        <book>
            <title>Code Complete</title>
            <author>Steve Mc Connell</author>
        </book>
    </category>
    <category name="database">
        <book>
            <title>Open Source XML Database Toolkit</title>
            <author>Liam Quin</author>
        </book>
        <book>
            <title>Database Application Programming with Linux</title>
            <author>Brian Jepson, et al</author>
        </book>
        <paper>
            <title>XML and Databases</title>
            <author>Ronald Bourret</author>
        </paper>
    </category>
</readings>
XML
ok($parsed);

my $xsl = $tr->compile_stylesheet_string(<<"XSL");
<?xml version="1.0"?>
<xsl:stylesheet version = "1.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:ext = "http://ExternalFunction.xalan-c++.xml.apache.org"
    exclude-result-prefixes = "ext"
>
<xsl:output method="html"/>
<xsl:template match="readings">
<html>
<head><title>My Readings</title></head>
<body>
<p>
<h2>Books</h2>
<ol>
<xsl:apply-templates select="ext:proxy(category/book)"/>
</ol>
</p>
<p>
<h2>Papers</h2>
<ol>
<xsl:apply-templates select="category/paper"/>
</ol>
</p>
</body>
</html>
</xsl:template>

<xsl:template match="book|paper">
<xsl:if test='ext:proxy(1 > 0)'>(book)</xsl:if>
<li><xsl:value-of select="title"/></li>
</xsl:template>

</xsl:stylesheet>
XSL
ok($xsl) or die $tr->errstr;

my $namespace = "http://ExternalFunction.xalan-c++.xml.apache.org";
my %functions = (
    'proxy' => sub {
        my ($context, $context_node, $xobj) = @_;
        my $obj_factory = $context->get_xobject_factory;
        
        if (ref $xobj eq "XML::Xalan::NodeSet") {
            my @nodes = $xobj->get_nodelist;
            #print STDERR Dumper(@nodes);

            my $ret = $obj_factory->create_nodeset(@nodes); 
            return $ret;
        } else {
            #print STDERR Dumper $xobj;
            my $ret = $obj_factory->create_boolean($xobj); 
            return $ret;
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

my $res = $tr->transform_to_file($parsed, $xsl, $file);
ok($res) or print STDERR $tr->errstr;

