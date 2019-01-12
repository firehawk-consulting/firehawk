<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atc="http://ltfinc.net/Accounting_Technology_Common"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tl="https://github.com/firehawk-consulting/firehawk/schemas/transaction_log.xsd"
    exclude-result-prefixes="xsl atc xs tl">
    <!--xsl:output method="text"/-->
    <xsl:variable name="linefeed"><xsl:text>&#xA;</xsl:text></xsl:variable>
    <xsl:variable name="carriagereturn"><xsl:text>&#13;</xsl:text></xsl:variable>
    <xsl:variable name="space" select="' '"/>
    <xsl:variable name="delimiter"><xsl:text>&#x09;</xsl:text></xsl:variable>
    <xsl:param name="summarylog.filename"/>
    <xsl:param name="summarylog.file.extension"/>

    <xsl:function name="atc:forceValue" as="xs:decimal">
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
            <xsl:for-each-group select="//tl:transaction_record" group-by="@tl:transaction_grouping">
                <xsl:variable name="currentsummarysplit">
                    <xsl:value-of select="current-grouping-key()"/>
                </xsl:variable>
                <tl:summary_log_information>
                    <xsl:attribute name="tl:filename">
                        <xsl:value-of select="'summarylevel_'"/>
                        <xsl:value-of select="$summarylog.filename"/>
                        <xsl:value-of select="$currentsummarysplit"/>
                        <xsl:value-of select="'.'"/>
                        <xsl:value-of select="$summarylog.file.extension"/>
                    </xsl:attribute>
                    <xsl:attribute name="tl:logging_level" select="'summary'"/>
                    <tl:summarylogdetails>
                        <html>
                            <head>
                                <style>
                                    table, th, td {
                                    border: 1px solid black;
                                    border-collapse: collapse;
                                    font-family:'Courier New';
                                    text-align:right;
                                    }
                                    table#summary { width: 100%;
                                    
                                    }
                                    th { background-color: orange;
                                    text-align: center;
                                    }
                                    th, td {
                                    padding: 3px;
                                    font-size:10px;
                                    }
                                </style>
                            </head>
                            <body>
                                
                                <h2 style="text-align:center;">Summary Processing Statistics</h2>
                                <p></p>
                                <table id="summary">
                                    <caption>
                                        <xsl:value-of select="'Summary for Transaction Grouping: '"/>
                                        <xsl:value-of select="current-grouping-key()"/>
                                    </caption>
                                    <tr>
                                        <th>Files Processed</th>
                                        <th>Records Imported</th>
                                        <th>Records Skipped</th>
                                        <th>Records Failed</th>
                                        <th>Total Records Processed</th>
                                        <th>Total Amount Processed</th>
                                    </tr>
                                    <tr>
                                        <td>
                                            <xsl:value-of select="max(current-group()//tl:file_data/tl:instance_number)"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="count(//current-group()[tl:record_stats/tl:status='imported'])"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="count(current-group()[tl:record_stats/tl:status='skipped'])"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="count(current-group()[tl:record_stats/tl:status='failed'])"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="count(current-group())"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="format-number(atc:forceValue(sum(current-group()//atc:forceValue(tl:record_stats//tl:amount))),'#,##0.00')"/>
                                        </td>
                                    </tr>
                                </table>
                                <br/>
                                <br/>
                                <xsl:for-each-group select="current-group()" group-by="tl:record_stats/tl:status">
                                    <table style="width:100%">
                                        <caption>
                                            <xsl:value-of select="current-grouping-key()"/>
                                            <xsl:value-of select="' Records'"/>
                                        </caption>
                                        <xsl:call-template name="header-record"/>
                                        <xsl:apply-templates select="current-group()"/>
                                    </table>
                                    <xsl:if test="position() != last()">
                                        <br/>
                                        <br/>
                                    </xsl:if>
                                </xsl:for-each-group>
                            </body>
                        </html>
                    </tl:summarylogdetails>
                </tl:summary_log_information>
            </xsl:for-each-group>
        </tl:summary_log>
    </xsl:template>
    
    <xsl:template match="tl:transaction_record">
        <tr>
            <td>
                <xsl:value-of select="@tl:transaction_record_number"/>
            </td>
            <td>
                <xsl:value-of select="tl:file_data/tl:instance_number"/>
            </td>
            <td>
                <xsl:value-of select="tl:file_data/tl:source_filename"/>
            </td>
            <td>
                <xsl:value-of select="tl:file_data/tl:record_number"/>
            </td>
            <td>
                <xsl:value-of select="tl:record_stats/tl:source_id"/>
            </td>
            <td>
                <xsl:choose>
                    <xsl:when test="tl:record_stats/tl:status = 'failed'"/>
                    <xsl:otherwise>
                        <xsl:value-of select="tl:record_stats/tl:workday_id"/>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <xsl:value-of select="tl:record_stats/tl:status"/>
            </td>
            <td>
                <xsl:value-of select="normalize-space(tl:record_error_info/tl:reason)"/>
            </td>
            <td>
                <xsl:value-of select="normalize-space(tl:record_error_info/tl:description)"/>
            </td>
            <td>
                <xsl:value-of select="format-number(atc:forceValue(tl:record_stats/tl:amount), '#,##0.00')"/>
            </td>
            <td>
                <xsl:value-of select="tl:record_stats/tl:additional_information"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template name="header-record">
        <tr>
            <th>Process Record Number</th>
            <th>File Number</th>
            <th>Source File Name</th>
            <th>File Record Number</th>
            <th>Source Transaction Id</th>
            <th>Workday Transaction Id</th>
            <th>Transaction Status</th>
            <th>Transaction Error Reason</th>
            <th>Transaction Error Details</th>
            <th>Transaction Amount</th>
            <th>Additional Information</th>
        </tr>
    </xsl:template>
</xsl:stylesheet>