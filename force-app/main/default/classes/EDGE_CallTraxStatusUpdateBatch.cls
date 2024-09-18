/**
* @description EDGE_CallTraxStatusUpdateBatch
* @history

Author          Version    Date           Detail
Sandip Ghosh    V1.0       03/07/2020     [ES20-8048]Create a Process on the Call Object_SFDC_GLO_03_Use TRAX on phone & iPad
Shahbaz Khan	V1.1	   22/07/2020	  [ES20-8055]Change Trax Validation to fail
Anamika Shukla  V1.2       10/02/2021     [ES20-8353]Trax Audit batch improvement through Unique_Id__c
**/

public class EDGE_CallTraxStatusUpdateBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    Date todayDate = system.today();//added for ES20-8055
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
  
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        String countryCode = batchSetting.Country_Code__c;        
        String queryString = 'SELECT Id, End_Date__c, Call_Performed_By__r.Email, Account__c'+
            ' from Call__c where Call_Completed_in_Mobile__c = true AND Trax_Validation__c = \'Pending\''+ 
            ' AND Account__r.Country__r.Code__c = \'' + countryCode +'\'';
        
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){     
        
        Map<Id, Call__c> callMapToUpdate = new Map<Id, Call__c>();
       
        try{
            if(scope != null && scope.size() > 0){               
                List<Call__c> callList = (List<Call__c>)scope;
                Map<String, List<Call__c>> callUniqueIdMap = new Map<String, List<Call__c>>();
                List<Call__c> callListToCheck = new List<Call__c>();
                //Added by Anamika
                Set<String> uniqueIdSet=new Set<String>();
                for(Call__c callRec : callList){
                    
                    if(callRec.End_Date__c != null && callRec.Call_Performed_By__c != null && callRec.Account__c != null){
                        Date convertedDate = Date.newinstance(callRec.End_Date__c.year(), callRec.End_Date__c.month(), callRec.End_Date__c.day());
                        // Added by Anamika for ES20-8353
                        Datetime datevalue=convertedDate;
                        String uniqueId = datevalue.format('yyyy-MM-dd') + '_' + callRec.Call_Performed_By__r.Email + '_' + callRec.Account__c;
                        uniqueIdSet.add(uniqueId);
                        
                        if(uniqueId != null){
                            if(!callUniqueIdMap.containsKey(uniqueId)){
                                callUniqueIdMap.put(uniqueId, new List<Call__c>{callRec}); 
                            }else{
                                callUniqueIdMap.get(uniqueId).add(callRec);
                            }
                        }
                        
                        if(convertedDate.daysBetween(todayDate) >=15){ //added if statement for ES20-8055
                            callListToCheck.add(callRec);
                        }
                    }                                       
                }
                
           
                if(!callUniqueIdMap.isEmpty()){
                     //Added by Anamika for ES20-8353:  
                    for(Visit_Audit__c visitAuditRec : [Select Id, Date__c, Email__c, Account__c, Unique_ID__c from Visit_Audit__c 
                                                        where Unique_ID__c in :uniqueIdSet]){
                                                                                        
                        if(visitAuditRec.Unique_ID__c != null && callUniqueIdMap.containsKey(visitAuditRec.Unique_ID__c)){
                            for(Call__c callRecord : callUniqueIdMap.get(visitAuditRec.Unique_ID__c)){
                              	callRecord.Trax_Validation__c = 'Complete';
                                //after discussion on 17-July
                                callRecord.Visit_Audit__c = visitAuditRec.Id;
                                callMapToUpdate.put(callRecord.Id, callRecord);
                            }
                        }
                    }   
                }
                if(callListToCheck!=null && callListToCheck.size()>0){ //added this block for ES20-8055
                    for(Call__c call : callListToCheck){
                        if(!callMapToUpdate.containsKey(call.id)){
                            call.Trax_Validation__c = 'Fail';
                            callMapToUpdate.put(call.id,call);
                        }
                    }
                }

                if(!callMapToUpdate.isEmpty() && Schema.sObjectType.Call__c.isUpdateable()){//added isUpdateable statement
                    Database.update(callMapToUpdate.values());
                }          
            }            
        }catch(Exception batchException){
            //System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
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
        
        //Update Batch Job Statushttps://edge--edge365dev.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_CallTraxStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}