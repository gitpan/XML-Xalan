use Test;
BEGIN { plan tests => 3 }
use XML::Xalan::Transformer;

my @files = (
    '../samples/docs/foo.xml', 
    '../samples/docs/foo.xsl',
    '../samples/docs/foo.out');
my $tr = new XML::Xalan::Transformer;
ok($tr);
my $res = $tr->transform_to_file(@files);
ok($res);
my $doc = $tr->transform_to_data(@files[0,1]);
ok($doc);
