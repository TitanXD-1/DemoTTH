/**

* @Description: EDGE_UpdateATLForCaseTempTest

* @Purpose : Test class for EDGE_UpdateATLForCaseTemp Batch Class 

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*   1.0       Anamika Shukla        15/01/2022      	ES20-11726
*	2.0		  Subhodeep Sarkar		31/01/2022			ES20-11757
*   3.0       Swaraj Samanta        05/09/2022          ES20-13284
*   4.0       Joshraj Sen           08/04/2024          152305
*/



@isTest
public class EDGE_UpdateATLForCaseTempTest {
    
    public static Map <String,Schema.RecordTypeInfo> mapActivityTargetList = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName();  
    public static Id caseTemplRecTypeId = mapActivityTargetList.get('Case Template').getRecordTypeId();
    static String qualityCaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    static String qualityCaseConfigRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    static String caseTaskTypeRecordId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseSubTypeRecordId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    
    
    @isTest
    public static void executeBatchTest(){  
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateATLForCaseTemp' AND Country_Code__c = 'GB' 
                                                  LIMIT 1];
        
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        //System.debug('Condition 1 '+Limits.getQueries());
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'On Bronze[GB]';
        insert pickupOption;        
        //System.debug('Condition 2 '+Limits.getQueries());
        List<Account> outlets=new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlets.add(outlet); 
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet1.BillingCity = 'Queensland'; 
        outlets.add(outlet1); 
        insert outlets;
        //System.debug('Condition 3 '+Limits.getQueries());
        Target_List__c targetLst1 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst1.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        insert targetLst1;
        //System.debug('Condition 4 '+Limits.getQueries());
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem.Assignment_Status__c = 'Waiting Activation';
        insert targetLstmem; 
        //System.debug('Condition 5 '+Limits.getQueries());
        Quality_Case_Configuration__c caseType = new Quality_Case_Configuration__c();
        caseType.Name ='Test Case Type';
        caseType.RecordTypeId = qualityCaseConfigRecTypeId;
        caseType.Active__c= True;
        caseType.Country__c = countryId;
        insert caseType;
        //System.debug('Condition 6 '+Limits.getQueries());
        Test.startTest(); 
        
        /*Product__c prod = EDGE_UtilityTestClass.getProd();
insert prod;   
System.debug('Condition 6 '+Limits.getQueries());*/
        
        
        Quality_Case_Configuration__c caseSubType = new Quality_Case_Configuration__c();
        caseSubType.Name ='Test Case Sub Type';
        caseSubType.RecordTypeId = caseSubTypeRecordId;
        caseSubType.Active__c= True;
        caseSubType.Case_Type__c=caseType.Id;
        caseSubType.Country__c = countryId;
        insert caseSubType;
        //System.debug('Condition 7 '+Limits.getQueries());
        Quality_Case_Configuration__c caseTaskType = new Quality_Case_Configuration__c();
        caseTaskType.Name ='Test Case Task Type';
        caseTaskType.RecordTypeId = caseTaskTypeRecordId;
        caseTaskType.Active__c= True;
        caseTaskType.Case_Type__c=caseType.Id;
        caseTaskType.Case_Sub_Type__c=caseSubType.Id;
        caseTaskType.Country__c = countryId;
        insert caseTaskType;
        //System.debug('Condition 8 '+Limits.getQueries());
        
        
        Case_Template__c  caseTemplate = new Case_Template__c();
        caseTemplate.Country__c = countryId;
        // caseTemplate.Product__c = prod.Id;
        caseTemplate.Case_Sub_Type__c=caseSubType.Id;
        caseTemplate.Case_Task_Type__c=caseTaskType.id;
        caseTemplate.Case_Type__c=caseType.id;
        caseTemplate.Quantity__c=1;
        caseTemplate.End_Date__c=system.today().addDays(5);
        insert caseTemplate;
        //System.debug('Condition 9 '+Limits.getQueries());
        List<Activity_Target_List__c> actLists=new List<Activity_Target_List__c>();
        Activity_Target_List__c  atLst1 = new Activity_Target_List__c();
        atLst1.RecordTypeId=caseTemplRecTypeId;
        atLst1.Target_List__c = targetLst1.Id;
        atLst1.Case_Template__c = caseTemplate.Id;
        atLst1.Status__c = 'Waiting Activation';
        actLists.add(atLst1);
        
        
        Activity_Target_List__c  atLst2 = new Activity_Target_List__c();
        atLst2.RecordTypeId=caseTemplRecTypeId;
        atLst2.Target_List__c = targetLst1.Id;
        atLst2.Case_Template__c = caseTemplate.Id;
        atLst2.Status__c = 'Waiting Activation';
        actLists.add(atLst2);
        insert actLists;
        //System.debug('Condition 10 '+Limits.getQueries());
        system.assertNotEquals(atLst2.Id, '','');
        /* try{
Activity_Target_List__c atl =new Activity_Target_List__c(Target_List__c=targetLst1.Id, Case_Template__c = caseTemplate.Id);
insert atl;
system.assertNotEquals(atl.Id, '','');            

} catch (Exception ex){

}*/
        
        
        
        
        Target_List_Member__c  targetLstmem2 = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem2.Assignment_Status__c = 'Active';
        insert targetLstmem2;  
        errorBatchCode();
        
        
        Test.stopTest();
    }
    
    static void errorBatchCode() {
        boolean hasError = false;
        try{
            Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                      from Market_Batch_Setting__mdt 
                                                      where Batch_Class__c = 'EDGE_UpdateATLForCaseTemp'
                                                      and Country_Code__c ='GB'];
            system.assert(batchSetting.Id != null,'Batch is Added');
            String className = batchSetting.Batch_Class__c;         
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c=-1));
            
            if(Test.isRunningTest()){
                //Schedule Next Batch from Batch Utility Class
                EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
            }
        }
        catch(Exception e){
            
            System.debug(LoggingLevel.Debug,'Error'+e.getMessage());
        }
        
    }
    
    /**
* @Description: Test Class for Cancel Case Task part of EDGE_UpdateATLForCaseTemp
*/
    
    @isTest
    public static void cTRemovalCreateBatch(){
        
        CTRemovalcreateData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_CancelCaseCTCaseTempBatch' AND Country_Code__c = 'GB' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    public static void cTRemovalcreateData(){
        
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
        caseTemplate.End_Date__c = system.today().addDays(2) ;
        insert caseTemplate;
        
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityCaseRecordTypeId;
        caseObj.AccountId = outlet2.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj.Case_Template__c = caseTemplate.Id;
        insert caseObj;
        
        Activity_Target_List__c  atLst2 = new Activity_Target_List__c();
        atLst2.Target_List__c = targetLst1.Id;
        atLst2.Case_Template__c  = caseTemplate.Id;
        atLst2.Status__c = 'Waiting Removal';
        atLst2.RecordTypeId = caseTemplRecTypeId;
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