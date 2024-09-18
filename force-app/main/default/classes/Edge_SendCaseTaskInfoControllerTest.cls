/****
* @Name: Edge_SendCaseTaskInfoControllerTest
* @Req: This is the test class for Edge_SendCaseTaskInfoController class.
* @User Story : ES20-11514
* @History                                                                                                                        
* @VERSION   AUTHOR            DATE              DETAIL
    1.0      Anamika Shukla     23/11/2021      Initial Development
    2.0      Joshraj Sen        08/04/2024      152305

******/
@isTest
public class Edge_SendCaseTaskInfoControllerTest {
    
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    @isTest
    public static void fetchCasetaskInfoTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        System.assert(geographyId!=null,'Geography Id is Added');
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 2';
        outlet1.BillingStreet = 'Street 2';
        outlet1.BillingCity = 'Scotland';
        insert outlet2;
        
        
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        qualityMgr.Contractor__c=True;
        insert qualityMgr; 
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
        
        Case caseObj1 = new Case();
        caseObj1.Status = 'New';
        caseObj1.Origin = 'EDGE 365 Global';
        caseObj1.RecordTypeId = qualityRecordTypeId;
        caseObj1.AccountId = outlet1.Id;   
        caseObj1.Case_Type__c = caseConfigType.Id;
        caseObj1.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj1.Case_Notes__c='Test Case Notes';
        caseObj1.Due_Date_Time__c=DateTime.now();
        insert caseObj1;
        
        
        Test.startTest();
        Case_Task__c ct6 = new Case_Task__c();
        ct6.Case__c = caseObj1.Id;
        ct6.Case_Task_Type__c = caseConfig.Id;
        ct6.Achievement_Status__c = 'Open';
        ct6.Actioned_Within_SLA__c = false;
        ct6.Account__c = outlet1.Id;
        ct6.Case_Task_Notes__c='Test Notes';
        ct6.Contractor_Name__c=qualityMgr.Id;
        
        
       // ct6.User_Assigned_To__c = qualityMgr.Id;
        insert ct6;
        Edge_SendCaseTaskInfoController.fetchCasetaskInfo(ct6.Id);
        Edge_SendCaseTaskInfoController.sendChatterMessages(ct6.Id);
        test.stopTest();
    }
}