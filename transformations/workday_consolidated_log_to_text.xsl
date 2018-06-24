<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:cr="urn:com.workday/support/ConsolidatedReport"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <xsl:output method="xml" version="1.0" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:param name="output.delimiter" select="'tab'"/>
    <xsl:param name="lineending" select="'LF'"/>
    <xsl:variable name="endquote">
        <xsl:text>"</xsl:text>
    </xsl:variable>
    <xsl:variable name="linefeed">
        <xsl:text>&#xA;</xsl:text>
    </xsl:variable>
    <xsl:variable name="carriagereturn">
        <xsl:text>&#x0D;</xsl:text>
    </xsl:variable>
    <xsl:variable name="space" select="' '"/>
    <xsl:variable name="line_ending">
        <xsl:choose>
            <xsl:when test="$lineending = 'CRLF'">
                <xsl:value-of select="$carriagereturn"/>
                <xsl:value-of select="$linefeed"/>
            </xsl:when>
            <xsl:when test="$lineending = 'LFCR'">
                <xsl:value-of select="$linefeed"/>
                <xsl:value-of select="$carriagereturn"/>
            </xsl:when>
            <xsl:when test="$lineending = 'CR'">
                <xsl:value-of select="$carriagereturn"/>
            </xsl:when>
            <xsl:when test="$lineending = 'LF'">
                <xsl:value-of select="$linefeed"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="output_delimiter">
        <xsl:choose>
            <xsl:when test="$output.delimiter = 'tab'">
                <xsl:text>&#x9;</xsl:text>
            </xsl:when>
            <xsl:when test="$output.delimiter = 'comma'">
                <xsl:text>","</xsl:text>
            </xsl:when>
            <xsl:when test="$output.delimiter = 'pipe'">
                <xsl:text>|</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:call-template name="create-header"/>
        <xsl:apply-templates select="//cr:event"/>
    </xsl:template>
    
    <xsl:template match="cr:event">
        <xsl:value-of select="@source"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="@application-name"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="@event-type"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="substring-before(@start-time,'T')"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="substring-before(substring-after(@start-time,'T'),'Z')"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="@duration-ms"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="format-number(@duration-ms div 60000,'####.00##')"/>
        <xsl:value-of select="$line_ending"/>
    </xsl:template>
    
    <xsl:template name="create-header">
        <xsl:value-of select="'source'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'application-name'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'event-type'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'start-date'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'start-time'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'duration-ms'"/>
        <xsl:value-of select="$output_delimiter"/>
        <xsl:value-of select="'duration-mins'"/>
        <xsl:value-of select="$line_ending"/>
    </xsl:template>
</xsl:stylesheet>