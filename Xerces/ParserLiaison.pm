package XML::Xerces::ParserLiaison;

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
$VERSION = '0.06';

bootstrap XML::Xerces::ParserLiaison $VERSION;

sub new {
    my ($class, $dom_supp_ref) = @_;
    my $self = {
        core => new XML::Xerces::_ParserLiaison($dom_supp_ref),
        dom_supp_ref => $dom_supp_ref,
    };
    bless $self, $class;
}

sub create_document {
    my ($self, $dom) = @_;
    $self->{core}->create_document($dom);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Xerces::ParserLiaison - Perl interface to XercesParserLiaison class

=head1 SYNOPSIS

  use XML::Xalan;
  use XML::Xerces;
  use XML::Xerces::ParserLiaison;

  my $parser = new XML::Xerces::DOMParser;
  $parser->parse(new XML::Xerces::LocalFileInputSource($src_file));

  # create Xerces ParserLiaison
  my $pl = new XML::Xerces::ParserLiaison(new XML::Xerces::DOMSupport);

  # create an XML::Xalan::Document object from the parsed document
  my $doc = $p_liaison->create_document($parser->getDocument);

=head1 DESCRIPTION

This module connects XML::Xalan and XML::Xerces.

=head1 METHODS

=over 4

=item new($xerces_dom_supp)

Constructor, takes an XML::Xerces::DOMSupport object as the argument. 
Return an XML::Xalan::Transformer object.

 my $dom_supp = new XML::Xerces::DOMSupport;
 my $pl = new XML::Xerces::ParserLiaison($dom_supp);

=item $pl->create_document($dom)

Takes a DOM tree, and returns an XML::Xalan::Document.

 my $parser = new XML::Xerces::DOMParser;
 my $input_src = XML::Xerces::LocalFileInputSource->new($src_file);
 $parser->parse($input_src);
 my $xalan_doc = $pl->create_document($parser->getDocument);

=back

=head1 BUGS

There's no error handling yet. Will be added soon.

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

XML::Xalan(3), XML::Xerces(3).

=cut
