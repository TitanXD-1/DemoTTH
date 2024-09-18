/**********************************************************************
Name: CC_CaseTriggerHelperTest
=======================================================================
Purpose: This Test Class is for CC_CaseTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S       19/03/2021		Test method for assignCSEandCCC
***********************************************************************/
@isTest
public class CC_CaseTriggerHelperTest {
    
    @isTest
    public static void testassignCSEandCCC(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        //retrieve Default Entitlement Process information
        String entitlementName = Label.CC_Entitlement_Name;
        Id entitlementProcessId = [SELECT Id FROM SlaProcess 
                                   WHERE SObjectType = 'Case' 
                                   AND Name=: entitlementName AND isActive = true].Id;
        
        //create Entitlement Record
        Entitlement ent = new Entitlement (AccountId=a.Id, SLAProcessId = entitlementProcessId, Name = 'Test Entitlement');
        insert ent;
        
        Id CC_ConsumerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        
        Case c = new Case();
        c.RecordTypeId = CC_ConsumerConcernRT;
        c.CC_Market__c = a.Id;
        c.CC_Product_Type__c = 'Prestige';
        c.CC_Prestige_Product__c = 'Prestige 1';
        c.CC_Passed_for_Investigation__c = Date.newInstance(2021, 05, 08);
        Test.startTest();
        insert c;
        
        c.CC_Received_from_Investigation__c = Date.newInstance(2021, 05, 09);
        update c;
        Test.stopTest();
    }
    
    @isTest
    public static void testassignCSEandCCCdefault(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Id CC_ConsumerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        
        Case c = new Case();
        c.RecordTypeId = CC_ConsumerConcernRT;
        c.CC_Market__c = a.Id;
        Test.startTest();
        insert c;
        
        c.Status ='In Progress';
        c.CC_Security_Manager__c =u.id;
        update c;
        Test.stopTest();
    }
}