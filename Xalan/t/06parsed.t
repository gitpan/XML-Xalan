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

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc>Hello</doc>
XML
ok($parsed);

my $res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res);

$parsed = $tr->parse_file($files[0]);
ok($parsed);

$res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res);
