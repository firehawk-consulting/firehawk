<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:bsvc="urn:com.workday/bsvc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tfxc="https://github.com/firehawk-consulting/firehawk/schemas/text_to_xml/transform_file_to_xml_unparsed.xsd"
    xmlns:fhcpd="https://github.com/firehawk-consulting/firehawk/schemas/external_file.xsd"
    xmlns:wd="urn:com.workday/bsvc" exclude-result-prefixes="xs bsvc wd xsl tfxc">

    <xsl:output indent="yes" method="xml"/>

    <xsl:variable name="column_headers">
        <xsl:apply-templates select="//tfxc:record[1]" mode="header"/>
    </xsl:variable>

    <xsl:template match="/">
        <fhcpd:external_file>
            <xsl:apply-templates select="//tfxc:record[position() != 1]" mode="details"/>
        </fhcpd:external_file>
    </xsl:template>

    <xsl:template match="tfxc:record" mode="details">
        <fhcpd:external_file_record>
            <xsl:apply-templates select=".//node()[name() != '']" mode="output"/>
        </fhcpd:external_file_record>
    </xsl:template>

    <xsl:template match="tfxc:record" mode="header">
        <xsl:for-each select=".//node()[name() != '']">
            <xsl:variable name="temp_element" select="name()"/>
            <xsl:element name="{$temp_element}">
                <xsl:value-of select="lower-case(replace(replace(replace(replace(., ' ', ''), '_', ''), '/', ''),'\.',''))"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="@* | node()" mode="output">
        <xsl:variable name="temp_name" select="name()"/>
        <xsl:variable name="temp_element" select="fhcpd:get-column-name($temp_name)"/>
        <xsl:element name="{$temp_element}">
            <xsl:value-of select="replace(., '&quot;', '')"/>
        </xsl:element>
    </xsl:template>

    <xsl:function name="fhcpd:get-column-name" as="xs:string">
        <xsl:param name="column_name_lkp"/>
        <xsl:variable name="column_name" select="$column_headers//node()[name(.) = $column_name_lkp]"/>
        <xsl:value-of select="concat('fhcpd:',$column_name)"/>
    </xsl:function>

</xsl:stylesheet>
