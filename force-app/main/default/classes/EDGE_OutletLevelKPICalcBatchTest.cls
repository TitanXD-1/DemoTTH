/**

* @Description :  EDGE_OutletLevelKPICalcBatchTest

* @Purpose : To test EDGE_OutletLevelKPICalcBatch

* @History :

* Version   Developer      Date       User Story	  Purpose
* 1.1       Aparajita    11/11/2021   ES20-11045      Method:testKPIFieldsCalcAtOutletLevel
* 1.2       Prasanth T   23/09/2022   ES20-13324      Test Class Correction due to Failure
* 1.3       Joshraj Sen  08/04/2024   152305          Fixed SCA
*/
@isTest
public class EDGE_OutletLevelKPICalcBatchTest {
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    @isTest
    public static void testKPIFieldsCalcAtOutletLevel(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();



        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(geographyId);
        marketCycle.Start_Date__c = Date.Today();
        marketCycle.End_Date__c = Date.Today().addDays(30);
        marketCycle.Geography__c = geographyId;
        insert marketCycle;
        system.debug(LoggingLevel.Debug,'Condition 1 '+Limits.getQueries());
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.debug(LoggingLevel.Debug,'Condition 2 '+Limits.getQueries());
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        system.debug(LoggingLevel.Debug,'Condition 3 '+Limits.getQueries());
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 2';
        outlet1.BillingStreet = 'Street 2';
        outlet1.BillingCity = 'Scotland';
        insert outlet2;
        system.debug(LoggingLevel.Debug,'Condition 4 '+Limits.getQueries());
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;
        system.debug(LoggingLevel.Debug,'Condition 5 '+Limits.getQueries());
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;
        system.debug(LoggingLevel.Debug,'Condition 6 '+Limits.getQueries());
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
        system.debug(LoggingLevel.Debug,'Condition 7 '+Limits.getQueries());
        
        Case caseObj1 = new Case();
        caseObj1.Status = 'New';
        caseObj1.Origin = 'EDGE 365 Global';
        caseObj1.RecordTypeId = qualityRecordTypeId;
        caseObj1.AccountId = outlet1.Id;   
        caseObj1.Case_Type__c = caseConfigType.Id;
        caseObj1.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj1;
        system.debug(LoggingLevel.Debug,'Condition 8 '+Limits.getQueries());
        Test.startTest();
        Case caseObj2 = new Case();
        caseObj2.Status = 'New';
        caseObj2.Origin = 'EDGE 365 Global';
        caseObj2.RecordTypeId = qualityRecordTypeId;
        caseObj2.AccountId = outlet2.Id;   
        caseObj2.Case_Type__c = caseConfigType.Id;
        caseObj2.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj2;
        system.debug(LoggingLevel.Debug,'Condition 9 '+Limits.getQueries());
        
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj1.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.CreatedDate = Date.Today().addDays(-1);
        ctList.add(ct1);
        
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj1.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Achieved';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet1.Id;
        ctList.add(ct2);
        
        Case_Task__c ct3 = new Case_Task__c();
        ct3.Case__c = caseObj1.Id;
        ct3.Case_Task_Type__c = caseConfig.Id;
        ct3.Achievement_Status__c = 'Achieved';
        ct3.Actioned_Within_SLA__c = false;
        ct3.Account__c = outlet1.Id;
        ctList.add(ct3);
        
        Case_Task__c ct4 = new Case_Task__c();
        ct4.Case__c = caseObj1.Id;
        ct4.Case_Task_Type__c = caseConfig.Id;
        ct4.Achievement_Status__c = 'Not Achieved';
        ct4.Actioned_Within_SLA__c = true;
        ct4.Account__c = outlet1.Id;
        ctList.add(ct4);
        
        Case_Task__c ct5 = new Case_Task__c();
        ct5.Case__c = caseObj1.Id;
        ct5.Case_Task_Type__c = caseConfig.Id;
        ct5.Achievement_Status__c = 'Not Achieved';
        ct5.Actioned_Within_SLA__c = false;
        ct5.Account__c = outlet1.Id;
        ctList.add(ct5);
        
        Case_Task__c ct6 = new Case_Task__c();
        ct6.Case__c = caseObj1.Id;
        ct6.Case_Task_Type__c = caseConfig.Id;
        ct6.Achievement_Status__c = 'Cancelled';
        ct6.Actioned_Within_SLA__c = false;
        ct6.Account__c = outlet1.Id;
        ctList.add(ct6);
        
        Case_Task__c ct7 = new Case_Task__c();
        ct7.Case__c = caseObj2.Id;
        ct7.Case_Task_Type__c = caseConfig.Id;
        ct7.Achievement_Status__c = 'Cancelled';
        ct7.Actioned_Within_SLA__c = false;
        ct7.Account__c = outlet2.Id;
        ctList.add(ct7);
        
        Database.insert(ctList);
        system.debug(LoggingLevel.Debug,'Condition 10 '+Limits.getQueries());
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletLevelKPICalcBatch' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();       
    }
}