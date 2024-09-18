/**
* @Name: EDGE_ManagerUserKpiAchievementBatch

* @Req: 
* 

* @History                                                            

* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Prasanth T          12/11/2021      ES20-10840
*  1.1         Anand Uppalapati    12/11/2021      ES20-11466
*  1.2         Joshraj Sen         14/03/2022      ES20-12291
*  1.3		   Rajarshi Lahiri     06/06/2022	   ES20-12745
*  1.4		   Rajarshi Lahiri	   17/06/2022	   ES20-13003
**/

public class EDGE_ManagerUserKpiAchievementBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    Id countryId;
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId;
    final static String UserKpiRecTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> kpiTypesQuality = new List<String>();
        List<String> kpiTypes = new List<String>();
        String kpiTypesStr = Label.EDGE_ManagerUserKpiTypes;
        String kpiTypesStrPlanVirtual=Label.EDGE_UserKPITypes;
        if(kpiTypesStr != null){
            kpiTypesQuality = kpiTypesStr.split(','); //Number of Visits,Case Task vs SLA,Case Task vs Total,Unique Outlets
        }
        if(kpiTypesStrPlanVirtual != null){
            kpiTypes = kpiTypesStrPlanVirtual.split(','); //Plan Call Compliance,Virtual Call Compliance
        }
        
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        if(String.isNotBlank(countryCode)){
            for(Geography__c country :[SELECT Id FROM Geography__c WHERE Code__c=:countryCode LIMIT 1]){
                countryId = country.Id;
            }
        }            
        //Query String        
        String queryString = 'SELECT Id,Name,KPI_Type__c, User__c,User__r.ManagerId,User__r.Profile.Name,User__r.IsActive, Country__c,Actual_Numerator_Aggregation_of_Reps__c,'
            +' Total_Denominator_Aggregation_of_Reps__c, Actual_Aggregation_of_Reps__c,Actual_Numerator__c,Total_Denominator__c,Achievement__c'
            +' FROM KPI_Achivement__c'
            +' WHERE (KPI_Type__c IN : kpiTypesQuality OR KPI_Type__c IN : kpiTypes)'
            +' AND Country__r.Code__c =:countryCode'
            +' AND RecordTypeId =:UserKpiRecTypeId';
        return Database.getQueryLocator(queryString);
        
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<KPI_Achivement__c> scope){
        
        List<KPI_Achivement__c> kpiAchivQualityList=new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> kpiAchivPlanVirtualList=new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> kpiAchievementtoUpsertList=new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> masterManagerRollUpPlanVirtualList=new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> masterManagerRollUpQualityList=new List<KPI_Achivement__c>();
        Set<Id> mgrIdSet=new Set<Id>();
        List<String> qualityKPITypes  = new List<String>();
        List<String> salesKPITypes  = new List<String>();
        String kpiTypesStr = Label.EDGE_ManagerUserKpiTypes;
        String kpiTypesStrPlanVirtual=Label.EDGE_UserKPITypes;
        if(kpiTypesStr != null){
            qualityKPITypes = kpiTypesStr.split(',');//Number of Visits,Case Task vs SLA,Case Task vs Total,Unique Outlets
        }
        if(kpiTypesStrPlanVirtual != null){
            salesKPITypes = kpiTypesStrPlanVirtual.split(','); //Plan Call Compliance,Virtual Call Compliance
        }
        
        
        try{
            if(scope != null && !scope.isEmpty() && String.isNotBlank(countryId)){
                for(KPI_Achivement__c kpiAch:scope){
                    //Separating Qaulity KPI Achievement functionality from Virtual and Planned Call
                    if(kpiAch.User__r.Profile.Name=='Quality Representative' && qualityKPITypes.contains(kpiAch.KPI_Type__c)){
                    	kpiAchivQualityList.add(kpiAch);
                    }
                    if(salesKPITypes.contains(kpiAch.KPI_Type__c) && kpiAch.User__r.IsActive){//added IsActive Check as part of ES20-13003
                    	kpiAchivPlanVirtualList.add(kpiAch);
                    }
                }

                if(!kpiAchivQualityList.isEmpty()){//Handling Quality KPIs
                    masterManagerRollUpQualityList= EDGE_ManagerUserKpiAchievementHelper.managerKPIRollUp(kpiAchivQualityList,countryId);
                }
                if(!kpiAchivPlanVirtualList.isEmpty()){//Handling KPI Ach for Plan Call Compliance,Virtual Call Compliance type
                    for(KPI_Achivement__c kpiAch:kpiAchivPlanVirtualList){
                        if(kpiAch.User__r.ManagerId!=null){
                            mgrIdSet.add(kpiAch.User__r.ManagerId);
                        }
                    }
                    //To get count of sales reps against a Manager to be used as a denominator for Virtual Call Complaince KPI
                    ////added IsActive Check as part of ES20-13003
                    Map<Id,AggregateResult> mgrToRepCountMap=new Map<id,AggregateResult>([Select ManagerId Id,COUNT(Id) repcount from User where ManagerId IN:mgrIdSet AND IsActive=true GROUP BY ManagerId]);
                    //calling the helper method to calculate manager level KPI Achievement
                    masterManagerRollUpPlanVirtualList=EDGE_VirtualPlanCallUsrKPIBatchHelper.managerKPIRollUp(kpiAchivPlanVirtualList,countryId,mgrToRepCountMap);
                }

                //Adding all records to one single list to upsert
                kpiAchievementtoUpsertList.addAll(masterManagerRollUpQualityList);
                kpiAchievementtoUpsertList.addAll(masterManagerRollUpPlanVirtualList);
            }            
            if(kpiAchievementtoUpsertList != null && kpiAchievementtoUpsertList.Size()>0){
                List<Database.upsertResult> urList= Database.upsert(kpiAchievementtoUpsertList,false);
                for (Database.upsertResult ur : urList) {
                    if (!ur.isSuccess()) {
                        // Operation failed, so get all errors 
                        System.debug('Error details : '+ ur.getErrors());
                    }
                }
            }
        }catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug(batchException.getStackTraceString());
            hasError = true;
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ManagerUserKpiAchievementBatch', exceptionMsg);
            system.debug('batchJobLog'+batchJobLog);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
        
    }  
    
}