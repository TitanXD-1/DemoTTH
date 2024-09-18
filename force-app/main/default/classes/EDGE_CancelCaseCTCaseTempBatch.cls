/**

* @Description: EDGE_CancelCaseCTCaseTempBatch

* @Purpose : Batch Class to cancel case and case task when Activity Target List Member status Waiting Removal or Case Template 
			 End Date is less than todays date

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*   1.0       Monalisa Halder       08/02/2022          ES20-11870

*/

public class EDGE_CancelCaseCTCaseTempBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    List<Activity_Target_List__c> activityTargetLstMemListToDelete = new List<Activity_Target_List__c>();
    Set<Id> cancelCaseCTtargetListIdSet = new Set<Id>();
    Date todaysDate = system.today();
       
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        // Upsert Market Batch Job Data
        string countryCode = batchSetting.Country_Code__c;
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        Set<Id> targetListIdSet = new Set<Id>();
       
        //Querying all the Activity_Target_List__c with Waiting Activation and Waiting Removal 
        for(Activity_Target_List__c actTLMem :[SELECT Id, Target_List__c,Case_Template__c,Case_Template__r.End_Date__c, Status__c FROM Activity_Target_List__c  
                               				   WHERE  Case_Template__c!= null AND (Status__c='Waiting Removal' 
                                               OR (Case_Template__r.End_Date__c != null AND Case_Template__r.End_Date__c < TODAY)) AND Target_List__r.Country__r.Code__c=:countryCode]){
        					   targetListIdSet.add(actTLMem.Target_List__c);       
                              if(actTLMem.Status__c=='Waiting Removal' || actTLMem.Case_Template__r.End_Date__c < todaysDate){
                                   //putting the waiting removal ones, in a list to update later
                                   // no need to update status of Activity Target List, when Case Template end date is past date

								  // if it is waiting removal then ATL is changed to Inactive
                                   if(actTLMem.Case_Template__r.End_Date__c > todaysDate || actTLMem.Status__c=='Waiting Removal'){

                                     activityTargetLstMemListToDelete.add(actTLMem);  
                                   }
                                   cancelCaseCTtargetListIdSet.add(actTLMem.Target_List__c);
                               }  
                                
        }
        
        string queryString='';
        if(targetListIdSet != null && targetListIdSet.size()>0){
        	queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE Target_List__c IN: targetListIdSet'+
                          ' and Target_List__r.Country__r.Code__c=:countryCode ORDER BY Outlet__c';
        	
        }else{
            queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c LIMIT 0';
        }
        
        return Database.getQueryLocator(queryString);
        
    }
    
    //Execute Batch
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList){
        List<Activity_Target_List__c> deleteActTLList= new list<Activity_Target_List__c>();
        Map<Id,Set<Id>> caseTemplateOutetIdCancelMap = new Map<Id,Set<Id>>();
        
        if(activityTargetLstMemListToDelete != null && activityTargetLstMemListToDelete.size() > 0){
            for(Activity_Target_List__c actTL :activityTargetLstMemListToDelete){
                actTL.Status__c = 'Inactive';
                deleteActTLList.add(actTL);
            }
        }
        
        try{
          if(cancelCaseCTtargetListIdSet != null && cancelCaseCTtargetListIdSet.size() >0){
                for(Target_List_Member__c targetLstMem :targetListMemberList){
                    
                     if(cancelCaseCTtargetListIdSet.contains(targetLstMem.Target_List__c)){
                         if(caseTemplateOutetIdCancelMap.containsKey(targetLstMem.Target_List__c)){
                             caseTemplateOutetIdCancelMap.get(targetLstMem.Target_List__c).add(targetLstMem.Outlet__c);
                         }
                         else {
                                Set<Id> outletIdSet = new Set<Id>();
                                outletIdSet.add(targetLstMem.Outlet__c);
                        		caseTemplateOutetIdCancelMap.put(targetLstMem.Target_List__c,outletIdSet);
                    	} 
                    }
                      
                }
            }
               
                if(caseTemplateOutetIdCancelMap != null && caseTemplateOutetIdCancelMap.size()>0){
					//EDGE_DynamicTLCaseTaskCreationHelper.deleteCaseTask(caseTemplateOutetIdMap2,caseTempIdSet);

                    EDGE_DynamicTLCaseTaskCreationHelper.updateStatusOfCaseTask(caseTemplateOutetIdCancelMap,true); 

                }
                if(deleteActTLList != null && deleteActTLList.size()>0){
                    update deleteActTLList;
                }
            
        }catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }       
    }   
    
    //Finish Method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_CancelCaseCTCaseTempBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            //Schedule Next Batch from Batch Utility Class
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}