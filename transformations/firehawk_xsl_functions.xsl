<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:tfxc="https://github.com/firehawk-consulting/firehawk/schemas/text_to_xml/transform_file_to_xml_unparsed.xsd"
        xmlns:fhcf="https://github.com/firehawk-consulting/firehawk/functions"
        xmlns:is="java:com.workday.esb.intsys.xpath.ParsedIntegrationSystemFunctions"
        xmlns:tv="java:com.workday.esb.intsys.TypedValue">

    <xsl:output method="xml" indent="yes"/>

    <xsl:variable name="column_headers">
        <xsl:apply-templates select="//tfxc:record[1]" mode="col_header"/>
    </xsl:variable>
    
    <xsl:function name="fhcf:convert-to-ASCII">
        <xsl:param name="inputValue"/>
        <xsl:param name="replaceChar"/>
        <xsl:value-of select="replace(normalize-unicode($inputValue,'NFC'),'\P{IsBasicLatin}',$replaceChar)"/>
    </xsl:function>

    <xsl:function name="fhcf:pad-string">
        <xsl:param name="fieldvalue"/>
        <xsl:param name="fieldsize"/>
        <xsl:param name="fillchar"/>
        <xsl:param name="padposition"/>
        <xsl:variable name="whatsthediff" select="$fieldsize - string-length(string($fieldvalue))"/>
        <xsl:choose>
            <xsl:when test="$whatsthediff &lt; 0">
                <xsl:value-of select="substring($fieldvalue, 1, $fieldsize)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$padposition = 'r' or $padposition = 'right'">
                        <xsl:value-of select="$fieldvalue"/>
                        <xsl:for-each select="1 to $whatsthediff">
                            <xsl:value-of select="$fillchar"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="$padposition = 'l' or $padposition = 'left'">
                        <xsl:for-each select="1 to $whatsthediff">
                            <xsl:value-of select="$fillchar"/>
                        </xsl:for-each>
                        <xsl:value-of select="$fieldvalue"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$fieldvalue"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="fhcf:get-column-position" as="xs:integer">
        <xsl:param name="column_name_lkp"/>
        <xsl:variable name="column_exists" select="count($column_headers//node()[. = $column_name_lkp])"/>
        <xsl:choose>
            <xsl:when test="$column_exists = 0">
                <xsl:value-of select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="count($column_headers//node()[. = $column_name_lkp]/preceding-sibling::node()) + 1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="@* | node()" mode="output">
        <xsl:param name="col_position"/>
        <xsl:variable name="column_name_lkp" select="name()"/>
        <xsl:variable name="node_name">
            <xsl:value-of select="'ecmc:'"/>
            <xsl:value-of select="lower-case($column_headers//node()[name(.) = $column_name_lkp])"/>
        </xsl:variable>
        <xsl:element name="{$node_name}">
            <xsl:value-of select="replace(.,'&quot;','')"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tfxc:record" mode="col_header">
        <xsl:for-each select=".//node()[name() != '']">
            <xsl:variable name="temp_element" select="name()"/>
            <xsl:element name="{$temp_element}">
                <xsl:value-of select="lower-case(replace(replace(replace(., ' ', ''), '_', ''), '/', ''))"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="fhcf:ApplyReverseMap">
        <xsl:param name="mapName"/>
        <xsl:param name="externalValue"/>
        <xsl:param name="overrideExternalValue"/>
        <xsl:param name="referenceId"/>
        <xsl:variable name="lookup" select="is:integrationMapReverseLookup(string($mapName), string($externalValue))"/>
        <xsl:variable name="overrideLookup">
            <xsl:if test="string-length($overrideExternalValue) != 0">
                <xsl:value-of select="is:integrationMapReverseLookup(string($mapName), string($overrideExternalValue))"/>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($overrideLookup) != 0">
                <xsl:value-of select="tv:getReferenceData($overrideLookup[1], string($referenceId))"/>
            </xsl:when>
            <xsl:when test="count($lookup) != 0">
                <xsl:value-of select="tv:getReferenceData($lookup[1], string($referenceId))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$externalValue"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="fhcf:reformat-date">
        <xsl:param name="dateIn"/>
        <xsl:param name="yearPositionIn"/>
        <xsl:param name="monthPositionIn"/>
        <xsl:param name="dayPositionIn"/>
        <xsl:param name="delimiterIn"/>
        <xsl:param name="yearPosition"/>
        <xsl:param name="monthPosition"/>
        <xsl:param name="dayPosition"/>
        <xsl:param name="delimiter"/>
        <xsl:if test="string-length($dateIn) != 0 and $delimiterIn != ''">
            <xsl:variable name="effdelim" select="if (string-length($dateIn) != 0) then $delimiter else ''"/>
            <xsl:variable name="dateParsed">
                <dateIn>
                    <xsl:for-each select="tokenize($dateIn, $delimiterIn)">
                        <part>
                            <xsl:attribute name="outPosition">
                                <xsl:choose>
                                    <xsl:when test="position() = $yearPositionIn">
                                        <xsl:value-of select="$yearPosition"/>
                                    </xsl:when>
                                    <xsl:when test="position() = $monthPositionIn">
                                        <xsl:value-of select="$monthPosition"/>
                                    </xsl:when>
                                    <xsl:when test="position() = $dayPositionIn">
                                        <xsl:value-of select="$dayPosition"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:value-of select="if (position() = $yearPositionIn) then normalize-space(.)
                                else format-number(xs:integer(.), '00')"/>
                        </part>
                    </xsl:for-each>
                </dateIn>
            </xsl:variable>
            <xsl:for-each select="1 to 3">
                <xsl:variable name="curPos" select="."/>
                <xsl:value-of select="$dateParsed//part[@outPosition = $curPos]"/>
                <xsl:value-of select="if (position() != last()) then $effdelim else ''"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>
    
</xsl:stylesheet>
