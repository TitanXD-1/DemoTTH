/**
* @ Name : EDGE_OutletLevelKPIResetBatch
* @ Description : 
* @ History  
* @ 	Author          Version    				Date           Detail
* @		Saranya L       Initial Development	   08/02/2022     Created for ES20-11576
**/

public class EDGE_OutletLevelKPIResetBatch  implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass {    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode;
    List<Market_Cycle__c> marketCycleRecord;
    Date actvMarketCycleStartDate;
    Date actvMarketCycleEndtDate;
    Date yesterdayDate;
    Date todayDate;
    public boolean isMarketCycleStart = false;
    Map<Id,Set<Id>> outletVsCaseTasksMap = new Map<Id,Set<Id>>();
    List<String> caseTaskStatusList = new List<String>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        String queryString='';
        
        caseTaskStatusList.add('Open');
        caseTaskStatusList.add('Pending');
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        todayDate = Date.today();
        marketCycleRecord = [SELECT Id, End_Date__c, Start_Date__c, Geography__r.code__c FROM Market_Cycle__c WHERE Geography__r.code__c=:countryCode and Active__c=TRUE LIMIT 1] ;
        System.debug('marketCycleRecord'+ marketCycleRecord);
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndtDate = marketCycleRecord[0].End_Date__c; 
        }
        if(actvMarketCycleStartDate == todayDate){
            isMarketCycleStart = true;  
        }
        yesterdayDate = Date.Today().addDays(-1);
        String  qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId(); 
        String  outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        
        if(isMarketCycleStart){
        queryString = 'SELECT Id,Name,Account__c,Achievement_Status__c,Country__r.Code__c,Carry_Forward_Check__c,Case_Task_Type__c FROM Case_Task__c '
            + 'WHERE Case__r.RecordTypeId=:qualityRecordTypeId AND Account__r.RecordTypeId=:outletRecordTypeId '
            + 'AND Account__c !=NULL AND Achievement_Status__c !=NULL AND Case__c !=NULL AND CreatedDate <=:yesterdayDate '
            + 'AND Account__r.Country__r.Code__c =:countryCode AND Achievement_Status__c IN :caseTaskStatusList order by Account__c';
        }
        else{
            queryString = 'SELECT Id FROM Case_Task__c Limit 0';  //Adding dummy query to run the batch with 0 data.
        }
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc,  List<Case_Task__c> caseTaskList){        
        try{
            Set<Id> accountIds = new Set<Id>();
            Map<Id,Account> accountsToUpdate = new Map<Id,Account>();
            List<Case_Task__c> caseTaskListToUpdate = new List<Case_Task__c>();
            
            for(Case_Task__c caseTaskObj : caseTaskList){
                if(caseTaskObj.Account__c != null){
                     accountIds.add(caseTaskObj.Account__c);
                }
                //Fetching all case-tasks per outlet
                if(outletVsCaseTasksMap.containsKey(caseTaskObj.Account__c)){
                    outletVsCaseTasksMap.get(caseTaskObj.Account__c).add(caseTaskObj.Id);
                }else{
                    outletVsCaseTasksMap.put(caseTaskObj.Account__c, new Set<Id>{caseTaskObj.Id});    
                }     
                caseTaskObj.Carry_Forward_Check__c = true;
            	caseTaskListToUpdate.add(caseTaskObj);
        	}
            if(outletVsCaseTasksMap !=null && outletVsCaseTasksMap.size() >0){
                //Creating a map to fetch outlet using its Id
            	for(Account  outlet : [SELECT Id, Case_Task_vs_SLA__c, Case_Task_vs_Total__c,Carry_Over_Case_Tasks_for_CT_vs_SLA__c,Carry_Over_Case_Tasks_for_CT_vs_Total__c FROM Account WHERE Id IN : accountIds]){
                    outlet.Case_Task_vs_SLA__c = 0;
                    outlet.Case_Task_vs_Total__c = 0;
                    outlet.Carry_Over_Case_Tasks_for_CT_vs_SLA__c = outletVsCaseTasksMap.get(outlet.Id).size();
                    outlet.Carry_Over_Case_Tasks_for_CT_vs_Total__c = outletVsCaseTasksMap.get(outlet.Id).size();
                    accountsToUpdate.put(outlet.Id,outlet);
                    
                }
            }
            if(accountsToUpdate!=null && accountsToUpdate.values().size()>0){
                Database.update(accountsToUpdate.Values(),false);
            }
            if(caseTaskListToUpdate!=null && caseTaskListToUpdate.size()>0){
                Database.update(caseTaskListToUpdate,false);
            }
            Map<String,Integer> totalCaseTaskMap = new Map<String,Integer>();
            for(sobject cstList : [SELECT Account__c, count(Id) FROM Case_Task__c WHERE Achievement_Status__c IN :caseTaskStatusList 
                                   AND Account__c IN :accountsToUpdate.keySet() AND Account__r.Country__r.Code__c =:countryCode 
                                   AND Account__c !=NULL AND Achievement_Status__c !=NULL AND Case__c !=NULL group by Account__c]){
                                       totalCaseTaskMap.put((Id) cstList.get('Account__c'), (Integer)cstList.get('expr0'));
                                       //mapping the account and the count of open or pending casetasks under the account
                                   }
            if(accountsToUpdate!=null && accountsToUpdate.size()>0){
                for(Id outletId : accountsToUpdate.keySet()){
                    if(totalCaseTaskMap.containsKey(outletId) && outletVsCaseTasksMap.containsKey(outletId)){
                        Integer cTLeft = totalCaseTaskMap.get(outletId);
                        if(cTLeft <= outletVsCaseTasksMap.get(outletId).size()){
                            outletVsCaseTasksMap.remove(outletId);
                        }
                    }
                }
            }
        }
        catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
     //Update ES20-6594
    public void finish(Database.BatchableContext bc){ 
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_OutletLevelKPIResetBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
}