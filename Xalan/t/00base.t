use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::Xalan::Transformer;
$loaded = 1;
ok(1);

my $tr = XML::Xalan::Transformer->new();
ok($tr);
