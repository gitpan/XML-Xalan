use Test;
use strict;
BEGIN { plan tests => 11 }
use XML::Xalan::Transformer;

my $res;
my $stylesheet = '../samples/docs/foo.xsl';
my @docs = map { "../samples/docs/foo$_.xml" } (1..9);

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $compiled = $tr->compile_stylesheet_file($stylesheet);
ok(defined $compiled);

for (@docs) {
    $res = $tr->transform_to_file($_, $compiled, "$_.out");
    ok($res);
}

#print STDERR "Pesan: ". $tr->errstr;
