use Test;
use strict;
use Data::Dumper;
use POSIX qw(strftime pow);

BEGIN { plan tests => 3 }
use XML::Xalan;

my @files = (
    './samples/docs/foo.xml', 
    './samples/docs/external.xsl',
    './samples/docs/external_ctx.out');

my $tr = new XML::Xalan::Transformer;
ok($tr);

my $parsed = $tr->parse_string(<<"XML");
<?xml version="1.0"?>
<doc>
  <area value="397" units="mm"/>
  <now/>
</doc>
XML
ok($parsed);

my $namespace = "http://ExternalFunction.xalan-c++.xml.apache.org";
my %functions = (
    'asctime'   => sub {
        my ($context, $context_node) = @_;
        #print STDERR Dumper($context);
        #print STDERR Dumper($context_node);

        # call DOM method on context node
        #print STDERR "Name of context node: ", $context_node->getNodeName() . "\n";

        my $obj_factory = $context->get_xobject_factory;
        my $ret = $obj_factory->create_string(strftime("%a %b %e %H:%M:%S %Y", localtime)); 
        return $ret; 
   },
    'square-root' => sub {
        my ($context, $context_node, $xobj) = @_;
        #print STDERR Dumper($xobj);

        my $num = $xobj->number;
        #print STDERR "Post converted xobj type: ". Dumper($num);
        #print STDERR "Name of context node: ", $context_node->getNodeName() . "\n";

        my $obj_factory = $context->get_xobject_factory;
        my $ret = $obj_factory->create_number(sqrt($num)); 
        return $ret; 
    },
    'cube'      => sub {
        my ($context, $context_node, $xobj) = @_;
        #print STDERR "xobj inside cube(): ", Dumper($xobj);

        my $doc = $context_node->getOwnerDocument;
        if ($doc) {
            #print STDERR "dump of doc: ", Dumper($doc);
            #print STDERR "Name of document: ", $doc->getNodeName, "\n";
        } else {
            #print STDERR "doc is undef\n";
        }

        #my $num = $xobj->num;
        my $num = $xobj;

        #print STDERR "Name of context node: ", $context_node->getNodeName() . "\n";

        # error handling where Context => 1 hasn't been defined yet.

        #if (@args != 1) {
        #    warn "square-root accepts exactly one arg!";
        #    return undef;
        #} 

        my $obj_factory = $context->get_xobject_factory;
        my $ret = $obj_factory->create_number(pow($num, 3)); 
        return $ret;
    },
);

for (keys %functions) {
    $tr->install_external_function(
        $namespace, 
        $_, 
        $functions{$_}, 
        {Context => 1});
}

my $res = $tr->transform_to_file($parsed, @files[1,2]);
ok($res) or print STDERR $tr->errstr;

