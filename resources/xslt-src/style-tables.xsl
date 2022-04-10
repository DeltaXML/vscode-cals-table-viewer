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
  
  <xsl:template match="/">
    <xsl:message select="'root message'"/>  
    <xsl:result-document href="#main">
      <xsl:apply-templates select="*"/>
    </xsl:result-document>
    <ixsl:schedule-action wait="5">
      <xsl:call-template name="scroll"/>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template name="scroll">
    <xsl:sequence select="ixsl:call(id('end', ixsl:page()), 'scrollIntoView', [])"/>
  </xsl:template>

  
  <xsl:template match="*:title[contains(.,'Section Title')]"/>
  <xsl:template match="*:title[contains(.,'Replace this')]"/>
  
</xsl:transform>	
