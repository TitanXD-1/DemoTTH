/**********************************************************************
Name: EDGE_OpportunityGenerationBatch
=======================================================================
Req: 
User Story : ES20-6532
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE            DETAIL
1.0         Preyanka Ghosh      23/12/2019      Initial Development 
2.0         Kapil Baliyan       30/12/2019		Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
3.0         Shahbaz Khan        30/12/2020    	Updated start method to change scope query for ES20-9124
4.0         Anamika Shukla      15/02/2021    	Updated Outlet Execution Query to filter Outlet Execution records for which Latest Entry marked true(ES20-9277).
5.0         Joshraj Sen         26/10/2022    	Create Opportunities of Type WPA ES20-13395
6.0			Sudipta Nandy		07/08/2024	  	155540 -- Amend Source Criteria check for mapping Opportunity Templates during re-evaluation of Opportunities basis TRAX response
6.1			Sudipta Nandy		08/08/2024		Fixing SCA
***********************************************************************/
   /**
* @Name : EDGE_OpportunityGenerationBatch
* @description  This class is used to revalidate the opportunity template in opportunity
*/
public class EDGE_OpportunityGenerationBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = ''; 
    String countryCode;
    Id marketBatchJobId; //Update ES20-6594
    final static String sourceTrax = 'TRAX'; //155540
    
    /**
* @Name : Interface
* @description  This method is used to get the batch details
* @param batchSetting
*/
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /**
* @Name : start
* @description  This method is used to get the Outlet Execution Record 
* @param bc
* @return Database.QueryLocator
*/ 
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594 
        countryCode = batchSetting.Country_Code__c;
        //Boolean pendingForBatch= true;
        Set<String> setGeoCode = new Set<String>();
        
        List<Opportunity_Template__c> lstOpportunityTemplate = new List<Opportunity_Template__c>();
        Set<String> productSet = new Set<String>();
        Set<String> activationSet = new Set<String>(); 
        
        //Get the Code of Market,Hub, Cluster and Country
        setGeoCode.add(countryCode);
        for(Geography__c objGeo : [SELECT ID, Code__c, Parent_Geography__r.Code__c, Parent_Geography__r.Parent_Geography__r.Code__c, 
                                   Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c FROM Geography__c 
                                   WHERE Code__c =:countryCode])
        {
            if(String.isNotBlank(objGeo.Parent_Geography__r.Code__c)){
                setGeoCode.add(objGeo.Parent_Geography__r.Code__c);                
            } 
            if(String.isNotBlank(objGeo.Parent_Geography__r.Parent_Geography__r.Code__c)){
                setGeoCode.add(objGeo.Parent_Geography__r.Code__c);                
            }
            if(String.isNotBlank(objGeo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c)){
                setGeoCode.add(objGeo.Parent_Geography__r.Code__c);                
            }
        }
        if(Test.isRunningTest()){
            lstOpportunityTemplate = [SELECT Id, Action__c, Channel__c, Activation__c, Activation_Name__c,  Territory__c, Opportunity_Type__c,
                                      Cluster__c, Weight_Value__c,End_Date__c, Product__c, Sub_Segment__c, Segment__c,Weight_Type__c, Multiply_By_Prioritisation__c,Area_Region__c
                                      FROM Opportunity_Template__c WHERE CreatedDate = TODAY AND Cluster__r.Code__c IN :setGeoCode AND Opportunity_Type__c IN ('MPA','MAS','NPA','WPA')
                                      AND Source__c = :sourceTrax];//ES20-13395 Included the Option WPA //155540 Adding Source as Trax
        }
        else{
            lstOpportunityTemplate = [SELECT Id, Action__c, Channel__c, Activation__c, Activation_Name__c,  Territory__c, Opportunity_Type__c,
                                      Cluster__c, Weight_Value__c,End_Date__c, Product__c, Sub_Segment__c, Segment__c,Weight_Type__c, Multiply_By_Prioritisation__c,Area_Region__c
                                      FROM Opportunity_Template__c WHERE  CreatedDate = Yesterday AND Cluster__r.Code__c IN :setGeoCode AND Opportunity_Type__c IN ('MPA','MAS','NPA','WPA')
                                      AND Source__c = 'Trax'];   //ES20-13395 Included the Option WPA and Included CreatedDate=TODAY For Testing Purposes //155540 Adding Source as Trax
        }
        if(lstOpportunityTemplate != null && lstOpportunityTemplate.size()>0){
            for(Opportunity_Template__c oppTemplate : lstOpportunityTemplate){
                if(String.isNotBlank(oppTemplate.Activation_Name__c)){
                    activationSet.add(oppTemplate.Activation_Name__c);                    
                }   
                if(String.isNotBlank(oppTemplate.Product__c)){
                    productSet.add(oppTemplate.Product__c);                    
                }                
            }
        }  
        //Query String 
        //Update ES20-9277
        String queryString; 
        queryString = 'SELECT ID,Latest_Entry__c, Activation_Reference__c, Product__c, MAS__c, NPA__c, MPA__c,Distribution_TRAX__c, Outlet__c, Commentary__c'+ 
            +' FROM Outlet_Execution__c WHERE Outlet_Execution__c.Latest_Entry__c=true AND (Activation_Reference__c Like :activationSet OR Product__c IN :productSet) AND'+ 
            +' Outlet__r.Country__r.Code__c = :countryCode AND (MAS__c = \'No\' OR NPA__c = \'No\' OR MPA__c = \'No\' OR Distribution_TRAX__c = \'No\')'; //ES20-13395 Included the Option WPA
        
        System.debug(LoggingLevel.DEBUG,'queryString:::'+queryString);
        
        return Database.getQueryLocator(queryString);
    }
    
    /**
* @Name : execute
* @description  This method is used to revalidate the Opportunity Temp assigned to Opp
* @param bc
* @param scope
*/
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        System.debug(LoggingLevel.DEBUG,'scope:'+scope);
        
        
        if(scope != null && scope.size() > 0){
            Map<Id,SObject> newItems = new Map<Id,SObject>(scope);
            system.debug(LoggingLevel.DEBUG,'newItems '+newItems);
            EDGE_OutletExecutionTriggerHelper.createOpportunity(newItems, null, true);
            
        }
    }
    
    /**
* @Name : finish Update ES20-6594
* @description  This method is used to see if the batch has run successfully
* @param bc
*/ 
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OpportunityGenerationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest())//ES20-13395 Included The !Test.isRunningTest() Condition so that the Schedule Next Batch is not called by a test class method
        {
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); 
        }     
    }
}