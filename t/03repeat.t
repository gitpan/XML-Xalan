use strict;
use Test;
BEGIN { plan tests => 21 }
use XML::Xalan;

my $p = XML::Xalan->new();
ok($p);

my $res = $p->parse_file('./samples/docs/foo.xsl');
ok($res);

my @docs = map { "./samples/docs/foo$_.xml" } (1..9);
for (@docs) {
    $res = $p->transform_to_file($_, "$_.out");
	ok($res);
}

$res = $p->parse_file('./samples/docs/foo.xsl');
ok($res);

for (@docs) {
    $res = $p->transform_to_file($_, "$_.out");
	ok($res);
}
