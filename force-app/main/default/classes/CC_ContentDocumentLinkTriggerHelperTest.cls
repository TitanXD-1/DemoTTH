@isTest
public class CC_ContentDocumentLinkTriggerHelperTest {
    
    @testSetup static void testDataSetup(){
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse','System Administrator');
        insert u1;
    }
    
    @isTest
    public static void testCloneEvidence(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        Id accRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        if(accRT != null)
            a.RecordTypeId = accRT;
        List<User> userList = [SELECT Id, Alias FROM User WHERE Alias = 'cc_ccc' OR Alias = 'cc_cse'];
        for(User u : userList){
            if(u.Alias == 'cc_ccc')
                a.CC_CCC__c = u.Id;
            if(u.Alias == 'cc_cse')
                a.CC_CSE__c = u.Id;
        }
        insert a;
        
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        if(concernConsumerCreationId != null)
            cc.RecordTypeId = concernConsumerCreationId;
        cc.Name = 'Test';
        cc.CC_Market__c = a.Id;
        insert cc;
        
        ContentVersion cv = new ContentVersion(); 
        cv.Title = 'Test_CV'; 
        cv.PathOnClient = '/' + cv.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        cv.VersionData = bodyBlob; 
        cv.origin = 'H';
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = cc.id;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        Test.startTest();
        insert cdl;
        Test.stopTest();
    }
}