use strict;
use Test;
BEGIN { plan tests => 3 }
use XML::Xalan::Transformer;

my @files = (
    '../samples/docs/bogus.xml', 
    '../samples/docs/foo.xsl',);

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $res = $tr->transform_to_data(@files);
ok(not defined $res);

my $err = $tr->errstr;
ok($err);

#print STDERR "Pesan: ".$err;
