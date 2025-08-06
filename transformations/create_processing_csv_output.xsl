<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fhc="https://github.com/firehawk-consulting/firehawk"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tl="https://github.com/firehawk-consulting/firehawk/schemas/transaction_log.xsd"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all">
    <!--xsl:output method="text"/-->
    <xsl:variable name="linefeed"><xsl:text>&#xA;</xsl:text></xsl:variable>
    <xsl:variable name="carriagereturn"><xsl:text>&#13;</xsl:text></xsl:variable>
    <xsl:variable name="space" select="' '"/>
    <!--<xsl:variable name="delimiter"><xsl:text>&#x09;</xsl:text></xsl:variable>-->
    <xsl:variable name="delimiter">
        <xsl:text>|</xsl:text>
    </xsl:variable>
    <xsl:param name="summarylog.filename"/>
    <xsl:param name="summarylog.file.extension"/>
    <xsl:param name="process.summary.name"/>

    <xsl:output indent="yes" omit-xml-declaration="no" method="xml"/>
    <xsl:mode streamable="yes" on-no-match="shallow-skip" use-accumulators="#all"/>

    <xsl:accumulator name="record.count.by.status" as="map(xs:string,xs:integer)" initial-value="map {}" streamable="yes">
        <xsl:accumulator-rule match="tl:status/text()">
            <xsl:variable name="new.value" select="if (map:contains($value,.)) then map:get($value,.) else 0"/>
            <xsl:sequence select="map:put($value, xs:string(.), $new.value + 1)"/>
        </xsl:accumulator-rule>
    </xsl:accumulator>

    <xsl:function name="fhc:forceValue" as="xs:decimal">
        <xsl:param name="inputdata"/>
        <xsl:choose>
            <xsl:when test="string-length(xs:string($inputdata))">
                <xsl:value-of select="$inputdata"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/">
        <tl:summary_log>
            <xsl:for-each-group select="copy-of(Process_Details/tl:transaction_record)" composite="yes" group-by="@tl:transaction_grouping">
                <xsl:variable name="currentsummarysplit">
                    <xsl:value-of select="current-grouping-key()"/>
                </xsl:variable>
                <tl:summary_log_information>
                    <xsl:attribute name="tl:filename">
                        <xsl:value-of select="'summarylevel_'"/>
                        <xsl:value-of select="$summarylog.filename"/>
                        <xsl:value-of select="'_'"/>
                        <xsl:value-of select="$currentsummarysplit"/>
                        <xsl:value-of select="'.txt'"/>
                    </xsl:attribute>
                    <xsl:attribute name="tl:logging_level" select="'summary'"/>
                    <tl:summarylogdetails>
                        <!--<xsl:value-of select="'Summary for Transaction Grouping'"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:text>Files Processed</xsl:text>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:text>Records Imported</xsl:text>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:text>Records Skipped</xsl:text>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:text>Records Failed</xsl:text>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:text>Total Records Processed</xsl:text>
                        <xsl:value-of select="$linefeed"/>
                        <xsl:value-of select="current-grouping-key()"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:value-of select="max(current-group()//tl:file_data/tl:instance_number)"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:value-of select="count(current-group()[tl:record_stats/tl:status = 'imported'])"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:value-of select="count(current-group()[tl:record_stats/tl:status = 'skipped'])"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:value-of select="count(current-group()[tl:record_stats/tl:status = 'failed'])"/>
                        <xsl:value-of select="$delimiter"/>
                        <xsl:value-of select="count(current-group())"/>
                        <xsl:value-of select="$linefeed"/>
                        <xsl:value-of select="$linefeed"/>-->
                        <xsl:call-template name="header-record"/>
                        <xsl:for-each-group select="copy-of(current-group())" group-by="tl:record_stats/tl:web_service_call_name">
                            <xsl:variable name="ws.call.name" select="current-grouping-key()"/>
                            <xsl:for-each-group select="copy-of(current-group())" group-by="tl:record_stats/tl:status">
                                <xsl:apply-templates select="current-group()"/>
                                <!--<xsl:if test="position() != last()">
                                    <xsl:value-of select="$linefeed"/>
                                </xsl:if>-->
                            </xsl:for-each-group>
                            <!--<xsl:if test="position() != last()">
                                <xsl:value-of select="$linefeed"/>
                            </xsl:if>-->
                        </xsl:for-each-group>
                    </tl:summarylogdetails>
                </tl:summary_log_information>
            </xsl:for-each-group>
        </tl:summary_log>
    </xsl:template>

    <xsl:template match="tl:transaction_record">
        <xsl:iterate select="./copy-of()">
            <xsl:value-of select="$process.summary.name"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:application_client_name"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:web_service_call_name"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="@tl:transaction_record_number"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:file_data/tl:instance_number"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:file_data/tl:source_filename"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:file_data/tl:record_number"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:source_id"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:workday_id"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:status"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="substring(normalize-space(tl:record_stats/tl:record_error_reason),1,256)"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="tl:record_stats/tl:record_error_code_message"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="substring(normalize-space(tl:record_stats/tl:record_error_description),1,1000)"/>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="$delimiter"/>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="normalize-space(tl:record_stats/tl:additional_information)"/>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="$linefeed"/>
        </xsl:iterate>
    </xsl:template>

    <xsl:template name="header-record">
        <xsl:text>Process File Name</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Application Client Name</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Web Service Call Name</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Process Record Number</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>File Number</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Source File Name</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>File Record Number</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Source Transaction Id</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Target Transaction Id</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Transaction Status</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Transaction Error Reason</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Transaction Error Code Message</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Transaction Error Details</xsl:text>
        <xsl:value-of select="$delimiter"/>
        <xsl:text>Additional Information</xsl:text>
        <xsl:value-of select="$linefeed"/>
    </xsl:template>
</xsl:stylesheet>
