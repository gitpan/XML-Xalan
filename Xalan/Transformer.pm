package XML::Xalan::Transformer;

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

bootstrap XML::Xalan::Transformer $VERSION;
XML::Xalan::Transformer::initialize();

*errstr = \&XML::Xalan::Transformer::getLastError;

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Xalan::Transformer - Perl interface to XalanTransformer class

=head1 SYNOPSIS

  use XML::Xalan::Transformer;

  my $tr = new XML::Xalan::Transformer;
  $tr->transform_to_file($src_file, $xsl_file, $dest_file) 
    or die $tr->errstr;
  my $res = $tr->transform_to_data($src_file, $xsl_file);
  die $tr->errstr unless defined $res;

=head1 DESCRIPTION

Interface to the XalanTransformer class.

=head1 METHODS

=over 4

=item new()

Constructor, with no argument. Return an XML::Xalan::Transformer object.

 my $tr = new XML::Xalan::Transformer;

=item $tr->transform_to_file($source, $xsl_file, $dest)

Transform a source file into a specified file. Returns undef on failure.

 $tr->transform_to_file("foo.xml", "foo.xsl", "bar.xml");

=item $tr->transform_to_data($source, $xsl_file)

Returns the transformed document. Example:

 my $result = $tr->transform_to_data("foo.xml", "foo.xsl");

=item $tr->transform_to_handler($source, $xsl, FH, $handler)

Example:

 $out_handler = sub {
     my ($ctx, $mesg);
     print $ctx $mesg;
 };
 $tr->transform_to_handler(
     $xmlfile, $xslfile, 
     STDERR, $out_handler);

=item $tr->errstr()

Returns current error string.

=back

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

XML::Xalan(3).

=cut
