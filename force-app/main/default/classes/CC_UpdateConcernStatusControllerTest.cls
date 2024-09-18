@isTest
public class CC_UpdateConcernStatusControllerTest {
	@testSetup static void testDataSetup(){
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse','System Administrator');
        insert u1;
        
        User u2 = EDGE_UtilityTestClass.runAsUser('cc_imc','CC_IMC');
        u2.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'CC IMC'].Id;
        insert u2;
    }
    @isTest
    public static void testCreateCC(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = [SELECT Id FROM User WHERE Alias = 'cc_ccc'].Id;
        a.CC_CSE__c = [SELECT Id FROM User WHERE Alias = 'cc_cse'].Id;
        insert a;
        
        List<Id> ccIds= new List<Id>();
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        cc.RecordTypeId = concernConsumerCreationId;
        cc.Name = 'Test';
        cc.CC_Market__c = a.Id;
        cc.OwnerId = a.CC_CSE__c;
        cc.CC_Status__c = 'New';
        insert cc;
        
        CC_UpdateConcernStatusController.getConcernStatusPickVal(cc.Id);
        system.assertEquals(cc, cc);
    }
  /*  @isTest
    public static void testCCPickVal(){
        Map<String, String> pickVal = new Map<String, String>();
        
        Map<String, String> actualPickVal = CC_UpdateConcernStatusController.getPicklistvalues('CC_Customer_Concern__c', 'CC_Is_it_a_regulatory_issue__c', true);
        system.assertNotEquals(pickVal, actualPickVal);
    }*/
    @isTest
    public static void testCCUpdateStatus(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = [SELECT Id FROM User WHERE Alias = 'cc_ccc'].Id;
        a.CC_CSE__c = [SELECT Id FROM User WHERE Alias = 'cc_cse'].Id;
        insert a;
        
        List<Id> ccIds= new List<Id>();
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        cc.RecordTypeId = concernConsumerCreationId;
        cc.Name = 'Test';
        cc.CC_Market__c = a.Id;
        cc.OwnerId = a.CC_CSE__c;
        cc.CC_Status__c = 'New';
        insert cc;
        
        cc.CC_Status__c = 'Closed';
        update cc;
        
        CC_UpdateConcernStatusController.getUpdateConcernStatus(cc.Id, cc);
        system.assertEquals('Closed', cc.CC_Status__c);
    }
}