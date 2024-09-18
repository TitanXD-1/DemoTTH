@isTest
public class CC_MilestoneMinutesCalculator_Test {
    
    @testSetup static void setup() {
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.Name = 'Test Account1';
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
    }
    
    static testmethod void testCC_MilestoneMinutesCalculator1(){
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account1'];
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        c.CC_Product_Type__c = 'Prestige';
        c.CC_Prestige_Product__c = 'Luxury';
        c.CC_Passed_for_Investigation__c = System.today() - 9;
        insert c;
        
        Test.startTest();
        CC_MilestoneMinutesCalculator mc = new CC_MilestoneMinutesCalculator();
        mc.calculateMilestoneTriggerTime(c.Id, '');
        
        c.CC_Passed_for_Investigation__c = System.today();
        update c;
        mc.calculateMilestoneTriggerTime(c.Id, '');
        
        Test.stopTest();
    }
    
    static testmethod void testCC_MilestoneMinutesCalculator2(){
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account1'];
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        c.CC_Product_Type__c = 'Prestige';
        c.CC_Prestige_Product__c = 'Prestige 1';
        c.CC_Passed_for_Investigation__c = System.today() - 9;
        insert c;
        
        Test.startTest();
        CC_MilestoneMinutesCalculator mc = new CC_MilestoneMinutesCalculator();
        mc.calculateMilestoneTriggerTime(c.Id, '');
        c.CC_Passed_for_Investigation__c = System.today();
        update c;
        mc.calculateMilestoneTriggerTime(c.Id, '');
        Test.stopTest();
    }
    
   static testmethod void testCC_MilestoneMinutesCalculator3(){
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account1'];
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        c.CC_Product_Type__c = 'Prestige';
        c.CC_Prestige_Product__c = 'Prestige 2';
        c.CC_Passed_for_Investigation__c = System.today() - 9;
        insert c;
        
        Test.startTest();
        CC_MilestoneMinutesCalculator mc = new CC_MilestoneMinutesCalculator();
        mc.calculateMilestoneTriggerTime(c.Id, '');
       c.CC_Passed_for_Investigation__c = System.today();
        update c;
        mc.calculateMilestoneTriggerTime(c.Id, '');
        Test.stopTest();
    }
    
    static testmethod void testCC_MilestoneMinutesCalculator4(){
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account1'];
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        c.CC_Product_Type__c = 'Standard';
        c.CC_Passed_for_Investigation__c = System.today() - 9;
        insert c;
        
        Test.startTest();
        CC_MilestoneMinutesCalculator mc = new CC_MilestoneMinutesCalculator();
        mc.calculateMilestoneTriggerTime(c.Id, '');
        c.CC_Passed_for_Investigation__c = System.today();
        update c;
        mc.calculateMilestoneTriggerTime(c.Id, '');
        Test.stopTest();
    }
    
}