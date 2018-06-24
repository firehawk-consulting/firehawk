<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xsl xs"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhc="https://github.com/firehawk-consulting/firehawk/schemas/text_to_xml/editxttoxml_unparsed.xsd">
    
    <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
    <xsl:param name="parseby" select="'asterisk'"/>
    
    <xsl:variable name="parse.string">
        <xsl:choose>
            <xsl:when test="$parseby = 'asterisk'">
                <xsl:text>\*</xsl:text>
            </xsl:when>
            <xsl:when test="$parseby = 'comma'">
                <xsl:text>,</xsl:text>
            </xsl:when>
            <xsl:when test="$parseby = 'tilda'">
                <xsl:text>~</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:template match="/">
        <fhc:edi_file>
            <xsl:apply-templates select=".//fhc:edi_record"/>
        </fhc:edi_file>
    </xsl:template>
    
    
    <xsl:template match="fhc:edi_record">
        <fhc:edi_record>
            <xsl:for-each select="tokenize(.,$parse.string)">
                <fhc:edi_column>
                    <xsl:value-of select="."/>
                </fhc:edi_column>
            </xsl:for-each>
        </fhc:edi_record>
    </xsl:template>

</xsl:stylesheet>