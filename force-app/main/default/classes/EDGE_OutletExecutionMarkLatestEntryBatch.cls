/********************************************************************************************
Class Name: EDGE_OutletExecutionMarkLatestEntryBatch 

Author              Version       Date           Detail
Monalisa Halder     V1.0          08/02/2021     [ES20-9278]
Aparajita 1         V2.0          25/02/2021     [ES20-9351]
Monalisa Halder     V3.0          19/04/2021     [ES20-10192]
Rajarshi Lahiri     V4.0          31/08/2022     [ES20-13231]
Joshraj Sen         V5.0          08/11/2022     [ES20-13508]
*********************************************************************************************/
public class EDGE_OutletExecutionMarkLatestEntryBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    final static String outletExecutionProductRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
    final static String outletExecutionActivationRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    Map<String,Outlet_Execution__c> outletExecutionFirstRecordMap = new Map<String,Outlet_Execution__c>(); 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        countryCode = batchSetting.Country_Code__c;
        Boolean latesttrue = true;
        
        String queryString = 'SELECT Id,Outlet__c,Outlet__r.Latest_Date_Of_Execution_Activation__c,Outlet__r.Latest_Date_Of_Execution_Product__c,Product__c,Date_of_Execution__c, Latest_Entry__c, RecordTypeId, Activation_Reference__c FROM Outlet_Execution__c  WHERE Outlet__r.Country__r.Code__c =:countryCode' +
            + ' AND Date_of_Execution__c != null AND Latest_Entry__c =: latesttrue ORDER BY Date_of_Execution__c DESC, Outlet__c DESC';//ES20-13231
        
        System.debug('queryString = '+ queryString);
        return Database.getQueryLocator(queryString);
        
    }
    public void execute(Database.BatchableContext bc, List<Outlet_Execution__c> outletExecutionList){ 
        Map<String,List<Outlet_Execution__c>> outletExecutionMPAMap = new Map<String,List<Outlet_Execution__c>>();
        Map<String,List<Outlet_Execution__c>> outletExecutionMASMap = new Map<String,List<Outlet_Execution__c>>();
        List<Outlet_Execution__c> outletExecutionUpdateList = new List<Outlet_Execution__c>(); 
        List<Outlet_Execution__c> outletExecutionTrueValuesList = new List<Outlet_Execution__c>(); 
        set<id> outletSetId = new set<id>();
        String key ;
        
        try{
            if(outletExecutionList != null && outletExecutionList.size()>0)
            {
                for(Outlet_Execution__c oexecRec :outletExecutionList)
                {
                    if(oexecRec.Outlet__c != null && oexecRec.Product__c != null 
                       && oexecRec.RecordTypeId == outletExecutionProductRecordTypeId)
                    {
                        if(oexecRec.Date_Of_Execution__c < oexecRec.Outlet__r.Latest_Date_Of_Execution_Product__c)
                        {
                            oexecRec.Latest_Entry__c = false;
                            outletExecutionUpdateList.add(oexecRec);                      
                            outletSetId.add(oexecRec.Outlet__c);//add outlet Id if those outlet execution where Latest Entry is False
                        } else{
                            outletExecutionTrueValuesList.add(oexecRec);//OE records having Latest Entry as True
                            
                        }
                    } 
                    
                    else if(oexecRec.Outlet__c != null && oexecRec.Activation_Reference__c != null 
                            && oexecRec.RecordTypeId == outletExecutionActivationRecordTypeId)
                    {
                        
                        if(oexecRec.Date_Of_Execution__c < oexecRec.Outlet__r.Latest_Date_Of_Execution_Activation__c)
                        {
                            oexecRec.Latest_Entry__c = false;
                            outletExecutionUpdateList.add(oexecRec);                      
                            outletSetId.add(oexecRec.Outlet__c);//add outlet Id if those outlet execution where Latest Entry is False
                        } else{
                            outletExecutionTrueValuesList.add(oexecRec);//OE records having Latest Entry as True
                            
                        }
                    }
                    
                }
            }
            
                       
            if(outletExecutionUpdateList != null && outletExecutionUpdateList.size()>0 && Schema.sObjectType.Outlet_Execution__c.isUpdateable())
            {
                Database.Update(outletExecutionUpdateList,true); 
            }
            
            // call outlet execution trigger helper
            EDGE_OutletExecutionTriggerHelper.expireOpportunity(outletExecutionTrueValuesList, outletSetId  );
            
            if(outletExecutionUpdateList != null && outletExecutionUpdateList.size()>0 && Schema.sObjectType.Outlet_Execution__c.isUpdateable())
            {
                Database.Delete(outletExecutionUpdateList,true); 
            }
            
        }
        
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
    }
    

    //finish method
    public void finish(Database.BatchableContext bc){        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletExecutionMarkLatestEntryBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
}