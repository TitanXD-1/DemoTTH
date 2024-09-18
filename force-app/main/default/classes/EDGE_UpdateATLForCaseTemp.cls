/**

* @Description: EDGE_UpdateATLForCaseTemp

* @Purpose : Batch Class to update Activity Target List Member status Waiting Activation to active  

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*   1.0       Anamika Shukla        15/01/2022          ES20-11726  
*	2.0		  Subhodeep Sarkar		28/01/2022			ES20-11757-moved the code to different class 'EDGE_CancelCaseAndCaseTaskCaseTempBatch'
*   3.0       Monalisa Halder       08/02/2022          ES20-11870

*   4.0       Monalisa Halder       15/02/2022          ES20-12052


*/

public class EDGE_UpdateATLForCaseTemp implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    List<Activity_Target_List__c> activityTargetLstMemListToUpdate = new List<Activity_Target_List__c>();
	Map<Id, Set<Id>> createCaseCTActivityTargetListMap = new Map<Id, Set<Id>>();
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
        for(Activity_Target_List__c actTL :[SELECT Id, Target_List__c,Case_Template__c,Case_Template__r.End_Date__c, Status__c FROM Activity_Target_List__c  
                               				   WHERE  Case_Template__c!= null AND (Status__c='Waiting Activation' AND

                                               (Case_Template__r.End_Date__c = null OR Case_Template__r.End_Date__c >= TODAY)) AND Target_List__r.Country__r.Code__c=:countryCode]){

        					   targetListIdSet.add(actTL.Target_List__c);       
                               if(actTL.Status__c=='Waiting Activation'){
                                   //putting the waiting activation ones, in a list to update later
                                   activityTargetLstMemListToUpdate.add(actTL);
                                   //creating the creation map which was previously in the execute method
                               	if(createCaseCTActivityTargetListMap.containsKey(actTL.Target_List__c)){
                               		createCaseCTActivityTargetListMap.get(actTL.Target_List__c).add(actTL.Case_Template__c);
                               	}else{
                               		createCaseCTActivityTargetListMap.put(actTL.Target_List__c, new Set<Id>{actTL.Case_Template__c});
                               	}              
                               }
                                   
        }
        
        string queryString='';
        if(targetListIdSet != null && targetListIdSet.size()>0){
        	queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE'+
                		  ' Target_List__c IN: targetListIdSet and Target_List__r.Country__r.Code__c=:countryCode ORDER BY Outlet__c';
        	
        }else{
            queryString = 'SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c LIMIT 0';
        }
        
        return Database.getQueryLocator(queryString);
        
    }
    
    //Execute Batch
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList){
        List<Activity_Target_List__c> updateActTLList= new list<Activity_Target_List__c>();
        Map<Id, Set<Id>> createCaseTempToOutletMap = new Map<Id, Set<Id>>();
       
        if(activityTargetLstMemListToUpdate != null && activityTargetLstMemListToUpdate.size() > 0){
            for(Activity_Target_List__c actTL :activityTargetLstMemListToUpdate){
                actTL.Status__c = 'Active';
                updateActTLList.add(actTL);
            }
        }
        
        try{
            if(createCaseCTActivityTargetListMap !=null && !createCaseCTActivityTargetListMap.isEmpty()){
                for(Target_List_Member__c targetLstMem :targetListMemberList){
                    if(createCaseCTActivityTargetListMap.containsKey(targetLstMem.Target_List__c)){
                        //createCaseTempToOutletMap.put(targetLstMem.Outlet__c,createCaseCTActivityTargetListMap.get(targetLstMem.Target_List__c)); 
                        if(createCaseTempToOutletMap.containsKey(targetLstMem.Outlet__c)){
                        	createCaseTempToOutletMap.get(targetLstMem.Outlet__c).addAll(createCaseCTActivityTargetListMap.get(targetLstMem.Target_List__c));
                        }
                        else {
                            Set<Id> caseTemplateIdSet = new Set<Id>();
                            caseTemplateIdSet.addAll(createCaseCTActivityTargetListMap.get(targetLstMem.Target_List__c));
                            createCaseTempToOutletMap.put(targetLstMem.Outlet__c,caseTemplateIdSet);
                        }
                    
                    } 
                     
                    
                }
                
            }
            if(createCaseTempToOutletMap != null && createCaseTempToOutletMap.size()>0){
                EDGE_DynamicTLCaseTaskCreationHelper.processCaseAndCaseTask(createCaseTempToOutletMap); 
            }
            if(updateActTLList != null && updateActTLList.size()>0){
                update updateActTLList;
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdateATLForCaseTemp', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            //Schedule Next Batch from Batch Utility Class
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}