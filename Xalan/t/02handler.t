use Test;
BEGIN { plan tests => 2 }
use XML::Xalan::Transformer;

my @files = (
	'../samples/docs/foo.xml', 
	'../samples/docs/foo.xsl',);

my $out_handler = sub {
    my ($ctx, $mesg) = @_;
    print $ctx $mesg;
};

my $tr1 = new XML::Xalan::Transformer;
ok($tr1);

my $res = $tr1->transform_to_handler(@files,
    STDERR, $out_handler);
ok($res);
