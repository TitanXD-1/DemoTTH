/**
* @Name: EDGE_VirtualPlanCallCompUserKPIBatch

* @Req: The requirement is we need the Virtual Call Count && Plan Called Compliance Metric of a User
to consider the Virtual Calls done in ALL outlets visited by the rep that maybe in his Primary territory OR Secondary Territory OR a Prospect Account. 
* 

* @History                                                            

* @VERSION     AUTHOR              		DATE            DETAIL
*  1.0         Aparajita,Rajarshi      25/05/2022	    ES20-12716,ES20-12717,ES20-12900
*  2.0 		   Rajarshi Lahiri		   09/06/2022		ES20-12745
*  3.0		   Rajarshi Lahiri		   17/06/2022       ES20-13003	
*  4.0         Mayukh SRoy             26/10/2022       ES20-13391
*  5.0         Joshraj Sen             26/12/2022       ES20-13692
*  5.1         Mayukh SRoy             12/01/2023       ES20-13717
**/

public class EDGE_VirtualPlanCallCompUserKPIBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    public Market_Batch_Setting__mdt batchSetting;
    Public string countryCode = '';
    Public List<Market_Cycle__c> marketCycleRecord;
    Public DateTime actvMarketCycleStartDate;
    Public DateTime actvMarketCycleEndDate;
    Public boolean hasError = false ;
    Public string exceptionMsg = '';
    Public Id marketBatchJobId; 
    public static final String planCallComp = 'Plan Call Compliance';
    public static final String virtualCallComp = 'Virtual Call Compliance';
    public String USER_KPI_RCRDTYPE_DVLPR_NAME = 'User_KPI';
    public Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    String queryString;
    Public Map<String,EDGE_CallUserKPIWrapper> usrToCallCount =new Map<String,EDGE_CallUserKPIWrapper>();
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
            queryString = 'SELECT Id,Account__c, Account__r.Status__c,Account__r.Record_Type_Name__c ,callPlanned__c,Call_duration_compliance__c,Start_Date__c, Status__c, End_Date__c, '+
                ' Plan_Start_Date__c, Call_Performed_By__c, Assigned_To__c,Call_Performed_By__r.IsActive, Assigned_To__r.IsActive,'+
                ' Type_of_Call__c, Type_of_Call__r.Global_Equivalent_Call_Type__c, Account__r.Country__c' +
                ' from Call__c where (Status__c = \'Completed\' OR (callPlanned__c=True AND Status__c != \'Deleted\'))'+ 
                ' AND ((Account__r.Record_Type_Name__c=\'Prospect\' AND Account__r.Status__c!=NULL ) OR (Account__r.Record_Type_Name__c=\'Outlet\' AND Account__r.Status__c IN (\'Active\',\'Temporarily Closed\') ))'+
                ' AND Account__r.Country__r.Code__c = \'' + countryCode +'\'';
        }
        else{
            queryString = 'SELECT Id FROM Call__c LIMIT 0';
        }
        
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){
       
        //Assignment
        Map<Id,Set<Call__c>> usrToCallMap =new Map<Id,Set<Call__c>>();
        Set<id> usrSet=new Set<Id>();
        //Integer currentMonth = date.today().month();
        //Integer currentYear = date.today().year();
        try{
            if(scope != null && scope.size() > 0){
                
                //Assignment
                List<Call__c> callList = (List<Call__c>)scope;
				if(marketCycleRecord!=null && marketCycleRecord.size()>0){                
                    actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
                    //System.debug('actvMarketCycleStartDate'+actvMarketCycleStartDate);
                    actvMarketCycleEndDate = marketCycleRecord[0].End_Date__c;
                }
                for(Call__c callRec : callList){
                    
                    //Planned Call block for mapping AssignedTo user with call
                    if(callRec.callPlanned__c==True && callRec.Assigned_To__c!=null && callRec.Assigned_To__r.IsActive==true){
                        if(usrToCallMap.containsKey(callRec.Assigned_To__c)){
                            usrToCallMap.get(callRec.Assigned_To__c).add(callRec);
                        }else{
                            usrToCallMap.put(callRec.Assigned_To__c,new Set<Call__c>{callRec});
                        }
                        usrSet.add(callRec.Assigned_To__c);
                    }
                    
                    //Virtual Call block for mapping CallPerformedBy user with call
                    else if(callRec.Status__c=='Completed' && callRec.Call_duration_compliance__c && callRec.Call_Performed_By__c!=null && callRec.Call_Performed_By__r.IsActive==true && 
                            (callRec.Type_of_Call__c!=null && callRec.Type_of_Call__r.Global_Equivalent_Call_Type__c=='Virtual' &&
                          /*(callRec.End_Date__c!=null && callRec.End_Date__c.month() == currentMonth && callRec.End_Date__c.year() == currentYear)*/
                            (callRec.End_Date__c!=null && callRec.End_Date__c.Date() >= actvMarketCycleStartDate && callRec.End_Date__c.Date() <= actvMarketCycleEndDate)  //ES20-13391 //ES20-13717 - Added Date in EndDate 
                            ))
                    {
                        if(usrToCallMap.containsKey(callRec.Call_Performed_By__c)){
                            usrToCallMap.get(callRec.Call_Performed_By__c).add(callRec);
                        }else{
                            usrToCallMap.put(callRec.Call_Performed_By__c,new Set<Call__c>{callRec});
                        }
                        usrSet.add(callRec.Call_Performed_By__c);
                    }
                }
                
                //Creating a wrapper containing call counts for KPI calculation
                for(Id usr : usrSet){
                    if(actvMarketCycleStartDate != null && actvMarketCycleEndDate != null){
                        if(usrToCallCount.containsKey(usr)){
                            EDGE_CallUserKPIWrapper usrCall = EDGE_VirtualPlanCallUsrKPIBatchHelper.updateCount(usrToCallMap.get(usr), usrToCallCount.get(usr), actvMarketCycleStartDate, actvMarketCycleEndDate);
                            usrToCallCount.put(usr,usrCall);
                        }else{
                            EDGE_CallUserKPIWrapper usrCall = EDGE_VirtualPlanCallUsrKPIBatchHelper.updateCount(usrToCallMap.get(usr), new EDGE_CallUserKPIWrapper(), actvMarketCycleStartDate, actvMarketCycleEndDate);
                            usrToCallCount.put(usr,usrCall);
                        }
                	}
                }
            }
        }catch(Exception batchException){
            System.debug(LoggingLevel.DEBUG,'Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            hasError = true;
        }
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){
        
        //Assignment
        Set<Id> userIdSet = new Set<Id>();
        Set<KPI_Achivement__c> kpiToUpsertSet = new Set<KPI_Achivement__c>();
        List<KPI_Achivement__c> kpiToUpsertList = new List<KPI_Achivement__c>(); 
        Map<String, KPI_Achivement__c> kpiAchivementMapVirtual = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchivementMapPlanned = new Map<String, KPI_Achivement__c>();
        Map<String, Id> geoMap = new Map<String, Id>();
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        Set<Id> managerSet=new Set<Id>();
        if(!usrToCallCount.isEmpty()){
            
            userIdSet = new Set<Id>((List<Id>)new List<String>(usrToCallCount.keySet()));
            kpiAchivementMapVirtual = EDGE_DataUtility.getkpiAchievementMap(usrToCallCount.keySet(), USER_KPI_RCRDTYPE_DVLPR_NAME, virtualCallComp);
            kpiAchivementMapPlanned = EDGE_DataUtility.getkpiAchievementMap(usrToCallCount.keySet(), USER_KPI_RCRDTYPE_DVLPR_NAME, planCallComp);
            userToCountryMap = EDGE_DataUtility.fetchUserCountry(userIdSet);
            
            if(!userToCountryMap.isEmpty()){
                for(Geography__c geo : [SELECT Id, Code__c FROM Geography__c WHERE Code__c IN : userToCountryMap.values()]){
                    geoMap.put(geo.Code__c, geo.Id);
                }
            }else{
                for(Geography__c geo : [SELECT Id, Code__c FROM Geography__c WHERE Code__c =: countryCode]){
                    geoMap.put(geo.Code__c, geo.Id);
                }
            }
            
            
            
            //ES20-12745
            //Get a set of Managers from the user set
            for(User usr:[Select Id from User where (Profile.Name='Sales Manager' OR Profile.Name='Quality Manager') AND Id IN: usrToCallCount.keySet()]){
                managerSet.add(usr.Id);
            }
            //Manager to rep count for Virtual Call KPI Denominator
            //added IsActive Check as part of ES20-13003
            Map<Id,AggregateResult> mgrToRepCountMap=new Map<id,AggregateResult>([Select ManagerId Id,COUNT(Id) repcount from User where ManagerId IN:managerSet AND IsActive=true GROUP BY ManagerId]);
            
                for(Id usrId : usrToCallCount.keySet()){
                    
                    //CmpKey creation for vitual & planned calls
                    EDGE_CallUserKPIWrapper callUser = usrToCallCount.get(usrId);
                    String cmpKeyVirtual = usrId + '_' + virtualCallComp;
                    String cmpKeyPlanned = usrId + '_' + planCallComp;
                    Id usrCountryId = ((userToCountryMap!=null && userToCountryMap.get(usrId)!=null)?geoMap.get(userToCountryMap.get(usrId)):geoMap.get(countryCode));
                    
                    //Virtual Call KPI record creation
                    KPI_Achivement__c kpiAchvVirtual = new KPI_Achivement__c(Id = kpiAchivementMapVirtual.containsKey(cmpKeyVirtual)?kpiAchivementMapVirtual.get(cmpKeyVirtual).Id : null);                 
                    kpiAchvVirtual.User__c = usrId;
                    kpiAchvVirtual.RecordTypeId = userKPIRecordTypeId;
                    kpiAchvVirtual.KPI_Type__c = virtualCallComp;
                    kpiAchvVirtual.Country__c = usrCountryId;
                    kpiAchvVirtual.Actual_Numerator__c = (callUser.noOfVirtualCalls==null?0:callUser.noOfVirtualCalls);
                    kpiAchvVirtual.Achievement__c = (callUser.noOfVirtualCalls==null?0:callUser.noOfVirtualCalls);
                    if(managerSet.contains(usrId)){//To keep track if Manager's contribution is calculated by this batch so that it can be picked up when aggregating for Reps
                        kpiAchvVirtual.Manager_Count_Reset__c=true;
                        kpiAchvVirtual.Total_Denominator__c= mgrToRepCountMap.get(usrId) != null? (Decimal)mgrToRepCountMap.get(usrId).get('repcount'):0 ;//ES20-13692
                        kpiAchvVirtual.Achievement__c = (kpiAchvVirtual.Total_Denominator__c != null && kpiAchvVirtual.Total_Denominator__c>0)?(kpiAchvVirtual.Actual_Numerator__c/kpiAchvVirtual.Total_Denominator__c):0;
                    }
                    kpiToUpsertSet.add(kpiAchvVirtual);
                    
                    //Planned Call KPI record creation
                    KPI_Achivement__c kpiAchvPlanned = new KPI_Achivement__c(Id = kpiAchivementMapPlanned.containsKey(cmpKeyPlanned)?kpiAchivementMapPlanned.get(cmpKeyPlanned).Id : null);
                    kpiAchvPlanned.User__c = usrId;
                    kpiAchvPlanned.RecordTypeId = userKPIRecordTypeId;
                    kpiAchvPlanned.KPI_Type__c = planCallComp;
                    if(managerSet.contains(usrId)){//To keep track if Manager's contribution is calculated by this batch so that it can be picked up when aggregating for Reps
                        kpiAchvPlanned.Manager_Count_Reset__c=true;
                    }
                    kpiAchvPlanned.Country__c = usrCountryId;
                    kpiAchvPlanned.Actual_Numerator__c = (callUser.noOfCompPlanCalls==null?0:callUser.noOfCompPlanCalls);
                    kpiAchvPlanned.Total_Denominator__c = (callUser.totalNumPlanCalls==null?0:callUser.totalNumPlanCalls);
                    kpiAchvPlanned.Achievement__c = kpiAchvPlanned.Total_Denominator__c>0?(Double)(kpiAchvPlanned.Actual_Numerator__c*100/kpiAchvPlanned.Total_Denominator__c):0;
                    kpiToUpsertSet.add(kpiAchvPlanned);
                }
            //System.debug('@@@kpiToUpsertSet: '+kpiToUpsertSet);
            
            //Upserting KPI achievements records
            if(kpiToUpsertSet!=null && kpiToUpsertSet.size()>0){
                kpiToUpsertList.addAll(kpiToUpsertSet);
                List<Database.upsertResult> urList=Database.upsert(kpiToUpsertList,false);
                for (Database.upsertResult ur : urList) {
                    if (!ur.isSuccess()) {
                        // Operation failed, so get all errors 
                        System.debug(LoggingLevel.DEBUG,'Error details : '+ ur.getErrors());
                    }
                }
            }
        }
        
        
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_VirtualPlanCallCompUserKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
  
}