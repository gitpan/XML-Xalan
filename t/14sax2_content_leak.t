use Test;
use strict;
BEGIN { plan tests => 2 }
use XML::Xalan;
use IO::File;

my @files = (
    './samples/docs/sax2.xml', 
    './samples/docs/foo.xsl',
    './samples/docs/sax2.out');

eval { require XML::SAX::PurePerl; };
my $SKIPPED = $@ ? 1 : 0;
my $SKIPPED_LOOP = 1;

my $tr = new XML::Xalan::Transformer;
ok($tr);

skip($SKIPPED_LOOP, sub {
    for (1..100000) {
        my $db = $tr->create_document_builder;
        my $ch = $db->get_content_handler;

        # create a parser with the content handler
        my $p = XML::SAX::PurePerl->new(
            Handler => $ch
        );

        my $file = IO::File->new($files[0]);
        $p->parse_file($file);
        my $res = $tr->transform_to_file($db, @files[1,2]);
        $tr->destroy_doc_builder($db);
        print STDERR "LOOP $_ passed\n";
    }
});


