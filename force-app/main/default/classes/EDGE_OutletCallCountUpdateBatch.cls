/********************************************************************************************
Class Name: EDGE_OutletCallCountUpdateBatch

Author           Version      Date           Detail
Sandip Ghosh      V1.0       15/09/2020     [ES20-8500]
Monalisa Halder   V2.0      25/03/2021     [ES20-10004]
*********************************************************************************************/
public class EDGE_OutletCallCountUpdateBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    String completedStatus = 'Completed';
    Date startdate;
    Date enddate;
  
    // this will retain the calls if the total no. of calls per outlet is not matching in a batch
    Map<Id, Set<Call__c>> outletIdToCallsRetained = new Map<Id, Set<Call__c>>();
    Map<Id,Integer> virtualCallsCountMap = new Map<Id,Integer>(); 
    Map<Id,Integer> telephoneCallsCountMap = new Map<Id,Integer>();
    Map<Id,Integer> physicalCallsCountMap = new Map<Id,Integer>(); 
    
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //EDGE_UtilityClass.printGovLimits(22);
        Integer currentMonth  = Date.Today().Month();
        
        if(currentMonth <= 6){
            startdate = Date.newinstance(system.today().year()-1, 7, 1);
            enddate = Date.newinstance(system.today().year(), 6, 30);
        }else{
            startdate = Date.newinstance(system.today().year(), 7, 1);
            enddate = Date.newinstance(system.today().year() +1, 6, 30);
        }
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        boolean isOperatorTrue = TRUE;     
        String queryString = 'SELECT Id, Account__c,Account__r.CreatedDate,Account__r.Operator__c,Type_of_Call__r.Global_Equivalent_Call_Type__c '+
                              'FROM Call__c where Type_of_Call__r.Global_Equivalent_Call_Type__c in (\'Telephone\',\'Virtual\',\'Physical\') '+
                              'AND Account__r.Country__r.Code__c =:countryCode AND Status__c = :completedStatus '+
                              'AND(End_Date__c <= :enddate AND End_Date__c >= :startdate) '+
                              'AND Account__r.Operator__c !=null ORDER by Account__r.CreatedDate DESC';
        System.debug('queryString = '+ queryString);
		return Database.getQueryLocator(queryString);
    
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Call__c> listOfCalls){ 
        
        Map<Id, Integer> outletIdToCallsCountMap = new Map<Id, Integer>();
        Map<Id, Set<Call__c>> callsToProcessMap = new Map<Id, Set<Call__c>>();
        try{
            for(Call__c call : listOfCalls){
                Id outletId = call.Account__c;
                
                if(!outletIdToCallsCountMap.containsKey(outletId)){
                    //Initializing the map for every outlet id 
                    outletIdToCallsCountMap.put(outletId, 0);
                } 
                // putting the calls in the global map
                if(outletIdToCallsRetained.containsKey(outletId)) {
                    Set<Call__c> callsSet = outletIdToCallsRetained.get(outletId);
                    callsSet.add(call);
                    outletIdToCallsRetained.put(outletId, callsSet);
                } else {
                    outletIdToCallsRetained.put(outletId, new Set<Call__c> { call });
                }
            }
            
            
            if(outletIdToCallsCountMap.size() > 0 && Schema.sObjectType.Call__c.isAccessible()){
                Id accountId; 
                for(AggregateResult agResult : [Select Count(Id) noOfCalls, Account__r.Operator__c, Account__c
                                                from Call__c where Account__c in :outletIdToCallsCountMap.keySet() 
                                                AND Status__c = :completedStatus 
                                                AND Type_of_Call__r.Global_Equivalent_Call_Type__c IN  ('Telephone','Virtual','Physical')
                                                AND(End_Date__c <= :enddate AND End_Date__c >= :startdate)
                                                group by Account__c ,Account__r.Operator__c ])
                {
                    accountId = (Id)agResult.get('Account__c');
                    outletIdToCallsCountMap.put((Id)agResult.get('Account__c'), (Integer)agResult.get('noOfCalls'));
                } 
                
                //when the count is matching , putting the calls in a map to be passed to helper class
                for(Id accId : outletIdToCallsRetained.keySet()){
                    if(outletIdToCallsCountMap.get(accId) == outletIdToCallsRetained.get(accId).size()){
                        
                        if(!callsToProcessMap.containsKey(accId)) {
                            Set<Call__c> callsSet = outletIdToCallsRetained.get(accId);
                            
                            callsToProcessMap.put(accId, callsSet);
                            outletIdToCallsRetained.remove(accId);
                        } 
                    }
                    
                }
                
                for(Id outletId : callsToProcessMap.keySet()){
                    for(Call__c call : callsToProcessMap.get(outletId)){
                        
                        if(call.Type_of_Call__r.Global_Equivalent_Call_Type__c == 'Virtual'){
                            if(!virtualCallsCountMap.containsKey(call.Account__c)){
                                virtualCallsCountMap.put(call.Account__c,1); 
                            }else{
                                if(virtualCallsCountMap.get(call.Account__c) != null){
                                    Integer virtualCall = virtualCallsCountMap.get(call.Account__c);  
                                    virtualCallsCountMap.put(call.Account__c,virtualCall+1);      
                                }
                                
                            }
                        }
                        if(call.Type_of_Call__r.Global_Equivalent_Call_Type__c == 'Physical'){
                            if(!physicalCallsCountMap.containsKey(call.Account__c)){
                                physicalCallsCountMap.put(call.Account__c,1); 
                            }else{
                                if(physicalCallsCountMap.get(call.Account__c) != null){
                                    Integer physicalCall = physicalCallsCountMap.get(call.Account__c);  
                                    physicalCallsCountMap.put(call.Account__c,physicalCall+1);     
                                }
                                
                            }
                            
                        }
                        if(call.Type_of_Call__r.Global_Equivalent_Call_Type__c == 'Telephone'){
                            if(!telephoneCallsCountMap.containsKey(call.Account__c)){
                                telephoneCallsCountMap.put(call.Account__c,1); 
                            }else{
                                if(telephoneCallsCountMap.get(call.Account__c) != null){
                                    Integer telephonicCall = telephoneCallsCountMap.get(call.Account__c);  
                                    telephoneCallsCountMap.put(call.Account__c,telephonicCall+1);   
                                }
                                
                            }
                            
                        }
                    }
                }
                
                
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
        List<EDGE_BatchSObjectWrapper> wrapperRecords = new List<EDGE_BatchSObjectWrapper>(); 
        EDGE_BatchSObjectWrapper batchWrapper = new EDGE_BatchSObjectWrapper();

         batchWrapper.virtualCallsCountMap = virtualCallsCountMap;
         batchWrapper.telephoneCallsCountMap = telephoneCallsCountMap;
         batchWrapper.physicalCallsCountMap  = physicalCallsCountMap;
         wrapperRecords.add(batchWrapper);
         
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Schedule Next Batch from Batch Utility Class
        System.debug('@@wrapperRecords = '+ wrapperRecords);
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletCallCountUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
          //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           System.debug('@@heapSize = ' +limits.getHeapSize());
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError,wrapperRecords);
        }
    }
    
}