/**

* @Description :  EDGE_OutletLevelKPICalcBatch

* @History :

* Version   Developer      Date       User Story	  Purpose
* 1.1       Aparajita    11/11/2021   ES20-11045      Populating the fields:Case_Task_vs_SLA__c and Case_Task_vs_Total__c in outlet
* 2.0		Saranya L	 10/02/2022	  ES20-11576	  Including the carry over case tasks(open,pending) in the KPI Calculation

* 3.0       Joshraj Sen  16/02/2022   ES20-12124      Null check in case there is no Active Market Cycle or there are no results returned due to Query String
* 4.0       Joshraj Sen  15/03/2022   ES20-12333      Only 1 Query for Active Market Cycle 

*/

public class EDGE_OutletLevelKPICalcBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
{
    public static String EDGE_ACHIEVED_STATUS ='Achieved';
    public static String EDGE_NOT_ACHIEVED_STATUS ='Not Achieved';
    public static String EDGE_CANCELLED_STATUS ='Cancelled';
    static String countryCode = '';
    static String  qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId(); 
    static String  outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 

    public  Datetime marketCycleStartDate;//ES20-12333
    public  Datetime marketCycleEndDate;//ES20-12333

    DateTime batchRundate = System.now();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    Map<Id,Set<Id>> outletVsCaseTasksCompletedWithinSLAMap = new Map<Id,Set<Id>>();
    Map<Id,Set<Id>> outletVsCaseTasksCompletedMap = new Map<Id,Set<Id>>();
    Map<Id,Set<Id>> outletVsTotalCaseTasksMap = new Map<Id,Set<Id>>();
    
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting)
    {
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String query = '';
        countryCode = batchSetting.Country_Code__c;
        List<Market_Cycle__c> marketCyl=new List<Market_Cycle__c>();
        marketCyl = [SELECT Id, End_Date__c, Start_Date__c, Geography__r.code__c FROM Market_Cycle__c WHERE Geography__r.code__c=:countryCode and Active__c=TRUE Limit 1];
        if(marketCyl!=null && marketCyl.size()>0){
            marketCycleStartDate = marketCyl[0].Start_Date__c;
            marketCycleEndDate = marketCyl[0].End_Date__c;


            query = 'SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Case_Task_vs_SLA__c, Account__r.Case_Task_vs_Total__c, '+
                'Case__c, Case__r.RecordTypeId, Case_Task_Type__c, Achievement_Status__c, Actioned_Within_SLA__c, LastModifiedDate,Account__r.Country_Code__c, '+
                'Carry_Forward_Check__c FROM Case_Task__c WHERE Case__r.RecordTypeId =:qualityRecordTypeId AND Account__r.RecordTypeId =:outletRecordTypeId '+    
                'AND Account__c !=NULL AND Achievement_Status__c !=NULL AND Case__c !=NULL '+
                'AND Account__r.Country__r.Code__c =:countryCode AND (LastModifiedDate>=:marketCycleStartDate AND LastModifiedDate<=:marketCycleEndDate) '+
                'order by Account__c';
        }
        else{
            //When there is no market cycle present in system for that country
            query = 'SELECT Id FROM Case_Task__c LIMIT 0';
        }
        
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> caseTaskList)
    {
        try{
            if(caseTaskList!=null && caseTaskList.size()>0)
            {
                //Initialization 
                Map<Id,Set<Id>> outletVsCaseTasksMap = new Map<Id,Set<Id>>(); 
                Map<Id,Account> outletMap = new Map<Id,Account>();
                List<Account> outletsToUpdate = new List<Account>();


                for(Case_Task__c caseTaskObj : caseTaskList){
                    //Fetching all case-tasks per outlet
                    if(outletVsCaseTasksMap.containsKey(caseTaskObj.Account__c)){
                        outletVsCaseTasksMap.get(caseTaskObj.Account__c).add(caseTaskObj.Id);
                    }else{
                        outletVsCaseTasksMap.put(caseTaskObj.Account__c, new Set<Id>{caseTaskObj.Id});    
                    }     
                    //Fetching all case-tasks per outlet which are completed within SLA     
                    if((caseTaskObj.Achievement_Status__c == EDGE_ACHIEVED_STATUS || caseTaskObj.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS) && caseTaskObj.Actioned_Within_SLA__c == TRUE){                
                        if(outletVsCaseTasksCompletedWithinSLAMap.containsKey(caseTaskObj.Account__c)){
                            outletVsCaseTasksCompletedWithinSLAMap.get(caseTaskObj.Account__c).add(caseTaskObj.Id);
                        }else{
                            outletVsCaseTasksCompletedWithinSLAMap.put(caseTaskObj.Account__c, new Set<Id>{caseTaskObj.Id});    
                        }     
                    }
                    //Fetching all case-tasks per outlet which are completed within/outside SLA      
                    if(caseTaskObj.Achievement_Status__c == EDGE_ACHIEVED_STATUS || caseTaskObj.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS){                
                        if(outletVsCaseTasksCompletedMap.containsKey(caseTaskObj.Account__c)){
                            outletVsCaseTasksCompletedMap.get(caseTaskObj.Account__c).add(caseTaskObj.Id);
                        }else{
                            outletVsCaseTasksCompletedMap.put(caseTaskObj.Account__c, new Set<Id>{caseTaskObj.Id});    
                        }     
                    }                
                    //Fetching all non-cancelled case-tasks per outlet    
                    if(caseTaskObj.Achievement_Status__c != EDGE_CANCELLED_STATUS){
                        if(outletVsTotalCaseTasksMap.containsKey(caseTaskObj.Account__c)){
                            outletVsTotalCaseTasksMap.get(caseTaskObj.Account__c).add(caseTaskObj.Id);
                        }else{
                            outletVsTotalCaseTasksMap.put(caseTaskObj.Account__c, new Set<Id>{caseTaskObj.Id});    
                        }     
                    }                
                }
                //Creating a map to fetch outlet using its Id
                for(Account  outlet : [SELECT Id, Case_Task_vs_SLA__c, Case_Task_vs_Total__c,Carry_Over_Case_Tasks_for_CT_vs_SLA__c
                                       FROM Account WHERE Id IN : outletVsCaseTasksMap.keySet()]){
                                           if(outletMap !=null && !outletMap.containsKey(outlet.Id)){
                                               outletMap.put(outlet.Id, outlet);
                                           }
                                       }
                //Calculating fields 'Case_Task_vs_SLA__c' and 'Case_Task_vs_Total__c' for each outlet
                if(outletVsCaseTasksMap !=null && outletVsCaseTasksMap.values().size()>0){
                    for(Id outletId : outletMap.keySet()){
                        Decimal caseTasksCompletedWithinSLAPerOutlet = 0;
                        Decimal caseTasksCompletedPerOutlet = 0;
                        Decimal totalCaseTasksPerOutlet = 0;   
                        Account outlet = outletMap.get(outletId);
                        
                        //Calculating the Numerator of 'Case Task vs SLA'
                        if(outletVsCaseTasksCompletedWithinSLAMap!=null && outletVsCaseTasksCompletedWithinSLAMap.size()>0 && outletVsCaseTasksCompletedWithinSLAMap.containsKey(outletId)){
                            caseTasksCompletedWithinSLAPerOutlet = outletVsCaseTasksCompletedWithinSLAMap.get(outletId).size();
                        }
                        //Calculating of Numerator of 'Case_Task_vs_Total__c' 
                        if(outletVsCaseTasksCompletedMap!=null && outletVsCaseTasksCompletedMap.size()>0 && outletVsCaseTasksCompletedMap.containsKey(outletId)){
                            caseTasksCompletedPerOutlet = outletVsCaseTasksCompletedMap.get(outletId).size();
                        }                    
                        //Calculating of Denominator of 'Case Task vs SLA' and 'Case_Task_vs_Total__c'
                        if(outletVsTotalCaseTasksMap!=null && outletVsTotalCaseTasksMap.size()>0 && outletVsTotalCaseTasksMap.containsKey(outletId)){
                            totalCaseTasksPerOutlet = outletVsTotalCaseTasksMap.get(outletId).size();
                        }                        
                        if(totalCaseTasksPerOutlet!=0){
                            outlet.Case_Task_vs_SLA__c = ((caseTasksCompletedWithinSLAPerOutlet/totalCaseTasksPerOutlet)*100).setScale(2,RoundingMode.HALF_UP);
                            outlet.Case_Task_vs_Total__c = ((caseTasksCompletedPerOutlet/totalCaseTasksPerOutlet)*100).setScale(2,RoundingMode.HALF_UP);
                        }else{
                            outlet.Case_Task_vs_SLA__c = 0;
                            outlet.Case_Task_vs_Total__c = 0;
                        }                   
                        outletsToUpdate.add(outlet);
                    }
                }
                
                if(outletsToUpdate!=null && outletsToUpdate.size()>0){
                    Database.update(outletsToUpdate,false);
                }
                
                Map<String,Integer> totalCaseTaskMap = new Map<String,Integer>();
                for(sobject cstList : [SELECT Account__c, count(Id) FROM Case_Task__c WHERE Achievement_Status__c NOT IN ('Cancelled') 
                                       AND Account__c IN :outletMap.keySet() AND Account__r.Country__r.Code__c =:countryCode 
                                       AND Account__c !=NULL AND Achievement_Status__c !=NULL AND Case__c !=NULL 
                                       AND (LastModifiedDate >=:marketCycleStartDate AND LastModifiedDate <=:marketCycleEndDate)
                                       AND Case__r.RecordTypeId =:qualityRecordTypeId
                                       group by Account__c]){
                                           totalCaseTaskMap.put((Id) cstList.get('Account__c'), (Integer)cstList.get('expr0'));
                                           //mapping the account and the count of open or pending casetasks under the account
                                       }
                if(outletMap!=null && outletMap.size()>0){
                    for(Id outletId : outletMap.keySet()){
                        if(totalCaseTaskMap.containsKey(outletId) && outletVsTotalCaseTasksMap.containsKey(outletId)){
                            Integer cTLeft = totalCaseTaskMap.get(outletId);
                            if(cTLeft <= outletVsTotalCaseTasksMap.get(outletId).size()){
                                outletVsTotalCaseTasksMap.remove(outletId);
                                if(outletVsCaseTasksCompletedMap.containsKey(outletId)){
                                    outletVsCaseTasksCompletedMap.remove(outletId);
                                }
                                if(outletVsCaseTasksCompletedWithinSLAMap.containsKey(outletId)){
                                    outletVsCaseTasksCompletedWithinSLAMap.remove(outletId);
                                }
                            }
                        }
                    }
                }
                
            }
        }
        catch(Exception ex)
        {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';  
        }   
    }
    
    //Finish Method 
    public void finish(Database.BatchableContext bc)
    {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed')
            hasError = true;
        
        //Update Batch Job Status
        if(hasError)
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletLevelKPICalcBatch', exceptionMsg);
        else
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}