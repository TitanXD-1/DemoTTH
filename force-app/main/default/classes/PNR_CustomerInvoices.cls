/**********************************************************************
  Name: PNR_CustomerInvoices
========================================================================
 Purpose: This is the Controller class for PNR_CustomerInvoices lightning component
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Tanmoy Bardhan     12-07-2019        Initial Development
    2.0        Mooventhan         30-01-2020        Changes made in the query part as part of PION 1355 user Story
***********************************************************************/
public with sharing class PNR_CustomerInvoices {
    /***************************************
     * Name : getCustomerInvoices
     * Description : This method is used to fetch customer invoices Data with customer id,
     * 				 customer type and sales org as parameter
    ****************************************/
    @AuraEnabled
    public static List<Invoice__c> getCustomerInvoices(String customerId, String customerType, String salesOrg){
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        /*  The below block is used to show invoices related to Sold-To if the customer type is Sold-To
			Or invoices related to Payer if the customer type is Payer */
        if(Schema.sObjectType.Invoice__c.isAccessible()){
            if(customerType == 'Sold-To'){
                invoiceList = [SELECT Id, SAP_Invoice_Number__c, Document_Type__c, Payer_Number__r.Name,
                               Due_Date__c, Due_Type__c, Payment_Term__c, Net_Value__c, CurrencyIsoCode,
                               Order__r.SAP_Order_Number__c, Account__r.AccountNumber,Sales_Org__c,
                               Payer_Number__r.AccountNumber, Account__r.Name, SAP_Order_Number__c,Payment_Status__c
                               FROM Invoice__c
                               WHERE Account__c = :customerId
                               AND Sales_Org__c = :salesOrg
                               AND (Due_Type__c = 'Open' OR Due_Type__c = 'Due' OR Due_Type__c = 'Overdue' OR (Due_Type__c = 'Cleared' AND Due_Date__c = LAST_90_DAYS) OR (Due_Type__c = 'Cleared' AND Due_Date__c > Today))//added as part of PION 1355 changes
                               AND Batch_Import__c = true 
                               ORDER BY Payment_Status__c DESC NULLS LAST,Due_Date__c ASC NULLS LAST];
            }else if(customerType == 'Payer'){
                invoiceList = [SELECT Id, SAP_Invoice_Number__c, Document_Type__c, Payer_Number__r.Name,
                               Due_Date__c, Due_Type__c, Payment_Term__c, Net_Value__c, CurrencyIsoCode,
                               Order__r.SAP_Order_Number__c, Account__r.AccountNumber,Sales_Org__c,
                               Payer_Number__r.AccountNumber, Account__r.Name, SAP_Order_Number__c,Payment_Status__c
                               FROM Invoice__c
                               WHERE Payer_Number__c = :customerId
                               AND Sales_Org__c = :salesOrg
                               AND (Due_Type__c = 'Open' OR Due_Type__c = 'Due' OR Due_Type__c = 'Overdue' OR (Due_Type__c = 'Cleared' AND Due_Date__c = LAST_90_DAYS) OR (Due_Type__c = 'Cleared' AND Due_Date__c > Today)) //added as part of PION 1355 changes
                               AND Batch_Import__c = true 
                               ORDER BY Payment_Status__c DESC NULLS LAST,Due_Date__c ASC NULLS LAST];
            }
        }
        return invoiceList;
    }
}