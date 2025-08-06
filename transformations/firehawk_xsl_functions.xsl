<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tfxc="https://github.com/firehawk-consulting/firehawk/schemas/text_to_xml/transform_file_to_xml_unparsed.xsd"
    xmlns:fhcf="https://github.com/firehawk-consulting/firehawk/functions"
    xmlns:is="java:com.workday.esb.intsys.xpath.ParsedIntegrationSystemFunctions"
    xmlns:tv="java:com.workday.esb.intsys.TypedValue">

    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="country.lookup.data" select="document('mctx:vars/country.lookup.data.xml')"/>
    
    <xsl:variable name="column_headers">
        <xsl:apply-templates select="//tfxc:record[1]" mode="col_header"/>
    </xsl:variable>

    <xsl:function name="fhcf:convert-to-ASCII">
        <xsl:param name="inputValue"/>
        <xsl:param name="replaceChar"/>
        <xsl:value-of select="replace(normalize-unicode($inputValue, 'NFC'), '\P{IsBasicLatin}', $replaceChar)"/>
    </xsl:function>

    <xsl:function name="fhcf:reformat-phone">
        <xsl:param name="phoneNumber"/>
        <xsl:variable name="cleanedPhoneNbr" select="translate($phoneNumber, '-+() ', '')"/>
        <xsl:variable name="startPos" select="string-length($cleanedPhoneNbr) - 9"/>
        <xsl:value-of select="substring($cleanedPhoneNbr, $startPos, 10)"/>
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

    <xsl:function name="fhcf:forceValueDecimal" as="xs:decimal">
        <xsl:param name="inputdata"/>
        <xsl:param name="defaultoutput" as="xs:decimal"/>
        <xsl:variable name="cleanInput" select="normalize-space(replace(xs:string($inputdata),',$',''))"/>
        <xsl:choose>
            <xsl:when test="not($cleanInput castable as xs:decimal)">
                <xsl:value-of select="$defaultoutput"/>
            </xsl:when>
            <xsl:when test="string-length(normalize-space($cleanInput)) != 0">
                <xsl:value-of select="$cleanInput"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$defaultoutput"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!--<xsl:function name="fhcf:forceValueDecimal" as="xs:decimal">
        <xsl:param name="inputdata"/>
        <xsl:param name="defaultoutput" as="xs:decimal"/>
        <!-\-<xsl:variable name="clean.input.data" select="replace(replace(replace($inputdata,',',''),'%',''),'$','')"/>-\->
        <xsl:choose>
            <xsl:when test="$inputdata = 'null'">
                <xsl:value-of select="xs:decimal($defaultoutput)"/>
            </xsl:when>
            <xsl:when test="string-length(normalize-space($inputdata))">
                <xsl:value-of select="xs:decimal(normalize-space($inputdata))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="xs:decimal($defaultoutput)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>-->

    <xsl:function name="fhcf:get-column-position" as="xs:integer">
        <xsl:param name="column_name_lkp"/>
        <xsl:variable name="column_exists"
            select="count($column_headers//node()[. = $column_name_lkp])"/>
        <xsl:choose>
            <xsl:when test="$column_exists = 0">
                <xsl:value-of select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="count($column_headers//node()[. = $column_name_lkp]/preceding-sibling::node()) + 1"
                />
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
            <xsl:value-of select="replace(., '&quot;', '')"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tfxc:record" mode="col_header">
        <xsl:for-each select=".//node()[name() != '']">
            <xsl:variable name="temp_element" select="name()"/>
            <xsl:element name="{$temp_element}">
                <xsl:value-of
                    select="lower-case(replace(replace(replace(., ' ', ''), '_', ''), '/', ''))"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:function name="fhcf:get-reverseMap">
        <xsl:param name="mapName"/>
        <xsl:param name="externalValue"/>
        <xsl:param name="overrideExternalValue"/>
        <xsl:param name="referenceId"/>
        <xsl:param name="returnExternalValue" as="xs:boolean"/>
        <xsl:variable name="lookup"
            select="is:integrationMapReverseLookup(string($mapName), string($externalValue))"/>
        <xsl:variable name="overrideLookup">
            <xsl:if test="string-length($overrideExternalValue) != 0">
                <xsl:value-of
                    select="is:integrationMapReverseLookup(string($mapName), string($overrideExternalValue))"
                />
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($overrideLookup) != 0">
                <xsl:value-of select="tv:getReferenceData($overrideLookup[1], string($referenceId))"
                />
            </xsl:when>
            <xsl:when test="count($lookup) != 0">
                <xsl:value-of select="tv:getReferenceData($lookup[1], string($referenceId))"/>
            </xsl:when>
            <xsl:when test="$returnExternalValue">
                <xsl:value-of select="$externalValue"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="fhcf:string-to-date" as="xs:date">
        <xsl:param name="dateIn"/>
        <xsl:param name="yearPosition"/>
        <xsl:param name="monthPosition"/>
        <xsl:param name="dayPosition"/>
        <xsl:param name="delimiter"/>
        <xsl:choose>
            <xsl:when test="string-length($dateIn) != 0 and $delimiter != ''">
                <xsl:variable name="effdelim" select="
                        if (string-length($dateIn) != 0) then
                            $delimiter
                        else
                            ''"/>
                <xsl:variable name="dateParsed" select="tokenize($dateIn, $delimiter)"/>
                <xsl:variable name="outputDate"
                    select="concat($dateParsed[$yearPosition], '-', $dateParsed[$monthPosition], '-', $dateParsed[$dayPosition])"/>
                <xsl:value-of select="
                        xs:date(if (string-length($outputDate) = 0) then
                            '1900-01-01'
                        else
                            $outputDate)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="xs:date('1900-01-01')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="fhcf:get-country_phone_code" as="xs:string">
        <xsl:param name="input.iso.3"/>
        <xsl:choose>
            <xsl:when test="$input.iso.3 = 'USA'">
                <xsl:value-of select="'USA_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CAN'">
                <xsl:value-of select="'CAN_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DZA'">
                <xsl:value-of select="'DZA_213'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ARG'">
                <xsl:value-of select="'ARG_54'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AUS'">
                <xsl:value-of select="'AUS_61'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AUT'">
                <xsl:value-of select="'AUT_43'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ZAF'">
                <xsl:value-of select="'ZAF_27'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ITA'">
                <xsl:value-of select="'ITA_39'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'JPN'">
                <xsl:value-of select="'JPN_81'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KOR'">
                <xsl:value-of select="'KOR_82'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LBN'">
                <xsl:value-of select="'LBN_961'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LUX'">
                <xsl:value-of select="'LUX_352'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MAR'">
                <xsl:value-of select="'MAR_212'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MEX'">
                <xsl:value-of select="'MEX_52'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MYS'">
                <xsl:value-of select="'MYS_60'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NLD'">
                <xsl:value-of select="'NLD_31'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NZL'">
                <xsl:value-of select="'NZL_64'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PHL'">
                <xsl:value-of select="'PHL_63'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'POL'">
                <xsl:value-of select="'POL_48'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VEN'">
                <xsl:value-of select="'VEN_58'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TWN'">
                <xsl:value-of select="'TWN_886'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SWE'">
                <xsl:value-of select="'SWE_46'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SGP'">
                <xsl:value-of select="'SGP_65'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SAU'">
                <xsl:value-of select="'SAU_966'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KAZ'">
                <xsl:value-of select="'KAZ_7'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'QAT'">
                <xsl:value-of select="'QAT_974'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PRT'">
                <xsl:value-of select="'PRT_351'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PRK'">
                <xsl:value-of select="'PRK_850'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ISR'">
                <xsl:value-of select="'ISR_972'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IRL'">
                <xsl:value-of select="'IRL_353'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IND'">
                <xsl:value-of select="'IND_91'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'HUN'">
                <xsl:value-of select="'HUN_36'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'HKG'">
                <xsl:value-of select="'HKG_852'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GRC'">
                <xsl:value-of select="'GRC_30'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GBR'">
                <xsl:value-of select="'GBR_44'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FRA'">
                <xsl:value-of select="'FRA_33'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FIN'">
                <xsl:value-of select="'FIN_358'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ESP'">
                <xsl:value-of select="'ESP_34'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'EGY'">
                <xsl:value-of select="'EGY_20'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DNK'">
                <xsl:value-of select="'DNK_45'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DEU'">
                <xsl:value-of select="'DEU_49'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CRI'">
                <xsl:value-of select="'CRI_506'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CHN'">
                <xsl:value-of select="'CHN_86'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CHL'">
                <xsl:value-of select="'CHL_56'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CHE'">
                <xsl:value-of select="'CHE_41'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BRA'">
                <xsl:value-of select="'BRA_55'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BEL'">
                <xsl:value-of select="'BEL_32'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ARE'">
                <xsl:value-of select="'ARE_971'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AGO'">
                <xsl:value-of select="'AGO_244'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BLZ'">
                <xsl:value-of select="'BLZ_501'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BMU'">
                <xsl:value-of select="'BMU_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'COL'">
                <xsl:value-of select="'COL_57'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CIV'">
                <xsl:value-of select="'CIV_225'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CZE'">
                <xsl:value-of select="'CZE_420'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ECU'">
                <xsl:value-of select="'ECU_593'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'EST'">
                <xsl:value-of select="'EST_372'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IDN'">
                <xsl:value-of select="'IDN_62'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'JAM'">
                <xsl:value-of select="'JAM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LVA'">
                <xsl:value-of select="'LVA_371'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LIE'">
                <xsl:value-of select="'LIE_423'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LTU'">
                <xsl:value-of select="'LTU_370'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MLT'">
                <xsl:value-of select="'MLT_356'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MOZ'">
                <xsl:value-of select="'MOZ_258'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NOR'">
                <xsl:value-of select="'NOR_47'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PAK'">
                <xsl:value-of select="'PAK_92'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PRI'">
                <xsl:value-of select="'PRI_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ROU'">
                <xsl:value-of select="'ROU_40'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SVK'">
                <xsl:value-of select="'SVK_421'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TUR'">
                <xsl:value-of select="'TUR_90'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DOM'">
                <xsl:value-of select="'DOM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SLV'">
                <xsl:value-of select="'SLV_503'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GTM'">
                <xsl:value-of select="'GTM_502'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'HND'">
                <xsl:value-of select="'HND_504'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NIC'">
                <xsl:value-of select="'NIC_505'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PAN'">
                <xsl:value-of select="'PAN_507'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PER'">
                <xsl:value-of select="'PER_51'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'THA'">
                <xsl:value-of select="'THA_66'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'UKR'">
                <xsl:value-of select="'UKR_380'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ALB'">
                <xsl:value-of select="'ALB_355'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BGR'">
                <xsl:value-of select="'BGR_359'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'HRV'">
                <xsl:value-of select="'HRV_385'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'JOR'">
                <xsl:value-of select="'JOR_962'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KEN'">
                <xsl:value-of select="'KEN_254'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KWT'">
                <xsl:value-of select="'KWT_965'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MUS'">
                <xsl:value-of select="'MUS_230'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NPL'">
                <xsl:value-of select="'NPL_977'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SRB'">
                <xsl:value-of select="'SRB_381'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SYR'">
                <xsl:value-of select="'SYR_963'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ISL'">
                <xsl:value-of select="'ISL_354'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BHR'">
                <xsl:value-of select="'BHR_973'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'URY'">
                <xsl:value-of select="'URY_598'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AFG'">
                <xsl:value-of select="'AFG_93'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ARM'">
                <xsl:value-of select="'ARM_374'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AZE'">
                <xsl:value-of select="'AZE_994'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BHS'">
                <xsl:value-of select="'BHS_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BGD'">
                <xsl:value-of select="'BGD_880'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BRB'">
                <xsl:value-of select="'BRB_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BLR'">
                <xsl:value-of select="'BLR_375'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BOL'">
                <xsl:value-of select="'BOL_591'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BWA'">
                <xsl:value-of select="'BWA_267'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BDI'">
                <xsl:value-of select="'BDI_257'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KHM'">
                <xsl:value-of select="'KHM_855'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TCD'">
                <xsl:value-of select="'TCD_235'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'COG'">
                <xsl:value-of select="'COG_242'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'COD'">
                <xsl:value-of select="'COD_243'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CYP'">
                <xsl:value-of select="'CYP_357'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ETH'">
                <xsl:value-of select="'ETH_251'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GEO'">
                <xsl:value-of select="'GEO_995'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GHA'">
                <xsl:value-of select="'GHA_233'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GUY'">
                <xsl:value-of select="'GUY_592'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'HTI'">
                <xsl:value-of select="'HTI_509'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IRN'">
                <xsl:value-of select="'IRN_98'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IRQ'">
                <xsl:value-of select="'IRQ_964'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KGZ'">
                <xsl:value-of select="'KGZ_996'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LAO'">
                <xsl:value-of select="'LAO_856'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LBY'">
                <xsl:value-of select="'LBY_218'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MKD'">
                <xsl:value-of select="'MKD_389'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MDG'">
                <xsl:value-of select="'MDG_261'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MWI'">
                <xsl:value-of select="'MWI_265'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MLI'">
                <xsl:value-of select="'MLI_223'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MRT'">
                <xsl:value-of select="'MRT_222'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MDA'">
                <xsl:value-of select="'MDA_373'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MNG'">
                <xsl:value-of select="'MNG_976'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NAM'">
                <xsl:value-of select="'NAM_264'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NGA'">
                <xsl:value-of select="'NGA_234'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PNG'">
                <xsl:value-of select="'PNG_675'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PRY'">
                <xsl:value-of select="'PRY_595'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'RWA'">
                <xsl:value-of select="'RWA_250'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SEN'">
                <xsl:value-of select="'SEN_221'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SVN'">
                <xsl:value-of select="'SVN_386'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LKA'">
                <xsl:value-of select="'LKA_94'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SDN'">
                <xsl:value-of select="'SDN_249'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TJK'">
                <xsl:value-of select="'TJK_992'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TZA'">
                <xsl:value-of select="'TZA_255'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TTO'">
                <xsl:value-of select="'TTO_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TUN'">
                <xsl:value-of select="'TUN_216'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TKM'">
                <xsl:value-of select="'TKM_993'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'UGA'">
                <xsl:value-of select="'UGA_256'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'UZB'">
                <xsl:value-of select="'UZB_998'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VNM'">
                <xsl:value-of select="'VNM_84'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ZMB'">
                <xsl:value-of select="'ZMB_260'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ZWE'">
                <xsl:value-of select="'ZWE_263'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'RUS'">
                <xsl:value-of select="'RUS_7'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GRL'">
                <xsl:value-of select="'GRL_299'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BRN'">
                <xsl:value-of select="'BRN_673'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NER'">
                <xsl:value-of select="'NER_227'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CMR'">
                <xsl:value-of select="'CMR_237'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GIN'">
                <xsl:value-of select="'GIN_224'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LBR'">
                <xsl:value-of select="'LBR_231'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SLE'">
                <xsl:value-of select="'SLE_232'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BIH'">
                <xsl:value-of select="'BIH_387'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MNE'">
                <xsl:value-of select="'MNE_382'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LSO'">
                <xsl:value-of select="'LSO_266'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'OMN'">
                <xsl:value-of select="'OMN_968'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'YEM'">
                <xsl:value-of select="'YEM_967'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SWZ'">
                <xsl:value-of select="'SWZ_268'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'COM'">
                <xsl:value-of select="'COM_269'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DMA'">
                <xsl:value-of select="'DMA_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FJI'">
                <xsl:value-of select="'FJI_679'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GRD'">
                <xsl:value-of select="'GRD_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MDV'">
                <xsl:value-of select="'MDV_960'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NRU'">
                <xsl:value-of select="'NRU_674'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PLW'">
                <xsl:value-of select="'PLW_680'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KNA'">
                <xsl:value-of select="'KNA_869'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'LCA'">
                <xsl:value-of select="'LCA_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BEN'">
                <xsl:value-of select="'BEN_229'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BFA'">
                <xsl:value-of select="'BFA_226'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CAF'">
                <xsl:value-of select="'CAF_236'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'DJI'">
                <xsl:value-of select="'DJI_253'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ERI'">
                <xsl:value-of select="'ERI_291'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GAB'">
                <xsl:value-of select="'GAB_241'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GNB'">
                <xsl:value-of select="'GNB_245'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SOM'">
                <xsl:value-of select="'SOM_252'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ATG'">
                <xsl:value-of select="'ATG_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TGO'">
                <xsl:value-of select="'TGO_228'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AND'">
                <xsl:value-of select="'AND_376'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BTN'">
                <xsl:value-of select="'BTN_975'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CPV'">
                <xsl:value-of select="'CPV_238'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GNQ'">
                <xsl:value-of select="'GNQ_240'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GMB'">
                <xsl:value-of select="'GMB_220'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KIR'">
                <xsl:value-of select="'KIR_686'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MHL'">
                <xsl:value-of select="'MHL_692'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FSM'">
                <xsl:value-of select="'FSM_691'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MCO'">
                <xsl:value-of select="'MCO_377'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MMR'">
                <xsl:value-of select="'MMR_95'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VCT'">
                <xsl:value-of select="'VCT_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'WSM'">
                <xsl:value-of select="'WSM_685'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SMR'">
                <xsl:value-of select="'SMR_378'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'STP'">
                <xsl:value-of select="'STP_239'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SYC'">
                <xsl:value-of select="'SYC_248'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SLB'">
                <xsl:value-of select="'SLB_677'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SUR'">
                <xsl:value-of select="'SUR_597'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TLS'">
                <xsl:value-of select="'TLS_670'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TON'">
                <xsl:value-of select="'TON_676'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TUV'">
                <xsl:value-of select="'TUV_688'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VUT'">
                <xsl:value-of select="'VUT_678'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MAC'">
                <xsl:value-of select="'MAC_853'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GGY'">
                <xsl:value-of select="'GGY_44'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CUB'">
                <xsl:value-of select="'CUB_53'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'AIA'">
                <xsl:value-of select="'AIA_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ABW'">
                <xsl:value-of select="'ABW_297'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VGB'">
                <xsl:value-of select="'VGB_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CYM'">
                <xsl:value-of select="'CYM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GUF'">
                <xsl:value-of select="'GUF_594'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GUM'">
                <xsl:value-of select="'GUM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'JEY'">
                <xsl:value-of select="'JEY_44'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CUW'">
                <xsl:value-of select="'CUW_599'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TCA'">
                <xsl:value-of select="'TCA_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ESH'">
                <xsl:value-of select="'ESH_212'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NCL'">
                <xsl:value-of select="'NCL_687'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'REU'">
                <xsl:value-of select="'REU_262'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GLP'">
                <xsl:value-of select="'GLP_590'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MTQ'">
                <xsl:value-of select="'MTQ_596'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PSE'">
                <xsl:value-of select="'PSE_970'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PYF'">
                <xsl:value-of select="'PYF_689'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SSD'">
                <xsl:value-of select="'SSD_211'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SXM'">
                <xsl:value-of select="'SXM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IMN'">
                <xsl:value-of select="'IMN_44'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KSV'">
                <xsl:value-of select="'KSV_386'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KSV'">
                <xsl:value-of select="'KSV_381'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KSV'">
                <xsl:value-of select="'KSV_377'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'GIB'">
                <xsl:value-of select="'GIB_350'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MNP'">
                <xsl:value-of select="'MNP_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VIR'">
                <xsl:value-of select="'VIR_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ASM'">
                <xsl:value-of select="'ASM_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FLK'">
                <xsl:value-of select="'FLK_500'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'VAT'">
                <xsl:value-of select="'VAT_39'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'IOT'">
                <xsl:value-of select="'IOT_246'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'FRO'">
                <xsl:value-of select="'FRO_298'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'UMI'">
                <xsl:value-of select="'UMI_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'COK'">
                <xsl:value-of select="'COK_682'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MSR'">
                <xsl:value-of select="'MSR_1'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'WLF'">
                <xsl:value-of select="'WLF_681'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SJM'">
                <xsl:value-of select="'SJM_47'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'PCN'">
                <xsl:value-of select="'PCN_64'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BES'">
                <xsl:value-of select="'BES_599'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CXR'">
                <xsl:value-of select="'CXR_61'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'ALA'">
                <xsl:value-of select="'ALA_358'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NIU'">
                <xsl:value-of select="'NIU_683'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'CCK'">
                <xsl:value-of select="'CCK_61'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MYT'">
                <xsl:value-of select="'MYT_262'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SPM'">
                <xsl:value-of select="'SPM_508'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'TKL'">
                <xsl:value-of select="'TKL_690'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'NFK'">
                <xsl:value-of select="'NFK_672'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'BLM'">
                <xsl:value-of select="'BLM_590'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SHN'">
                <xsl:value-of select="'SHN_247'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'SHN'">
                <xsl:value-of select="'SHN_290'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'MAF'">
                <xsl:value-of select="'MAF_590'"/>
            </xsl:when>
            <xsl:when test="$input.iso.3 = 'KSV'">
                <xsl:value-of select="'KSV_383'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'UNK'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="fhcf:getCountryISO">
        <xsl:param name="inputCountry"/>
        <xsl:param name="inputCodeType"/>
        <xsl:param name="outputCodeType"/>
        <xsl:variable name="lookup.country.name">
            <xsl:choose>
                <xsl:when test="$inputCodeType = 'ISO-2'">
                    <xsl:value-of select="$inputCountry"/>
                </xsl:when>
                <xsl:when test="$inputCodeType = 'ISO-3'">
                    <xsl:value-of select="$inputCountry"/>
                </xsl:when>
                <xsl:when test="$inputCodeType = 'ISO-2'">
                    <xsl:value-of select="$inputCountry"/>
                </xsl:when>
                <xsl:when test="$inputCodeType = 'NUMERIC'">
                    <xsl:value-of select="$inputCountry"/>
                </xsl:when>
                <xsl:when test="$inputCodeType != 'NAME'">
                    <xsl:value-of select="'Invalid Lookup'"/>
                </xsl:when>
                <xsl:when test="lower-case(replace($inputCountry, ' ', '')) = 'unitedstates'">
                    <xsl:value-of select="'unitedstatesofamerica'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="lower-case(replace($inputCountry, ' ', ''))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$inputCodeType = 'NAME'">
                <xsl:choose>
                    <xsl:when test="$outputCodeType = 'ISO-2'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[country_name = $lookup.country.name][1]/alpha_2_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'ISO-3'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[country_name = $lookup.country.name][1]/alpha_3_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NUMERIC'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[country_name = $lookup.country.name][1]/numeric"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NAME'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[country_name = $lookup.country.name][1]/country_name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$inputCodeType = 'ISO-2'">
                <xsl:choose>
                    <xsl:when test="$outputCodeType = 'ISO-2'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_2_code) = $lookup.country.name][1]/alpha_2_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'ISO-3'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_2_code) = $lookup.country.name][1]/alpha_3_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NUMERIC'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_2_code) = $lookup.country.name][1]/numeric"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NAME'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_2_code) = $lookup.country.name][1]/country_name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$inputCodeType = 'ISO-3'">
                <xsl:choose>
                    <xsl:when test="$outputCodeType = 'ISO-2'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_3_code) = $lookup.country.name][1]/alpha_2_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'ISO-3'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_3_code) = $lookup.country.name][1]/alpha_3_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NUMERIC'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_3_code) = $lookup.country.name][1]/numeric"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NAME'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(alpha_3_code) = $lookup.country.name][1]/country_name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$inputCodeType = 'NUMERIC'">
                <xsl:choose>
                    <xsl:when test="$outputCodeType = 'ISO-2'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(numeric) = $lookup.country.name][1]/alpha_2_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'ISO-3'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(numeric) = $lookup.country.name][1]/alpha_3_code"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NUMERIC'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(numeric) = $lookup.country.name][1]/numeric"/>
                    </xsl:when>
                    <xsl:when test="$outputCodeType = 'NAME'">
                        <xsl:value-of select="$country.lookup.data//country_lookup_list/country_lookup[lower-case(numeric) = $lookup.country.name][1]/country_name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <fhcf:country_lookup_list>
        <country_lookup>
            <country_name>afghanistan</country_name>
            <alpha_2_code>AF</alpha_2_code>
            <alpha_3_code>AFG</alpha_3_code>
            <numeric>004</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>albania</country_name>
            <alpha_2_code>AL</alpha_2_code>
            <alpha_3_code>ALB</alpha_3_code>
            <numeric>008</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>algeria</country_name>
            <alpha_2_code>DZ</alpha_2_code>
            <alpha_3_code>DZA</alpha_3_code>
            <numeric>012</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>americansamoa</country_name>
            <alpha_2_code>AS</alpha_2_code>
            <alpha_3_code>ASM</alpha_3_code>
            <numeric>016</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>andorra</country_name>
            <alpha_2_code>AD</alpha_2_code>
            <alpha_3_code>AND</alpha_3_code>
            <numeric>020</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>angola</country_name>
            <alpha_2_code>AO</alpha_2_code>
            <alpha_3_code>AGO</alpha_3_code>
            <numeric>024</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>anguilla</country_name>
            <alpha_2_code>AI</alpha_2_code>
            <alpha_3_code>AIA</alpha_3_code>
            <numeric>660</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>antarctica</country_name>
            <alpha_2_code>AQ</alpha_2_code>
            <alpha_3_code>ATA</alpha_3_code>
            <numeric>010</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>antiguaandbarbuda</country_name>
            <alpha_2_code>AG</alpha_2_code>
            <alpha_3_code>ATG</alpha_3_code>
            <numeric>028</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>argentina</country_name>
            <alpha_2_code>AR</alpha_2_code>
            <alpha_3_code>ARG</alpha_3_code>
            <numeric>032</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>armenia</country_name>
            <alpha_2_code>AM</alpha_2_code>
            <alpha_3_code>ARM</alpha_3_code>
            <numeric>051</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>aruba</country_name>
            <alpha_2_code>AW</alpha_2_code>
            <alpha_3_code>ABW</alpha_3_code>
            <numeric>533</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>australia</country_name>
            <alpha_2_code>AU</alpha_2_code>
            <alpha_3_code>AUS</alpha_3_code>
            <numeric>036</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>austria</country_name>
            <alpha_2_code>AT</alpha_2_code>
            <alpha_3_code>AUT</alpha_3_code>
            <numeric>040</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>azerbaijan</country_name>
            <alpha_2_code>AZ</alpha_2_code>
            <alpha_3_code>AZE</alpha_3_code>
            <numeric>031</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bahamas</country_name>
            <alpha_2_code>BS</alpha_2_code>
            <alpha_3_code>BHS</alpha_3_code>
            <numeric>044</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bahrain</country_name>
            <alpha_2_code>BH</alpha_2_code>
            <alpha_3_code>BHR</alpha_3_code>
            <numeric>048</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bangladesh</country_name>
            <alpha_2_code>BD</alpha_2_code>
            <alpha_3_code>BGD</alpha_3_code>
            <numeric>050</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>barbados</country_name>
            <alpha_2_code>BB</alpha_2_code>
            <alpha_3_code>BRB</alpha_3_code>
            <numeric>052</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>belarus</country_name>
            <alpha_2_code>BY</alpha_2_code>
            <alpha_3_code>BLR</alpha_3_code>
            <numeric>112</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>belgium</country_name>
            <alpha_2_code>BE</alpha_2_code>
            <alpha_3_code>BEL</alpha_3_code>
            <numeric>056</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>belize</country_name>
            <alpha_2_code>BZ</alpha_2_code>
            <alpha_3_code>BLZ</alpha_3_code>
            <numeric>084</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>benin</country_name>
            <alpha_2_code>BJ</alpha_2_code>
            <alpha_3_code>BEN</alpha_3_code>
            <numeric>204</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bermuda</country_name>
            <alpha_2_code>BM</alpha_2_code>
            <alpha_3_code>BMU</alpha_3_code>
            <numeric>060</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bhutan</country_name>
            <alpha_2_code>BT</alpha_2_code>
            <alpha_3_code>BTN</alpha_3_code>
            <numeric>064</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bolivia(plurinationalstateof)</country_name>
            <alpha_2_code>BO</alpha_2_code>
            <alpha_3_code>BOL</alpha_3_code>
            <numeric>068</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bonaire,sinteustatiusandsaba</country_name>
            <alpha_2_code>BQ</alpha_2_code>
            <alpha_3_code>BES</alpha_3_code>
            <numeric>535</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bosniaandherzegovina</country_name>
            <alpha_2_code>BA</alpha_2_code>
            <alpha_3_code>BIH</alpha_3_code>
            <numeric>070</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>botswana</country_name>
            <alpha_2_code>BW</alpha_2_code>
            <alpha_3_code>BWA</alpha_3_code>
            <numeric>072</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bouvetisland</country_name>
            <alpha_2_code>BV</alpha_2_code>
            <alpha_3_code>BVT</alpha_3_code>
            <numeric>074</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>brazil</country_name>
            <alpha_2_code>BR</alpha_2_code>
            <alpha_3_code>BRA</alpha_3_code>
            <numeric>076</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>britishindianoceanterritory</country_name>
            <alpha_2_code>IO</alpha_2_code>
            <alpha_3_code>IOT</alpha_3_code>
            <numeric>086</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bruneidarussalam</country_name>
            <alpha_2_code>BN</alpha_2_code>
            <alpha_3_code>BRN</alpha_3_code>
            <numeric>096</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>bulgaria</country_name>
            <alpha_2_code>BG</alpha_2_code>
            <alpha_3_code>BGR</alpha_3_code>
            <numeric>100</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>burkinafaso</country_name>
            <alpha_2_code>BF</alpha_2_code>
            <alpha_3_code>BFA</alpha_3_code>
            <numeric>854</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>burundi</country_name>
            <alpha_2_code>BI</alpha_2_code>
            <alpha_3_code>BDI</alpha_3_code>
            <numeric>108</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>caboverde</country_name>
            <alpha_2_code>CV</alpha_2_code>
            <alpha_3_code>CPV</alpha_3_code>
            <numeric>132</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cambodia</country_name>
            <alpha_2_code>KH</alpha_2_code>
            <alpha_3_code>KHM</alpha_3_code>
            <numeric>116</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cameroon</country_name>
            <alpha_2_code>CM</alpha_2_code>
            <alpha_3_code>CMR</alpha_3_code>
            <numeric>120</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>canada</country_name>
            <alpha_2_code>CA</alpha_2_code>
            <alpha_3_code>CAN</alpha_3_code>
            <numeric>124</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>caymanislands</country_name>
            <alpha_2_code>KY</alpha_2_code>
            <alpha_3_code>CYM</alpha_3_code>
            <numeric>136</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>centralafricanrepublic</country_name>
            <alpha_2_code>CF</alpha_2_code>
            <alpha_3_code>CAF</alpha_3_code>
            <numeric>140</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>chad</country_name>
            <alpha_2_code>TD</alpha_2_code>
            <alpha_3_code>TCD</alpha_3_code>
            <numeric>148</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>chile</country_name>
            <alpha_2_code>CL</alpha_2_code>
            <alpha_3_code>CHL</alpha_3_code>
            <numeric>152</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>china</country_name>
            <alpha_2_code>CN</alpha_2_code>
            <alpha_3_code>CHN</alpha_3_code>
            <numeric>156</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>christmasisland</country_name>
            <alpha_2_code>CX</alpha_2_code>
            <alpha_3_code>CXR</alpha_3_code>
            <numeric>162</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cocos(keeling)islands</country_name>
            <alpha_2_code>CC</alpha_2_code>
            <alpha_3_code>CCK</alpha_3_code>
            <numeric>166</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>colombia</country_name>
            <alpha_2_code>CO</alpha_2_code>
            <alpha_3_code>COL</alpha_3_code>
            <numeric>170</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>comoros</country_name>
            <alpha_2_code>KM</alpha_2_code>
            <alpha_3_code>COM</alpha_3_code>
            <numeric>174</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>congo(thedemocraticrepublicofthe)</country_name>
            <alpha_2_code>CD</alpha_2_code>
            <alpha_3_code>COD</alpha_3_code>
            <numeric>180</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>congo</country_name>
            <alpha_2_code>CG</alpha_2_code>
            <alpha_3_code>COG</alpha_3_code>
            <numeric>178</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cookislands</country_name>
            <alpha_2_code>CK</alpha_2_code>
            <alpha_3_code>COK</alpha_3_code>
            <numeric>184</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>costarica</country_name>
            <alpha_2_code>CR</alpha_2_code>
            <alpha_3_code>CRI</alpha_3_code>
            <numeric>188</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>croatia</country_name>
            <alpha_2_code>HR</alpha_2_code>
            <alpha_3_code>HRV</alpha_3_code>
            <numeric>191</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cuba</country_name>
            <alpha_2_code>CU</alpha_2_code>
            <alpha_3_code>CUB</alpha_3_code>
            <numeric>192</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>curaçao</country_name>
            <alpha_2_code>CW</alpha_2_code>
            <alpha_3_code>CUW</alpha_3_code>
            <numeric>531</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>cyprus</country_name>
            <alpha_2_code>CY</alpha_2_code>
            <alpha_3_code>CYP</alpha_3_code>
            <numeric>196</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>czechia</country_name>
            <alpha_2_code>CZ</alpha_2_code>
            <alpha_3_code>CZE</alpha_3_code>
            <numeric>203</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>côted'ivoire</country_name>
            <alpha_2_code>CI</alpha_2_code>
            <alpha_3_code>CIV</alpha_3_code>
            <numeric>384</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>denmark</country_name>
            <alpha_2_code>DK</alpha_2_code>
            <alpha_3_code>DNK</alpha_3_code>
            <numeric>208</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>djibouti</country_name>
            <alpha_2_code>DJ</alpha_2_code>
            <alpha_3_code>DJI</alpha_3_code>
            <numeric>262</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>dominica</country_name>
            <alpha_2_code>DM</alpha_2_code>
            <alpha_3_code>DMA</alpha_3_code>
            <numeric>212</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>dominicanrepublic</country_name>
            <alpha_2_code>DO</alpha_2_code>
            <alpha_3_code>DOM</alpha_3_code>
            <numeric>214</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ecuador</country_name>
            <alpha_2_code>EC</alpha_2_code>
            <alpha_3_code>ECU</alpha_3_code>
            <numeric>218</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>egypt</country_name>
            <alpha_2_code>EG</alpha_2_code>
            <alpha_3_code>EGY</alpha_3_code>
            <numeric>818</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>elsalvador</country_name>
            <alpha_2_code>SV</alpha_2_code>
            <alpha_3_code>SLV</alpha_3_code>
            <numeric>222</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>equatorialguinea</country_name>
            <alpha_2_code>GQ</alpha_2_code>
            <alpha_3_code>GNQ</alpha_3_code>
            <numeric>226</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>eritrea</country_name>
            <alpha_2_code>ER</alpha_2_code>
            <alpha_3_code>ERI</alpha_3_code>
            <numeric>232</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>estonia</country_name>
            <alpha_2_code>EE</alpha_2_code>
            <alpha_3_code>EST</alpha_3_code>
            <numeric>233</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>eswatini</country_name>
            <alpha_2_code>SZ</alpha_2_code>
            <alpha_3_code>SWZ</alpha_3_code>
            <numeric>748</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ethiopia</country_name>
            <alpha_2_code>ET</alpha_2_code>
            <alpha_3_code>ETH</alpha_3_code>
            <numeric>231</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>falklandislands[malvinas]</country_name>
            <alpha_2_code>FK</alpha_2_code>
            <alpha_3_code>FLK</alpha_3_code>
            <numeric>238</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>faroeislands</country_name>
            <alpha_2_code>FO</alpha_2_code>
            <alpha_3_code>FRO</alpha_3_code>
            <numeric>234</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>fiji</country_name>
            <alpha_2_code>FJ</alpha_2_code>
            <alpha_3_code>FJI</alpha_3_code>
            <numeric>242</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>finland</country_name>
            <alpha_2_code>FI</alpha_2_code>
            <alpha_3_code>FIN</alpha_3_code>
            <numeric>246</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>france</country_name>
            <alpha_2_code>FR</alpha_2_code>
            <alpha_3_code>FRA</alpha_3_code>
            <numeric>250</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>frenchguiana</country_name>
            <alpha_2_code>GF</alpha_2_code>
            <alpha_3_code>GUF</alpha_3_code>
            <numeric>254</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>frenchpolynesia</country_name>
            <alpha_2_code>PF</alpha_2_code>
            <alpha_3_code>PYF</alpha_3_code>
            <numeric>258</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>frenchsouthernterritories</country_name>
            <alpha_2_code>TF</alpha_2_code>
            <alpha_3_code>ATF</alpha_3_code>
            <numeric>260</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>gabon</country_name>
            <alpha_2_code>GA</alpha_2_code>
            <alpha_3_code>GAB</alpha_3_code>
            <numeric>266</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>gambia</country_name>
            <alpha_2_code>GM</alpha_2_code>
            <alpha_3_code>GMB</alpha_3_code>
            <numeric>270</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>georgia</country_name>
            <alpha_2_code>GE</alpha_2_code>
            <alpha_3_code>GEO</alpha_3_code>
            <numeric>268</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>germany</country_name>
            <alpha_2_code>DE</alpha_2_code>
            <alpha_3_code>DEU</alpha_3_code>
            <numeric>276</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ghana</country_name>
            <alpha_2_code>GH</alpha_2_code>
            <alpha_3_code>GHA</alpha_3_code>
            <numeric>288</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>gibraltar</country_name>
            <alpha_2_code>GI</alpha_2_code>
            <alpha_3_code>GIB</alpha_3_code>
            <numeric>292</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>greece</country_name>
            <alpha_2_code>GR</alpha_2_code>
            <alpha_3_code>GRC</alpha_3_code>
            <numeric>300</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>greenland</country_name>
            <alpha_2_code>GL</alpha_2_code>
            <alpha_3_code>GRL</alpha_3_code>
            <numeric>304</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>grenada</country_name>
            <alpha_2_code>GD</alpha_2_code>
            <alpha_3_code>GRD</alpha_3_code>
            <numeric>308</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guadeloupe</country_name>
            <alpha_2_code>GP</alpha_2_code>
            <alpha_3_code>GLP</alpha_3_code>
            <numeric>312</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guam</country_name>
            <alpha_2_code>GU</alpha_2_code>
            <alpha_3_code>GUM</alpha_3_code>
            <numeric>316</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guatemala</country_name>
            <alpha_2_code>GT</alpha_2_code>
            <alpha_3_code>GTM</alpha_3_code>
            <numeric>320</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guernsey</country_name>
            <alpha_2_code>GG</alpha_2_code>
            <alpha_3_code>GGY</alpha_3_code>
            <numeric>831</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guinea</country_name>
            <alpha_2_code>GN</alpha_2_code>
            <alpha_3_code>GIN</alpha_3_code>
            <numeric>324</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guinea-bissau</country_name>
            <alpha_2_code>GW</alpha_2_code>
            <alpha_3_code>GNB</alpha_3_code>
            <numeric>624</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>guyana</country_name>
            <alpha_2_code>GY</alpha_2_code>
            <alpha_3_code>GUY</alpha_3_code>
            <numeric>328</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>haiti</country_name>
            <alpha_2_code>HT</alpha_2_code>
            <alpha_3_code>HTI</alpha_3_code>
            <numeric>332</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>heardislandandmcdonaldislands</country_name>
            <alpha_2_code>HM</alpha_2_code>
            <alpha_3_code>HMD</alpha_3_code>
            <numeric>334</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>holysee</country_name>
            <alpha_2_code>VA</alpha_2_code>
            <alpha_3_code>VAT</alpha_3_code>
            <numeric>336</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>honduras</country_name>
            <alpha_2_code>HN</alpha_2_code>
            <alpha_3_code>HND</alpha_3_code>
            <numeric>340</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>hongkong</country_name>
            <alpha_2_code>HK</alpha_2_code>
            <alpha_3_code>HKG</alpha_3_code>
            <numeric>344</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>hungary</country_name>
            <alpha_2_code>HU</alpha_2_code>
            <alpha_3_code>HUN</alpha_3_code>
            <numeric>348</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>iceland</country_name>
            <alpha_2_code>IS</alpha_2_code>
            <alpha_3_code>ISL</alpha_3_code>
            <numeric>352</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>india</country_name>
            <alpha_2_code>IN</alpha_2_code>
            <alpha_3_code>IND</alpha_3_code>
            <numeric>356</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>indonesia</country_name>
            <alpha_2_code>ID</alpha_2_code>
            <alpha_3_code>IDN</alpha_3_code>
            <numeric>360</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>iran(islamicrepublicof)</country_name>
            <alpha_2_code>IR</alpha_2_code>
            <alpha_3_code>IRN</alpha_3_code>
            <numeric>364</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>iraq</country_name>
            <alpha_2_code>IQ</alpha_2_code>
            <alpha_3_code>IRQ</alpha_3_code>
            <numeric>368</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ireland</country_name>
            <alpha_2_code>IE</alpha_2_code>
            <alpha_3_code>IRL</alpha_3_code>
            <numeric>372</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>isleofman</country_name>
            <alpha_2_code>IM</alpha_2_code>
            <alpha_3_code>IMN</alpha_3_code>
            <numeric>833</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>israel</country_name>
            <alpha_2_code>IL</alpha_2_code>
            <alpha_3_code>ISR</alpha_3_code>
            <numeric>376</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>italy</country_name>
            <alpha_2_code>IT</alpha_2_code>
            <alpha_3_code>ITA</alpha_3_code>
            <numeric>380</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>jamaica</country_name>
            <alpha_2_code>JM</alpha_2_code>
            <alpha_3_code>JAM</alpha_3_code>
            <numeric>388</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>japan</country_name>
            <alpha_2_code>JP</alpha_2_code>
            <alpha_3_code>JPN</alpha_3_code>
            <numeric>392</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>jersey</country_name>
            <alpha_2_code>JE</alpha_2_code>
            <alpha_3_code>JEY</alpha_3_code>
            <numeric>832</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>jordan</country_name>
            <alpha_2_code>JO</alpha_2_code>
            <alpha_3_code>JOR</alpha_3_code>
            <numeric>400</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>kazakhstan</country_name>
            <alpha_2_code>KZ</alpha_2_code>
            <alpha_3_code>KAZ</alpha_3_code>
            <numeric>398</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>kenya</country_name>
            <alpha_2_code>KE</alpha_2_code>
            <alpha_3_code>KEN</alpha_3_code>
            <numeric>404</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>kiribati</country_name>
            <alpha_2_code>KI</alpha_2_code>
            <alpha_3_code>KIR</alpha_3_code>
            <numeric>296</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>korea(thedemocraticpeople'srepublicof)</country_name>
            <alpha_2_code>KP</alpha_2_code>
            <alpha_3_code>PRK</alpha_3_code>
            <numeric>408</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>korea(therepublicof)</country_name>
            <alpha_2_code>KR</alpha_2_code>
            <alpha_3_code>KOR</alpha_3_code>
            <numeric>410</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>kuwait</country_name>
            <alpha_2_code>KW</alpha_2_code>
            <alpha_3_code>KWT</alpha_3_code>
            <numeric>414</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>kyrgyzstan</country_name>
            <alpha_2_code>KG</alpha_2_code>
            <alpha_3_code>KGZ</alpha_3_code>
            <numeric>417</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>laopeople'sdemocraticrepublic</country_name>
            <alpha_2_code>LA</alpha_2_code>
            <alpha_3_code>LAO</alpha_3_code>
            <numeric>418</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>latvia</country_name>
            <alpha_2_code>LV</alpha_2_code>
            <alpha_3_code>LVA</alpha_3_code>
            <numeric>428</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>lebanon</country_name>
            <alpha_2_code>LB</alpha_2_code>
            <alpha_3_code>LBN</alpha_3_code>
            <numeric>422</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>lesotho</country_name>
            <alpha_2_code>LS</alpha_2_code>
            <alpha_3_code>LSO</alpha_3_code>
            <numeric>426</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>liberia</country_name>
            <alpha_2_code>LR</alpha_2_code>
            <alpha_3_code>LBR</alpha_3_code>
            <numeric>430</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>libya</country_name>
            <alpha_2_code>LY</alpha_2_code>
            <alpha_3_code>LBY</alpha_3_code>
            <numeric>434</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>liechtenstein</country_name>
            <alpha_2_code>LI</alpha_2_code>
            <alpha_3_code>LIE</alpha_3_code>
            <numeric>438</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>lithuania</country_name>
            <alpha_2_code>LT</alpha_2_code>
            <alpha_3_code>LTU</alpha_3_code>
            <numeric>440</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>luxembourg</country_name>
            <alpha_2_code>LU</alpha_2_code>
            <alpha_3_code>LUX</alpha_3_code>
            <numeric>442</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>macao</country_name>
            <alpha_2_code>MO</alpha_2_code>
            <alpha_3_code>MAC</alpha_3_code>
            <numeric>446</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>madagascar</country_name>
            <alpha_2_code>MG</alpha_2_code>
            <alpha_3_code>MDG</alpha_3_code>
            <numeric>450</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>malawi</country_name>
            <alpha_2_code>MW</alpha_2_code>
            <alpha_3_code>MWI</alpha_3_code>
            <numeric>454</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>malaysia</country_name>
            <alpha_2_code>MY</alpha_2_code>
            <alpha_3_code>MYS</alpha_3_code>
            <numeric>458</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>maldives</country_name>
            <alpha_2_code>MV</alpha_2_code>
            <alpha_3_code>MDV</alpha_3_code>
            <numeric>462</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mali</country_name>
            <alpha_2_code>ML</alpha_2_code>
            <alpha_3_code>MLI</alpha_3_code>
            <numeric>466</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>malta</country_name>
            <alpha_2_code>MT</alpha_2_code>
            <alpha_3_code>MLT</alpha_3_code>
            <numeric>470</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>marshallislands</country_name>
            <alpha_2_code>MH</alpha_2_code>
            <alpha_3_code>MHL</alpha_3_code>
            <numeric>584</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>martinique</country_name>
            <alpha_2_code>MQ</alpha_2_code>
            <alpha_3_code>MTQ</alpha_3_code>
            <numeric>474</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mauritania</country_name>
            <alpha_2_code>MR</alpha_2_code>
            <alpha_3_code>MRT</alpha_3_code>
            <numeric>478</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mauritius</country_name>
            <alpha_2_code>MU</alpha_2_code>
            <alpha_3_code>MUS</alpha_3_code>
            <numeric>480</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mayotte</country_name>
            <alpha_2_code>YT</alpha_2_code>
            <alpha_3_code>MYT</alpha_3_code>
            <numeric>175</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mexico</country_name>
            <alpha_2_code>MX</alpha_2_code>
            <alpha_3_code>MEX</alpha_3_code>
            <numeric>484</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>micronesia(federatedstatesof)</country_name>
            <alpha_2_code>FM</alpha_2_code>
            <alpha_3_code>FSM</alpha_3_code>
            <numeric>583</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>moldova(therepublicof)</country_name>
            <alpha_2_code>MD</alpha_2_code>
            <alpha_3_code>MDA</alpha_3_code>
            <numeric>498</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>monaco</country_name>
            <alpha_2_code>MC</alpha_2_code>
            <alpha_3_code>MCO</alpha_3_code>
            <numeric>492</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mongolia</country_name>
            <alpha_2_code>MN</alpha_2_code>
            <alpha_3_code>MNG</alpha_3_code>
            <numeric>496</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>montenegro</country_name>
            <alpha_2_code>ME</alpha_2_code>
            <alpha_3_code>MNE</alpha_3_code>
            <numeric>499</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>montserrat</country_name>
            <alpha_2_code>MS</alpha_2_code>
            <alpha_3_code>MSR</alpha_3_code>
            <numeric>500</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>morocco</country_name>
            <alpha_2_code>MA</alpha_2_code>
            <alpha_3_code>MAR</alpha_3_code>
            <numeric>504</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>mozambique</country_name>
            <alpha_2_code>MZ</alpha_2_code>
            <alpha_3_code>MOZ</alpha_3_code>
            <numeric>508</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>myanmar</country_name>
            <alpha_2_code>MM</alpha_2_code>
            <alpha_3_code>MMR</alpha_3_code>
            <numeric>104</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>namibia</country_name>
            <alpha_2_code>NA</alpha_2_code>
            <alpha_3_code>NAM</alpha_3_code>
            <numeric>516</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>nauru</country_name>
            <alpha_2_code>NR</alpha_2_code>
            <alpha_3_code>NRU</alpha_3_code>
            <numeric>520</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>nepal</country_name>
            <alpha_2_code>NP</alpha_2_code>
            <alpha_3_code>NPL</alpha_3_code>
            <numeric>524</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>netherlands</country_name>
            <alpha_2_code>NL</alpha_2_code>
            <alpha_3_code>NLD</alpha_3_code>
            <numeric>528</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>newcaledonia</country_name>
            <alpha_2_code>NC</alpha_2_code>
            <alpha_3_code>NCL</alpha_3_code>
            <numeric>540</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>newzealand</country_name>
            <alpha_2_code>NZ</alpha_2_code>
            <alpha_3_code>NZL</alpha_3_code>
            <numeric>554</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>nicaragua</country_name>
            <alpha_2_code>NI</alpha_2_code>
            <alpha_3_code>NIC</alpha_3_code>
            <numeric>558</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>niger</country_name>
            <alpha_2_code>NE</alpha_2_code>
            <alpha_3_code>NER</alpha_3_code>
            <numeric>562</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>nigeria</country_name>
            <alpha_2_code>NG</alpha_2_code>
            <alpha_3_code>NGA</alpha_3_code>
            <numeric>566</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>niue</country_name>
            <alpha_2_code>NU</alpha_2_code>
            <alpha_3_code>NIU</alpha_3_code>
            <numeric>570</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>norfolkisland</country_name>
            <alpha_2_code>NF</alpha_2_code>
            <alpha_3_code>NFK</alpha_3_code>
            <numeric>574</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>northernmarianaislands</country_name>
            <alpha_2_code>MP</alpha_2_code>
            <alpha_3_code>MNP</alpha_3_code>
            <numeric>580</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>norway</country_name>
            <alpha_2_code>NO</alpha_2_code>
            <alpha_3_code>NOR</alpha_3_code>
            <numeric>578</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>oman</country_name>
            <alpha_2_code>OM</alpha_2_code>
            <alpha_3_code>OMN</alpha_3_code>
            <numeric>512</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>pakistan</country_name>
            <alpha_2_code>PK</alpha_2_code>
            <alpha_3_code>PAK</alpha_3_code>
            <numeric>586</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>palau</country_name>
            <alpha_2_code>PW</alpha_2_code>
            <alpha_3_code>PLW</alpha_3_code>
            <numeric>585</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>palestine,stateof</country_name>
            <alpha_2_code>PS</alpha_2_code>
            <alpha_3_code>PSE</alpha_3_code>
            <numeric>275</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>panama</country_name>
            <alpha_2_code>PA</alpha_2_code>
            <alpha_3_code>PAN</alpha_3_code>
            <numeric>591</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>papuanewguinea</country_name>
            <alpha_2_code>PG</alpha_2_code>
            <alpha_3_code>PNG</alpha_3_code>
            <numeric>598</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>paraguay</country_name>
            <alpha_2_code>PY</alpha_2_code>
            <alpha_3_code>PRY</alpha_3_code>
            <numeric>600</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>peru</country_name>
            <alpha_2_code>PE</alpha_2_code>
            <alpha_3_code>PER</alpha_3_code>
            <numeric>604</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>philippines</country_name>
            <alpha_2_code>PH</alpha_2_code>
            <alpha_3_code>PHL</alpha_3_code>
            <numeric>608</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>pitcairn</country_name>
            <alpha_2_code>PN</alpha_2_code>
            <alpha_3_code>PCN</alpha_3_code>
            <numeric>612</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>poland</country_name>
            <alpha_2_code>PL</alpha_2_code>
            <alpha_3_code>POL</alpha_3_code>
            <numeric>616</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>portugal</country_name>
            <alpha_2_code>PT</alpha_2_code>
            <alpha_3_code>PRT</alpha_3_code>
            <numeric>620</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>puertorico</country_name>
            <alpha_2_code>PR</alpha_2_code>
            <alpha_3_code>PRI</alpha_3_code>
            <numeric>630</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>qatar</country_name>
            <alpha_2_code>QA</alpha_2_code>
            <alpha_3_code>QAT</alpha_3_code>
            <numeric>634</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>republicofnorthmacedonia</country_name>
            <alpha_2_code>MK</alpha_2_code>
            <alpha_3_code>MKD</alpha_3_code>
            <numeric>807</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>romania</country_name>
            <alpha_2_code>RO</alpha_2_code>
            <alpha_3_code>ROU</alpha_3_code>
            <numeric>642</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>russianfederation</country_name>
            <alpha_2_code>RU</alpha_2_code>
            <alpha_3_code>RUS</alpha_3_code>
            <numeric>643</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>rwanda</country_name>
            <alpha_2_code>RW</alpha_2_code>
            <alpha_3_code>RWA</alpha_3_code>
            <numeric>646</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>réunion</country_name>
            <alpha_2_code>RE</alpha_2_code>
            <alpha_3_code>REU</alpha_3_code>
            <numeric>638</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintbarthélemy</country_name>
            <alpha_2_code>BL</alpha_2_code>
            <alpha_3_code>BLM</alpha_3_code>
            <numeric>652</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sainthelena,ascensionandtristandacunha</country_name>
            <alpha_2_code>SH</alpha_2_code>
            <alpha_3_code>SHN</alpha_3_code>
            <numeric>654</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintkittsandnevis</country_name>
            <alpha_2_code>KN</alpha_2_code>
            <alpha_3_code>KNA</alpha_3_code>
            <numeric>659</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintlucia</country_name>
            <alpha_2_code>LC</alpha_2_code>
            <alpha_3_code>LCA</alpha_3_code>
            <numeric>662</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintmartin(frenchpart)</country_name>
            <alpha_2_code>MF</alpha_2_code>
            <alpha_3_code>MAF</alpha_3_code>
            <numeric>663</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintpierreandmiquelon</country_name>
            <alpha_2_code>PM</alpha_2_code>
            <alpha_3_code>SPM</alpha_3_code>
            <numeric>666</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saintvincentandthegrenadines</country_name>
            <alpha_2_code>VC</alpha_2_code>
            <alpha_3_code>VCT</alpha_3_code>
            <numeric>670</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>samoa</country_name>
            <alpha_2_code>WS</alpha_2_code>
            <alpha_3_code>WSM</alpha_3_code>
            <numeric>882</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sanmarino</country_name>
            <alpha_2_code>SM</alpha_2_code>
            <alpha_3_code>SMR</alpha_3_code>
            <numeric>674</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saotomeandprincipe</country_name>
            <alpha_2_code>ST</alpha_2_code>
            <alpha_3_code>STP</alpha_3_code>
            <numeric>678</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>saudiarabia</country_name>
            <alpha_2_code>SA</alpha_2_code>
            <alpha_3_code>SAU</alpha_3_code>
            <numeric>682</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>senegal</country_name>
            <alpha_2_code>SN</alpha_2_code>
            <alpha_3_code>SEN</alpha_3_code>
            <numeric>686</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>serbia</country_name>
            <alpha_2_code>RS</alpha_2_code>
            <alpha_3_code>SRB</alpha_3_code>
            <numeric>688</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>seychelles</country_name>
            <alpha_2_code>SC</alpha_2_code>
            <alpha_3_code>SYC</alpha_3_code>
            <numeric>690</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sierraleone</country_name>
            <alpha_2_code>SL</alpha_2_code>
            <alpha_3_code>SLE</alpha_3_code>
            <numeric>694</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>singapore</country_name>
            <alpha_2_code>SG</alpha_2_code>
            <alpha_3_code>SGP</alpha_3_code>
            <numeric>702</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sintmaarten(dutchpart)</country_name>
            <alpha_2_code>SX</alpha_2_code>
            <alpha_3_code>SXM</alpha_3_code>
            <numeric>534</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>slovakia</country_name>
            <alpha_2_code>SK</alpha_2_code>
            <alpha_3_code>SVK</alpha_3_code>
            <numeric>703</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>slovenia</country_name>
            <alpha_2_code>SI</alpha_2_code>
            <alpha_3_code>SVN</alpha_3_code>
            <numeric>705</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>solomonislands</country_name>
            <alpha_2_code>SB</alpha_2_code>
            <alpha_3_code>SLB</alpha_3_code>
            <numeric>090</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>somalia</country_name>
            <alpha_2_code>SO</alpha_2_code>
            <alpha_3_code>SOM</alpha_3_code>
            <numeric>706</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>southafrica</country_name>
            <alpha_2_code>ZA</alpha_2_code>
            <alpha_3_code>ZAF</alpha_3_code>
            <numeric>710</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>southgeorgiaandthesouthsandwichislands</country_name>
            <alpha_2_code>GS</alpha_2_code>
            <alpha_3_code>SGS</alpha_3_code>
            <numeric>239</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>southsudan</country_name>
            <alpha_2_code>SS</alpha_2_code>
            <alpha_3_code>SSD</alpha_3_code>
            <numeric>728</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>spain</country_name>
            <alpha_2_code>ES</alpha_2_code>
            <alpha_3_code>ESP</alpha_3_code>
            <numeric>724</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>srilanka</country_name>
            <alpha_2_code>LK</alpha_2_code>
            <alpha_3_code>LKA</alpha_3_code>
            <numeric>144</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sudan</country_name>
            <alpha_2_code>SD</alpha_2_code>
            <alpha_3_code>SDN</alpha_3_code>
            <numeric>729</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>suriname</country_name>
            <alpha_2_code>SR</alpha_2_code>
            <alpha_3_code>SUR</alpha_3_code>
            <numeric>740</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>svalbardandjanmayen</country_name>
            <alpha_2_code>SJ</alpha_2_code>
            <alpha_3_code>SJM</alpha_3_code>
            <numeric>744</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>sweden</country_name>
            <alpha_2_code>SE</alpha_2_code>
            <alpha_3_code>SWE</alpha_3_code>
            <numeric>752</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>switzerland</country_name>
            <alpha_2_code>CH</alpha_2_code>
            <alpha_3_code>CHE</alpha_3_code>
            <numeric>756</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>syrianarabrepublic</country_name>
            <alpha_2_code>SY</alpha_2_code>
            <alpha_3_code>SYR</alpha_3_code>
            <numeric>760</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>taiwan</country_name>
            <alpha_2_code>TW</alpha_2_code>
            <alpha_3_code>TWN</alpha_3_code>
            <numeric>158</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tajikistan</country_name>
            <alpha_2_code>TJ</alpha_2_code>
            <alpha_3_code>TJK</alpha_3_code>
            <numeric>762</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tanzania,unitedrepublicof</country_name>
            <alpha_2_code>TZ</alpha_2_code>
            <alpha_3_code>TZA</alpha_3_code>
            <numeric>834</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>thailand</country_name>
            <alpha_2_code>TH</alpha_2_code>
            <alpha_3_code>THA</alpha_3_code>
            <numeric>764</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>timor-leste</country_name>
            <alpha_2_code>TL</alpha_2_code>
            <alpha_3_code>TLS</alpha_3_code>
            <numeric>626</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>togo</country_name>
            <alpha_2_code>TG</alpha_2_code>
            <alpha_3_code>TGO</alpha_3_code>
            <numeric>768</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tokelau</country_name>
            <alpha_2_code>TK</alpha_2_code>
            <alpha_3_code>TKL</alpha_3_code>
            <numeric>772</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tonga</country_name>
            <alpha_2_code>TO</alpha_2_code>
            <alpha_3_code>TON</alpha_3_code>
            <numeric>776</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>trinidadandtobago</country_name>
            <alpha_2_code>TT</alpha_2_code>
            <alpha_3_code>TTO</alpha_3_code>
            <numeric>780</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tunisia</country_name>
            <alpha_2_code>TN</alpha_2_code>
            <alpha_3_code>TUN</alpha_3_code>
            <numeric>788</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>turkey</country_name>
            <alpha_2_code>TR</alpha_2_code>
            <alpha_3_code>TUR</alpha_3_code>
            <numeric>792</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>turkmenistan</country_name>
            <alpha_2_code>TM</alpha_2_code>
            <alpha_3_code>TKM</alpha_3_code>
            <numeric>795</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>turksandcaicosislands</country_name>
            <alpha_2_code>TC</alpha_2_code>
            <alpha_3_code>TCA</alpha_3_code>
            <numeric>796</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>tuvalu</country_name>
            <alpha_2_code>TV</alpha_2_code>
            <alpha_3_code>TUV</alpha_3_code>
            <numeric>798</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>uganda</country_name>
            <alpha_2_code>UG</alpha_2_code>
            <alpha_3_code>UGA</alpha_3_code>
            <numeric>800</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ukraine</country_name>
            <alpha_2_code>UA</alpha_2_code>
            <alpha_3_code>UKR</alpha_3_code>
            <numeric>804</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>unitedarabemirates</country_name>
            <alpha_2_code>AE</alpha_2_code>
            <alpha_3_code>ARE</alpha_3_code>
            <numeric>784</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>unitedkingdom</country_name>
            <alpha_2_code>GB</alpha_2_code>
            <alpha_3_code>GBR</alpha_3_code>
            <numeric>826</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>unitedstatesminoroutlyingislands</country_name>
            <alpha_2_code>UM</alpha_2_code>
            <alpha_3_code>UMI</alpha_3_code>
            <numeric>581</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>unitedstatesofamerica</country_name>
            <alpha_2_code>US</alpha_2_code>
            <alpha_3_code>USA</alpha_3_code>
            <numeric>840</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>uruguay</country_name>
            <alpha_2_code>UY</alpha_2_code>
            <alpha_3_code>URY</alpha_3_code>
            <numeric>858</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>uzbekistan</country_name>
            <alpha_2_code>UZ</alpha_2_code>
            <alpha_3_code>UZB</alpha_3_code>
            <numeric>860</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>vanuatu</country_name>
            <alpha_2_code>VU</alpha_2_code>
            <alpha_3_code>VUT</alpha_3_code>
            <numeric>548</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>venezuela</country_name>
            <alpha_2_code>VE</alpha_2_code>
            <alpha_3_code>VEN</alpha_3_code>
            <numeric>862</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>vietnam</country_name>
            <alpha_2_code>VN</alpha_2_code>
            <alpha_3_code>VNM</alpha_3_code>
            <numeric>704</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>virginislands(british)</country_name>
            <alpha_2_code>VG</alpha_2_code>
            <alpha_3_code>VGB</alpha_3_code>
            <numeric>092</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>virginislands(u.s.)</country_name>
            <alpha_2_code>VI</alpha_2_code>
            <alpha_3_code>VIR</alpha_3_code>
            <numeric>850</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>wallisandfutuna</country_name>
            <alpha_2_code>WF</alpha_2_code>
            <alpha_3_code>WLF</alpha_3_code>
            <numeric>876</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>westernsahara</country_name>
            <alpha_2_code>EH</alpha_2_code>
            <alpha_3_code>ESH</alpha_3_code>
            <numeric>732</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>yemen</country_name>
            <alpha_2_code>YE</alpha_2_code>
            <alpha_3_code>YEM</alpha_3_code>
            <numeric>887</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>zambia</country_name>
            <alpha_2_code>ZM</alpha_2_code>
            <alpha_3_code>ZMB</alpha_3_code>
            <numeric>894</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>zimbabwe</country_name>
            <alpha_2_code>ZW</alpha_2_code>
            <alpha_3_code>ZWE</alpha_3_code>
            <numeric>716</numeric>
        </country_lookup>
        <country_lookup>
            <country_name>ålandislands</country_name>
            <alpha_2_code>AX</alpha_2_code>
            <alpha_3_code>ALA</alpha_3_code>
            <numeric>248</numeric>
        </country_lookup>
    </fhcf:country_lookup_list>

</xsl:stylesheet>
