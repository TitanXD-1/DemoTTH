@isTest
public class CC_SendFinalReportEmailTest {
    
    @testSetup static void testDataSetup(){
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse','System Administrator');
        insert u1;
    }
    
    @isTest
    public static void testSendFinalReportPDF(){
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
        
        Id CC_ConsumerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        
        Case c = new Case();
        c.RecordTypeId = CC_ConsumerConcernRT;
        c.CC_Market__c = a.Id;
        c.CC_Product_Type__c = 'Prestige';

        c.CC_Prestige_Product__c = 'Prestige 1';

        c.CC_Passed_for_Investigation__c = Date.newInstance(2021, 05, 08);
        Test.startTest();
        insert c;
        
        List<CC_SendFinalReportEmail.FlowInputs> fiList = new List<CC_SendFinalReportEmail.FlowInputs>();
        CC_SendFinalReportEmail.FlowInputs fi = new CC_SendFinalReportEmail.FlowInputs();
        fi.toAddress = 'test@test.com';
        fi.ccAddress = 'test@test.com';
        fi.recordId = c.Id;
        fiList.add(fi);

        
        CC_SendFinalReportEmail.sendFinalReportEmail(fiList);
        Test.stopTest();

        
    }
    
}