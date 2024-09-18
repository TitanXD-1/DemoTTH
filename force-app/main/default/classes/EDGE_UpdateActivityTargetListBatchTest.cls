@isTest
public class EDGE_UpdateActivityTargetListBatchTest {
    
    public static Map <String,Schema.RecordTypeInfo> mapActivityTargetList =    Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id surveyRecTypeId = mapActivityTargetList.get('Survey').getRecordTypeId();        
    public static Id oppTemplRecTypeId = mapActivityTargetList.get('Opportunity Template').getRecordTypeId();
    
    
    @isTest
    public static void executeBatchTest(){
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateActivityTargetListBatch' AND Country_Code__c = 'AU' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null);
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,2);
        
        Test.stopTest();
        
    }
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'GOLD[AU]';
        insert pickupOption;        
        
        List<Account> accList=new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        accList.add(outlet); 
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet1.BillingCity = 'Kolkata';      
        accList.add(outlet1); 
        insert accList;
        Target_List__c targetLst1 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst1.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        insert targetLst1;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem.Assignment_Status__c = 'Waiting Activation';
        insert targetLstmem; 
        
        Target_List_Member__c  targetLstmem1 = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst1.Id);
        targetLstmem1.Assignment_Status__c = 'Waiting Removal';
        insert targetLstmem1;    
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(targetLst1.Country__c);
        insert survey;
        
        Activity_Target_List__c  atLst = EDGE_UtilityTestClass.getActivityTargetList(survey.Id,targetLst1.Id);
        insert atLst;
        
        Outlet_Survey__c otSurvey = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        insert otSurvey;

        Product__c prod = EDGE_UtilityTestClass.getProd();
        insert prod;        
        
        Id clusterId = [Select Id,Code__c from Geography__c where Code__c = 'AUCT'].Id;
        
        List<Opportunity_Template__c> oppTemp= new List<Opportunity_Template__c>();
        Opportunity_Template__c  oppTemplate = new Opportunity_Template__c();
        oppTemplate.Cluster__c = clusterId;
        //oppTemplate.Country__c = countryId;
        oppTemplate.Product__c = prod.Id;
        oppTemplate.Opportunity_Type__c = 'Cycle Brief';
        oppTemplate.Action__c='Test';
        oppTemplate.Closing_Method__c='Order';
        oppTemplate.Start_Date__c=system.today();
        oppTemplate.Weight_Type__c='Always on Top';
        oppTemp.add(oppTemplate);
        
        Opportunity_Template__c  oppTemplate2 = new Opportunity_Template__c();
        oppTemplate2.Cluster__c = clusterId;
        //oppTemplate.Country__c = countryId;
        oppTemplate2.Product__c = prod.Id;
        oppTemplate2.Opportunity_Type__c = 'Cycle Brief';
        oppTemplate2.Action__c='Test';
        oppTemplate2.Closing_Method__c='Order';
        oppTemplate2.Start_Date__c=system.today();
        oppTemplate2.Weight_Type__c='Always on Top';
        oppTemp.add(oppTemplate2);
        insert oppTemp;
        
        Activity_Target_List__c  atLst1 = new Activity_Target_List__c();
        atLst1.Target_List__c = targetLst1.Id;
        atLst1.Opportunity_Template__c = oppTemplate.Id;
        atLst1.Status__c = 'Waiting Activation';
        insert atLst1;
        
        Target_List_Member__c  targetLstmem2 = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem2.Assignment_Status__c = 'Active';
        insert targetLstmem2;       
        
        
        Activity_Target_List__c  atLst2 = new Activity_Target_List__c();
        atLst2.Target_List__c = targetLst1.Id;
        atLst2.Opportunity_Template__c=oppTemplate2.Id;
        atLst2.Status__c = 'Waiting Removal';
        insert atLst2 ;
        
        Opportunity opp=EDGE_UtilityTestClass.getOpportunity(outlet1.Id);
        opp.Type='Cycle Brief';
        opp.StageName='Open';
        opp.Opportunity_Template__c=oppTemplate2.Id;
        insert opp;
                
    }
    /*
    @isTest
    public static void testQueueable(){

        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'GOLD[AU]';
        insert pickupOption;        
        
        List<Account> accList=new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        accList.add(outlet); 
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet1.BillingCity = 'Kolkata';      
        accList.add(outlet1); 
        insert accList;
        
        Opportunity opp=EDGE_UtilityTestClass.getOpportunity(outlet1.Id);
        insert opp;
        Map<String,List<Opportunity>> atlMap=new Map<String,List<Opportunity>>();
        atlMap.put('Deletion Queued',new List<Opportunity>{opp});
        System.enqueueJob(new EDGE_OppInsDelQueueable(atlMap));
    }
    
    **/
}