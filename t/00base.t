use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::Xalan;
$loaded = 1;
ok(1);

my $p = XML::Xalan->new();
ok($p);
