use Test;
use strict;
BEGIN { plan tests => 22 }
use XML::Xalan;

my $res;
my $stylesheet = './samples/docs/foo.xsl';
my @docs = map { "./samples/docs/foo$_.xml" } (1..9);

my $tr = new XML::Xalan::Transformer;
ok($tr);

# compiles file and do multiple transforms..
my $compiled = $tr->compile_stylesheet_file($stylesheet);
ok(defined $compiled);

for (@docs) {
    $res = $tr->transform_to_file($_, $compiled, "$_.out");
    ok($res);
}
$res = $tr->destroy_stylesheet($compiled);
ok($res);

# now compiles string and do multiple transforms..
$compiled = $tr->compile_stylesheet_string(<<"XSLT");
<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="doc">
    <out><xsl:value-of select="."/></out>
  </xsl:template>
</xsl:stylesheet>
XSLT
ok($compiled);

for (@docs) {
    $res = $tr->transform_to_file($_, $compiled, "$_.out");
    ok($res);
}

