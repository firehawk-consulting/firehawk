<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:tl="https://github.com/firehawk-consulting/firehawk/schemas/transaction_log.xsd" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- Transaction Attributes -->
    <xsl:param name="transaction.grouping" select="'nosplit'"/>
    <xsl:param name="record.counter"/>
    <!-- File Information -->
    <xsl:param name="file.number"/>
    <xsl:param name="file.record.counter"/>
    <xsl:param name="file.name"/>
    <!-- Transaction Details -->
    <xsl:param name="source.transaction.id"/>
    <xsl:param name="workday.transaction.id"/>
    <xsl:param name="record.status"/>
    <xsl:param name="additional.information" select="''"/>
    <xsl:param name="transaction.amount" select="0"/>
    <!-- Error Information -->
    <xsl:param name="error.reason" select="''"/>
    <xsl:param name="error.message.detail" select="''"/>

    <xsl:template match="/">
        <tl:transaction_record>
            <xsl:attribute name="tl:transaction_grouping" select="$transaction.grouping"/>
            <xsl:attribute name="tl:transaction_record_number" select="$record.counter"/>
            <tl:file_data>
                <xsl:if test="string-length(format-number($file.number, '####')) != 0">
                    <tl:instance_number>
                        <xsl:value-of select="$file.number"/>
                    </tl:instance_number>
                    <tl:record_number>
                        <xsl:value-of select="$file.record.counter"/>
                    </tl:record_number>
                </xsl:if>
                <xsl:if test="string-length($file.name) != 0">
                    <tl:source_filename>
                        <xsl:value-of select="$file.name"/>
                    </tl:source_filename>
                </xsl:if>
            </tl:file_data>
            <tl:record_stats>
                <tl:source_id>
                    <xsl:value-of select="$source.transaction.id"/>
                </tl:source_id>
                <tl:workday_id>
                    <xsl:value-of select="$workday.transaction.id"/>
                </tl:workday_id>
                <tl:status>
                    <xsl:value-of select="$record.status"/>
                </tl:status>
                <xsl:if test="string-length($additional.information) != 0">
                    <tl:additional_information>
                        <xsl:value-of select="$additional.information"/>
                    </tl:additional_information>
                </xsl:if>
                <tl:amount>
                    <xsl:value-of select="$transaction.amount"/>
                </tl:amount>
            </tl:record_stats>
            <tl:record_error_info>
                <xsl:if test="string-length($error.reason) != 0">
                    <tl:reason>
                        <xsl:value-of select="$error.reason"/>
                    </tl:reason>
                </xsl:if>
                <xsl:if test="string-length($error.message.detail) != 0">
                    <tl:description>
                        <xsl:value-of select="$error.message.detail"/>
                    </tl:description>
                </xsl:if>
            </tl:record_error_info>
        </tl:transaction_record>
    </xsl:template>
</xsl:stylesheet>