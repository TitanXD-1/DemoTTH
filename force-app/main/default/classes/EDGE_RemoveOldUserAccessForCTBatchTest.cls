/**

* @Description: EDGE_RemoveOldUserAccessForCTBatchTest

* @Purpose : Test Class for EDGE_RemoveOldUserAccessForCTBatch

* @History:

* @Version     Developer             Date              Story/Purpose

*  1.1         Aparajita            25/01/2022        ES20-11892(Method:testRemoveAccess)
*  1.2         Joshraj              08/04/2024        152305

*/

@isTest
public class EDGE_RemoveOldUserAccessForCTBatchTest {
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    @isTest
    public static void testRemoveAccess(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
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
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration1';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration1';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration1';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
        
        Test.startTest();
        
        System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());
        
        List<User> qualityUsers = new List<User>();
        
        User qualityRep1 = EDGE_UtilityTestClass.runAsUser('TestQualityRep1', 'Quality Representative');
        qualityRep1.Available_Countries__c = 'GB';
        qualityUsers.add(qualityRep1);  
        insert qualityUsers;
        
         System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());

        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet1.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
        
         System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.User_Assigned_To__c = qualityRep1.Id;
        insert ct1;  
        
        System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());
      
        Test.stopTest();            
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_RemoveOldUserAccessForCTBatch' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));   
        System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());        
    }
}