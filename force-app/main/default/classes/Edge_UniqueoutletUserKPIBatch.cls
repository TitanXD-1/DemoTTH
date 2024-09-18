/**
* @Name: Edge_UniqueoutletUserKPIBatch

* @Req: 
* 

* @History                                                            

* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Sudipta Nandi        11/09/20201    [ES20-10648] Create Unique outlet User KPI record                
**/

public class Edge_UniqueoutletUserKPIBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    public Market_Batch_Setting__mdt batchSetting;
    Public string countryCode = '';
    Public List<Market_Cycle__c> marketCycleRecord;
    Public DateTime actvMarketCycleStartDate;
    Public DateTime actvMarketCycleEndDate;
    Public boolean hasError = false ;
    Public string exceptionMsg = '';
    Public Id marketBatchJobId; 
    public static final String uniqueOutlets = EDGE_Constant.EDGE_UNIQUE_OUTLETS;
    public String USER_KPI_RCRDTYPE_DVLPR_NAME = 'User_KPI';
    String queryString;
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c; 
        marketCycleRecord = [SELECT Id,Start_Date__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1];
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndDate = marketCycleRecord[0].End_Date__c; 
              queryString = 'SELECT Id, Type_of_Call__c,Account__c,Start_Date__c,Status__c,End_Date__c,Call_Performed_By__c,Call_Performed_By__r.ProfileId'+
            ' from Call__c where Status__c = \'Completed\''+ 
            ' AND Account__r.Country__r.Code__c = \'' + countryCode +'\''+
            ' And DAY_ONLY(End_Date__c) >= '+actvMarketCycleStartDate.format('YYYY-MM-dd')+' And DAY_ONLY(End_Date__c) <= '+actvMarketCycleEndDate.format('YYYY-MM-dd');
            
        }
        else{
            queryString = 'SELECT Id FROM Call__c LIMIT 0';
        }
        
       
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        List<Id> callTypeMap = new List<Id>();
        List<Id> assignedUsermap = new List<Id>();
        Map<Id, Id> uniqueOutletmap = new Map<Id, Id>();
        Map<Id, Id> userRoleMap = new Map<Id, Id>();
        Map<String, Boolean> roleCallMap = new Map<String, Boolean>();
        Map<String, Integer> userToOutletMap = new Map<String, Integer>();
        Map<String, Integer> userToTotalCount = new Map<String, Integer> ();
        Map<String, KPI_Achivement__c> existingKpiMap = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchvMap = new Map<String, KPI_Achivement__c>();   
        try{
            if(scope != null && scope.size() > 0){               
                List<Call__c> callList = (List<Call__c>)scope;
               
                for(Call__c callRec : callList){
                    assignedUsermap.add(callRec.Call_Performed_By__c);
                    callTypeMap.add(callRec.Type_of_Call__c);
                }
                
                if(assignedUsermap != null && assignedUsermap.size()>0){
                    for(User_Business_Role__c userRoleRec : [SELECT Business_Role__c,User__c FROM User_Business_Role__c 
                                                             where User__c in :assignedUsermap]){
                         userRoleMap.put(userRoleRec.User__c, userRoleRec.Business_Role__c);
                     }
                }
                if(!userRoleMap.isEmpty() && callTypeMap.size()>0){
                    for(Role_Call__c userRoleRec : [SELECT Business_Role__c,Call_Type__c,KPIs_Active__c FROM Role_Call__c 
                                                    WHERE Call_Type__c IN:callTypeMap AND Business_Role__c IN:userRoleMap.values()
                                                    AND KPIs_Active__c includes ('Unique Outlets')]){
                        roleCallMap.put(userRoleRec.Business_Role__c + '_' +userRoleRec.Call_Type__c,True);
                     }
                }
                
                for(Call__c callRec : callList){
                    String cmpKey = (userRoleMap.get(callRec.Call_Performed_By__c) + '_' + callRec.Type_of_Call__c);
                    if(roleCallMap !=null && roleCallMap.containsKey(cmpKey)){
                        String uniqueKey = callRec.Call_Performed_By__c + '_' + callRec.Account__c;
                        if(!userToOutletMap.containsKey(uniqueKey)){
                            userToOutletMap.put(uniqueKey,1);
                        }
                    }
                }
                if(userToOutletMap !=null && !userToOutletMap.isEmpty()){
                    for(String key : userToOutletMap.keySet()){
                        Id userRecId = key.split('_')[0];
                        Id outletRecId = key.split('_')[1];
                        if(!userToTotalCount.containsKey(userRecId)){
                            userToTotalCount.put(userRecId, 1);
                        }
                        else{
                            Integer count = userToTotalCount.get(userRecId);
                            count++;
                            userToTotalCount.put(userRecId,count);
                        }
                    }          
                }
                if(userToTotalCount !=null && !userToTotalCount.isEmpty()){
                    existingKpiMap = EDGE_DataUtility.getkpiAchievementMap(userToTotalCount.keySet(), USER_KPI_RCRDTYPE_DVLPR_NAME, uniqueOutlets);
                    for(String userId : userToTotalCount.keySet()){
                        String cmpKey = userId + '_' + uniqueOutlets;
                        if(existingKpiMap == null || (existingKpiMap!=null && !existingKpiMap.containsKey(cmpKey)))
                        {
                            KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
                            kpiAchive.RecordTypeId = userKPIRecordTypeId;
                            kpiAchive.KPI_Type__c = uniqueOutlets;
                            kpiAchive.Actual_Numerator__c = userToTotalCount.get(userId);
                            kpiAchive.Achievement__c = userToTotalCount.get(userId);
                            kpiAchive.User__c = userId;
                            kpiAchvMap.put(cmpKey,kpiAchive);
                        }
                        else{
            				KPI_Achivement__c kpiAchive = existingKpiMap.get(cmpKey);
                            kpiAchive.Actual_Numerator__c = userToTotalCount.get(userId);
                            kpiAchive.Achievement__c = userToTotalCount.get(userId);
                            kpiAchvMap.put(cmpKey,kpiAchive);
                        }
                    }
                }
                if(kpiAchvMap != null && kpiAchvMap.values().Size()>0){
        			Database.upsert(kpiAchvMap.values());
    			}
            }
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'Edge_UniqueoutletUserKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}