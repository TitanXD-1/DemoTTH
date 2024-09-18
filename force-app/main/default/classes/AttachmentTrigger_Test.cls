/*
 * @class: PNR_AttachmentTriggerHelper_Test
 * @description: This is test class for PNR_AttachmentTriggerHelper
 * @author: Sai Kiran Sagaram
 * This class is written for PION-1715 change.
 * */
@isTest
public class AttachmentTrigger_Test {
    
    @testSetup 
    public static void setup() {
        
        PNR_TestDataUtility.createOrgSettings();
        Id countryId = PNR_TestDataUtility.setupCountry('AUS');
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=countryId;
        insert cust;
        
        Id ddRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Direct_Disputes').getRecordTypeId();
        Case cse =PNR_TestDataUtility.getCaseData();
        cse.CurrencyIsoCode = 'GBP';
        cse.Claimed_Amount__c = 102.00;
        cse.AccountId=cust.Id;
        cse.Status = 'New';
        cse.RecordTypeId = ddRecordTypeId;
        insert cse;
        
        Attachment attach=new Attachment();   	
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=cse.id;
        insert attach;
    }
    
    static testmethod void deleteAttachmenttTest(){
        case cse = [select id from case limit 1];
        cse.Status = 'Externally Approved';
        update cse;
        Attachment att = [select id from Attachment limit 1];
        try{ 
            update att;
            delete att;
        }catch(exception e){}
    }
    
    static testmethod void deletePositiveTest(){
        Attachment att = [select id from Attachment limit 1];
        delete att;
    }
    
}