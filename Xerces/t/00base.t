use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }
use XML::Xerces;
$loaded = 1;
ok(1);

