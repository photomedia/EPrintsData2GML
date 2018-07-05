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
<xsl:for-each select="eprints:contributors/eprints:item">
<xsl:copy-of select="$TitleNode" /><xsl:text>&#009;</xsl:text><xsl:value-of select="eprints:type" /><xsl:text>&#009;</xsl:text><xsl:value-of select="normalize-space(eprints:name/eprints:family)" />, <xsl:value-of select="normalize-space(eprints:name/eprints:given)" />
<xsl:text>&#xa;</xsl:text>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>