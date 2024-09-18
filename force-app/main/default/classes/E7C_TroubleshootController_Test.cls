@isTest
public class E7C_TroubleshootController_Test {
    @testSetup static void setup() {
        E7C_Troubleshoot__c ts = new E7C_Troubleshoot__c();
        ts.Name = 'Troubleshoot-IRELAND';
        ts.E7C_Market__c = 'IRELAND';
        insert ts;
        
        E7C_Troubleshoot_Content__c tsContent = new E7C_Troubleshoot_Content__c();
        tsContent.E7C_Action__c = 'Connect to a new bottle';
        tsContent.E7C_Cause__c = 'Gas bottle is empty';
        tsContent.E7C_Criteria__c = 'C1 Correct Gas';
        tsContent.E7C_Troubleshoot__c = ts.Id;
        tsContent.E7C_Type__c = 'No Flow;Slow Flow'; 
        insert tsContent;
    }
    
    @isTest
    public static void E7C_TroubleshootController(){
        E7C_TroubleshootController.getTroubleshootData();
    }

}