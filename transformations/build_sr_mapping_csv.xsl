<?xml version='1.0'?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fhc="urn:com.firehawk-consulting"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xtt="urn:com.workday/xtt" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:output method="text" encoding="UTF-8" indent="no"/>
    <xsl:variable name="linefeed"><xsl:text>&#xA;</xsl:text></xsl:variable>
    <xsl:variable name="delimiter"><xsl:text>","</xsl:text></xsl:variable>


    <xsl:template match="/">
        <xsl:apply-templates select="//content"/>
    </xsl:template>
    
    <xsl:template match="content">
        <xsl:text>"</xsl:text>
            <xsl:for-each select="node()[name() != '']">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:if test="position()!= last()">
                    <xsl:value-of select="$delimiter"/>
                </xsl:if>
            </xsl:for-each>
        <xsl:text>"</xsl:text>
        <xsl:value-of select="$linefeed"/>
    </xsl:template>
</xsl:stylesheet>