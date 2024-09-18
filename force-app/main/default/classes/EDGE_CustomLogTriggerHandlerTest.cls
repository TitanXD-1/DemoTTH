/**
* @name EDGE_CustomLogTriggerHandlerTest
* @purpose - This is a test class to cover CustomLogTriggerHandler
* @history
* Version              Author                   Date            Detail
   1.0              Shameer/Syed Ali           27/12/2022      ES20-13690 - Initial Development

**/


@isTest
public class EDGE_CustomLogTriggerHandlerTest {
    @isTest    
    public static void testGUIDPopulate(){
        EDGE_UtilityTestClass.createOrgSettings();
         Custom_Log__c cl = new Custom_Log__c();
         cl.Class_Name__c = 'EDGE_CaseIntegrationWithSNOW';
        cl.Method_Name__c = 'execute';
        cl.Error_Message__c ='null;82;Unauthorized endpoint, please check Setup->Security->Remote site settings. endpoint =';
        cl.Stack_Trace__c = 'Class.EDGE_CaseIntegrationWithSNOW.execute: line 82, column 1';
        cl.Type__c = 'System.CalloutException';
        cl.Error_Code__c = 104;
        cl.Interface_Name__c = 'Salesforce';
        cl.OS__c = 'IOS';
        cl.Application_Version__c = '16.2';
        insert cl;
        System.assert(cl.Id!=null,'Custom Log Inserted');
        cl.Application_Version__c = '16.1';
        update cl;
        delete cl;
        undelete cl;

    }

}