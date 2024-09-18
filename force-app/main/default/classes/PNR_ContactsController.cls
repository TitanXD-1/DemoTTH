/*****************************************************************************************
* Class Name   : PNR_ContactsController
* Purpose      : Display customer contacts and diageo contacts associated to customer.
* Created Date : 29th May, 2019
* Created By   : Jyothsna Nagapudi
******************************************************************************************/
public with sharing class PNR_ContactsController {
    
    @AuraEnabled
    //Method retrieve customer contacts of customer
    public static List<Contact> getCustomerContacts(String customerId) {
        system.debug('customerId:' + customerId);
        List<Contact> customerContacts = new List<Contact>();
        List<Id> contactIdList = new List<Id>();
        List<AccountContactRelation> customerContactRelations=new List<AccountContactRelation>();
        if(Schema.sObjectType.AccountContactRelation.isAccessible()){
            customerContactRelations = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE AccountId = :customerId AND IsActive = true];
        }
        if(!customerContactRelations.isEmpty() && customerContactRelations.size()>0){
            for(AccountContactRelation record : customerContactRelations) {
                contactIdList.add(record.ContactId);    
            }   
        }
        if(Schema.sObjectType.Contact.isAccessible()){
            customerContacts = [SELECT Id, Name, PNR_Contact_Type__c, Email, Phone, PNR_Comments__c,
                                Description FROM Contact WHERE Id = : contactIdList];
        }
        return customerContacts;
    }

    @AuraEnabled
    //Method retrieve diageo contacts of customer
    public static List<PNR_Diageo_Contact__c> getDiageoContacts(String customerId) {
        List<PNR_Diageo_Contact__c> diageoContacts=new List<PNR_Diageo_Contact__c>();
        if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            diageoContacts = [SELECT Id, PNR_Contact_Type__c, PNR_Customer__c, PNR_Name__c, PNR_Diageo_Rep__r.Name, PNR_Diageo_Rep__c, PNR_Email__c, PNR_Phone__c, PNR_Comments__c,PNR_Additional_Info__c FROM PNR_Diageo_Contact__c WHERE PNR_Customer__c = : customerId];
        }
        return diageoContacts;
    }
}