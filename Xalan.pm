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
$VERSION = '0.32';
bootstrap XML::Xalan $VERSION;

package XML::Xalan::Transformer;

XML::Xalan::Transformer::initialize();

*errstr = \&XML::Xalan::Transformer::getLastError;
*create_document_builder = *create_doc_builder = \&XML::Xalan::Transformer::createDocumentBuilder;
*destroy_document_builder = *destroy_doc_builder = \&XML::Xalan::Transformer::destroyDocumentBuilder;

package XML::Xalan::DocumentBuilder;

*get_content_handler = \&XML::Xalan::DocumentBuilder::getContentHandler;

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

C<XML::Xalan::Transformer>(3), C<XML::Xalan::DocumentBuilder>(3).

=cut
