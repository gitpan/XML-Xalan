use Test;
use strict;
BEGIN { plan tests => 3 }
use XML::Xalan::Transformer;

my @files = (
    '../samples/docs/foo.xml', 
    '../samples/docs/param.xsl',
    '../samples/docs/param.out');

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc>Hello</doc>
XML
ok($parsed);

$tr->set_stylesheet_param("start", "'asdfafdaf'");

my $res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res);
