# base class.
package Driver::Xalan;

use Driver::BaseClass;
@ISA = qw(Driver::BaseClass);

use XML::Xalan;

use vars qw(
        $tr
        $compiled
        $input
        );

sub init {
    $tr = XML::Xalan::Transformer->new();
}

sub load_stylesheet {
    $tr->destroy_stylesheet($compiled) if defined $compiled;
    $compiled = $tr->compile_stylesheet_file(shift);
}

sub load_input {
    $tr->destroy_parsed_source($input) if defined $input;
    $input = $tr->parse_file(shift);
}

sub run_transform {
    $tr->transform_to_file($input, $compiled, shift);
#    print STDERR "\n";
}

1;
