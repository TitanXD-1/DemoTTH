/*
 * Name: EDGE_ComplianceMetricResetBatch
 * Req: Reseting ComplianceMatrix related fields on outlet as 0 when new market cycle isstarting for a particular market
 * User Story : ES20-4300
 * History                                                                                           
 * VERSION   AUTHOR                   DATE              DETAIL
 * 1.0       Anuja Chattopadhyay      29/10/2019        Reseting ComplianceMetric related fields on outlet as 0 when new market cycle isstarting for a particular market
 * 2.0		 Sagar Barman			  11/07/2020		ES20-6537 Update/copy the base achievement score of KPI Achievements with the achievement at the start date of the Market cycleA	
 * 3.0       Amar Deep                24/07/2020        ES20-8352
 * 4.0       Amar Deep                19/08/2020        ES20-8489 To calculate physical and virtual call frequency
 * 5.0		 Saranya L/Geethika 	  26/10/2022		ES20-13409 changed the reset of total virtual calls from monthly to market cycle
 * 6.0       Joshraj Sen              12/01/2023        ES20-13725 To Optimise the Number Of Calls Generated 
*/
public class EDGE_ComplianceMetricResetBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    public Market_Batch_Setting__mdt batchSetting;
    string countryCode = '';
    List<Market_Cycle__c> marketCycleRecord ;
    Date actvMarketCycleStartDate;
    Date actvMarketCycleEndtDate;
    Date today;
    public boolean dateMatch = false;
    Decimal numOfworkingDay = 0.0;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    //ES20-8247
    public boolean firstDayOfMonthMatch = false;
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //List<sobject> accList= new List<sobject>();
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        countryCode = batchSetting.Country_Code__c;
        today = Date.today();
        marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1] ;
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndtDate = marketCycleRecord[0].End_Date__c; 
            numOfworkingDay =  marketCycleRecord[0].Number_Of_Working_Day__c;
        }
        
        if(actvMarketCycleStartDate == today){
            dateMatch = true;  
        }
        System.debug(LoggingLevel.Debug,'--dateMatch--'+dateMatch);
        //ES20-8247
        /*if(today.day() == Integer.valueOf(System.Label.EDGE_Virtual_Call_Reset_Day)){
            firstDayOfMonthMatch = true;
        }*/
        
        String queryString = '';
        
        //ES20-8247 : Start
        if(dateMatch){//ES20-13409
            queryString = 'SELECT Id,Actual_Visits__c,Capped_Visits__c,Expected_Visits__c,Country__r.Code__c,Outlet_Visit_Prioritisation_Grade__c,Outlet_Visit_Prioritisation_Grade__r.Days_between_visit__c,Total_Virtual_Calls__c,Primary_Sales_Territory__c,Primary_Sales_Territory_Region__c,Primary_Sales_Area__c,Actual_Physical_Call_Market_Cycle__c,Actual_Virtual_Call_Market_Cycle__c,Virtual_Visit_Frequency__c,Physical_Visit_Frequency__c,Outlet_Visit_Prioritisation_Grade__r.Min_Physical_Call_Per_Market_Cycle__c,Outlet_Visit_Prioritisation_Grade__r.Min_Virtual_Call_Per_Market_Cycle__c FROM ACCOUNT WHERE RecordType.name =\'Outlet\' AND Country__r.Code__c = \'' + countryCode + '\'' ;
        }/*else if(!dateMatch && firstDayOfMonthMatch){ 
            queryString = 'SELECT Id,Total_Virtual_Calls__c FROM ACCOUNT WHERE RecordType.name =\'Outlet\' AND Country__r.Code__c = \'' + countryCode + '\'' ;
        }else if(dateMatch && !firstDayOfMonthMatch){ 
            queryString = 'SELECT Id,Actual_Visits__c,Capped_Visits__c,Expected_Visits__c,Country__r.Code__c,Outlet_Visit_Prioritisation_Grade__c,Outlet_Visit_Prioritisation_Grade__r.Days_between_visit__c,Primary_Sales_Territory__c,Primary_Sales_Territory_Region__c,Primary_Sales_Area__c,Actual_Physical_Call_Market_Cycle__c,Actual_Virtual_Call_Market_Cycle__c,Virtual_Visit_Frequency__c,Physical_Visit_Frequency__c,Outlet_Visit_Prioritisation_Grade__r.Min_Physical_Call_Per_Market_Cycle__c,Outlet_Visit_Prioritisation_Grade__r.Min_Virtual_Call_Per_Market_Cycle__c FROM ACCOUNT WHERE RecordType.name =\'Outlet\' AND Country__r.Code__c = \'' + countryCode + '\'' ;
        }*/else{
            queryString = 'SELECT Id FROM Account Limit 0'; //Adding dummy query to run the batch with 0 data.
        }
        //ES20-8247 : End
        
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Account> accountList){  
        Set<Id> territoryIdSet = new Set<Id>();
        try{
            if(accountList!=null){
                //Set<Id> outletIdSet = new Set<Id>();
                //Map<Id,Id> outletVisitPrioritizationMap = new Map<Id,Id>();
                //Map<Id,Decimal> daysBtwnVisitPrioritizationMap = new Map<Id,Decimal>();
                Map<Id,Integer> accountPlannedCallMap = new Map<Id,Integer>();
                Integer count = 0; 
                for(AggregateResult  callRecord : [SELECT count(Id) calls,Account__c AccountId FROM Call__c WHERE
                                          Status__c = 'Planned' AND Account__c IN :accountList AND DAY_ONLY(Plan_Start_Date__c) >= :actvMarketCycleStartDate
                                          AND DAY_ONLY(Plan_End_Date__c)  <=:actvMarketCycleEndtDate GROUP BY Account__c ])
                {
                        count=(Integer)callRecord.get('calls');
                        Id accountId=(Id)callRecord.get('AccountId');
                        accountPlannedCallMap.put(accountId,count);
                    
                    }
                System.debug(LoggingLevel.Debug,'--dateMatch--'+dateMatch);
                //Resetting account Compliance Metric related fields
                for(Account accntObj:accountList){
                    
                    //ES20-8247 : Resetting Virtual Calls Count related fields at the start of a Calendar Month                    
                   /* if(firstDayOfMonthMatch){ES20-13409
                        accntObj.Total_Virtual_Calls__c = 0;
                    }
                    */
                    //ES20-8247 : Run the following code only when the current day is Market Cycle Start Day                    
                    if(dateMatch){
                        accntObj.Total_Virtual_Calls__c = 0;//ES20-13409
                        accntObj.Actual_Visits__c = 0;
                        accntObj.Number_Of_Planned_Calls_Completed__c = 0;
                        accntObj.Actual_Physical_Call_Market_Cycle__c = 0;  
                        accntObj.Actual_Virtual_Call_Market_Cycle__c = 0;
                        //calculation for Physical Visit Frequency
                        decimal phyVisitCall = EDGE_UtilityClass.checkForNull(accntObj.Outlet_Visit_Prioritisation_Grade__r.Min_Physical_Call_Per_Market_Cycle__c) != 0 ? accntObj.Outlet_Visit_Prioritisation_Grade__r.Min_Physical_Call_Per_Market_Cycle__c : 1;
                        decimal physicalVisitFrequency =  numOfworkingDay/phyVisitCall;
                        accntObj.Physical_Visit_Frequency__c = physicalVisitFrequency.intValue();
                        
                        //calculation for Virtual Visit Frequency
                        decimal minVirtualCall = EDGE_UtilityClass.checkForNull(accntObj.Outlet_Visit_Prioritisation_Grade__r.Min_Virtual_Call_Per_Market_Cycle__c) != 0 ? accntObj.Outlet_Visit_Prioritisation_Grade__r.Min_Virtual_Call_Per_Market_Cycle__c : 1;
                        decimal virtualVisitFrequency =  numOfworkingDay/minVirtualCall;
                        accntObj.Virtual_Visit_Frequency__c = virtualVisitFrequency.intValue();
                        
                        if(accntObj.Outlet_Visit_Prioritisation_Grade__r.Days_between_visit__c!=null){
                            decimal expectedVisit = numOfworkingDay/accntObj.Outlet_Visit_Prioritisation_Grade__r.Days_between_visit__c;
                            accntObj.Expected_Visits__c= expectedVisit.setscale(0);
                        } 
                        
                        if(accountPlannedCallMap!=null && accountPlannedCallMap.containsKey(accntObj.Id)){
                            accntObj.Number_Of_Planned_Calls__c = accountPlannedCallMap.get(accntObj.Id);  
                        }
                        //If there is no planned call is loaded in the system reset previous month's value with 0
                        else if (!accountPlannedCallMap.containsKey(accntObj.Id)){
                            accntObj.Number_Of_Planned_Calls__c = 0;
                        }   
                        //taking the Territory and TerritoryHierarchy Ids from Account ES20-6537
                        if(null != accntObj.Primary_Sales_Territory__c){
                            territoryIdSet.add(accntObj.Primary_Sales_Territory__c);
                        }
                    }
                } 
                //Update Account records
                if(Schema.sObjectType.Account.isUpdateable()){
                    database.update(accountList,False);
                }
            }
               if(Test.isRunningTest()){
              throw new EDGE_GenericException();
          }
      }catch(DmlException de){
           hasError = true;
           Integer numErrors = de.getNumDml();
           for(Integer i=0; i<numErrors; i++) {
               exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
           }
       }catch(Exception ex) {
           hasError = true;
           exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
       }
   }
     //Finish Method - Update ES20-6594
   public void finish(Database.BatchableContext bc){
        
       //Get Batch Job
       Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
          //Check whether Batch Job has been updated by Batch Platform Event or Not
       if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
           hasError = true;
       }
         //Update Batch Job Status
       if(hasError){
           EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ComplianceMetricResetBatch', exceptionMsg);
       }else{
           EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
       }
         //Schedule Next Batch from Batch Utility Class
       if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
   }}