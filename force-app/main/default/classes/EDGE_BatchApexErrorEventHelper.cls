/**********************************************************************
	Name: EDGE_BatchApexErrorEventHelper
=======================================================================
	Purpose: This is to helper class for BatchApexErrorEventTrigger
=======================================================================
	History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Kapil Baliyan	   29/12/2019		 Initial Development ES20-6594
***********************************************************************/

public with sharing class EDGE_BatchApexErrorEventHelper {
	
    //Method to handle Apex Batch Exception
    public static void handleBatchException(Map<Id, SObject> newItems){
        List<Country_Batch_Job_Log__c> batchJobLogList = new List<Country_Batch_Job_Log__c>();
        Map<Id, BatchApexErrorEvent> batchApexErrorEventMap = new Map<Id, BatchApexErrorEvent>();
        
        //Get job id
        for(SObject obj : newItems.values()){
            BatchApexErrorEvent errorEvt = (BatchApexErrorEvent)obj;
            batchApexErrorEventMap.put(errorEvt.AsyncApexJobId, errorEvt);
        }
        
        //Get All Country_Batch_Job_Log__c
        if(Schema.SObjectType.Country_Batch_Job_Log__c.isAccessible()){
            for(Country_Batch_Job_Log__c batchJobLog : [SELECT Id, Batch_Job_Id__c, Exception__c, Exception_Block__c, Status__c, Batch_Scope__c 
                                                        FROM Country_Batch_Job_Log__c WHERE Batch_Job_Id__c IN :batchApexErrorEventMap.keySet()])
            {
                if(batchApexErrorEventMap.containsKey(batchJobLog.Batch_Job_Id__c)){
                    Country_Batch_Job_Log__c bLog = new Country_Batch_Job_Log__c();
                    bLog.Id = batchJobLog.Id;
                    bLog.Exception__c = batchApexErrorEventMap.get(batchJobLog.Batch_Job_Id__c).Message;
                    bLog.Batch_Scope__c = batchApexErrorEventMap.get(batchJobLog.Batch_Job_Id__c).JobScope;
                    bLog.Stack_Trace__c = batchApexErrorEventMap.get(batchJobLog.Batch_Job_Id__c).StackTrace;
                    bLog.Status__c = 'Failed';
                    bLog.Is_Updated_By_Platform_Event__c = TRUE;
                    bLog.Finish__c = system.now();
                    
                    batchJobLogList.add(bLog);
                }
            }
        }
        
        //Update Batch Job Log
        if(batchJobLogList.size()>0 && Schema.SObjectType.Country_Batch_Job_Log__c.isUpdateable()){
            update batchJobLogList;
        }
    }
}