package XML::Xalan;

#
#   Copyright (c) 2001 Edwin Pratomo
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
$VERSION = '0.09';

bootstrap XML::Xalan $VERSION;
XML::Xalan::initialize();

# Preloaded methods go here.

sub new {
    my ($class) = @_;
    my $dom = new XML::Xalan::DOMSupport;
    my $parser_liaison = new XML::Xalan::ParserLiaison(\$dom);

    my $self = {        
        ObjectFactory   => new XML::Xalan::ObjectFactory,
        XPathFactory    => {
            Processor   => new XML::Xalan::XPathFactory,
            Stylesheet  => new XML::Xalan::XPathFactory,
        },
        ParserLiaison   => $parser_liaison,
        DOMSupport      => $dom, # support objects must stay alive
        Error           => '',
    };

    # make env 
    my $env = new XML::Xalan::ProcessorEnvSupport;

    # make processor
    $self->{Processor} = XML::Xalan::XSLTEngineImpl->new(
        \$self->{ParserLiaison}, \$env, \$dom,
        \$self->{ObjectFactory},
        \$self->{XPathFactory}->{Processor});

    # create execution and construction contexts
    # exec context uses the same object factory as the processor's
    @{$self}{'ExecutionCtx', 'ConstructionCtx', 'EnvSupport'} = (
        XML::Xalan::ExecutionContext->new(\$self->{Processor}, 
            \$env, \$self->{DOMSupport}, 
            \$self->{ObjectFactory}),
        XML::Xalan::ConstructionContext->new(\$self->{Processor}, 
            \$env, \$self->{XPathFactory}->{Stylesheet}),
        $env,
    );

    $self->{DOMSupport}->set_parser_liaison($self->{ParserLiaison});

    # init the env to this processor
    $self->{EnvSupport}->set_processor($self->{Processor});

    bless $self, $class;
}

sub parse_stylesheet {
    my ($self, $xalan_doc) = @_;
    $self->{StyleRoot} = $self->{Processor}->_process_stylesheet(
        $xalan_doc, $self->{ConstructionCtx});
    return $self->{StyleRoot} ? 1 : undef;
}

sub parse_file {
    my ($self, $xsl_file) = @_;
    $self->{StyleRoot} = $self->{Processor}->_process_file(
        $xsl_file, $self->{ConstructionCtx});
    return $self->{StyleRoot} ? 1 : undef;
}

sub transform_to_file {
    my ($self, $xml_in, $xml_out) = @_;
    die "No stylesheet parsed" unless $self->{StyleRoot};

    $self->{ExecutionCtx}->set_stylesheet_root($self->{StyleRoot});
    my $ret = $self->{Processor}->_transform_to_file($xml_in, $xml_out, 
        $self->{ExecutionCtx}, \$self->{Error});

    # reset for next reuse
    $self->{Processor}->reset;
    $self->{ExecutionCtx}->reset;
    $self->{ParserLiaison}->reset;
    $ret;
}

sub transform_doc_to_file {
    my ($self, $xalan_doc, $xml_out) = @_;
    die "No stylesheet parsed" unless $self->{StyleRoot};

    $self->{ExecutionCtx}->set_stylesheet_root($self->{StyleRoot});
    my $ret = $self->{Processor}->_transform_doc_to_file(
        $xalan_doc, $xml_out, $self->{ExecutionCtx}, \$self->{Error});

    # reset for next reuse
    $self->{Processor}->reset;
    $self->{ExecutionCtx}->reset;
    $self->{ParserLiaison}->reset;
    $ret;
}

sub transform_to_data {
    my ($self, $xml_in) = @_;
    die "No stylesheet parsed" unless $self->{StyleRoot};

    $self->{ExecutionCtx}->set_stylesheet_root($self->{StyleRoot});
    my $result = $self->{Processor}->_transform_to_data(
        $xml_in, $self->{ExecutionCtx}, \$self->{Error});

    # reset for next reuse
    $self->{Processor}->reset;
    $self->{ExecutionCtx}->reset;
    $self->{ParserLiaison}->reset;
    $result;
}

# transform a Xalan document
sub transform_doc_to_data {
    my ($self, $xalan_doc) = @_;
    die "No stylesheet parsed" unless $self->{StyleRoot};

    $self->{ExecutionCtx}->set_stylesheet_root($self->{StyleRoot});
    my $result = $self->{Processor}->_transform_doc_to_data(
        $xalan_doc, $self->{ExecutionCtx}, \$self->{Error});

    # reset for next reuse
    $self->{Processor}->reset;
    $self->{ExecutionCtx}->reset;
    $self->{ParserLiaison}->reset;
    $result;
}


sub set_stylesheet_param {
    my ($self, $key, $val) = @_;
    $self->{Processor}->_set_stylesheet_param(
        $key, $val, \$self->{Error});
}

sub errstr {
    shift->{Error};
}

package XML::Xalan::DOMSupport;

*new = \&XML::Xalan::_DOMSupport::new;

sub set_parser_liaison {
    my ($self, $parser_liaison) = @_;
    XML::Xalan::_DOMSupport::setParserLiaison($self, $parser_liaison->{core});
}

*DESTROY = \&XML::Xalan::_DOMSupport::DESTROY;

package XML::Xalan::ParserLiaison;

sub new {
    my ($class, $dom_ref) = @_;
    my $self = { 
        core => new XML::Xalan::_ParserLiaison($dom_ref),
        dom_ref => $dom_ref,
    };
    bless $self, $class;
}

sub reset {
    shift->{core}->reset;
}

package XML::Xalan::XSLTEngineImpl;

sub new {
    my ($class, $parser_liaison_ref, $env_ref, $dom_ref, $obj_fac_ref,
        $xpath_fac_ref) = @_;
    bless {
        core => new XML::Xalan::_XSLTEngineImpl(
            \${$parser_liaison_ref}->{core}, 
            $env_ref, $dom_ref, $obj_fac_ref, $xpath_fac_ref),
        parser_liaison_ref  => $parser_liaison_ref,
        env_ref             => $env_ref,
        dom_ref             => $dom_ref,
        obj_fac_ref         => $obj_fac_ref,
        xpath_fac_ref       => $xpath_fac_ref,
    }, $class;
}

sub _process_stylesheet {
    shift->{core}->_processStylesheet(shift, shift->{core});
}

sub _process_file {
    shift->{core}->_processFile(shift, shift->{core});
}

sub _set_stylesheet_param {
    my ($self, $key, $val, $err) = @_;
    $self->{core}->_set_stylesheet_param($key, $val, $self->{Error});
}

sub _transform_to_file {
    my ($self, $xml_in, $xml_out, $ExecCtx, $err) = @_;
    $self->{core}->_transform_to_file(
        $xml_in, $xml_out, $ExecCtx->{core}, $err);
}

sub _transform_doc_to_file {
    my ($self, $doc, $xml_out, $ExecCtx, $err) = @_;
    $self->{core}->_transform_doc_to_data(
        $doc, $xml_out, $ExecCtx->{core}, $err);
}

sub _transform_to_data {
    my ($self, $xml_in, $ExecCtx, $err) = @_;
    $self->{core}->_transform_to_data($xml_in, $ExecCtx->{core}, $err);
}

sub _transform_doc_to_data {
    my ($self, $doc, $ExecCtx, $err) = @_;
    $self->{core}->_transform_doc_to_data($doc, $ExecCtx->{core}, $err);
}

sub reset {
    shift->{core}->reset;
}

package XML::Xalan::ExecutionContext;

sub new {
    my ($class, $p_ref, $env_ref, $dom_ref, $obj_fac_ref) = @_;
    my $self = {
        core => XML::Xalan::_ExecutionContext->new(
            \${$p_ref}->{core}, 
            $env_ref, $dom_ref, 
            $obj_fac_ref),
        p_ref       => $p_ref,
        env_ref     => $env_ref,
        dom_ref     => $dom_ref,
        obj_fac_ref => $obj_fac_ref,
    };
    bless $self, $class;
}

sub set_stylesheet_root {
    my $self = shift;
    $self->{core}->setStylesheetRoot(shift);
}

sub reset {
    shift->{core}->reset;
}

package XML::Xalan::ConstructionContext;

sub new {
    my ($class, $p_ref, $env_ref, $xpath_fac_ref) = @_;
    my $self = {
        core => XML::Xalan::_ConstructionContext->new(
            \${$p_ref}->{core}, 
            $env_ref, $xpath_fac_ref),
        p_ref           => $p_ref,
        env_ref         => $env_ref,
        xpath_fac_ref   => $xpath_fac_ref,
    };
    bless $self, $class;
}

package XML::Xalan::ProcessorEnvSupport;

sub set_processor {
    my ($self, $proc) = @_;
    $self->setProcessor($proc->{core});
}

package XML::Xalan;

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Xalan - Perl interface to Xalan

=head1 SYNOPSIS

  use XML::Xalan;

  $p = new XML::Xalan;
  $p->parse_file($xsl_file);
  $p->transform_to_file($src_file, $dest_file);
    or die $p->errstr;
  my $res = $p->transform_to_data($src_file);

=head1 DESCRIPTION

This module provides easy-to-use object oriented interface on top of several 
Xalan classes, as well as interfaces to those classes.

=head1 METHODS

=over 4

=item new()

Constructor, with no argument. Returns an XML::Xalan object.

 $p = new XML::Xalan;

=item $p->parse_file($xsl_file)

Takes a path to the stylesheet file as the argument, parses it and stores the result 
internally for further usages. Example:

 $p->parse_file('./samples/docs/foo.xsl');

=item $p->parse_stylesheet($xsl_doc)

Same as parse_file(), but takes an XML::Xalan::Document object instead as
the argument. 

See the documentation of XML::Xerces::ParserLiaison on how to get an
XML::Xalan::Document object.

=item $p->transform_to_file($src_file, $dest_file)

Takes an XML document as input, and writes the output to the specified file. 
Returns undef on failure. The following takes foo.xml and writes to bar.xml:

 $p->transform_to_file("foo.xml", "bar.xml")
   or die $p->errstr;

=item $p->transform_to_data($src_file)

Returns the transformed document on success, otherwise returns undef.

 $result = $p->transform_to_data("foo.xml");
 die $p->errstr unless defined $result;

=item $p->transform_doc_to_file($xalan_doc, $dest_file)

Takes an XML::Xalan::Document object as the input, and writes the result to
$dest_file. Returns TRUE on success, otherwise returns undef.

See the documentation of XML::Xerces::ParserLiaison for details on using this 
method.

=item $p->transform_doc_to_data($xalan_doc)

Takes an XML::Xalan::Document object as the input, and returns the
transformation result. Returns undef on error.

See the documentation of XML::Xerces::ParserLiaison for details on using this 
method.

=item $p->errstr()

Returns current error string.

=back

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

XML::Xerces::ParserLiaison(3), XML::Xalan::Transformer(3).

=cut
