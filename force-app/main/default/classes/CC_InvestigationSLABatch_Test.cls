@isTest
public class CC_InvestigationSLABatch_Test {
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
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        insert c;        
    }
    
    static testmethod void testInvestigationSLABatch1() {
        
        Case c = [SELECT Id FROM Case WHERE CC_Market__r.Name = 'Test Account1'];
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Lab Investigation').getRecordTypeId();
        invest.CC_Date_sent_by_market__c = Date.newInstance(2021, 01, 05);
        invest.CC_Case__c = c.Id;
        insert invest;
        
        String cronexpression = '0 0 0 15 3 ? *';
        
        Test.startTest();
        String jobId = System.schedule('ScheduleBatchApexClass',  cronexpression, new CC_InvestigationSLABatchScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronexpression, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }
    
    static testmethod void testInvestigationSLABatch2() {
        
        Case c = [SELECT Id FROM Case WHERE CC_Market__r.Name = 'Test Account1'];
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Lab Investigation').getRecordTypeId();
        invest.CC_Date_arrived_at_lab__c = Date.newInstance(2021, 03, 12);
        invest.CC_Case__c = c.Id;
        insert invest;
        
        String cronexpression = '0 0 0 15 3 ? *';
        
        Test.startTest();
        String jobId = System.schedule('ScheduleBatchApexClass',  cronexpression, new CC_InvestigationSLABatchScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronexpression, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }
    
    static testmethod void testInvestigationSLABatch3() {
        
        Case c = [SELECT Id FROM Case WHERE CC_Market__r.Name = 'Test Account1'];
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Lab Investigation').getRecordTypeId();
        invest.CC_Date_investigation_starts__c = Date.newInstance(2021, 03, 12);
        invest.CC_Case__c = c.Id;
        insert invest;
        
        String cronexpression = '0 0 0 15 3 ? *';
        
        Test.startTest();
        String jobId = System.schedule('ScheduleBatchApexClass',  cronexpression, new CC_InvestigationSLABatchScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronexpression, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }

}