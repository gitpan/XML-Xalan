use Test;
use strict;
BEGIN { plan tests => 7 }
use XML::Xalan;
use IO::File;

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

# create filehandle and parse it
my $file = IO::File->new($files[0]);
ok($file);

skip($SKIPPED, sub {
    $p->parse_file($file);
    1;
});

skip($SKIPPED, sub {
    my $res = $tr->transform_to_file($db, @files[1,2]);
    $tr->destroy_doc_builder($db);
    $res;
});


