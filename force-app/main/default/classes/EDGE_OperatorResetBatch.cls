/*
* @Name: EDGE_OperatorResetBatch

* @Req: Reseting Operator fields
* @User Story : ES20-8499,8602,8500

* @History                                                                                                                       
* @VERSION   AUTHOR              DATE            STORY/DETAIL
* 1.0       Monalisa Halder     22/09/2020      ES20-8499,8602,8500Reseting Operator JSON fields
* 2.0       Prasanth T     		16/01/2023      ES20-13732 Changing update list to a Map to avoid apex cpu limit

**/
public class EDGE_OperatorResetBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    public Market_Batch_Setting__mdt batchSetting;
    string countryCode = '';
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
   
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(23);
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        countryCode = batchSetting.Country_Code__c;
       
        String queryString = 'SELECT Id,Closed_Cycle_Brief_Opp__c,Cycle_Brief_Opportunities__c,Open_Cycle_Brief_Opp__c,Outlet_Calls_List__c,Country__r.Code__c,IsOperator__c,Activation_Survey_KPI_List__c FROM ACCOUNT WHERE IsOperator__c = true AND Country__r.Code__c = \'' + countryCode + '\'' ;
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Account> accountList){ 
        Map<Id,Account> accountIdMap = new Map<Id,Account>();
        try{
            if(accountList!=null){
              
                //Resetting operator fields
                for(Account accntObj:accountList){
                    accntObj.Open_Cycle_Brief_Opp__c = 0;
                    accntObj.Closed_Cycle_Brief_Opp__c = 0;
                    accntObj.Cycle_Brief_Opportunities__c = '';
                    accntObj.Outlet_Calls_List__c = '';
                    accntObj.Outlet_Calls_List2__c = '';
                    accntObj.Outlet_Calls_List3__c = '';
                    accntObj.Outlet_Calls_List4__c = '';
                    accntObj.Outlet_Calls_List5__c = '';
                    accntObj.Activation_Survey_KPI_List__c = '';
                    //ES20-13732
                    if(!accountIdMap.containsKey(accntObj.Id)){
                        accountIdMap.put(accntObj.Id,accntObj);
                    }else{
                        accountIdMap.remove(accntObj.Id);
                        accountIdMap.put(accntObj.Id,accntObj);
                    }
                    
                } 
                //Update Account records
                if(Schema.sObjectType.Account.isUpdateable()){
                    database.update(accountIdMap.values(),true);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OperatorResetBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}