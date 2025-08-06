<?xml version='1.0'?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fhc="urn:com.firehawk-consulting"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xtt="urn:com.workday/xtt" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:output method="text" encoding="UTF-8" indent="no"/>
    <xsl:variable name="linefeed" select="//File/@xtt:separator"/>
    <xsl:variable name="delimiter" select="//Record[1]/@xtt:separator"/>


    <xsl:template match="/">
        <xsl:apply-templates select="//Record[1]"/>
        <xsl:apply-templates select="//Record[position()!=1]">
            <xsl:sort select="concat(node()[name() != ''][1],node()[name() != ''][2],node()[name() != ''][3])"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="Record">
        <xsl:for-each select="node()[name() != '']">
            <!--<xsl:value-of select="normalize-space(.)"/>-->
            <xsl:value-of select="."/>
            <xsl:if test="position()!= last()">
                <xsl:value-of select="$delimiter"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:value-of select="$linefeed"/>
    </xsl:template>
</xsl:stylesheet>