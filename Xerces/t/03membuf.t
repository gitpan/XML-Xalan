use strict;
use Test;
BEGIN { plan tests => 9 }
use XML::Xerces;
use XML::Xerces::ParserLiaison;
use XML::Xalan;

my $parser = new XML::Xerces::DOMParser;
ok($parser);

my $input_src = 
	XML::Xerces::MemBufInputSource->new(<<'XML', 1);
<?xml version="1.0"?>
<doc>Hello</doc>
XML
ok($input_src);

$parser->parse($input_src);
my $dom = $parser->getDocument;
ok($dom);

my $dom_supp = new XML::Xerces::DOMSupport;
ok($dom_supp);

my $p_liaison = new XML::Xerces::ParserLiaison($dom_supp);
ok($p_liaison);

my $p = new XML::Xalan;
ok($p);

my $res = $p->parse_stylesheet('../samples/docs/foo.xsl');
ok($res);

my $doc = $p_liaison->create_document($dom);
ok($doc);

$res = $p->transform_doc_to_data($doc);
ok($res);

print $res;
