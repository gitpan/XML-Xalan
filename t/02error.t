use strict;
use Test;
BEGIN { plan tests => 4 }
use XML::Xalan;

my $p = XML::Xalan->new();
ok($p);

my $res = $p->parse_stylesheet('./samples/docs/foo.xsl');
ok($res);

my $doc = "./samples/docs/bogus.xml";
$res = $p->transform_to_file($doc, "$doc.out");
ok(not defined $res);

my $err = $p->errstr;
ok($err);
#print STDERR "Pesan kesalahan: ".$p->errstr;
