use strict;
use Test;
BEGIN { plan tests => 17 }
use XML::Xerces;
use XML::Xerces::ParserLiaison;
use XML::Xalan;

my $parser = new XML::Xerces::DOMParser;
ok($parser);

my $xsl_src = 
	XML::Xerces::MemBufInputSource->new(<<'XSL', 1);
<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="doc">
    <out><xsl:value-of select="."/></out>
  </xsl:template>
</xsl:stylesheet>
XSL
ok($xsl_src);

$parser->parse($xsl_src);
my $dom = $parser->getDocument;
ok($dom);

my $dom_supp = new XML::Xerces::DOMSupport;
ok($dom_supp);

my $p_liaison = new XML::Xerces::ParserLiaison($dom_supp);
ok($p_liaison);

my $p = new XML::Xalan;
ok($p);

my $xsl_doc = $p_liaison->create_document($dom);
ok($xsl_doc);

my $res = $p->parse_stylesheet($xsl_doc);
ok($res);

my @docs = map { "../samples/docs/foo$_.xml" } (1..9);
for (@docs) {
    $res = $p->transform_to_file($_, "$_.out");
	ok($res);
}

