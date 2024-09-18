/**
@name EDGE_UpdateTargetListMemberBatchTest
@description Test Class for EDGE_UpdateTargetListMemberBatch apex class
@history
VERSION     	AUTHOR           DATE           DETAIL
1.0         Monalisa Halder    05/04/2019 		ES20-11865
2.0         Saurav Prasad      05/08/2024     155306 : GB Opportunity Scoring: Generate Cycle Brief Opportunity in EDGE when template source is set to 'EDGE'
**/


@isTest
public class EDGE_UpdateTargetListMemberBatchTest{
    final static String QUALITYASSETRECORDTYPEID = asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String QUALITYRECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String CASETEMPLATERECORDTYPEID = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Template').getRecordTypeId();
    final static String DYNAMICTARGETRECORDTYPEID = Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Dynamic_Target_List').getRecordTypeId();
    @isTest
    public static void testDynamicTargetListCreateBatch(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateTargetListMemberBatch' AND Country_Code__c = 'AU' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'batchSetting is null');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //Second run
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testDynamicTargetListCreateBatchNegative(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateTargetListMemberBatch' AND Country_Code__c = 'AU' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'batchSetting is null');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        createOpportunity();
        //Second run
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');         
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
        qualityMgr.Available_Countries__c = 'AU';
        insert qualityMgr; 
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Name='Outlet 1 One';
        // outlet.Region__c =  pickupOptionReg.Id;
        outletListToInsert.add(outlet);             
        //insert outlet; 
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name='Two Outlets 2 Two';
        outlet1.BillingCity = 'Kolkata';    
        outletListToInsert.add(outlet1);
        //insert outlet1; 
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Three Outletz 3 Three';
        outlet1.BillingCity = 'Raipur';
       // insert outlet2;
        outletListToInsert.add(outlet2);
        
        insert outletListToInsert;
        
        Target_List__c targetLst1 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst1.recordTypeId = DYNAMICTARGETRECORDTYPEID;
        //insert targetLst1;
        tlListToInsert.add(targetLst1);
        
        Target_List__c targetLst2 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst2.recordTypeId = DYNAMICTARGETRECORDTYPEID;
        tlListToInsert.add(targetLst2);
        
        insert tlListToInsert;
        
        for(Integer i=0;i<outletListToInsert.size();i++){
            Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outletListToInsert[i].Id, targetLst1.Id);
            targetLstmem.Assignment_Status__c = i==0?'Waiting Removal':'Waiting Activation';
            tlmListToInsert.add(targetLstmem);
        }
        insert tlmListToInsert;
        
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(targetLst1.Country__c);
        insert survey;
        
        Activity_Target_List__c  atLst = EDGE_UtilityTestClass.getActivityTargetList(survey.Id,targetLst1.Id);
        activityTLInsertList.add(atLst);
       // insert atLst;
        
         List<Outlet_Survey__c> otSurveyInsert = new List<Outlet_Survey__c>();
        for(Integer i=0;i<outletListToInsert.size();i++){
            Outlet_Survey__c otSurvey = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outletListToInsert[i].Id);
            otSurveyInsert.add(otSurvey);
        }
        insert otSurveyInsert;
        //system.assertEquals(otSurvey.Survey__c,atLst.Survey__c);
        //system.assertEquals(otSurvey.Outlet__c,targetLstmem1.Outlet__c);
        
        Opportunity_Template__c  oppTemplate = createOpTemp(null);
        
        Activity_Target_List__c  atLst1 = new Activity_Target_List__c();
        atLst1.Target_List__c = targetLst1.Id;
        atLst1.Opportunity_Template__c = oppTemplate.Id;
        activityTLInsertList.add(atLst1);
        //insert atLst1;
        
        Master_Asset__c masterAsst = createMasterAsset(countryId);
        insert masterAsst;
        
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKAFF';
        asst.AccountId = outlet.Id;
        asst.Country__c = countryId;
        asst.Quantity = 1;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Offset_Day__c = 2;
        asst.Batch_Processed__c = true;
        asst.Asset_Removed__c = false;
        asst.Is_OffsetDay_Changed__c = false;
        asst.RecordTypeId = qualityAssetRecordTypeId;
        Insert asst;
        
        List<Case_Template__c> casetemplatelist = createQualityCaseConfig(countryId,outlet2,qualityMgr);
        
        
        activityTLInsertList.addall(createCaseTempActivity(targetLst1,casetemplatelist));
        
        Promotion_Master__c pm = createPromoMaster(countryId);
        
        activityTLInsertList.addall(createPromoActivity(targetLst1, pm));
        
        insert activityTLInsertList;
        
        
    }
    
    public static Opportunity_Template__c createOpTemp(Id outletId){
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        insert prod;        
        
        Id clusterId = [Select Id,Code__c from Geography__c where Code__c = 'AUCT'].Id;
        
        Opportunity_Template__c  oppTemplate = new Opportunity_Template__c();
        oppTemplate.Cluster__c = clusterId;
        //oppTemplate.Country__c = countryId;
        oppTemplate.Product__c = prod.Id;
        oppTemplate.Opportunity_Type__c = 'Cycle Brief';
        //155306
        oppTemplate.Source__c = 'EDGE';
        oppTemplate.Action__c='Test';
        oppTemplate.Closing_Method__c='Order';
        oppTemplate.Start_Date__c=Date.newInstance(2022,1,1);
        oppTemplate.Weight_Type__c='Always on Top';
        
        insert oppTemplate;
        
        return oppTemplate;
    }
    
    public static void createOpportunity(){
        
        Opportunity_Template__c oppTemplate = [SELECT Id, Opportunity_Type__c, Action__c, Start_Date__c, Product__c, Source__c FROM Opportunity_Template__c Limit 1];
        List<Opportunity> oppList = new List<Opportunity>();
        
        for(Account acc:[Select Id From Account]){
            Opportunity oppRec = new Opportunity();
            oppRec.Opportunity_Template__c = oppTemplate.Id;
            oppRec.product__c = oppTemplate.product__c;
            oppRec.AccountId = acc.Id;
            oppRec.Name = oppTemplate.Opportunity_Type__c + '-' + oppTemplate.Action__c;
            oppRec.Start_Date__c = oppTemplate.Start_Date__c;
            oppRec.CloseDate = oppTemplate.Start_Date__c.addMonths(12); 
            oppRec.Type = oppTemplate.Opportunity_Type__c;
            oppRec.StageName = 'Open';
            oppRec.Source__c = oppTemplate.Source__c;
            oppList.add(oppRec); 
        }
        Insert oppList;
        
    }
    
    public static Master_Asset__c createMasterAsset(String countryId){
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = countryId;
        masterAsst.Priority_Assets__c = true;
        masterAsst.Line_Cleaning_Asset__c = true;
        masterAsst.Active__c = true;
        return masterAsst;
    }
    
    public static Promotion_Master__c createPromoMaster(String countryId){
        String promoMasterRecTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Promotion_Master__c pm = new Promotion_Master__c();
        pm.Start_Date__c = system.today();
        pm.End_Date__c = System.today() +5;
        pm.Country__c = countryId;
        pm.name = 'Test Pm';
        pm.Description__c = 'testing';
        pm.RecordTypeId= promoMasterRecTypeId;
        Insert pm;
        return pm;
        
    }
    
    public static List<Activity_Target_List__c> createPromoActivity(Target_List__c targetLst1,Promotion_Master__c pm){
        List<Activity_Target_List__c> activityTLInsertList  = new List<Activity_Target_List__c>();
        String promATLRecTypeId = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        Activity_Target_List__c  atLst4 = new Activity_Target_List__c();
        atLst4.Target_List__c = targetLst1.Id;
        atLst4.Promotion_Master__c  = pm.Id;
        atLst4.Status__c = 'Waiting Activation';
        atLst4.RecordTypeId = promATLRecTypeId;
        activityTLInsertList.add(atLst4);
        return activityTLInsertList;
    }
    
    public static List<Activity_Target_List__c> createCaseTempActivity(Target_List__c targetLst1,List<Case_Template__c> casetemplatelist){
        List<Activity_Target_List__c> activityTLInsertList = new List<Activity_Target_List__c>();
            
        Activity_Target_List__c  atLst2 = new Activity_Target_List__c();
        atLst2.Target_List__c = targetLst1.Id;
        atLst2.Case_Template__c  = casetemplatelist[0].Id;
        atLst2.Status__c = 'Waiting Activation';
        atLst2.RecordTypeId = caseTemplateRecordTypeId;
        activityTLInsertList.add(atLst2);
        
        Activity_Target_List__c  atLst3 = new Activity_Target_List__c();
        atLst3.Target_List__c = targetLst1.Id;
        atLst3.Case_Template__c  = casetemplatelist[1].Id;
        atLst3.Status__c = 'Waiting Activation';
        atLst3.RecordTypeId = caseTemplateRecordTypeId;
        activityTLInsertList.add(atLst3);
        
        return activityTLInsertList;
    }
    
    public static List<Case_Template__c> createQualityCaseConfig(String countryId,Account outlet2,User qualityMgr){
        
        List<Quality_Case_Configuration__c> caseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [AU]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        caseConfigType.Active__c = true;
        caseConfigType.Country__c = countryId;
        caseConfigList.add(caseConfigType);
        
        String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Line Cleaning & Maintenance [AU]';
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
        
        List<Case_Template__c> casetemplatelist = new List<Case_Template__c>();
        Case_Template__c  caseTemplate = new Case_Template__c();
        caseTemplate.Case_Sub_Type__c = caseConfigSubType.Id;
        caseTemplate.Case_Task_Type__c = caseTaskConfig.Id;
        caseTemplate.Case_Type__c = caseConfigType.Id;
        caseTemplate.Country__c = countryId;
        //caseTemplate.Asset__c = asst.Id;
        caseTemplate.Task_Comment__c = 'Test Comment';
      //  caseTemplate.Product__c = prod.Id;
        caseTemplate.Quantity__c = 5 ;
        caseTemplate.Due_Date_Time__c = null;
        caseTemplate.Case_Notes__c = 'Test Comment';

        caseTemplate.Case_Task_Name__c = 'Test Name';
		casetemplatelist.add(caseTemplate);
        //insert caseTemplate;
        
         Case_Template__c  caseTemplate2 = new Case_Template__c();
        caseTemplate2.Case_Sub_Type__c = caseConfigSubType.Id;
        caseTemplate2.Case_Task_Type__c = caseTaskConfig.Id;
        caseTemplate2.Case_Type__c = caseConfigType.Id;
        caseTemplate2.Country__c = countryId;
       // caseTemplate2.Asset__c = asst.Id;
        caseTemplate2.Task_Comment__c = 'Test Comment';
      // caseTemplate2.Product__c = prod.Id;
        caseTemplate2.Quantity__c = 5 ;
        caseTemplate2.Due_Date_Time__c = Date.newInstance(2022,2,2);
        caseTemplate2.Case_Notes__c = 'Test Comment';
        caseTemplate2.End_Date__c = Date.newInstance(2022,2,1);
        casetemplatelist.add(caseTemplate2);
        
        Insert casetemplatelist;
        
         List<Case> caselist = new List<Case>();
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet2.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj.Case_Template__c = caseTemplate.Id;
        caselist.add(caseObj);
        
        
        Case caseObj2 = new Case();
        caseObj2.Status = 'New';
        caseObj2.Origin = 'EDGE 365 Global';
        caseObj2.RecordTypeId = qualityRecordTypeId;
        caseObj2.AccountId = outlet2.Id;
        caseObj2.Case_Type__c = caseConfigType.Id;
        caseObj2.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj2.Case_Template__c = caseTemplate2.Id;
        caselist.add(caseObj2);
        insert caselist;
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseTaskConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet2.Id;
        ct1.User_Assigned_To__c = qualityMgr.Id;
        Insert ct1;
        
        return casetemplatelist;
        
    }
}