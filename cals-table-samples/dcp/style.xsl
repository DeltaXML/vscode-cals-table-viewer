<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     Converts DeltaV2 output specifically to convert CALS tables to HTML tables with differences highlighted.
     This XSLT is not intended for any input files, just those included in the CALS table processing sample.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:deltaxml="http://www.deltaxml.com/ns/well-formed-delta-v1"
                xmlns:dxa="http://www.deltaxml.com/ns/non-namespaced-attribute"
                xmlns:cals="http://www.deltaxml.com/ns/cals-table"
                xmlns:cte="http://www.deltaxml.com/ns/cals-table-elements"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">
  
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="insertInputs" on-no-match="shallow-copy"/>
  <xsl:mode name="add-table" on-no-match="shallow-copy"/>
  <xsl:output method="html" version="5" indent="no"/>
  
  <xsl:param name="include-css" as="xs:boolean" select="true()"/>
  <xsl:variable name="showSpans" as="xs:boolean" select="true()"/>
  
  <xsl:template match="/">
    <html>
      <head>
        <xsl:choose>
          <xsl:when test="$include-css">
            <style>
              <xsl:sequence select="unparsed-text(resolve-uri('htmltable.css', static-base-uri()))"/>
            </style>
          </xsl:when>
          <xsl:otherwise>
            <link rel="stylesheet" type="text/css" href="{resolve-uri('htmltable.css', static-base-uri())}"/>
          </xsl:otherwise>
        </xsl:choose>
      </head>
      <body>
        <xsl:apply-templates select="*//*[*:tgroup]" mode="#default"/>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="section" mode="#all">
    <div class="section">
      <xsl:apply-templates mode="#current"/>
    </div>
  </xsl:template>
  
  <xsl:template match="p" mode="insertInputs">
    <p>
      <xsl:apply-templates select="deltaxml:textGroup/deltaxml:text[@deltaxml:deltaV2 eq 'A']" mode="#current"/>
    </p>
    <xsl:variable name="uriA" as="xs:string" select="string-join((text()| deltaxml:textGroup/deltaxml:text[@deltaxml:deltaV2 eq 'A']),'')"/>
    <xsl:apply-templates select="(doc($uriA)//*:table)[1]" mode="#current"/>
    <p>
      <xsl:apply-templates select="deltaxml:textGroup/deltaxml:text[@deltaxml:deltaV2 eq 'B']"/>
    </p>
    <xsl:variable name="uriB" as="xs:string" select="string-join((text()| deltaxml:textGroup/deltaxml:text[@deltaxml:deltaV2 eq 'B']),'')"/>
    <xsl:apply-templates select="(doc($uriB)//*:table)[1]" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p[@id eq 'uri']" mode="#default"/>
  
  <xsl:template match="section/title" mode="#all">
    <h2><xsl:apply-templates mode="#current"/></h2>
  </xsl:template>
  
  <xsl:template match="*:topic|*:tgroup|*:informaltable">
    <xsl:apply-templates select="node()" mode="#current"/>    
  </xsl:template>
  
  <xsl:template match="*:tbody|*:thead|*:tfoot" mode="#all">
    <xsl:element name="{local-name(.)}">
      <xsl:apply-templates select="parent::tgroup/@*" mode="#current"/>
      <xsl:apply-templates select="@deltaxml:deltaV2"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match="*:row" mode="#all">
    <tr>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="*:entry" mode="#all">
    <td>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </td>
  </xsl:template>
  
  <xsl:template match="*:entrytbl" mode="#all">
    <td>
      <xsl:apply-templates select="@*" mode="#current"/>
      <table>
        <xsl:apply-templates select="node()" mode="#current"/>
      </table>
    </td>
  </xsl:template>
  
  <xsl:template match="*:entry[(exists(@nameend) and exists(@namest)) or exists(@spanname)][$showSpans]" mode="#all">
    <td>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="sppanInfoElement" as="element()" select="if (exists(@spanname)) then cte:spanSpecFromName(@spanname) else ."/>      
      <xsl:attribute name="colspan" select="deltaxml:calcColspan($sppanInfoElement)"/>      
      <xsl:apply-templates select="node()" mode="#current"/>
    </td>
  </xsl:template>
  
  <xsl:template match="deltaxml:textGroup" mode="#all">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="span[deltaxml:attributes/dxa:class]" mode="#default">
    <span class="idIdRef">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </span>
  </xsl:template>
  
  <xsl:template match="deltaxml:text" mode="#all">
    <xsl:param name="from" as="xs:string?" tunnel="yes"/>
    <span>
      <xsl:if test="$from">
        <xsl:attribute name="data-from" select="$from"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </span>
  </xsl:template>
  
  <xsl:template match="*:table" mode="#all">
    <xsl:apply-templates select="p[@id eq 'uri' and @deltaxml:deltaV2 eq 'A!=B']" mode="insertInputs"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:table/*:title" mode="#all">
    <caption>
      <xsl:apply-templates/>
    </caption>
  </xsl:template>
  
  <xsl:template match="*:p[*:table]" mode="#all">
    <section>
      <xsl:apply-templates mode="#current"/>
    </section>
  </xsl:template>
  
  <xsl:template match="cals:mergeCells" mode="#all">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="cals:mergeCell[empty(*)][@deltaxml:deltaV2]" mode="#all">
    <xsl:variable name="deltav2" as="attribute()?" select="@deltaxml:deltaV2"/>
    <xsl:for-each select="node()">
      <span data-deltaV2="{$deltav2}" data-from="{@from}">
        <xsl:value-of select="."/>
      </span>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="cals:mergeCell[exists(*)]" mode="#all">
    <xsl:apply-templates>
      <xsl:with-param name="from" as="xs:string" select="@from" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="@morerows" mode="insertInputs">
    <xsl:attribute name="rowspan" select="xs:integer(.) + 1"/>
  </xsl:template>
  
  <xsl:template match="@morerows[$showSpans]" mode="#default">
    <xsl:attribute name="rowspan" select="xs:integer(.) + 1"/>
  </xsl:template>
  
  <xsl:template match="@deltaxml:deltaV2" mode="#all">
    <xsl:attribute name="data-deltaV2" select="."/>
  </xsl:template>
  
  <xsl:template match="@deltaxml:padding-cell" mode="#all">
    <xsl:attribute name="data-padding-cell" select="."/>
  </xsl:template>
  
  <xsl:template match="@deltaxml:missing-cell" mode="#all">
    <xsl:attribute name="data-missing-cell" select="."/>
  </xsl:template>
  
  <xsl:template match="@colname|@frame|@rowsep|@colsep" mode="#all"/>
  
  <xsl:template match="*:colspec" mode="#all"/>
  
  <xsl:function name="deltaxml:calcColspan" as="xs:integer">
    <xsl:param name="elem" as="element()"/> <!-- an entry, entrytbl or spanspec -->
    <xsl:variable name="colspan" as="attribute()?" select="$elem/@colspan"/>
    <xsl:variable name="namest" as="attribute()?" select="$elem/@namest"/>
    <xsl:variable name="nameend" as="attribute()?" select="$elem/@nameend"/>
    
    <xsl:variable name="precedingColSpecs" as="element()*" 
      select="$elem/ancestor::*[self::*:entrytbl|self::*:tgroup|self::*:thead|self::*:tfoot]/*:colspec"/>
    
    <xsl:variable name="stColnum" as="xs:integer" select="
      let $p := $precedingColSpecs[@colname eq $namest][last()] return
        if ($p/@colnum) then xs:integer($p/@colnum)
        else count($p/preceding-sibling::*:colspec) + 1"/>
    
    <xsl:variable name="endColnum" as="xs:integer" select="
      let $p := $precedingColSpecs[@colname eq $nameend][last()] return
        if ($p/@colnum) then xs:integer($p/@colnum)
        else count($p/preceding-sibling::*:colspec) + 1"/> 
    <!-- +1 colspan for html renderer -->
    <xsl:sequence 
      select="if ($colspan) then xs:integer($colspan)
        else if ($namest and $nameend) then
          ($endColnum + 1) - ($stColnum)
        else 1
      "/>
  </xsl:function>
  
  <xsl:function name="cte:spanSpecFromName" as="element()">
    <xsl:param name="spanname" as="attribute()"/>
    <!-- Docbook supports `entrytbl` element - even though this is explicitly excluded in the CALS Exchange Model -->
    <xsl:sequence select="$spanname/ancestor::*[local-name() = ('tgroup', 'entrytbl')][1]/*:spanspec[@spanname eq $spanname]"/>
  </xsl:function>
  
</xsl:stylesheet>