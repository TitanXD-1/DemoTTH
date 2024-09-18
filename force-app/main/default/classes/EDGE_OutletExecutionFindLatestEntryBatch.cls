/********************************************************************************************
Class Name: EDGE_OutletExecutionFindLatestEntryBatch 

Author              Version       Date           Detail
Sandip Ghosh        V1.0          08/02/2021     ES20-13432
*********************************************************************************************/
public class EDGE_OutletExecutionFindLatestEntryBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    final static String OUTLETEXECUTIONPRODUCTRECORDTYPEID = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
    final static String OUTLETEXECUTIONACTIVATIONRECORDTYPEID = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    Map<String,Outlet_Execution__c> outletExecutionFirstRecordMap = new Map<String,Outlet_Execution__c>(); 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Needs to be uncommented
        countryCode = batchSetting.Country_Code__c;  //Needs to be uncommented
        // this needs to be deleted once above two line are commented
       // Boolean latesttrue = true;
        
        String queryString = 'SELECT Id,Outlet__c,Product__c,Date_of_Execution__c, Latest_Entry__c,'
            +' RecordTypeId, Activation_Reference__c FROM Outlet_Execution__c  WHERE Outlet__r.Country__r.Code__c = :countryCode'
            +' AND Date_of_Execution__c != null AND (CreatedDate = YESTERDAY OR LastModifiedDate = YESTERDAY) ORDER BY Outlet__c, RecordTypeId, Date_of_Execution__c DESC';
        
        System.debug(LoggingLevel.Debug,'queryString = '+ queryString);
        EDGE_UtilityClass.printGovLimits(35);
        return Database.getQueryLocator(queryString);
        
    }
    public void execute(Database.BatchableContext bc, List<Outlet_Execution__c> outletExecutionList){ 
        
       // List<Account> outlets = new List<Account>();
        Set<Id> outletWithProduct = new Set<Id>();
        Set<Id> outletWithActivation = new Set<Id>();
        Map<Id,Account> outletMap = new Map<Id,Account>();
        Set<Id> outletIds = new Set<Id>();
        
        try{
            if(outletExecutionList != null && outletExecutionList.size()>0){
                
                for(Outlet_Execution__c oexecRec : outletExecutionList){
                	outletIds.add(oexecRec.Outlet__c);    
                }
                
                Map<Id, Account> outletMapFromDB = new Map<Id, Account>([SELECT Id, Updated_Product_Date_of_Execution__c,
                                                                  Updated_Activation_Date_of_Execution__c
                                                                  FROM Account
                                                                  where Id in :outletIds]);
                
                for(Outlet_Execution__c oexecRec : outletExecutionList){
                    Id outletId = oexecRec.Outlet__c;
                    if(outletId != null && !outletWithProduct.contains(outletId)
                       && outletMapFromDB.get(outletId).Updated_Product_Date_of_Execution__c != System.today()
                       && oexecRec.Product__c != null 
                       && oexecRec.RecordTypeId == OUTLETEXECUTIONPRODUCTRECORDTYPEID)
                    {
                        
                        Account outletRec = null;
                        updateAccountWithOE('Product', outletId, outletRec, outletMap, oexecRec, outletWithProduct, null);
                        
                    }
                    
                    if(outletId != null && !outletWithActivation.contains(outletId) 
                       && outletMapFromDB.get(outletId).Updated_Activation_Date_of_Execution__c != System.today()
                       && oexecRec.Activation_Reference__c != null 
                       && oexecRec.RecordTypeId == outletExecutionActivationRecordTypeId)
                    {
                        Account outletRec = null;
                        updateAccountWithOE('Activation', outletId, outletRec, outletMap, oexecRec, null,outletWithActivation);
                        
                    }
                }
            }
            
            if(outletMap != null && outletMap.size()>0 && Schema.sObjectType.Account.isUpdateable()){
                Database.update(outletMap.values());
            }        
            
        }
        
        catch(Exception batchException){
            System.debug(LoggingLevel.Debug,'Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug(LoggingLevel.Debug,'StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
        EDGE_UtilityClass.printGovLimits(80);
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){  
        EDGE_UtilityClass.printGovLimits(84);
        //Needs to be uncommented - the entire block from 107 - 127
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
    
    private void updateAccountWithOE(String oetype, Id outletId, Account outletRec, Map<Id,Account> outletMap, 
                                     Outlet_Execution__c oexecRec ,Set<Id> outletWithProduct,
                                     Set<Id> outletWithActivation)
    {
        
        
        if(!outletMap.containsKey(outletId)){
            
            if(oetype =='Product'){
                outletRec = new Account(Id = outletId,
                                        Latest_Date_Of_Execution_Product__c = oexecRec.Date_of_Execution__c,
                                        Updated_Product_Date_of_Execution__c = System.today()); 
            }
            if(oetype =='Activation'){
                outletRec = new Account(Id = outletId,
                                        Latest_Date_Of_Execution_Activation__c	= oexecRec.Date_of_Execution__c,
                                        Updated_Activation_Date_of_Execution__c = System.today()); 
            }
            
        }
        else{
            outletRec = outletMap.get(outletId);
            if(oetype =='Product'){
                outletRec.Latest_Date_Of_Execution_Product__c = oexecRec.Date_of_Execution__c;
                outletRec.Updated_Product_Date_of_Execution__c = System.today();
            }
            if(oetype =='Activation'){
                outletRec.Latest_Date_Of_Execution_Activation__c = oexecRec.Date_of_Execution__c;
                outletRec.Updated_Activation_Date_of_Execution__c = System.today();
            }
            
        }
        if(outletRec != null){
            outletMap.put(outletId, outletRec);
            if(oetype =='Product'){
                outletWithProduct.add(outletId);
            }
            if(oetype =='Activation'){
                outletWithActivation.add(outletId);
            }
        }
    }
    
}