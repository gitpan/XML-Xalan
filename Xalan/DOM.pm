package XML::Xalan::DOM;

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
@EXPORT = qw(
    UNKNOWN_NODE
    ELEMENT_NODE
    ATTRIBUTE_NODE
    TEXT_NODE
    CDATA_SECTION_NODE
    ENTITY_REFERENCE_NODE
    ENTITY_NODE
    PROCESSING_INSTRUCTION_NODE
    COMMENT_NODE
    DOCUMENT_NODE
    DOCUMENT_TYPE_NODE
    DOCUMENT_FRAGMENT_NODE
    NOTATION_NODE
);

$VERSION = '0.01';

# DOM Node types

sub UNKNOWN_NODE                () { 0 }        # not in the DOM Spec

sub ELEMENT_NODE                () { 1 }
sub ATTRIBUTE_NODE              () { 2 }
sub TEXT_NODE                   () { 3 }
sub CDATA_SECTION_NODE          () { 4 }
sub ENTITY_REFERENCE_NODE       () { 5 }
sub ENTITY_NODE                 () { 6 }
sub PROCESSING_INSTRUCTION_NODE () { 7 }
sub COMMENT_NODE                () { 8 }
sub DOCUMENT_NODE               () { 9 }
sub DOCUMENT_TYPE_NODE          () { 10}
sub DOCUMENT_FRAGMENT_NODE      () { 11}
sub NOTATION_NODE               () { 12}

1;

=head1 NAME

XML::Xalan::DOM - Exports DOM node type constants

=head1 SYNOPSIS

  use XML::Xalan;
  use XML::Xalan::DOM;
  ...
  
  my $parsed = $tr->parse_file($files);
  my $dom = $parsed->get_document();
  my $root = $dom->getDocumentElement();
  my $node = $element->getFirstChild();

  if ($node->getNodeType() == ELEMENT_NODE) {
      print "Node is of type XML::Xalan::DOM::Element\n";
  }

=head1 DESCRIPTION

This module exports the following constants which represent DOM node types:

  UNKNOWN_NODE(0)                   an unknown node
  ELEMENT_NODE(1)                   an Element node
  ATTRIBUTE_NODE(2)                 an Attribute node
  TEXT_NODE(3)                      a Text node
  CDATA_SECTION_NODE(4)             a CDATASection node
  ENTITY_REFERENCE_NODE(5)          an EntityReference node
  ENTITY_NODE(6)                    an Entity node
  PROCESSING_INSTRUCTION_NODE(7)    a ProcessingInstruction node
  COMMENT_NODE(8)                   a Comment node
  DOCUMENT_NODE(9)                  a Document node
  DOCUMENT_TYPE_NODE(10)            a DocumentType node
  DOCUMENT_FRAGMENT_NODE(11)        a DocumentFragment node
  NOTATION_NODE(12)                 a Notation node

Note that DOM interface in Xalan C++ 1.2 hasn't been finished yet. Some
methods are known to simply return 0.

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

C<XML::Xalan::Transformer>(3), C<XML::Xalan::DocumentBuilder>(3), C<XML::Xalan::ParsedSource>(3).

=cut

