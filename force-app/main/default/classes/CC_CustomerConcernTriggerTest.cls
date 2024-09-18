/**********************************************************************
Name: CC_CustomerConcernTriggerTest
=======================================================================
Purpose: This Test Class is for CC_CustomerConcernTrigger
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S       11/05/2021		Test methods
***********************************************************************/
@isTest
public class CC_CustomerConcernTriggerTest {
    
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
        
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        cc.RecordTypeId = concernConsumerCreationId;
        cc.Name = 'Test';
        cc.CC_Market__c = a.Id;
        cc.CC_Concern_Type__c ='Dispute – Delivery';
        Test.startTest();
        insert cc;
        Test.stopTest();
    }
    
    /*@isTest
    public static void testCreateCCasIMC(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = [SELECT Id FROM User WHERE Alias = 'cc_ccc'].Id;
        a.CC_CSE__c = [SELECT Id FROM User WHERE Alias = 'cc_cse'].Id;
        insert a;
        system.debug(a);
        
        User cc_imc = [SELECT Id FROM User WHERE Alias = 'cc_imc'];
        system.runAs(cc_imc){
            Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
            Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
            
            CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
            cc.RecordTypeId = concernConsumerCreationId;
            cc.Name = 'Test1';
            insert cc;
            
            List<Account> accList = [SELECT Id FROM Account LIMIT 1];
            CC_Customer_Concern__c cc1 = new CC_Customer_Concern__c();
            cc1.RecordTypeId = concernConsumerCreationId;
            cc1.Name = 'Test1';
            //if(accList.size()>0)
                cc1.CC_Market__c = accList[0].Id;
            insert cc1;
        }
    }*/
    
    @isTest
    public static void testCCstatuschange(){
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
        Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
        
        CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
        cc.RecordTypeId = concernCustomerCreationId;
        cc.Name = 'Test';
        Test.startTest();
        insert cc;
        
        cc.CC_Status__c = 'Closed';
        update cc;
        Test.stopTest();
      
    }
}