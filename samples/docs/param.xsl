<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
version="1.0">
  <xsl:param name="start">1</xsl:param>
  <xsl:template match="doc">
    <out><xsl:value-of select="."/></out>
    <number><xsl:value-of select="$start"/></number>
  </xsl:template>
</xsl:stylesheet>
