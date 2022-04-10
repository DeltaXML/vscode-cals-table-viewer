<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:deltaxml="http://www.deltaxml.com/ns/well-formed-delta-v1"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">
  
  <xsl:output method="xml" indent="no"/>
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:param name="ordered-row" as="xs:boolean"/>
  <xsl:param name="ordered-col" as="xs:boolean"/>
  
  <xsl:template match="tbody" mode="#all">
    <xsl:copy>
      <xsl:attribute name="deltaxml:ordered" select="$ordered-row"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="*:tgroup" mode="#all">
    <xsl:copy>
      <xsl:attribute name="deltaxml:table-columns-ordered" select="$ordered-col"/>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entrytbl" mode="#all">
    <xsl:copy>
      <xsl:attribute name="deltaxml:table-columns-ordered" select="$ordered-col"/>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>