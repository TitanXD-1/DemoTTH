/**********************************************************************
Name: PNR_OpenOrdersController
=======================================================================
Purpose: This is the Controller class for PNR_OpenOrdersComponent
=======================================================================
History                                                            
------------------------------------------------------------------------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     12-06-2019        Initial Development
1.1        Tanmoy Bardhan    25-06-2019        Modified
***********************************************************************/
public with sharing class PNR_OpenOrdersController {
    /***************************************
* Name : fetchOpenOrders
* Description : This method is used to fetch openOrders Data 
****************************************/
    @AuraEnabled
    public static List<Order__c> fetchOpenOrders(String customerId, String customerType,String salesOrg) {
        string soldTocustomerType =  'Sold-To';
        string payercustomerType =  'Payer';
        //This methd is for getting orders from Order Object based on Customer Type i.e. Sold-To, Payer and Status
        system.debug('customerId:' + customerId);
        List<Order__c> openOrders = new List<Order__c>();
        if(customerType.equalsIgnoreCase(soldTocustomerType)){
            if(Schema.sObjectType.Order__c.isAccessible()){
                //openOrders = [SELECT Id, PNR_SAP_Order_Number__c,Account.PNR_Customer_Number__c,PoNumber, Account.PNR_Customer_Name__c,PNR_Payer_Number__r.PNR_Customer_Number__c,PNR_RDD__c,PNR_Net_Value__c,PNR_Currency__c,PNR_Credit_Held__c,PNR_Order_Type__c FROM Order WHERE AccountId = :customerId AND Status = 'Open'];
                openOrders = [SELECT Id, SAP_Order_Number__c,Account__r.AccountNumber,PO_Number__c, Account__r.Name,
                              Payer_Number__r.AccountNumber,Requested_Delivery_Date__c,Net_Value__c,Credit_Held__c,
                              CurrencyIsoCode,SAP_Order_Type__c,Billing_Document__c,Is_Deletion_Indicator_Flag__c,Delivery_Document__c,Central_Billing_Block__c,Delivery_Block__c
                              FROM Order__c
                              WHERE Account__c = :customerId
                              AND Sales_Org__c = :salesOrg
                              AND Billing_Document__c = NULL 
                              AND Is_Deletion_Indicator_Flag__c = False 
                              AND Real_Time_Fetch_from_SAP__c = False
                              Order by Requested_Delivery_Date__c DESC NULLS LAST,SAP_Order_Number__c DESC NULLS LAST];
            }
        }
        else if (customerType.equalsIgnoreCase(payercustomerType)){
            if(Schema.sObjectType.Order__c.isAccessible()){
                //openOrders = [SELECT Id,PNR_SAP_Order_Number__c,Account.PNR_Customer_Number__c,PoNumber,Account.PNR_Customer_Name__c,PNR_Payer_Number__r.PNR_Customer_Number__c,PNR_RDD__c,PNR_Net_Value__c,PNR_Currency__c,PNR_Credit_Held__c,PNR_Order_Type__c FROM Order WHERE PNR_Payer_Number__c = :customerId AND Status = 'Open'];
                openOrders = [SELECT Id,SAP_Order_Number__c,Account__r.AccountNumber,PO_Number__c,Account__r.Name,
                              Payer_Number__r.AccountNumber,Requested_Delivery_Date__c,Net_Value__c,Credit_Held__c,
                              CurrencyIsoCode,SAP_Order_Type__c,Billing_Document__c,Is_Deletion_Indicator_Flag__c,Delivery_Document__c,Central_Billing_Block__c,Delivery_Block__c
                              FROM Order__c
                              WHERE Payer_Number__c = :customerId
                              AND Sales_Org__c = :salesOrg 
                              AND Billing_Document__c = NULL 
                              AND Is_Deletion_Indicator_Flag__c = False
                              AND Real_Time_Fetch_from_SAP__c = False
                              Order by Requested_Delivery_Date__c DESC NULLS LAST,SAP_Order_Number__c DESC NULLS LAST];
            }
        }
        
        system.debug('customerContacts:' + openOrders);
        return openOrders;
        
    }
    
}