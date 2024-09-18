@isTest
public class CC_SendRejectionEmailToCaseOwnerTest {
    
    @testSetup static void testDataSetup(){
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse','System Administrator');
        insert u1;
    }
    
    @isTest
    public static void testSendRejectionMail(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = [SELECT Id FROM User WHERE Alias = 'cc_ccc'].Id;
        a.CC_CSE__c = [SELECT Id FROM User WHERE Alias = 'cc_cse'].Id;
        insert a;
        
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        cc.RecordTypeId = concernConsumerCreationId;
        cc.Name = 'Test';
        cc.CC_Market__c = a.Id;
        insert cc;
        
        CC_SendRejectionEmailToCaseOwner.checkStatus(cc.Id);
        
        CC_SendRejectionEmailToCaseOwner.sendMail(cc.Id);
        
        cc.CC_Status__c = 'Under Investigation';
        update cc;
        
        CC_SendRejectionEmailToCaseOwner.checkStatus(cc.Id);
    }
}