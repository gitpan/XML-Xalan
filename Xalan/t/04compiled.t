use Test;
use strict;
BEGIN { plan tests => 5 }
use XML::Xalan::Transformer;

my @files = (
    '../samples/docs/foo.xml', 
    '../samples/docs/foo.xsl',
    '../samples/docs/foo.out');

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $compiled = $tr->compile_stylesheet_file($files[1]);
ok(defined $compiled);

my $res = $tr->transform_to_file($files[0], $compiled, $files[2]);
ok($res);

$compiled = $tr->compile_stylesheet_string(<<"XSLT");
<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="doc">
    <out><xsl:value-of select="."/></out>
  </xsl:template>
</xsl:stylesheet>
XSLT
ok($compiled);

$res = $tr->transform_to_file($files[0], $compiled, $files[2]);
ok($res);

#print STDERR "Pesan: ". $tr->errstr;
