use Test;
use strict;
BEGIN { plan tests => 7 }
use XML::Xalan;

my @files = (
    './samples/docs/sax2.xml', 
    './samples/docs/foo.xsl',
    './samples/docs/sax2.out');

eval { require XML::SAX::PurePerl; };
my $SKIPPED = $@ ? 1 : 0;

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $db = $tr->create_document_builder;
ok($db);

my $ch = $db->get_content_handler;
ok($ch);

# create a parser with the content handler
my $p;

skip($SKIPPED, sub {
    $p= XML::SAX::PurePerl->new(
        Handler => $ch);
});

skip($SKIPPED, sub {
    $p->parse_uri($files[0]);
    1;
});

skip($SKIPPED, sub {
    my $res = $tr->transform_to_file($db, @files[1,2]);
    $res;
});

# reuse and destroy the doc builder
skip($SKIPPED, sub {
    my $res = $tr->transform_to_file($db, @files[1,2]);
    $tr->destroy_doc_builder($db);
    $res;
});

