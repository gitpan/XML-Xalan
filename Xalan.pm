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

$VERSION = '0.42';
bootstrap XML::Xalan $VERSION;

@XML::Xalan::DOM::Document::ISA                 = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::DocumentType::ISA             = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::Element::ISA                  = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::Attr::ISA                     = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::CharacterData::ISA            = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::Text::ISA                     = "XML::Xalan::DOM::CharacterData";
@XML::Xalan::DOM::CDATASection::ISA             = "XML::Xalan::DOM::Text";
@XML::Xalan::DOM::Comment::ISA                  = "XML::Xalan::DOM::CharacterData";
@XML::Xalan::DOM::EntityReference::ISA          = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::Entity::ISA                   = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::ProcessingInstruction::ISA    = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::DocumentFragment::ISA         = "XML::Xalan::DOM::Node";
@XML::Xalan::DOM::Notation::ISA                 = "XML::Xalan::DOM::Node";


package XML::Xalan::Transformer;

XML::Xalan::Transformer::initialize();

*errstr = \&XML::Xalan::Transformer::getLastError;
*create_document_builder = *create_doc_builder = \&XML::Xalan::Transformer::createDocumentBuilder;
*destroy_document_builder = *destroy_doc_builder = \&XML::Xalan::Transformer::destroyDocumentBuilder;

sub install_external_function {
    my ($self, $nspace, $funcname, $funchandler, $opt) = @_;
    $self->_install_external_function($nspace, $funcname, $funchandler, 
        defined($opt) && exists($opt->{AutoCast}) ? $opt->{AutoCast} : 0,
        defined($opt) && exists($opt->{Context}) ? $opt->{Context} : 0);
}

*install_function = \&XML::Xalan::Transformer::install_external_function;
*uninstall_function = \&XML::Xalan::Transformer::uninstall_external_function;

package XML::Xalan::ParsedSource;

*get_document = \&XML::Xalan::ParsedSource::getDocument;

package XML::Xalan::DocumentBuilder;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::ParsedSource);

*get_document = \&XML::Xalan::DocumentBuilder::getDocument;
*get_content_handler = \&XML::Xalan::DocumentBuilder::getContentHandler;
*get_dtd_handler = \&XML::Xalan::DocumentBuilder::getDTDHandler;
*get_lexical_handler = \&XML::Xalan::DocumentBuilder::getLexicalHandler;

package XML::Xalan::ContentHandler; #SAX2 content handler

sub start_document {
    shift->startDocument;
}

sub end_document {
    shift->endDocument;
}

sub start_element {
    my ($self, $el) = @_;
    $self->_start_element(
        $el->{NamespaceURI} || '', $el->{LocalName},
        $el->{Name}, $el->{Attributes}); 
}

sub end_element {
    my ($self, $el) = @_;
    $self->_end_element(
        $el->{NamespaceURI} || '', $el->{LocalName},
        $el->{Name});
}

sub characters {
    my ($self, $ch) = @_;
    $self->_characters($ch->{Data});
}

sub ignorable_whitespace {
    my ($self, $ch) = @_;
    $self->_ignorable_whitespace($ch->{Data});
}

sub set_document_locator { }

sub start_prefix_mapping {
    my ($self, $mapping) = @_;
    $self->_start_prefix_mapping(
        $mapping->{Prefix},
        $mapping->{NamespaceURI});
}

sub end_prefix_mapping {
    my ($self, $mapping) = @_;
    $self->_end_prefix_mapping(
        $mapping->{Prefix});
}

sub processing_instruction {
    my ($self, $pi) = @_;
    $self->_processing_instruction(
        $pi->{Target}, $pi->{Data});
}

sub skipped_entity {
    my ($self, $ent) = @_;
    $self->_skipped_entitity($ent->{Name});
}

package XML::Xalan::DTDHandler;

sub notation_decl {
    my ($self, $notation) = @_;
    $self->_notation_decl(
        $notation->{Name},
        $notation->{PublicId},
        $notation->{SystemId});
}

sub unparsed_entity_decl {
    my ($self, $ent) = @_;
    $self->_unparsed_entity_decl(
        $ent->{Name},
        $ent->{PublicId},
        $ent->{SystemId},
        $ent->{Notation});
}

package XML::Xalan::LexicalHandler;

sub start_dtd {
    my ($self, $dtd) = @_;
    $self->_start_dtd(
        $dtd->{Name},
        $dtd->{PublicId},
        $dtd->{SystemId});
}

sub end_dtd {
    shift->endDTD();
}

sub start_entity {
    my ($self, $ent) = @_;
    $self->_start_entity($ent->{Name});
}

sub end_entity {
    my ($self, $ent) = @_;
    $self->_end_entity($ent->{Name});
}

sub start_cdata {
    shift->startCDATA();
}

sub end_cdata {
    shift->endCDATA();
}

sub comment {
    my ($self, $comment) = @_;
    $self->_comment($comment->{Data});
}



# XPath and XSLT classes

package XML::Xalan::XObject;

*string = \&XML::Xalan::XObject::str;
*number = \&XML::Xalan::XObject::num;


package XML::Xalan::Boolean;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);

sub value {
    shift->SUPER::boolean;
}


package XML::Xalan::Number;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);

sub value {
    shift->SUPER::num;
}


package XML::Xalan::String;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);

sub value {
    shift->SUPER::str;
}


package XML::Xalan::Scalar;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);


package XML::Xalan::NodeSet;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);

sub get_nodelist {
    shift->SUPER::nodeset;
}


package XML::Xalan::ResultTreeFragment;
use vars qw(@ISA);
@ISA = qw(XML::Xalan::XObject);

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Xalan - Perl interface to Xalan C++

=head1 SYNOPSIS

  use XML::Xalan;

  my $tr = new XML::Xalan::Transformer;

  my $compiled = $tr->compile_stylesheet_file("foo.xsl");
  my $parsed = $tr->parse_file("foo.xml");

  $tr->transform_to_file($parsed, $compiled, $dest_file)
    or die $tr->errstr;

=head1 DESCRIPTION

Perl interface to the Xalan C++ version 1.2. 
See C<XML::Xalan::Transformer> documentation for further information.

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

C<XML::Xalan::Transformer>(3), C<XML::Xalan::DocumentBuilder>(3),
C<XML::Xalan::DOM>(3).

=cut
