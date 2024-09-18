/**
* @Name: EDGE_UserVisitsKPIBatch
* @Req: 
* @History                                                            
* @VERSION     AUTHOR              DATE          DETAIL
*  1.0         Joshraj Sen                      ES20-10978
*  2.0         Prasanth T		24/12/2021		ES20-11803
**/
public class EDGE_UserVisitsKPIBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    string countryCode = '';
    String qualityRep = 'Quality Representative';
    String queryString;
    List<Market_Cycle__c> marketCycleRecord;
    Datetime actvMarketCycleStartDate;
    Date startDate;
    Datetime actvMarketCycleEndDate;
    Date endDate;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId;
    Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    ID countryRecord;
    List<String> profileList = new List<String>();
    final String NUMBER_OF_VISITS_STR = 'Number of Visits';
    Map<Id,Integer>countOfCallsForEachUser = new Map<Id,Integer>();//Changes for E3GB-503
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        String profilesStr = Label.EDGE_User_Visits_KPI_Batch_Profiles;    
        
        if(profilesStr != null){
            profileList = profilesStr.split(',');
        }
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        countryRecord =[Select ID From Geography__c where code__c=:countryCode LIMIT 1][0].Id;
        marketCycleRecord = [SELECT Id,Start_Date__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1];
        //Null-Check for marketCycleRecord
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndDate = marketCycleRecord[0].End_Date__c;
            startDate =  date.newinstance(actvMarketCycleStartDate.year(), actvMarketCycleStartDate.month(), actvMarketCycleStartDate.day());
            endDate = date.newinstance(actvMarketCycleEndDate.year(), actvMarketCycleEndDate.month(), actvMarketCycleEndDate.day());
            
            queryString = 'SELECT Id,Name, End_Date__c,Status__c,Start_Date__c,Call_Performed_By__c,Call_Performed_By__r.Profile.Name,Call_Performed_By__r.Business_Role_Id__c,'+
                ' Account__c,Account__r.Activation_Specialist__c,Account__r.Primary_Sales_Territory__c,Account__r.Activation_Territory_LT__c,Type_of_Call__c,Type_of_Call__r.Global_Equivalent_Call_Type__c,Last_Visit_from_Mobile__c'+
                ' FROM Call__c WHERE Status__c = \'Completed\''+ 
                ' AND Call_Performed_By__r.Profile.Name IN :profileList'+ 
                ' AND Account__r.Country__r.Code__c =:countryCode'+
                ' AND DAY_ONLY(End_Date__c) >=:startDate'+
                ' AND DAY_ONLY(End_Date__c) <=:endDate'+
                ' AND Account__r.RecordType.Name = \'Outlet\'';
        }
        else{
            //When there is no market cycle present in system for that country
            queryString = 'SELECT Id FROM Call__c LIMIT 0';
        }
        return Database.getQueryLocator(queryString);
    }
    //execute method
    public void execute(Database.BatchableContext bc, List<Call__c> calls){   
        //System.debug('Heap Size'+ Limits.getHeapSize());
        //Map<Id,Integer>countOfCallsForEachUser = new Map<Id,Integer>();
        Map<Id,KPI_Achivement__c> userwithKpi=new Map<Id,KPI_Achivement__c>();
        try{
            if(calls!=null){
                //The Number of Calls performed by each of the quality reps is stored as a map where the key is his or her id and the value is the number of calls
                for(Call__c call:calls)   
                {
                    if(call.Call_Performed_By__r.Profile.Name == qualityRep && call.Last_Visit_from_Mobile__c == true){
                        if(!countOfCallsForEachUser.containsKey(call.Call_Performed_By__c))
                            countOfCallsForEachUser.put(call.Call_Performed_By__c,1);//If a new user has been observed while traversing the query
                        else
                            countOfCallsForEachUser.put(call.Call_Performed_By__c,countOfCallsForEachUser.get(call.Call_Performed_By__c)+1);                                                                                                      
                    }
                }
                system.debug('Count-- '+countOfCallsForEachUser.keyset());
                //We store the kpi achievement records as a map where the key is the user id and the value is the kpi object
                for(KPI_Achivement__c kpi:[Select ID,Achievement__c,Actual_Numerator__c,RecordTypeId,
                                           Unique_Key__c,User__c,Country__c,Country__r.Code__c 
                                           FROM KPI_Achivement__c where RecordTypeId=:userKPIRecordTypeId 
                                           AND Country__r.Code__c=:countryCode 
                                           AND User__r.Profile.Name = : qualityRep
                                           AND KPI_Type__c= :NUMBER_OF_VISITS_STR and User__c != null])
                {
                    userwithKpi.put(kpi.User__c,kpi);                        
                }
                //Null check for countOfCallsForEachUser Map
                if(countOfCallsForEachUser!=null && countOfCallsForEachUser.size()>0)
                {
                    for(Id callperformedBy : countOfCallsForEachUser.keySet())    
                    {
                        KPI_Achivement__c userkpirecord=new KPI_Achivement__c();
                        if(userwithKpi.containsKey(callperformedBy))    
                            userkpirecord = userwithKpi.get(callperformedBy);//If there is already a kpi record for a particular user
                        userkpirecord.RecordTypeId=userKPIRecordTypeId;
                        userkpirecord.KPI_Type__c= NUMBER_OF_VISITS_STR;
                        userkpirecord.Achievement__c=countOfCallsForEachUser.get(callperformedBy);
                        userkpirecord.Actual_Numerator__c=countOfCallsForEachUser.get(callperformedBy);
                        userkpirecord.Unique_Key__c=callperformedBy+'_'+NUMBER_OF_VISITS_STR;
                        userkpirecord.Country__c= countryRecord; 
                        userkpirecord.User__c=callperformedBy;
                        userwithKpi.put(callperformedBy,userkpirecord);
                    }
                    if(userwithKpi != null && !userwithKpi.isEmpty() 
                       && Schema.sObjectType.KPI_Achivement__c.iscreateable() 
                       && Schema.sObjectType.KPI_Achivement__c.isUpdateable())//Check if the Records of the KPI Achievement Object can be created and inserted
                    {
                        Database.upsert(userwithKpi.values(),KPI_Achivement__c.Unique_Key__c);    
                    }    
                }            
            }
            
            List<Call__c> callsList = new List<Call__c>();
            List<Outlet_KPI_Achievement__c> masterOuletKPIAchievementList= new List<Outlet_KPI_Achievement__c>();
            if(calls != null && calls.size()>0){
                for(Call__c callObj : calls){    
                    if(callObj.Type_of_Call__r.Global_Equivalent_Call_Type__c =='Physical'){
                        callsList.add(callObj);
                    }
                }
                masterOuletKPIAchievementList = EDGE_CoverageOutletKPIAchivHelper.coverageComplianceOutletKPIMethod(callsList,countryCode);
                if(masterOuletKPIAchievementList != null && masterOuletKPIAchievementList.Size()>0){
                    List<Database.UpsertResult> dsrList = Database.upsert(masterOuletKPIAchievementList,false);
                }
            }
            System.debug('Heap Size at End'+ Limits.getHeapSize());
        }
        catch(DmlException de){
            System.debug('DML Exception Stack Trace'+ de.getStackTraceString());
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
            
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UserVisitsKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}