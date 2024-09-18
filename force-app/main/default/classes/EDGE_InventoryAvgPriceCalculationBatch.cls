/********************************************************************************************
Class Name: EDGE_InventoryAvgPriceCalculationBatch

Author              Version       Date           Detail
Monalisa Halder      V1.0        18/09/2020     [ES20-8625]
Monalisa Halder      V2.0        13/05/2021     [ES20-10354]
*********************************************************************************************/
public class EDGE_InventoryAvgPriceCalculationBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
	Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    Date today = System.today();
	Date last_n_month = today.addMonths(-3);
    //ES20-10354
    //Map<String, Set<Outlet_Inventory__c>> outletInvSetPerOutletProdMap = new Map<String, Set<Outlet_Inventory__c>>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        Id outletRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();
        String querySt = 'SELECT Id FROM Account WHERE Country_Code__c  =:countryCode AND recordTypeId =:outletRecTypeId ';
        
        return Database.getQueryLocator(querySt);
    }
	//execute method
    public void execute(Database.BatchableContext bc, List<Account> outlets){ //List<Outlet_Inventory__c> listOfOutletInventories
        List<Outlet_Inventory__c> outletInvAvgPriceNullUpdateList = new List<Outlet_Inventory__c>();
        Map<String, Set<Outlet_Inventory__c>> outletInventoryMap = new Map<String, Set<Outlet_Inventory__c>>();
        Set<id> accountIdSet = new Set<Id>();
        //ES20-10354
        Map<String, Set<Outlet_Inventory__c>> outletInvSetPerOutletProdMap = new Map<String, Set<Outlet_Inventory__c>>();
        
        for(Account outlet : outlets){
            accountIdSet.add(outlet.Id);
        }
        String queryString = 'SELECT Id,Account__c,Call__c,Date__c,Price__c,Product__c,Stock_Available__c,Type__c,Unique_Id__c '+
            'FROM Outlet_Inventory__c WHERE Type__c= \'Inventory\' ';
        
        if(!Test.isRunningTest()){
            queryString +=  'AND (Date__c >=:last_n_month and Date__c<= :today) AND Account__c IN :accountIdSet '; 
        }
        queryString += 'ORDER By Account__c DESC,Product__c DESC,Date__c DESC';
       
        try{
            for(Outlet_Inventory__c outletInven :Database.query(queryString)){ //listOfOutletInventories
                String str = outletInven.Account__c + '_' + outletInven.Product__c;
                if(!outletInventoryMap.containsKey(str)){
                    outletInventoryMap.put(str, new Set<Outlet_Inventory__c>{outletInven});
                }else{
                    outletInventoryMap.get(str).add(outletInven);
                }
                
            }
            for(String outletProd : outletInventoryMap.keySet()){
                EDGE_OutletInventoryTriggerHelper.limitOutletInventoryinMap(outletProd, outletInventoryMap, outletInvSetPerOutletProdMap);
            }
            
            //LastModifiedDate check used so that it does not modify the records which has been modified today already
            String query = 'Select Id,Price__c,Type__c FROM Outlet_Inventory__c WHERE Type__c = \'Average\' AND Account__c in :accountIdSet';
            if(!Test.isRunningTest()){
                query += ' AND LastModifiedDate < :today';
            }
            List<Outlet_Inventory__c> outletInvAvgPriceList = Database.query(query);
            //ES20-10354
            if(outletInvAvgPriceList != null && outletInvAvgPriceList.size()>0){
                for(Outlet_Inventory__c otInvenRec :outletInvAvgPriceList){
                    otInvenRec.Price__c = 0.0;
                    outletInvAvgPriceNullUpdateList.add(otInvenRec);
                }    
            }
            
            if(outletInvAvgPriceNullUpdateList != null && outletInvAvgPriceNullUpdateList.size()>0){
                database.update(outletInvAvgPriceNullUpdateList,true);
                
             }
            
            EDGE_OutletInventoryTriggerHelper.createAveragePriceOutletInventory(outletInvSetPerOutletProdMap); 
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(99);
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_InventoryAvgPriceCalculationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
         System.debug('@@heapSize103 = ' +limits.getHeapSize());
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
     	  EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError); 
        }
        
    }

}