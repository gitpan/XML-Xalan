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
$VERSION = '0.09';

bootstrap XML::Xalan::Transformer $VERSION;
XML::Xalan::Transformer::initialize();

*errstr = \&XML::Xalan::Transformer::getLastError;
*destroy_stylesheet = \&XML::Xalan::Transformer::destroyStylesheet;
*destroy_parsed_source = \&XML::Xalan::Transformer::destroyParsedSource;

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Xalan::Transformer - Perl interface to XalanTransformer class

=head1 SYNOPSIS

  use XML::Xalan::Transformer;

  my $tr = new XML::Xalan::Transformer;

Compiling a stylesheet file:

  my $compiled = $tr->compile_stylesheet_file("foo.xsl");

Compiling a stylesheet string:

  my $compiled = $tr->compile_stylesheet_string(<<"XSLT");
  <?xml version="1.0"?> 
  <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template match="doc">
      <out><xsl:value-of select="."/></out>
    </xsl:template>
  </xsl:stylesheet>
  XSLT

Parsing an XML file:

  my $parsed = $tr->parse_file("foo.xml");

Parsing an XML string:

  my $parsed = $tr->parse_string(<<"XML");
  <?xml version="1.0"?>
  <doc>Hello</doc>
  XML

Performing a transformation and storing the result into a destination file:

  $tr->transform_to_file($src_file, $xsl_file, $dest_file) 
    or die $tr->errstr;

  $tr->transform_to_file($parsed, $xsl_file, $dest_file)
    or die $tr->errstr;

  $tr->transform_to_file($parsed, $compiled, $dest_file)
    or die $tr->errstr;

Performing a transformation and returning the result:

  my $res = $tr->transform_to_data($src_file, $xsl_file);
  die $tr->errstr unless defined $res;      # error checking

  my $res = $tr->transform_to_data($parsed, $xsl_file);
  my $res = $tr->transform_to_data($parsed, $compiled);

=head1 DESCRIPTION

Interface to the XalanTransformer class.

=head1 METHODS

=over 4

=item new()

Constructor, with no argument. Returns an XML::Xalan::Transformer object.

 my $tr = new XML::Xalan::Transformer;

=item $tr->compile_stylesheet_file($xsl_file)

Compiles a stylesheet file and returns an XML::Xalan::CompiledStylesheet object.

 my $compiled = $tr->compile_stylesheet("foo.xsl");

=item $tr->compile_stylesheet_string($xsl_string)

Compiles a stylesheet string and returns an XML::Xalan::CompiledStylesheet object.

 my $compiled = $tr->compile_stylesheet_string(<<"XSLT");
 <?xml version="1.0"?> 
 <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   <xsl:template match="doc">
     <out><xsl:value-of select="."/></out>
   </xsl:template>
 </xsl:stylesheet>
 XSLT

=item $tr->parse_file($xml_file)

Parses an XML file and returns an XML::Xalan::ParsedSource object.

 my $parsed = $tr->parse_file("foo.xml");

=item $tr->parse_string($xml_string)

Parses an XML string and returns an XML::Xalan::ParsedSource object.

 my $parsed = $tr->parse_string(<<"XML");
 <?xml version="1.0"?>
 <doc>Hello</doc>
 XML

=item $tr->transform_to_file($source, $xsl, $dest)

Transforms a source into a specified file. Returns undef on failure.
$source could be an XML::Xalan::ParsedSource object or an XML file.
$xsl could be an XML::Xalan::CompiledStylesheet object or an XSL
file.

 $tr->transform_to_file("foo.xml", "foo.xsl", "bar.xml");

=item $tr->transform_to_data($source, $xsl)

Transforms a source and returns the result. 
$source could be an XML::Xalan::ParsedSource object or an XML file.
$xsl could be an XML::Xalan::CompiledStylesheet object or an XSL file.

Example:

 my $result = $tr->transform_to_data("foo.xml", "foo.xsl");

=item $tr->transform_to_handler($source, $xsl, *FH, $handler)

Transforms a source and pass the result to a callback handler. 
$xsl could be an XML::Xalan::CompiledStylesheet object or an XSL file.

If $xsl is an XML::Xalan::CompiledStylesheet object, then $source B<must> be an
XML::Xalan::ParsedSource object. 

Example:

 $out_handler = sub {
     my ($ctx, $mesg);
     print $ctx $mesg;
 };
 $tr->transform_to_handler(
     $xmlfile, $xslfile, 
     *STDERR, $out_handler);

=item $tr->errstr()

Returns current error string.

=back

=head1 AUTHOR

Edwin Pratomo, edpratomo@cpan.org

=head1 SEE ALSO

XML::Xalan(3).

=cut
