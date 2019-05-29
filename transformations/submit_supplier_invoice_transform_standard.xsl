<!-- Copyright 2014 Matthew Davis -->
<!-- This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/> -->
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:bsvc="urn:com.workday/bsvc"
    xmlns:wd="urn:com.workday/bsvc"
    xmlns:intsys="java:com.workday.esb.intsys.xpath.ParsedIntegrationSystemFunctions"
    xmlns:fhcsi="https://github.com/firehawk-consulting/firehawk/schemas/financials/supplierinvoicedatastandard.xsd"
    xmlns:fhc="https://github.com/firehawk-consulting/firehawk"
    exclude-result-prefixes="xsl intsys xsd wd fhcsi fhc" version="2.0">

    <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" omit-xml-declaration="yes"/>

    <xsl:param name="import.type"/>
    <xsl:param name="business.process.defaultcomment"/>
    <xsl:param name="taxoption.id" select="'ENTER_TAX_DUE'"/>
    <xsl:param name="supplier.id" select="''"/>
    <xsl:param name="web.service.add.only"/>
    <xsl:param name="web.service.auto.complete"/>
    <xsl:param name="web.service.version"/>
    <xsl:param name="web.service.submit"/>
    <xsl:param name="sftp.filename"/>
    <xsl:param name="attachmentdata.file"/>
    <xsl:param name="attachmentdata.contenttype"/>
    <xsl:param name="attachmentdata.filename"/>
    <xsl:param name="attachmentdata.encoding"/>
    <xsl:param name="attachmentdata.compressed"/>
    <!-- New Variables add to Eval Step-->
    <xsl:param name="transaction.id.type.lookup"/>
    <xsl:param name="invoice.defaultmemo.lookup"/>
    <xsl:param name="web.service.lock.transaction"/>
    <xsl:param name="tax.spendcategory.id"/>
    <xsl:param name="tax.costcenter.id"/>
    <xsl:param name="tax.region.id"/>
    <xsl:param name="tax.offering.id"/>
    <xsl:param name="transaction.source.id"/>
    <xsl:param name="ignore.poline.contingentworker" select="1"/>

    <xsl:variable name="taxapplicabilityid.type" select="'Tax_Applicability_ID'"/>
    <!-- Variable populated within Workday Studio with all Spend Categories for the current file -->
    <!-- <xsl:variable name="spendcategory.data" select="document('mctx:vars/spendcategory.data')"/> -->
    <xsl:variable name="spendcategory.data">
        <xsl:call-template name="create_blank_xml"/>
    </xsl:variable>
    <!-- Variable populated within Workday Studio with all Purchase Order Data for the current file -->
    <xsl:variable name="po.details" select="document('mctx:vars/lookup.wd.data.xml')"/>
    <!-- <xsl:variable name="po.details">
        <xsl:call-template name="create_blank_xml"/>
    </xsl:variable> -->
    <!-- Variable populated within Workday Studio with all Supplier Contract Data for the current file -->
    <!-- <xsl:variable name="suppliercontract.details" select="document('mctx:vars/suppliercontractdetails.xml')"/> -->
    <xsl:variable name="suppliercontract.details">
        <xsl:call-template name="create_blank_xml"/>
    </xsl:variable>
    <!-- Variable populated within Workday Studio with all encoded Attachments for the current file -->
    <!-- <xsl:variable name="attachment.data" select="document('mctx:vars/attachment.data')"/> -->
    <xsl:variable name="attachment.data">
        <xsl:call-template name="create_blank_xml"/>
    </xsl:variable>

    <xsl:function name="fhc:forceValue" as="xsd:decimal">
        <xsl:param name="inputdata"/>
        <xsl:param name="defaultoutput" as="xsd:decimal"/>
        <xsl:choose>
            <xsl:when test="string-length(normalize-space($inputdata))">
                <xsl:value-of select="normalize-space($inputdata)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$defaultoutput"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/">
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bsvc="urn:com.workday/bsvc">
            <soapenv:Header/>
            <soapenv:Body>
                <!--<xsl:apply-templates select="//fhcsi:supplier_invoice_data[fhcsi:invoice_type='d' or fhcsi:invoice_type='i' or fhcsi:invoice_type='c']"/>-->
                <xsl:apply-templates select="//fhcsi:supplier_invoice_data" mode="#default"/>
            </soapenv:Body>
        </soapenv:Envelope>
    </xsl:template>

    <xsl:template match="fhcsi:supplier_invoice_data" mode="#default">
        <xsl:variable name="ponumber">
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(fhcsi:workday_po_number))!= 0">
                    <xsl:value-of select="fhcsi:workday_po_number"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(.//fhcsi:invoice_line_data[1]/fhcsi:workday_line_po_number)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="po_supplier_id">
            <xsl:value-of select="$po.details//bsvc:Purchase_Order_Data[bsvc:Document_Number = $ponumber]//bsvc:Supplier_Reference/bsvc:ID[@bsvc:type='Supplier_ID']"/>
        </xsl:variable>
        <xsl:variable name="import_supplier_id">
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:supplier_info/fhcsi:workday_supplier_id) = 0 and string-length($supplier.id) = 0">
                    <xsl:value-of select="$po_supplier_id"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:supplier_info/fhcsi:workday_supplier_id) = 0">
                    <xsl:value-of select="$supplier.id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="fhcsi:supplier_info/fhcsi:workday_supplier_id"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="lkp_invoice_type">
            <xsl:choose>
                <xsl:when test="not(contains($import_supplier_id, 'SUP-'))">
                    <xsl:value-of select="'contingent_worker'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@fhcsi:invoice_type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="invoice_type" select="document('')/*/fhc:invoice_type_lookup_map/fhc:invoice_type_lookup[@lkp_value = $lkp_invoice_type]/@invoice_type"/>
        <xsl:if test="$invoice_type = 'invoice' or $invoice_type = 'invoice_adjustment' or $invoice_type = 'invoice_cw' ">
            <xsl:apply-templates select="." mode="transaction">
                <xsl:with-param name="invoice.type" select="$invoice_type"/>
                <xsl:with-param name="po.number" select="$ponumber"/>
                <xsl:with-param name="import.supplier.id" select="$import_supplier_id"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="fhcsi:supplier_invoice_data" mode="transaction">
        <xsl:param name="invoice.type"/>
        <xsl:param name="po.number"/>
        <xsl:param name="import.supplier.id"/>
        <xsl:variable name="webservice_call_name">
        <xsl:copy-of copy-namespaces="no" select="document('')/*/fhc:webservice_tags/webservice[@type = $invoice.type]"/>
        </xsl:variable>
        <xsl:element name="{$webservice_call_name//call}">
            <xsl:attribute name="bsvc:version">
                <xsl:value-of select="$web.service.version"/>
            </xsl:attribute>
            <xsl:attribute name="bsvc:Add_Only">
                <xsl:value-of select="$web.service.add.only"/>
            </xsl:attribute>
            <bsvc:Business_Process_Parameters>
                <bsvc:Auto_Complete>
                    <xsl:value-of select="$web.service.auto.complete"/>
                </bsvc:Auto_Complete>
                <bsvc:Comment_Data>
                    <bsvc:Comment>
                        <xsl:choose>
                            <xsl:when test="string-length(concat(fhcsi:comment,' Source Filename: ',$sftp.filename)) != 0">
                                <xsl:value-of select="concat(fhcsi:comment,' Source Filename: ',$sftp.filename)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat($business.process.defaultcomment,' Source Filename: ',$sftp.filename)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </bsvc:Comment>
                </bsvc:Comment_Data>
            </bsvc:Business_Process_Parameters>
            <xsl:element name="{$webservice_call_name//transaction}">
                <xsl:if test="string-length(fhcsi:invoice_prefix) != 0">
                    <xsl:element name="{$webservice_call_name//id}">
                        <xsl:value-of select="fhcsi:invoice_prefix"/>
                        <xsl:choose>
                            <xsl:when test="$transaction.id.type.lookup = 'invoicenumber'">
                                <xsl:value-of select="fhcsi:supplier_invoice_number"/>
                            </xsl:when>
                            <xsl:when test="$transaction.id.type.lookup = 'supplierid'">
                                <xsl:value-of select=".//fhcsi:workday_supplier_id"/>
                                <xsl:value-of select="'-'"/>
                                <xsl:value-of select="fhcsi:workday_internal_invoice_number"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="fhcsi:workday_internal_invoice_number"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                </xsl:if>
                <xsl:element name="{$webservice_call_name//date}">
                    <xsl:value-of select="fhcsi:invoice_date"/>
                </xsl:element>
                <xsl:if test="string-length(fhcsi:invoice_due_date) != 0">
                    <wd:Due_Date_Override>
                        <xsl:value-of select="fhcsi:invoice_due_date"/>
                    </wd:Due_Date_Override>
                </xsl:if>
                <xsl:element name="{$webservice_call_name//memo}">
                    <xsl:choose>
                        <xsl:when test="string-length(fhcsi:invoice_memo) != 0">
                            <xsl:value-of select="fhcsi:invoice_memo"/>
                        </xsl:when>
                        <xsl:when test="$invoice.defaultmemo.lookup != $import.type">
                            <xsl:value-of select="$invoice.defaultmemo.lookup"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'XML Invoice Load'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
                <xsl:choose>
                    <xsl:when test="$invoice.type = 'invoice' or $invoice.type = 'invoice_cw' ">
                        <bsvc:Control_Amount_Total>
                            <xsl:value-of select="format-number(fhcsi:invoice_total,'####.00')"/>
                        </bsvc:Control_Amount_Total>
                    </xsl:when>
                    <xsl:when test="$invoice.type = 'invoice_adjustment'">
                        <bsvc:Adjustment_Reason_Reference>
                            <bsvc:ID bsvc:type="Adjustment_Reason_ID">
                                <xsl:choose>
                                    <xsl:when test="string-length(fhcsi:credit_reason) != 0">
                                        <xsl:value-of select="fhcsi:credit_reason"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="'OTHER_TERMS'"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </bsvc:ID>
                        </bsvc:Adjustment_Reason_Reference>
                    </xsl:when>
                </xsl:choose>
                <xsl:apply-templates select="node()[self::fhcsi:invoice_freighttotal or self::fhcsi:invoice_othertotal]"/>
                <xsl:choose>
                    <xsl:when test="count(.//fhcsi:invoice_taxdetail[@fhcsi:tax_type = 'VAT'
                        or @fhcsi:tax_type = 'GST'
                        or @fhcsi:tax_type = 'HST']) != 0">
                        <xsl:apply-templates select=".//fhcsi:invoice_taxdetail[@fhcsi:tax_type = 'VAT'
                            or @fhcsi:tax_type = 'GST'
                            or @fhcsi:tax_type = 'HST']"/>
                        <xsl:apply-templates select=".//fhcsi:invoice_taxdetail[@fhcsi:tax_type != 'VAT'
                            and @fhcsi:tax_type != 'GST'
                            and @fhcsi:tax_type != 'HST'][1]">
                            <xsl:with-param name="tax_amount">
                                <xsl:value-of select="sum(.//fhcsi:invoice_taxdetail[@fhcsi:tax_type != 'VAT'
                                    and @fhcsi:tax_type != 'GST'
                                    and @fhcsi:tax_type != 'HST'])"/>
                            </xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select=".//fhcsi:invoice_taxtotal"/>
                    </xsl:otherwise>
                </xsl:choose>
                <bsvc:Submit>
                    <xsl:value-of select="$web.service.submit"/>
                </bsvc:Submit>
                <bsvc:Locked_in_Workday>
                    <xsl:value-of select="$web.service.lock.transaction"/>
                </bsvc:Locked_in_Workday>
                <xsl:variable name="header.company.id">
                    <xsl:choose>
                        <xsl:when test="string-length(normalize-space(fhcsi:header_company_id)) = 0">
                            <xsl:value-of select="$po.details//bsvc:Purchase_Order_Data[bsvc:Document_Number = $po.number]//bsvc:Company_Reference/bsvc:ID[@bsvc:type='Organization_Reference_ID']"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(fhcsi:header_company_id)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <bsvc:Company_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="document('')/*/fhc:type_id_lookup/type_id[@name = 'company']"/>
                        <xsl:value-of select="$header.company.id"/>
                    </bsvc:ID>
                </bsvc:Company_Reference>
                <bsvc:Currency_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="document('')/*/fhc:type_id_lookup/type_id[@name = 'currency']"/>
                        <xsl:value-of select="fhcsi:header_currency_id"/>
                    </bsvc:ID>
                </bsvc:Currency_Reference>
                <xsl:choose>
                    <xsl:when test="not(contains($import.supplier.id, 'SUP-'))">
                        <bsvc:Contingent_Worker_Reference>
                            <bsvc:ID>
                                <xsl:attribute name="bsvc:type">
                                    <xsl:value-of select="'Contingent_Worker_ID'"/>
                                </xsl:attribute>
                                <xsl:value-of select="$import.supplier.id"/>
                            </bsvc:ID>
                        </bsvc:Contingent_Worker_Reference>
                    </xsl:when>
                    <xsl:otherwise>
                        <bsvc:Supplier_Reference>
                            <bsvc:ID>
                                <xsl:attribute name="bsvc:type">
                                    <xsl:value-of select="'Supplier_ID'"/>
                                </xsl:attribute>
                                <xsl:value-of select="$import.supplier.id"/>
                            </bsvc:ID>
                        </bsvc:Supplier_Reference>
                    </xsl:otherwise>
                </xsl:choose>
                <bsvc:Suppliers_Invoice_Number>
                    <xsl:value-of select="fhcsi:supplier_invoice_number"/>
                </bsvc:Suppliers_Invoice_Number>
                <xsl:if test="string-length(fhcsi:external_po_number) !=0">
                    <bsvc:External_PO_Number>
                        <xsl:value-of select="fhcsi:external_po_number"/>
                    </bsvc:External_PO_Number>
                </xsl:if>
                <xsl:if test="string-length(fhcsi:workday_contract_number) != 0">
                    <bsvc:Supplier_Contract_Reference>
                        <bsvc:ID bsvc:type="Supplier_Contract_ID">
                            <xsl:value-of select="fhcsi:workday_contract_number"/>
                        </bsvc:ID>
                    </bsvc:Supplier_Contract_Reference>
                </xsl:if>
                <xsl:variable name="imagefilename">
                    <xsl:value-of select="fhcsi:image_data/fhcsi:image_file"/>
                </xsl:variable>
                <xsl:apply-templates select="$attachment.data//encodedfile[@filename=$imagefilename]"/>
                <xsl:variable name="all_line_amounts">
                    <xsl:if test="fhcsi:invoice_othertotal &lt; 0">
                        <xsl:for-each select="fhcsi:invoice_line_data">
                            <xsl:value-of select="fhcsi:extended_amount"/>
                            <xsl:if test="position() != last()">
                                <xsl:value-of select="','"/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:variable>
                <xsl:if test="string-length(fhcsi:override_payment_type) != 0">
                    <bsvc:Override_Payment_Type_Reference>
                        <bsvc:ID bsvc:type=""></bsvc:ID>
                    </bsvc:Override_Payment_Type_Reference>
                </xsl:if>
                <xsl:variable name="other_line_amounts">
                    <xsl:call-template name="othertotallinebreakout">
                        <xsl:with-param name="subtotal" select="fhcsi:invoice_subtotal"/>
                        <xsl:with-param name="othertotal" select="fhcsi:invoice_othertotal"/>
                        <xsl:with-param name="totallineamounts" select="string-join(.//fhcsi:invoice_line_data/fhcsi:extended_amount,',')"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="offset_amount" select="fhcsi:invoice_othertotal - sum($other_line_amounts//lineamount)"/>
                <xsl:variable name="other_amount" select="if (fhcsi:invoice_othertotal &lt; 0) then fhcsi:invoice_othertotal else 0"/>
                <!-- Process Transaction Lines -->
                <xsl:for-each-group select="fhcsi:invoice_line_data" group-by="concat(fhc:forceValue(fhcsi:workday_line_po_number/@fhcsi:line_number,0),fhc:forceValue(fhcsi:workday_line_contract_number/@fhcsi:line_number,0))">
                    <xsl:apply-templates select="current-group()[fhcsi:extended_amount != 0]" mode="#default">
                        <xsl:with-param name="headercompany" select="$header.company.id"/>
                        <xsl:with-param name="invoicetype" select="$invoice.type"/>
                        <xsl:with-param name="subtotal" select="ancestor-or-self::fhcsi:supplier_invoice_data/fhcsi:invoice_subtotal"/>
                        <xsl:with-param name="othertotal" select="$other_amount"/>
                        <xsl:with-param name="offset.amount" select="$offset_amount"/>
                        <xsl:with-param name="headerpurchaseorder" select="$po.number"/>
                        <xsl:with-param name="line.instance" select="position()"/>
                    </xsl:apply-templates>
                </xsl:for-each-group>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_line_data" mode="#default">
        <xsl:param name="headercompany"/>
        <xsl:param name="invoicetype" select="''"/>
        <xsl:param name="subtotal"/>
        <xsl:param name="othertotal"/>
        <xsl:param name="offset.amount"/>
        <xsl:param name="headerpurchaseorder"/>
        <xsl:param name="line.instance"/>

        <xsl:variable name="po_number">
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                    <xsl:value-of select="fhcsi:workday_line_contract_number"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_po_number) = 0">
                    <xsl:value-of select="ancestor::fhcsi:supplier_invoice_data/fhcsi:external_po_number"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="fhcsi:workday_line_po_number"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="line_number">
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                    <xsl:value-of select="fhcsi:workday_line_contract_number/@fhcsi:line_number"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_po_number/@fhcsi:line_number) != 0">
                    <xsl:value-of select="fhcsi:workday_line_po_number/@fhcsi:line_number"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="po.information">
            <xsl:call-template name="set_po_information">
                <xsl:with-param name="po.number" select="$po_number"/>
                <xsl:with-param name="line.number" select="$line_number"/>
            </xsl:call-template>
        </xsl:variable>

        <!--<po_info>
            <xsl:attribute name="po_number" select="$po_number"/>
            <xsl:attribute name="line_number" select="$line_number"/>
            <xsl:copy-of select="$po.information"/>
        </po_info>-->

        <xsl:apply-templates select="." mode="transaction">
            <xsl:with-param name="headercompany" select="$headercompany"/>
            <xsl:with-param name="invoicetype" select="$invoicetype"/>
            <xsl:with-param name="po.information" select="$po.information"/>
        </xsl:apply-templates>

        <xsl:variable name="offset_amount" select="if (xsd:integer($line.instance) = 1 and position() = 1) then $offset.amount else 0"/>
        <xsl:variable name="line_percent" select="if ($subtotal = 0) then 0 else fhcsi:extended_amount div $subtotal"/>
        <xsl:variable name="discount_line_total" select="if ($othertotal != 0) then ($othertotal * $line_percent) + $offset_amount else 0"/>
        <xsl:if test="$discount_line_total != 0">
            <xsl:apply-templates select="." mode="discount_line">
                <xsl:with-param name="discount.line.total" select="$discount_line_total"/>
                <xsl:with-param name="headercompany" select="$headercompany"/>
                <xsl:with-param name="po.information" select="$po.information"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="fhcsi:invoice_line_data" mode="transaction">
        <xsl:param name="headercompany"/>
        <xsl:param name="invoicetype" select="''"/>
        <xsl:param name="po.information"/>
        <bsvc:Invoice_Line_Replacement_Data>
            <!--<po_info>
                <xsl:attribute name="po_nbr_len" select="string-length(fhcsi:workday_line_po_number)"/>
                <xsl:attribute name="invoice_type" select="$invoicetype"/>
                <xsl:attribute name="po_status" select="$po.information//po_status"/>
                <xsl:attribute name="po_position" select="position()"/>
                <xsl:attribute name="po_line_found" select="$po.information//po_line_data/@po_line_found"/>
                <xsl:copy-of select="$po.information"/>
            </po_info>-->
            <xsl:if test="$headercompany != fhcsi:line_company_id and string-length(fhcsi:line_company_id) != 0">
                <bsvc:Intercompany_Affiliate_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="'Organization_Refence_ID'"/>
                        <xsl:value-of select="fhcsi:line_company_id"/>
                    </bsvc:ID>
                </bsvc:Intercompany_Affiliate_Reference>
            </xsl:if>
            <xsl:variable name="spendcategory.id" select="if (string-length(fhcsi:spend_category_id) = 0) then $po.information//po_line_data//bsvc:ID[@bsvc:type = 'Spend_Category_ID'] else fhcsi:spend_category_id"/>
            <xsl:variable name="tax.applicability">
                <spend_category>
                    <xsl:apply-templates select="$spendcategory.data//bsvc:Resource_Category_Data[bsvc:Resource_Category_ID=$spendcategory.id][1]"/>
                </spend_category>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:taxapplicability) != 0">
                    <bsvc:Tax_Applicability_Reference>
                        <bsvc:ID>
                            <xsl:attribute name="bsvc:type" select="$taxapplicabilityid.type"/>
                            <xsl:value-of select="fhcsi:taxapplicability"/>
                        </bsvc:ID>
                    </bsvc:Tax_Applicability_Reference>
                </xsl:when>
                <xsl:when test="string-length($tax.applicability//taxapplicabilityid[1]) != 0">
                    <bsvc:Tax_Applicability_Reference>
                        <bsvc:ID>
                            <xsl:attribute name="bsvc:type" select="$taxapplicabilityid.type"/>
                            <xsl:value-of select="$tax.applicability//taxapplicabilityid[1]"/>
                        </bsvc:ID>
                    </bsvc:Tax_Applicability_Reference>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:if test="string-length(fhcsi:line_order) != 0">
                <bsvc:Line_Order>
                    <xsl:value-of select="fhcsi:line_order"/>
                </bsvc:Line_Order>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:workday_line_po_number) != 0
                    and ($invoicetype = 'invoice'
                    or ($invoicetype = 'invoice_cw'
                    and $ignore.poline.contingentworker != 1))
                    and $po.information//po_status != 'CLOSED'
                    and position() = 1
                    and $po.information//po_line_data/@po_line_found = 'yes'">
                    <bsvc:Purchase_Order_Line_Reference>
                        <bsvc:ID bsvc:type="Line_Number" bsvc:parent_type="Document_Number">
                            <xsl:attribute name="bsvc:parent_id" select="fhcsi:workday_line_po_number"/>
                            <xsl:value-of select="$po.information//po_line_data/@line_number"/>
                        </bsvc:ID>
                    </bsvc:Purchase_Order_Line_Reference>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                    and ($invoicetype = 'invoice'
                    or $invoicetype = 'invoice_cw')
                    and position() = 1">
                    <bsvc:Supplier_Contract_Line_Reference>
                        <bsvc:ID bsvc:type="Supplier_Contract_Line_Number" bsvc:parent_type="Supplier_Contract_ID">
                            <xsl:attribute name="bsvc:parent_id" select="fhcsi:workday_line_contract_number"/>
                            <xsl:value-of select="$po.information//po_line_data/@line_number"/>
                        </bsvc:ID>
                    </bsvc:Supplier_Contract_Line_Reference>
                </xsl:when>
                <xsl:when
                    test="string-length(fhcsi:workday_line_po_number) != 0
                    and ($invoicetype = 'invoice'
                    or ($invoicetype = 'invoice_cw'
                    and $ignore.poline.contingentworker = 1))
                    and $po.information//po_status != 'CLOSED'
                    and (position() != 1
                    or $po.information//po_line_data/@po_line_found  = 'no')">
                    <xsl:if test="$po.information//po_line_data/@po_line_found  = 'no'">
                        <bsvc:Item_Description>
                            <xsl:choose>
                                <xsl:when test="string-length(fhcsi:item_description) != 0">
                                    <xsl:value-of select="replace(normalize-unicode(fhcsi:item_description,'NFC'),'\P{IsBasicLatin}','')"/>
                                </xsl:when>
                                <xsl:when test="$po.information//po_line_data/@po_line_found  = 'yes'">
                                    <xsl:value-of select="replace(normalize-unicode($po.information//po_line_data//bsvc:Item_Description,'NFC'),'\P{IsBasicLatin}','')"/>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </bsvc:Item_Description>
                    </xsl:if>
                    <xsl:if test="string-length($spendcategory.id) != 0">
                        <bsvc:Spend_Category_Reference>
                            <bsvc:ID>
                                <xsl:attribute name="bsvc:type" select="'Spend_Category_ID'"/>
                                <xsl:value-of select="$spendcategory.id"/>
                            </bsvc:ID>
                        </bsvc:Spend_Category_Reference>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and (position() != 1
                    or $po.information//po_line_data/@po_line_found = 'no')">
                    <xsl:if test="$po.information//po_line_data/@po_line_found = 'no'">
                        <bsvc:Item_Description>
                            <xsl:choose>
                                <xsl:when test="string-length(fhcsi:item_description) != 0">
                                    <xsl:value-of select="replace(normalize-unicode(fhcsi:item_description,'NFC'),'\P{IsBasicLatin}','')"/>
                                </xsl:when>
                                <xsl:when test="$po.information//po_line_data/@po_line_found = 'yes'">
                                    <xsl:value-of select="replace(normalize-unicode($po.information//po_line_data//bsvc:Item_Description,'NFC'),'\P{IsBasicLatin}','')"/>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </bsvc:Item_Description>
                    </xsl:if>
                    <xsl:if test="string-length($spendcategory.id) != 0">
                        <bsvc:Spend_Category_Reference>
                            <bsvc:ID>
                                <xsl:attribute name="bsvc:type" select="'Spend_Category_ID'"/>
                                <xsl:value-of select="$spendcategory.id"/>
                            </bsvc:ID>
                        </bsvc:Spend_Category_Reference>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <bsvc:Item_Description>
                        <xsl:choose>
                            <xsl:when test="string-length(fhcsi:item_description) != 0">
                                <xsl:value-of select="replace(normalize-unicode(fhcsi:item_description,'NFC'),'\P{IsBasicLatin}','')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'XML Invoice Line'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </bsvc:Item_Description>
                    <xsl:if test="string-length($spendcategory.id) != 0">
                        <bsvc:Spend_Category_Reference>
                            <bsvc:ID>
                                <xsl:attribute name="bsvc:type" select="'Spend_Category_ID'"/>
                                <xsl:value-of select="$spendcategory.id"/>
                            </bsvc:ID>
                        </bsvc:Spend_Category_Reference>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            
            <!-- Calls a Sub-Process to confirm the quantity, unit_cost and extended_amount values to avoid Workday errors. -->
            <xsl:call-template name="line_qty_amounts">
                <xsl:with-param name="extended_amount" select="fhcsi:extended_amount"/>
                <xsl:with-param name="otherlinetotal" select="0"/>
                <xsl:with-param name="line_type" select="$po.information//po_line_data/@line_type"/>
            </xsl:call-template>
            
            <!-- Determines what "type" of line is being processed: PO, Contract, Manual.
                This identifies scenarios that require the Worktag values be passed to Workday,
                    otherwise they would be linked to the PO data within Workday. -->
            <xsl:choose>
                <xsl:when test="(string-length(fhcsi:workday_line_po_number) != 0
                    or string-length($po.information//po_number) != 0)
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and $po.information//po_status = 'CLOSED'">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktags_Reference"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_po_number) != 0
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and string-length(normalize-space($po.information//po_status)) != 0
                    and position() = 1
                    and string-length($transaction.source.id) = 0"/>
                <xsl:when test="(string-length(fhcsi:workday_line_po_number) != 0
                    or string-length($po.information//po_number) != 0)
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and string-length(normalize-space($po.information//po_status)) != 0
                    and position() = 1
                    and string-length($transaction.source.id) != 0">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktags_Reference"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and position() = 1">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktag_Reference"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_po_number) != 0
                    and $invoicetype = 'invoice_adjustment'">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktags_Reference"/>
                </xsl:when>
                <xsl:when test="(string-length(fhcsi:workday_line_po_number) != 0
                    or string-length($po.information//po_number) != 0)
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and string-length(normalize-space($po.information//po_status)) != 0
                    and (position() != 1
                    or $po.information//po_line_data/@po_line_found = 'no')">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktags_Reference"/>
                </xsl:when>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                    and ($invoicetype = 'invoice' or $invoicetype = 'invoice_cw')
                    and position() != 1">
                    <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktag_Reference"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="fhcsi:worktags/fhcsi:worktag[@fhcsi:type != 'sourceprojectphase'
                        and @fhcsi:type != 'sourceproject'
                        and @fhcsi:type != 'sourceprojecttask'
                        and @fhcsi:type != 'sourcefulltask']"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="string-length($transaction.source.id) != 0">
                <bsvc:Worktags_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type">
                            <xsl:value-of select="document('')/*/fhc:type_id_lookup/type_id[@name = 'transaction_source']"/>
                        </xsl:attribute>
                        <xsl:value-of select="$transaction.source.id"/>
                    </bsvc:ID>
                </bsvc:Worktags_Reference>
            </xsl:if>
        </bsvc:Invoice_Line_Replacement_Data>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_line_data" mode="discount_line">
        <xsl:param name="discount.line.total"/>
        <xsl:param name="headercompany"/>
        <xsl:param name="po.information"/>

        <xsl:variable name="spend_category_id" select="if (string-length(fhcsi:spend_category_id) = 0) then $po.information//po_line_data//bsvc:ID[@bsvc:type = 'Spend_Category_ID'] else fhcsi:spend_category_id"/>
        <bsvc:Invoice_Line_Replacement_Data>
            <xsl:if test="string-length(fhcsi:line_order) != 0">
                <bsvc:Line_Order>
                    <xsl:value-of select="concat(fhcsi:line_order,'.discount')"/>
                </bsvc:Line_Order>
            </xsl:if>
            <xsl:if test="$headercompany != fhcsi:line_company_id and string-length(fhcsi:line_company_id) != 0">
                <bsvc:Intercompany_Affiliate_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="'Organization_Refence_ID'"/>
                        <xsl:value-of select="fhcsi:line_company_id"/>
                    </bsvc:ID>
                </bsvc:Intercompany_Affiliate_Reference>
            </xsl:if>
            <bsvc:Item_Description>
                <xsl:value-of select="concat('Discount - ',replace(normalize-unicode(fhcsi:item_description,'NFC'),'\P{IsBasicLatin}',''))"/>
            </bsvc:Item_Description>
            <bsvc:Spend_Category_Reference>
                <bsvc:ID bsvc:type="Spend_Category_ID">
                    <xsl:value-of select="$spend_category_id"/>
                </bsvc:ID>
            </bsvc:Spend_Category_Reference>
            <bsvc:Quantity>
                <xsl:value-of select="1"/>
            </bsvc:Quantity>
            <bsvc:Unit_Cost>
                <xsl:value-of select="format-number(xsd:decimal($discount.line.total),'####.00')"/>
            </bsvc:Unit_Cost>
            <bsvc:Extended_Amount>
                <xsl:value-of select="format-number(xsd:decimal($discount.line.total),'####.00')"/>
            </bsvc:Extended_Amount>
            <xsl:apply-templates select="$po.information//po_line_data//bsvc:Worktags_Reference"/>
        </bsvc:Invoice_Line_Replacement_Data>
    </xsl:template>

    <xsl:template match="fhcsi:worktag">
        <xsl:variable name="worktag_type" select="@fhcsi:type"/>
        <xsl:variable name="use_worktag_type">
            <xsl:choose>
                <xsl:when test="string-length(document('')/*/fhc:type_id_lookup/type_id[@name = $worktag_type]) != 0">
                    <xsl:value-of select="document('')/*/fhc:type_id_lookup/type_id[@name = $worktag_type]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$worktag_type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="string-length(.) != 0 and . != 'DOES_NOT_EXIST'">
            <bsvc:Worktags_Reference>
                <bsvc:ID>
                    <xsl:attribute name="bsvc:type" select="$use_worktag_type"/>
                    <xsl:value-of select="."/>
                </bsvc:ID>
            </bsvc:Worktags_Reference>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[local-name() = 'Worktags_Reference']">
        <xsl:if test="count(.//bsvc:ID[@wd:type='Custom_Worktag_5_ID']) = 0">
            <bsvc:Worktags_Reference>
                <xsl:apply-templates select="bsvc:ID"/>
            </bsvc:Worktags_Reference>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[local-name() = 'Worktag_Reference']">
        <xsl:if test="count(.//bsvc:ID[@wd:type='Custom_Worktag_5_ID']) = 0">
            <bsvc:Worktags_Reference>
                <xsl:apply-templates select="bsvc:ID"/>
            </bsvc:Worktags_Reference>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[local-name()= 'Resource_Category_Data']">
        <taxapplicabilityid>
            <xsl:value-of select="bsvc:Tax_Applicability_Reference/bsvc:ID[@bsvc:type=$taxapplicabilityid.type]"/>
        </taxapplicabilityid>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_taxtotal">
        <xsl:choose>
            <xsl:when test="string-length(.) != 0
                    and @fhcsi:tax_type != 'VAT'
                    and @fhcsi:tax_type != 'GST'
                    and @fhcsi:tax_type != 'HST'">
                <bsvc:Tax_Amount>
                    <xsl:variable name="tax_amount1" as="xsd:decimal" select="."/>
                    <xsl:value-of select="format-number($tax_amount1, '####.00')"/>
                </bsvc:Tax_Amount>
            </xsl:when>
            <xsl:when test="string-length(.) != 0
                    and (@fhcsi:tax_type = 'VAT'
                    or @fhcsi:tax_type = 'GST'
                    or @fhcsi:tax_type = 'HST')">
                <!-- Create Tax Line for CAN Taxes ('VAT', 'HST', 'GST') -->
                <xsl:call-template name="create_tax_line">
                    <xsl:with-param name="tax_amount" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <bsvc:Tax_Amount>
                    <xsl:variable name="tax_amount1" as="xsd:decimal" select="."/>
                    <xsl:value-of select="format-number($tax_amount1, '####.00')"/>
                </bsvc:Tax_Amount>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_taxdetail">
        <xsl:param name="tax_amount" select="0"/>
        <xsl:choose>
            <xsl:when test="string-length(.) != 0
                and @fhcsi:tax_type != 'VAT'
                and @fhcsi:tax_type != 'GST'
                and @fhcsi:tax_type != 'HST'">
                <bsvc:Tax_Amount>
                    <xsl:value-of select="format-number($tax_amount,'####.00')"/>
                </bsvc:Tax_Amount>
            </xsl:when>
            <xsl:when test="string-length(.) != 0
                and (@fhcsi:tax_type = 'VAT'
                or @fhcsi:tax_type = 'GST'
                or @fhcsi:tax_type = 'HST')">
                <!-- Create Tax Line for CAN Taxes ('VAT', 'HST', 'GST') -->
                <xsl:call-template name="create_tax_line">
                    <xsl:with-param name="tax_amount" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <bsvc:Tax_Amount>
                    <xsl:variable name="tax_amount1" as="xsd:decimal" select="."/>
                    <xsl:value-of select="format-number($tax_amount1, '####.00')"/>
                </bsvc:Tax_Amount>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_freighttotal">
        <bsvc:Freight_Amount>
            <xsl:value-of select="fhc:forceValue(.,0)"/>
        </bsvc:Freight_Amount>
    </xsl:template>

    <xsl:template match="fhcsi:invoice_othertotal">
        <xsl:if test="fhc:forceValue(.,-1) &gt;= 0">
            <bsvc:Other_Charges>
                <xsl:value-of select="."/>
            </bsvc:Other_Charges>
        </xsl:if>
    </xsl:template>

    <xsl:template match="fhcsi:comment">
        <xsl:attribute name="bsvc:version" select="$web.service.version"/>
        <xsl:attribute name="bsvc:Add_Only" select="$web.service.add.only"/>
        <xsl:variable name="comment_detail" select="concat(.,' Source Filename: ',$sftp.filename)"/>
        <bsvc:Business_Process_Parameters>
            <bsvc:Auto_Complete>
                <xsl:value-of select="$web.service.auto.complete"/>
            </bsvc:Auto_Complete>
            <bsvc:Comment_Data>
                <bsvc:Comment>
                    <xsl:value-of select="if (string-length(.) != 0) then $comment_detail else $business.process.defaultcomment"/>
                </bsvc:Comment>
            </bsvc:Comment_Data>
        </bsvc:Business_Process_Parameters>
    </xsl:template>

    <xsl:template match="encodedfile">
        <bsvc:Attachment_Data>
            <xsl:attribute name="bsvc:Content_Type" select="@content-type"/>
            <xsl:attribute name="bsvc:Filename" select="@filename"/>
            <xsl:attribute name="bsvc:Encoding" select="@encoding"/>
            <xsl:attribute name="bsvc:Compressed" select="@compressed"/>
            <bsvc:File_Content>
                <xsl:value-of select="."/>
            </bsvc:File_Content>
        </bsvc:Attachment_Data>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="line_qty_amounts">
        <xsl:param name="extended_amount"/>
        <xsl:param name="otherlinetotal"/>
        <xsl:param name="line_type"/>

        <xsl:variable name="effective_extended_amount" as="xsd:decimal">
            <xsl:value-of select="format-number((round(($extended_amount + $otherlinetotal) * 100) div 100),'####.00')"/>
        </xsl:variable>
        <xsl:variable name="effective_quantity" as="xsd:decimal">
            <xsl:value-of select="format-number((round(fhc:forceValue(fhcsi:quantity,1)*1000000) div 1000000), '####.00####')"/>
        </xsl:variable>
        <xsl:variable name="unitcost" as="xsd:decimal">
            <xsl:value-of select="format-number((round(fhc:forceValue(fhcsi:unit_cost,0)*1000000) div 1000000), '####.00####')"/>
        </xsl:variable>
        <xsl:variable name="effective_unit_cost" as="xsd:decimal">
            <xsl:value-of select="if (($effective_quantity*$unitcost) != $effective_extended_amount) then $effective_extended_amount div $effective_quantity else $unitcost"/>
        </xsl:variable>

        <xsl:if test="$line_type != 'service' and $line_type != 'contingent'">
            <bsvc:Quantity>
                <xsl:value-of select="format-number($effective_quantity, '####.00')"/>
            </bsvc:Quantity>
            <bsvc:Unit_Cost>
                <xsl:value-of select="format-number($effective_unit_cost, '####.00####')"/>
            </bsvc:Unit_Cost>
        </xsl:if>
        <bsvc:Extended_Amount>
            <xsl:value-of select="format-number($effective_extended_amount,'####.00')"/>
        </bsvc:Extended_Amount>
    </xsl:template>
    <xsl:template name="othertotallinebreakout">
        <xsl:param name="othertotal"/>
        <xsl:param name="subtotal"/>
        <xsl:param name="totallineamounts"/>
        <lineamounts>
            <xsl:for-each select="tokenize($totallineamounts,',')">
                <xsl:if test="normalize-space(.) != ''">
                    <xsl:variable name="linepercent" select="if ($subtotal = 0) then 0 else xsd:decimal(normalize-space(.)) div $subtotal"/>
                    <xsl:variable name="otherlinetotal" select="if ($othertotal &lt;= 0) then $othertotal * $linepercent else 0"/>
                    <lineamount>
                        <xsl:attribute name="lineposition" select="position()"/>
                        <xsl:value-of select="format-number($otherlinetotal,'####.00')"/>
                    </lineamount>
                </xsl:if>
            </xsl:for-each>
        </lineamounts>
    </xsl:template>

    <xsl:template name="set_po_information">
        <xsl:param name="po.number"/>
        <xsl:param name="line.number"/>
        <xsl:variable name="po_data">
            <xsl:choose>
                <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                    <xsl:copy-of select="$suppliercontract.details//bsvc:Supplier_Contract_Data[bsvc:Supplier_Contract_ID = $po.number]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$po.details//bsvc:Purchase_Order_Data[bsvc:Document_Number = $po.number]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <po_information>
            <po_number>
                <xsl:value-of select="$po.number"/>
            </po_number>
            <po_company>
                <xsl:value-of select="$po_data//bsvc:Company_Reference/bsvc:ID[@bsvc:type='Organization_Reference_ID']"/>
            </po_company>
            <po_status>
                <xsl:value-of select="$po_data//bsvc:Purchase_Order_Document_Status_Reference/bsvc:ID[@bsvc:type = 'Document_Status_ID']"/>
            </po_status>
            <po_line_data>
                <xsl:attribute name="line_number" select="$line.number"/>
                <xsl:attribute name="po_line_found">
                    <xsl:choose>
                        <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                            and count($po_data//bsvc:Goods_Lines_Replacement_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'yes'"/>
                        </xsl:when>
                        <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                            <xsl:value-of select="'no'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Goods_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'yes'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Service_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'yes'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'yes'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'no'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="line_type">
                    <xsl:choose>
                        <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                            and count($po_data//bsvc:Goods_Lines_Replacement_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'goods'"/>
                        </xsl:when>
                        <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                            <xsl:value-of select="'contract'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Goods_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'goods'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Service_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'service'"/>
                        </xsl:when>
                        <xsl:when test="count($po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                            <xsl:value-of select="'contingent'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'none'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0
                        and count($po_data//bsvc:Goods_Lines_Replacement_Data[bsvc:Line_Number=$line.number]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Goods_Lines_Replacement_Data[bsvc:Line_Number=$line.number]"/>
                    </xsl:when>
                    <xsl:when test="string-length(fhcsi:workday_line_contract_number) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Goods_Lines_Replacement_Data[bsvc:Line_Number=1]"/>
                    </xsl:when>
                    <xsl:when test="count($po_data//bsvc:Goods_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Goods_Line_Data[bsvc:Line_Number=$line.number]"/>
                    </xsl:when>
                    <xsl:when test="count($po_data//bsvc:Service_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Service_Line_Data[bsvc:Line_Number=$line.number]"/>
                    </xsl:when>
                    <xsl:when test="count($po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=$line.number]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=$line.number]"/>
                    </xsl:when>
                    <xsl:when test="count($po_data//bsvc:Service_Line_Data[bsvc:Line_Number=1]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Service_Line_Data[bsvc:Line_Number=1]"/>
                    </xsl:when>
                    <xsl:when test="count($po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=1]) != 0">
                        <xsl:copy-of select="$po_data//bsvc:Contingent_Worker_Line_Data[bsvc:Line_Number=1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$po_data//bsvc:Goods_Line_Data[bsvc:Line_Number=1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </po_line_data>
        </po_information>
    </xsl:template>

    <xsl:template name="create_tax_line">
        <xsl:param name="tax_amount"/>
        <xsl:if test="number($tax_amount) != 0 ">
            <bsvc:Invoice_Line_Replacement_Data>
                <bsvc:Spend_Category_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="'Spend_Category_ID'"/>
                        <xsl:value-of select="$tax.spendcategory.id"/>
                    </bsvc:ID>
                </bsvc:Spend_Category_Reference>
                <bsvc:Item_Description>
                    <xsl:value-of select="'HST Tax'"/>
                </bsvc:Item_Description>
                <bsvc:Quantity>
                    <xsl:value-of select="1"/>
                </bsvc:Quantity>
                <bsvc:Unit_Cost>
                    <xsl:value-of select="format-number($tax_amount,'####.00####')"/>
                </bsvc:Unit_Cost>
                <bsvc:Extended_Amount>
                    <xsl:value-of select="format-number($tax_amount,'####.00####')"/>
                </bsvc:Extended_Amount>
                <bsvc:Worktags_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="'Organization_Reference_ID'"/>
                        <xsl:value-of select="$tax.region.id"/>
                    </bsvc:ID>
                </bsvc:Worktags_Reference>
                <bsvc:Worktags_Reference>
                    <bsvc:ID>
                        <xsl:attribute name="bsvc:type" select="'Organization_Reference_ID'"/>
                        <xsl:value-of select="$tax.costcenter.id"/>
                    </bsvc:ID>
                </bsvc:Worktags_Reference>
                <xsl:if test="lower-case($tax.offering.id) != 'no' and string-length($tax.offering.id) != 0">
                    <bsvc:Worktags_Reference>
                        <bsvc:ID>
                            <xsl:attribute name="bsvc:type" select="'Organization_Reference_ID'"/>
                            <xsl:value-of select="$tax.offering.id"/>
                        </bsvc:ID>
                    </bsvc:Worktags_Reference>
                </xsl:if>
                <xsl:if test="string-length($transaction.source.id) != 0">
                    <bsvc:Worktags_Reference>
                        <bsvc:ID>
                            <xsl:attribute name="bsvc:type" select="document('')/*/fhc:type_id_lookup/type_id[@name = 'transaction_source']"/>
                            <xsl:value-of select="$transaction.source.id"/>
                        </bsvc:ID>
                    </bsvc:Worktags_Reference>
                </xsl:if>
            </bsvc:Invoice_Line_Replacement_Data>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="create_blank_xml">
        <blank_xml/>
    </xsl:template>

    <fhc:webservice_tags>
        <webservice type="invoice">
            <!--<call>bsvc:Submit_Supplier_Invoice_Request</call>-->
            <call>bsvc:Import_Supplier_Invoice_Request</call>
            <transaction>bsvc:Supplier_Invoice_Data</transaction>
            <id>bsvc:Supplier_Invoice_ID</id>
            <date>bsvc:Invoice_Date</date>
            <memo>bsvc:Memo</memo>
        </webservice>
        <webservice type="invoice_cw">
            <!--<call>bsvc:Submit_Supplier_Invoice_Request</call>-->
            <call>bsvc:Import_Supplier_Invoice_Request</call>
            <transaction>bsvc:Supplier_Invoice_Data</transaction>
            <id>bsvc:Supplier_Invoice_ID</id>
            <date>bsvc:Invoice_Date</date>
            <memo>bsvc:Memo</memo>
        </webservice>
        <webservice type="invoice_adjustment">
            <call>bsvc:Submit_Supplier_Invoice_Adjustment_Request</call>
            <transaction>bsvc:Supplier_Invoice_Adjustment_Data</transaction>
            <id>bsvc:Supplier_Invoice_Adjustment_ID</id>
            <date>bsvc:Adjustment_Date</date>
            <memo>bsvc:Document_Memo</memo>
        </webservice>
    </fhc:webservice_tags>

    <fhc:invoice_type_lookup_map>
        <fhc:invoice_type_lookup lkp_value="credit_memo" invoice_type="invoice_adjustment"/>
        <fhc:invoice_type_lookup lkp_value="standard" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="d" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="c" invoice_type="invoice_adjustment"/>
        <fhc:invoice_type_lookup lkp_value="invoice_adjustment" invoice_type="invoice_adjustment"/>
        <fhc:invoice_type_lookup lkp_value="i" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="INVOICE" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="contingent_worker" invoice_type="invoice_cw"/>
        <fhc:invoice_type_lookup lkp_value="Non PO Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="PO Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Credit Memo" invoice_type="invoice_adjustment"/>
        <fhc:invoice_type_lookup lkp_value="Freight Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Legal Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Medical Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Utility" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Travel and Expense" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Payment Request" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Refund Request" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Acknowledgement" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Change of Address" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Correspondence" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Cover Page" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Late Final Shut Off Notice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Statement" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Other" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="Invalid Invoice" invoice_type="invoice"/>
        <fhc:invoice_type_lookup lkp_value="W9" invoice_type="none"/>
        <fhc:invoice_type_lookup lkp_value="Revolving Account Invoice" invoice_type="invoice"/>
    </fhc:invoice_type_lookup_map>

    <fhc:type_id_lookup>
        <type_id name="accountset">Account_Set_ID</type_id>
        <type_id name="adhocbanktransaction">Ad_hoc_Bank_Transaction_ID</type_id>
        <type_id name="bankaccount">Bank_Account_ID</type_id>
        <type_id name="book">Book_Code_ID</type_id>
        <type_id name="company">Company_Reference_ID</type_id>
        <type_id name="costcenter">Cost_Center_Reference_ID</type_id>
        <type_id name="currency">Currency_ID</type_id>
        <type_id name="employeeintegrationid">WD-EMPLID</type_id>
        <type_id name="integrationsystem">Integration_System_ID</type_id>
        <type_id name="journalentrystatus">Journal_Entry_Status_ID</type_id>
        <type_id name="journalsource">Journal_Source_ID</type_id>
        <type_id name="ledgeraccount">Ledger_Account_ID</type_id>
        <type_id name="offering">Custom_Organization_Reference_ID</type_id>
        <type_id name="paymentelectionrule">Payment_Election_Rule_ID</type_id>
        <type_id name="paymentmessage">Payment_Message_ID</type_id>
        <type_id name="paymentstatus">Payment_Status</type_id>
        <type_id name="paymenttype">Payment_Type_ID</type_id>
        <type_id name="phase">Project_Plan_ID</type_id>
        <type_id name="project">Project_ID</type_id>
        <type_id name="projectplantask">Project_Plan_ID</type_id>
        <type_id name="region">Region_Reference_ID</type_id>
        <type_id name="revenuecategory">Revenue_Category_ID</type_id>
        <type_id name="spendcategory">Spend_Category_ID</type_id>
        <type_id name="supplier">Supplier_ID</type_id>
        <type_id name="worker">Employee_ID</type_id>
        <type_id name="transaction_source">Custom_Worktag_5_ID</type_id>
    </fhc:type_id_lookup>
</xsl:transform>
