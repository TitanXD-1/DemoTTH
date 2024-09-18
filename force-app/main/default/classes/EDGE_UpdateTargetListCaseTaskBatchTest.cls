/**
@name EDGE_UpdateTargetListCaseTaskBatchTest
@description Test Class for EDGE_UpdateTargetListCaseTaskBatch apex class
@history
VERSION     	AUTHOR           DATE           DETAIL
1.0         	Prasanth T    18/01/2022 		ES20-11866
**/


@isTest
public class EDGE_UpdateTargetListCaseTaskBatchTest{
    final static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String caseTemplateRecordTypeId = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Template').getRecordTypeId();
    @isTest
    public static void testDynamicTargetListCreateBatch(){
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateTargetListCaseTaskBatch' AND Country_Code__c = 'GB' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null);
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');         
        List<Account> outletListToInsert = new List<Account>();
        List<Target_List__c> tlListToInsert = new List<Target_List__c>();
        List<Target_List_Member__c> tlmListToInsert = new List<Target_List_Member__c>();
        List<Activity_Target_List__c> activityTLInsertList = new List<Activity_Target_List__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;        
        
        /* Pick_Up_Options__c pickupOptionReg = EDGE_UtilityTestClass.getPickUpOption(countryId,'Region');
insert pickupOptionReg; */
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        insert qualityMgr; 
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Name='Outlet 1 One';
        // outlet.Region__c =  pickupOptionReg.Id;
        //outletListToInsert.add(outlet);             
        insert outlet; 
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name='Two Outlets 2 Two';
        outlet1.BillingCity = 'Kolkata';    
        //outletListToInsert.add(outlet1);
        insert outlet1; 
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Three Outletz 3 Three';
        outlet1.BillingCity = 'Raipur';
        insert outlet2;
        //outletListToInsert.add(outlet2);
        
        insert outletListToInsert;
        
        Target_List__c targetLst1 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst1.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        //insert targetLst1;
        tlListToInsert.add(targetLst1);
        
        Target_List__c targetLst2 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst2.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        tlListToInsert.add(targetLst2);
        
        insert tlListToInsert;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem.Assignment_Status__c = 'Waiting Activation';
        tlmListToInsert.add(targetLstmem);
        //insert targetLstmem; 
        
        Target_List_Member__c  targetLstmem1 = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst1.Id);
        targetLstmem1.Assignment_Status__c = 'Waiting Removal';
        targetLstmem1.Outlet__c = outlet2.Id;
        tlmListToInsert.add(targetLstmem1);
        //insert targetLstmem1;
        
        Target_List_Member__c  targetLstmem2 = EDGE_UtilityTestClass.getTargetMemList(outlet2.Id, targetLst1.Id);
        targetLstmem2.Assignment_Status__c = 'Waiting Removal';
        tlmListToInsert.add(targetLstmem2);
        insert tlmListToInsert;
       
        
        List<Quality_Case_Configuration__c> caseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [GB]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        caseConfigType.Active__c = true;
        caseConfigType.Country__c = countryId;
        caseConfigList.add(caseConfigType);
        
        String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Line Cleaning & Maintenance [GB]';
        caseConfigSubType.Case_Type__c = caseConfigType.Id;
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        caseConfigSubType.Active__c = true;
        caseConfigSubType.Country__c = countryId;
        caseConfigList.add(caseConfigSubType);
        
        String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
        Quality_Case_Configuration__c caseTaskConfig = new Quality_Case_Configuration__c();
        caseTaskConfig.Name = 'Clean Lines';
        caseTaskConfig.Description__c = 'Test Case Configuration Record';
        caseTaskConfig.RecordTypeId = caseTaskTypeRecTypeId;
        caseTaskConfig.Active__c = true;
        caseTaskConfig.Country__c = countryId;
        caseConfigList.add(caseTaskConfig);
        Insert caseConfigList;
        
        Case_Template__c  caseTemplate = new Case_Template__c();
        caseTemplate.Case_Sub_Type__c = caseConfigSubType.Id;
        caseTemplate.Case_Task_Type__c = caseTaskConfig.Id;
        caseTemplate.Case_Type__c = caseConfigType.Id;
        caseTemplate.Country__c = countryId;
        //caseTemplate.Asset__c = asst.Id;
        caseTemplate.Task_Comment__c = 'Test Comment';
      //  caseTemplate.Product__c = prod.Id;
        caseTemplate.Quantity__c = 5 ;
        insert caseTemplate;
        
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet2.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj.Case_Template__c = caseTemplate.Id;
        insert caseObj;
        
        Activity_Target_List__c  atLst2 = new Activity_Target_List__c();
        atLst2.Target_List__c = targetLst1.Id;
        atLst2.Case_Template__c  = caseTemplate.Id;
        atLst2.Status__c = 'Waiting Activation';
        atLst2.RecordTypeId = caseTemplateRecordTypeId;
        activityTLInsertList.add(atLst2);
        insert activityTLInsertList;
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseTaskConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet2.Id;
        ct1.User_Assigned_To__c = qualityMgr.Id;
        Insert ct1;
    }
}