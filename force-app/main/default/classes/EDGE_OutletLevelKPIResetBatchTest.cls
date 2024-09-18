/**
* @ Name : EDGE_OutletLevelKPIResetBatchTest

* @description  Test class for EDGE_OutletLevelKPIResetBatch

* @ History  
* @	 	Author          Version    				Date           Detail
* @		Saranya L       Initial Development	   08/02/2022     Created for ES20-11576
* @     Prasanth T      1.1                    23/09/2022     Test Class Correction due to Failure(ES20-13324) 
* @     Sakshi Shah                            26/07/2024     PMD Fix
* @.    Saikiran        156229                 26/08/2024.    Deployment fix
**/

@isTest
public class EDGE_OutletLevelKPIResetBatchTest {
    final static String OUTLET_RECORD_TYPE_ID  = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String CASE_TASK_TYPE_REC_TYPE_ID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String CASE_TYPE_REC_TYPE_ID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String CASE_RASK_SUBTYPE_REC_TYPE_ID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String QAULITY_RECORD_TYPE_ID  = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    /** 
* @description  Test KPI Calucation at Outlet
**/
    @isTest
    public static void testKPIFieldsCalcAtOutletLevel(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(geographyId);
        marketCycle.Start_Date__c = Date.today();
        marketCycle.End_Date__c = Date.Today().addDays(30);
        marketCycle.Geography__c = geographyId;
        insert marketCycle;
        
        List<Pick_Up_Options__c> pickUpList=new List<Pick_Up_Options__c>();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        pickUpList.add(pickupOption);
        
        String qualityReasonCodeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Reason Code').getRecordTypeId();
        Pick_Up_Options__c pickupQual=new Pick_Up_Options__c();
        pickupQual.Geography__c=geographyId;
        pickupQual.RecordTypeId=qualityReasonCodeId;
        pickupQual.Reason_Code_Name__c='PickupQuality[GB]';
        pickupQual.Type__c='Pending Reason Code';
        pickUpList.add(pickupQual);
        
        //156229 -> fix start
        Pick_Up_Options__c pickupQual1=new Pick_Up_Options__c();
        pickupQual1.Geography__c=geographyId;
        pickupQual1.RecordTypeId=qualityReasonCodeId;
        pickupQual1.Reason_Code_Name__c='PickQuality[GB]';
        pickupQual1.Type__c='Cancellation Reason Code';
        pickUpList.add(pickupQual1);
        insert pickUpList;
        //156229 -> fix end
        
        List<Account> lstAcc = new List<Account>();
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.Country__c = geographyId;
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        lstAcc.add(outlet1);
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet2.Name = 'Test Outlet 2';
        outlet2.Country__c = geographyId;
        outlet2.BillingStreet = 'Street 2';
        outlet2.BillingCity = 'Scotland';
        lstAcc.add(outlet2);
        insert lstAcc;
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = CASE_TASK_TYPE_REC_TYPE_ID;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = CASE_TYPE_REC_TYPE_ID;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = CASE_RASK_SUBTYPE_REC_TYPE_ID;
        insert caseConfigSubType;
        
        Case caseObj1 = new Case();
        caseObj1.Status = 'New';
        caseObj1.Origin = 'EDGE 365 Global';
        caseObj1.RecordTypeId = QAULITY_RECORD_TYPE_ID;
        caseObj1.AccountId = outlet1.Id;   
        caseObj1.Case_Type__c = caseConfigType.Id;
        caseObj1.Case_Sub_Type__c = caseConfigSubType.Id;
        
        insert caseObj1;
        
        Case caseObj2 = new Case();  
        caseObj2.Status = 'New';
        caseObj2.Origin = 'EDGE 365 Global';
        caseObj2.RecordTypeId = QAULITY_RECORD_TYPE_ID;
        caseObj2.AccountId = outlet2.Id; 
        caseObj2.Case_Type__c = caseConfigType.Id;
        caseObj2.Case_Sub_Type__c = caseConfigSubType.Id;
        Test.startTest();     
        insert caseObj2;
        
        
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj1.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.Country__c = geographyId;
        ct1.CreatedDate = System.today()-2;
        ct1.Reason_Code__c=pickupQual.Id;
        ctList.add(ct1);
        
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj1.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Achieved';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet1.Id;
        ct2.Country__c = geographyId;
        ct2.CreatedDate = System.today()-2;
        ct2.Reason_Code__c=pickupQual.Id;
        ctList.add(ct2);
        
        Case_Task__c ct3 = new Case_Task__c();
        ct3.Case__c = caseObj1.Id;
        ct3.Case_Task_Type__c = caseConfig.Id;
        ct3.Achievement_Status__c = 'Achieved';
        ct3.Actioned_Within_SLA__c = false;
        ct3.Account__c = outlet1.Id;
        ct3.Country__c = geographyId;
        ct3.CreatedDate = System.today()-2;
        ct3.Reason_Code__c=pickupQual.Id;
        ctList.add(ct3);
        
        Case_Task__c ct4 = new Case_Task__c();
        ct4.Case__c = caseObj1.Id;
        ct4.Case_Task_Type__c = caseConfig.Id;
        ct4.Achievement_Status__c = 'Not Achieved';
        ct4.Actioned_Within_SLA__c = true;
        ct4.Account__c = outlet1.Id;
        ct4.Country__c = geographyId;
        ct4.CreatedDate = System.today()-2;
        ct4.Reason_Code__c=pickupQual.Id;
        ctList.add(ct4);
        
        Case_Task__c ct5 = new Case_Task__c();
        ct5.Case__c = caseObj1.Id;
        ct5.Case_Task_Type__c = caseConfig.Id;
        ct5.Achievement_Status__c = 'Pending';
        ct5.Actioned_Within_SLA__c = false;
        ct5.Account__c = outlet1.Id;
        ct5.Country__c = geographyId;
        ct5.CreatedDate = System.today()-2;
        ct5.Reason_Code__c=pickupQual.Id;
        ctList.add(ct5);
        
        Case_Task__c ct6 = new Case_Task__c();
        ct6.Case__c = caseObj1.Id;
        ct6.Case_Task_Type__c = caseConfig.Id;
        ct6.Achievement_Status__c = 'Cancelled';
        ct6.Actioned_Within_SLA__c = false;
        ct6.Account__c = outlet1.Id;
        ct6.Country__c = geographyId;
        ct6.CreatedDate = System.today()-2;
        ct6.Reason_Code__c=pickupQual1.Id;//156229
        ctList.add(ct6);
        
        Case_Task__c ct7 = new Case_Task__c();
        ct7.Case__c = caseObj2.Id;
        ct7.Case_Task_Type__c = caseConfig.Id;
        ct7.Achievement_Status__c = 'Cancelled';
        ct7.Actioned_Within_SLA__c = false;
        ct7.Account__c = outlet2.Id;
        ct7.Country__c = geographyId;
        ct7.CreatedDate = System.today()-2;
        ct7.Reason_Code__c=pickupQual1.Id;//156229
        ctList.add(ct7);
        
        Database.insert(ctList);
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletLevelKPIResetBatch' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch Setting should not be null.');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();     
    }
}