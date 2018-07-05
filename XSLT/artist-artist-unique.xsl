<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:eprints="http://eprints.org/ep2/data/2.0"
	>
<xsl:output method="text" encoding="utf-8" indent="yes"/>

<xsl:template match="/">
<xsl:apply-templates select="/eprints:eprints/eprints:eprint"/>
</xsl:template>

<xsl:template match="/eprints:eprints/eprints:eprint">
<xsl:variable name="TitleNode"><xsl:value-of select="eprints:eprintid"/>[<xsl:value-of select="eprints:title" />]</xsl:variable>
<xsl:for-each select="eprints:artists">
<xsl:for-each select="eprints:item">

<xsl:variable name="i" select="position()" />
        
<xsl:variable name="ArtistNode"><xsl:value-of select="." /></xsl:variable>

<xsl:for-each select="../eprints:item">
<xsl:variable name="j" select="position()" />
<xsl:variable name="ArtistNodeCompare"><xsl:value-of select="." /></xsl:variable>

<xsl:choose>
  <xsl:when test="$i &gt;= $j">
  </xsl:when>
  <xsl:otherwise>
  	<xsl:copy-of select="$ArtistNode" /><xsl:text>&#009;</xsl:text><xsl:copy-of select="$TitleNode" /><xsl:text>&#009;</xsl:text><xsl:copy-of select="$ArtistNodeCompare" /><xsl:text>&#xa;</xsl:text>
  </xsl:otherwise>
</xsl:choose>

</xsl:for-each>


</xsl:for-each>
</xsl:for-each>
</xsl:template>


</xsl:stylesheet>