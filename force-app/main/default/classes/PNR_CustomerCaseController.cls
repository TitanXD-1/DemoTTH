/**********************************************************************
Name: PNR_CustomerCaseComponent
=======================================================================
Purpose: This is the Controller class for PNR_CustomerCaseComponent
=======================================================================
History                                                            
------------------------------------------------------------------------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     12-06-2019        Initial Development

***********************************************************************/
public with sharing class PNR_CustomerCaseController {
    /***************************************
* Name : fetchOpenOrders
* Description : This method is used to fetch case Data
****************************************/
    // Sprint 10 Changes start
    public static Map<Id, String> recordtypemap {get;set;}
    // Sprint 10 Changes end
    @AuraEnabled
    public static List<Case> fetchCustomerCases(String customerId) {
        //This methd is for getting cases from Case Object based on Customer Id
        system.debug('customerId:' + customerId);
        List<Case> customerCases = new List<Case>();
        if(Schema.sObjectType.Case.isAccessible()){
            customerCases = [SELECT Account.AccountNumber,CaseNumber,Case_Age__c,ContactEmail,Description,
                             Id,Origin,Owner.Name,Claimed_Amount__c,Dispute_Breakdown__c,Dispute_Sub_type__c,
                             Multiple_Reference__c,Reference_Invoice__r.SAP_Invoice_Number__c,Rejection_Reason__c,
                             Priority,Status,Type,Subject,CurrencyIsoCode
                             FROM Case
                             WHERE AccountId = :customerId];
        }
        
        system.debug('customerCases:' + customerCases);
        return customerCases;
        
    }
    // Sprint 10 Changes start
    @AuraEnabled        
    public static List<String> fetchRecordTypeValues(){
        List<Schema.RecordTypeInfo> recordtypes = Case.SObjectType.getDescribe().getRecordTypeInfos(); 
        Id ddCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        recordtypemap = new Map<Id, String>();
        List<String> pnrcasercdtypes = System.Label.PNR_CaseRecordTypes.Split(';');
        //String ccDDcasercdtype = System.Label.PNR_DDCaseRecordType;
        system.debug('PNR_CaseRecordTypes : '+pnrcasercdtypes);
        String profileName=[Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        if(profileName == 'CC IMC User'){
            recordtypemap.put(ddCaseRecordTypeId, 'Direct Disputes');
        }
        else {
            for(RecordTypeInfo rt : recordtypes){
                //CR-2365 - Arijit Poddar
                for(String scrty : pnrcasercdtypes){
                    if(scrty == rt.getName()){
                        recordtypemap.put(rt.getRecordTypeId(), rt.getName());
                    }
                }
                /*if(rt.getName() != 'Master' && rt.getName() != 'My Diageo Cases' && rt.getName() != 'MyDiageo Registration Issues' && rt.getName() != 'Default'){
recordtypemap.put(rt.getRecordTypeId(), rt.getName());
}*/
            }
        }
        
        return recordtypemap.values();
    }
    
    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();        
        return recid;
    }
    // Sprint 10 Changes end
    
}