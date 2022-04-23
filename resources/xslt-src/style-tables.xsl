<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:err="http://www.w3.org/2005/xqt-errors"
  exclude-result-prefixes="xs"
  extension-element-prefixes="ixsl"
  expand-text="yes"
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
  <xsl:param name="sourceText" as="xs:string*"/>
  <xsl:param name="sourceFilename" as="xs:string*"/>
  
  <xsl:template name="main">
    <xsl:message select="'main method: ' || $method"/>
    <xsl:message select="'file count: ' || count($sourceFilename)"/>
    <xsl:message select="'sourceFilename', $sourceFilename"/>
    <xsl:choose>
      <xsl:when test="$method eq $Result.clear">
        <xsl:result-document href="#main" method="ixsl:replace-content">
          <xsl:sequence select="' '"/>
        </xsl:result-document>
      </xsl:when>
      <xsl:when test="$method eq $Result.replace">
        <xsl:result-document href="#main" method="ixsl:replace-content">
          <xsl:for-each select="1 to count($sourceFilename)">
            <xsl:variable name="index" as="xs:integer" select="."/>  
            <p class="headerText"><xsl:value-of select="$sourceFilename[$index]"/></p>
            <xsl:call-template name="applyToFile"/>
            <hr class="headerText"/>
          </xsl:for-each>
        </xsl:result-document>
      </xsl:when>
      <xsl:when test="$method eq $Result.append">
        <xsl:for-each select="1 to count($sourceFilename)">
          <xsl:variable name="index" as="xs:integer" select="."/>  
          <xsl:result-document href="#main" method="ixsl:append-content">
            <p class="headerText"><xsl:value-of select="$sourceFilename[$index]"/></p>            
            <xsl:call-template name="applyToFile"/>
            <hr class="headerText"/>
          </xsl:result-document>
        </xsl:for-each>
        <ixsl:schedule-action wait="5">
          <xsl:call-template name="scrollToEnd"/>
        </ixsl:schedule-action>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="applyToFile">
    <xsl:variable name="index" as="xs:integer" select="."/>
    <xsl:variable name="content" as="xs:string" select="$sourceText[$index]"/>
    <xsl:try>
      <xsl:apply-templates select="parse-xml($content)/*"/>
      <xsl:catch>
        <xsl:choose>
          <xsl:when test="starts-with($content, '<')">
            <p>[XML Parse Error: {$err:description}]</p>
          </xsl:when>
          <xsl:otherwise>
            <p>[Non XML File]</p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:catch>
    </xsl:try>
  </xsl:template>
  
  <xsl:template name="scrollToEnd">
    <xsl:sequence select="ixsl:call(id('end', ixsl:page()), 'scrollIntoView', [])"/>
  </xsl:template>
  
  
  <xsl:template match="*:title[contains(.,'Section Title')]"/>
  <xsl:template match="*:title[contains(.,'Replace this')]"/>
  
</xsl:transform>	
