<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs"
  extension-element-prefixes="ixsl"
  version="3.0"
  >
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- 
       Note: The XHTML namespace is required for matching input elements
       this is counter to the SaxonJS documentation/samples
  -->
  <xsl:import href="style.xsl"/>
  <xsl:variable name="Result.replace" as="xs:string" select="'replace'"/>
  <xsl:variable name="Result.append" as="xs:string" select="'append'"/>
  <xsl:variable name="Result.clear" as="xs:string" select="'clear'"/>
  <xsl:param name="method" as="xs:string"/>
  
  <xsl:template match="/">
    <xsl:message select="'root message'"/>
    <xsl:choose>
      <xsl:when test="$method eq $Result.clear">
        <xsl:result-document href="#main" method="ixsl:replace-content">
          <xsl:sequence select="' '"/>
        </xsl:result-document>
      </xsl:when>
      <xsl:when test="$method eq $Result.replace">
        <xsl:result-document href="#main" method="ixsl:replace-content">
          <xsl:apply-templates select="*"/>
        </xsl:result-document>
      </xsl:when>
      <xsl:when test="$method eq $Result.append">
        <xsl:result-document href="#main" method="ixsl:append-content">
          <xsl:apply-templates select="*"/>
        </xsl:result-document>
        <ixsl:schedule-action wait="5">
          <xsl:call-template name="scrollToEnd"/>
        </ixsl:schedule-action>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="scrollToEnd">
    <xsl:sequence select="ixsl:call(id('end', ixsl:page()), 'scrollIntoView', [])"/>
  </xsl:template>
  
  
  <xsl:template match="*:title[contains(.,'Section Title')]"/>
  <xsl:template match="*:title[contains(.,'Replace this')]"/>
  
</xsl:transform>	
