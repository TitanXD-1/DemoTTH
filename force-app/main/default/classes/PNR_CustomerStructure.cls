/****************************************************************************************************************
Name: PNR_CustomerStructure
=======================================================================
Purpose: Controller for Customer Struction Screen of Customer 360 module. Display customer structure of sold to/payer
=======================================================================
History                                                            
-------                                                            
VERSION         AUTHOR                  DATE                        DETAIL
1.0         Jyothsna Nagapudi       29th May, 2019                Initial Development
2.0      	Tanmoy Bardhan   	        --                              --
3.0      	Pratik Kumar   	        17th Nov, 2021                PION-966: Added relevant fields in the SOQL query
********************************************************************************************************************/
public with sharing class PNR_CustomerStructure {
    @AuraEnabled
    //Method to fetch customer structure of sold-to
    public static List<PNR_CustomerStructureWrapper> fetchSoldToStructure(Id customerID, String salesOrg){
        system.debug('customerID-->'+customerID);
        //Need to display all Payer, bill to, ship to associated to 'Sold to' Customer in same order
        List<PNR_CustomerStructureWrapper> finalPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> soldToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> payerToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> billToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> shipToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        
        List<PNR_Partner_Function__c> partnerFunctionList = new List<PNR_Partner_Function__c>();
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
            partnerFunctionList = [SELECT PNR_Default_Partner__c, PNR_Distribution_Channel__c, PNR_Division__c, 
                                   PNR_Customer_No__r.Account_Number_with_Credit_Limit_Ref__c,
                                   PNR_Customer_No__r.SAP_Customer_Status__c,
                                   PNR_Sold_To__c, PNR_Sales_Org__c, PNR_Type__c,PNR_Correspondence_Indicator__c,  
                                   PNR_Customer_No__r.Name,PNR_Customer_No__r.BillingStreet,PNR_Customer_No__r.BillingCity,//changed here
                                   PNR_Customer_No__r.BillingCountry,PNR_Customer_No__r.BillingPostalCode,PNR_Customer_No__r.AccountNumber, //changed here
                                   PNR_Customer_No__r.Central_Order_Block__c, PNR_Customer_No__r.Central_Delivery_Block__c, PNR_Customer_No__r.Central_Billing_Block__c //ver 3.0 editted here
                                   FROM PNR_Partner_Function__c
                                   WHERE PNR_Sold_To__c = :customerID AND PNR_Sales_Org__c = :salesOrg
                                   AND PNR_Customer_No__r.Sort__c !='staff'
                                   AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                                   AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE];
        } 
        if(partnerFunctionList != null && partnerFunctionList.size() > 0) {
            for(PNR_Partner_Function__c pfRecord : partnerFunctionList) {
                if(pfRecord.PNR_Type__c == 'Sold-To') {
                    soldToPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pfRecord, false));
                }
                else if(pfRecord.PNR_Type__c == 'Payer'){
                    payerToPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pfRecord, false));
                }
                else if(pfRecord.PNR_Type__c == 'Bill-To'){
                    billToPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pfRecord, true));
                }
                else if(pfRecord.PNR_Type__c == 'Ship-To'){
                    shipToPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pfRecord,true));
                }
            }
        }
        if(soldToPartnerFunctionWrapper != null && soldToPartnerFunctionWrapper.size() > 0) {
            finalPartnerFunctionWrapper.addAll(soldToPartnerFunctionWrapper); 
        }
        if(payerToPartnerFunctionWrapper != null && payerToPartnerFunctionWrapper.size() > 0) {
            finalPartnerFunctionWrapper.addAll(payerToPartnerFunctionWrapper);    
        }
        if(billToPartnerFunctionWrapper != null && billToPartnerFunctionWrapper.size() > 0) {
            finalPartnerFunctionWrapper.addAll(billToPartnerFunctionWrapper);    
        }
        if(shipToPartnerFunctionWrapper != null && shipToPartnerFunctionWrapper.size() > 0) {
            finalPartnerFunctionWrapper.addAll(shipToPartnerFunctionWrapper);    
        }
        system.debug('finalPartnerFunctionWrapper'+finalPartnerFunctionWrapper);
        return finalPartnerFunctionWrapper;
    }
    @AuraEnabled
    //Method to fetch customer structure of Payer
    public static List<PNR_CustomerStructureWrapper> fetchPayerStructure(Id customerID, String salesOrg){
        system.debug('customerID-->'+customerID);
        //system.debug('customerID-->'+salesArea);
        List<PNR_CustomerStructureWrapper> finalPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> soldToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> payerToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> billToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        List<PNR_CustomerStructureWrapper> shipToPartnerFunctionWrapper = new List<PNR_CustomerStructureWrapper>();
        
        //Need to display all Sold to, bill to associated to 'Payer' Customer in same order
        Set<String> uniqueSoldToSalesOrg = new Set<String>();
        Set<String> salesOrgSet = new Set<String>();
        Set<Id> soldToSet = new Set<Id>();
        PNR_Partner_Function__c firstPayerRecord = new PNR_Partner_Function__c(); 
        Map<String,List<PNR_Partner_Function__c>> soldToMap = new Map<String,List<PNR_Partner_Function__c>>();
        Map<String,List<PNR_Partner_Function__c>> billToMap = new Map<String,List<PNR_Partner_Function__c>>();
        Map<String,List<PNR_Partner_Function__c>> payerMap = new Map<String,List<PNR_Partner_Function__c>>();
        List<PNR_Partner_Function__c> finalPFList = new List<PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> payerPFList = new List<PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> soldToPFList = new List<PNR_Partner_Function__c>();
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
            payerPFList = [SELECT PNR_Default_Partner__c, PNR_Distribution_Channel__c, PNR_Division__c, 
                           PNR_Customer_No__r.Account_Number_with_Credit_Limit_Ref__c,PNR_Correspondence_Indicator__c,
                           PNR_Customer_No__r.SAP_Customer_Status__c,
                           PNR_Sold_To__c, PNR_Sold_To__r.AccountNumber, PNR_Sales_Org__c, PNR_Type__c, //changed here
                           PNR_Customer_No__r.Name,PNR_Customer_No__r.BillingStreet,PNR_Customer_No__r.BillingCity,//changed here
                           PNR_Customer_No__r.BillingCountry,PNR_Customer_No__r.BillingPostalCode,PNR_Customer_No__r.AccountNumber //changed here
                           FROM PNR_Partner_Function__c
                           WHERE PNR_Customer_No__c = :customerID
                           AND PNR_Sales_Org__c = :salesOrg
                           AND PNR_Customer_No__r.Sort__c !='staff'
                           AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                           AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE];
        }    
        system.debug('payerPFList'+payerPFList+'size:' +payerPFList.size());
        if(payerPFList != null && payerPFList.size() > 0) {
            for(PNR_Partner_Function__c payerPF : payerPFList) {
                salesOrgSet.add(payerPF.PNR_Sales_Org__c);
                soldToSet.add(payerPF.PNR_Sold_To__c);
            }
        }
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
            soldToPFList = [SELECT PNR_Default_Partner__c, PNR_Distribution_Channel__c, PNR_Division__c,  
                            PNR_Customer_No__r.Account_Number_with_Credit_Limit_Ref__c,PNR_Correspondence_Indicator__c,
                            PNR_Customer_No__r.SAP_Customer_Status__c,
                            PNR_Sold_To__c, PNR_Sold_To__r.AccountNumber, PNR_Sales_Org__c, PNR_Type__c, //changed here
                            PNR_Customer_No__r.Name,PNR_Customer_No__r.BillingStreet,PNR_Customer_No__r.BillingCity,//changed here
                            PNR_Customer_No__r.BillingCountry,PNR_Customer_No__r.BillingPostalCode,PNR_Customer_No__r.AccountNumber //changed here
                            FROM PNR_Partner_Function__c
                            WHERE (PNR_Sold_To__c IN :soldToSet AND PNR_Sales_Org__c = :salesOrg)
                            AND PNR_Customer_No__r.Sort__c !='staff'
                            AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                            AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE
                            AND PNR_Type__c != 'Ship-To'];
        }    
        system.debug('soldToPFList'+soldToPFList+'size:' +soldToPFList.size());
        for(PNR_Partner_Function__c soldToRecord : soldToPFList) {
            if(soldToRecord.PNR_Type__c == 'Sold-To') {//changed here    
                if(soldToMap.containsKey(soldToRecord.PNR_Sold_To__c)) {
                    soldToMap.get(soldToRecord.PNR_Sold_To__c).add(soldToRecord);    
                }
                else{
                    List<PNR_Partner_Function__c> tempList = new List<PNR_Partner_Function__c>();
                    tempList.add(soldToRecord);
                    soldToMap.put(soldToRecord.PNR_Sold_To__c,tempList);
                }
                
            }
            else if(soldToRecord.PNR_Type__c == 'Payer') {//changed here
                if(soldToRecord.PNR_Customer_No__r.AccountNumber == payerPFList.get(0).PNR_Customer_No__r.AccountNumber &&
                   soldToRecord.PNR_Distribution_Channel__c  == payerPFList.get(0).PNR_Distribution_Channel__c  &&
                   soldToRecord.PNR_Division__c  == payerPFList.get(0).PNR_Division__c) {//changed here
                    //skipping payer for what customer structure is displaying
                    system.debug('skip record');
                }
                else {
                    if(payerMap.containsKey(soldToRecord.PNR_Sold_To__c)) {
                        payerMap.get(soldToRecord.PNR_Sold_To__c).add(soldToRecord);    
                    }
                    else{
                        List<PNR_Partner_Function__c> tempList = new List<PNR_Partner_Function__c>();
                        tempList.add(soldToRecord);
                        payerMap.put(soldToRecord.PNR_Sold_To__c,tempList);
                    }
                }    
                
            }
            else if(soldToRecord.PNR_Type__c == 'Bill-To') {//changed here
                if(billToMap.containsKey(soldToRecord.PNR_Sold_To__c)) {
                    billToMap.get(soldToRecord.PNR_Sold_To__c).add(soldToRecord);    
                }
                else{
                    List<PNR_Partner_Function__c> tempList = new List<PNR_Partner_Function__c>();
                    tempList.add(soldToRecord);
                    billToMap.put(soldToRecord.PNR_Sold_To__c,tempList);
                }
                
            }
        }
        system.debug('payerMap:' + payerMap);
        system.debug('billToMap:' + billToMap);
        system.debug('soldToMap:' + soldToMap);
        system.debug('payerPFList.get(0):' + payerPFList.get(0));
        firstPayerRecord = payerPFList.get(0);
        firstPayerRecord.PNR_Type__c = 'Payer';
        finalPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(firstPayerRecord, false));
        system.debug('finalPFList before:' + finalPartnerFunctionWrapper);
        for(String uniqueSoldTo : soldToSet) {
            if(soldToMap.containsKey(uniqueSoldTo)) {
                for(PNR_Partner_Function__c pf : soldToMap.get(uniqueSoldTo)) {
                	finalPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pf, false));    
                }
            }
            if(payerMap.containsKey(uniqueSoldTo)) {
                for(PNR_Partner_Function__c pf : payerMap.get(uniqueSoldTo)) {
                	finalPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pf, false));    
                }   
            }
            if(billToMap.containsKey(uniqueSoldTo)) {
                for(PNR_Partner_Function__c pf : billToMap.get(uniqueSoldTo)) {
                	finalPartnerFunctionWrapper.add(new PNR_CustomerStructureWrapper(pf, true));    
                }  
            }
            
        }
        
        system.debug('finalPFList after:' + finalPartnerFunctionWrapper);
        return finalPartnerFunctionWrapper;
    }
}