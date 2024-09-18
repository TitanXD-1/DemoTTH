/**************************************************************************************
Name: EDGE_ContractStatusUpdateBatch 
=======================================================================================
Purpose:3148- 1.Contract to be made Inactive if End date is less than today and UOS Earnt is 
greater than UOS Target.Also related outlet contracts to be made Inactive
3149- 2.The Contract will be extended based on the Market Settings and Extended 
checkbox will be marked as true and set the Original End Date
3150-3.The Contract should remain active , based on the extended End Date
========================================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder       19/07/2019         ES20-3148,3149,3150
2.0         Monalisa Halder       19/09/2019         ES20-4141
3.0	   	    Kapil Baliyan		  30/12/2019		 Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
***********************************************************************/
public with sharing class EDGE_ContractStatusUpdateBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode ;
    string responseMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        datetime dt = System.now()-1;
        
        String queryString = 'SELECT Id, AccountId, Account.Country__c, Account.Country__r.Code__c, UOS_Earnt__c, UOS_Target__c, Extended__c,' +
            ' Contract_End_Date__c,Original_End_Date__c,Status FROM Contract'+
            ' WHERE Contract_End_Date__c < Today and  Status = \'Active\' and Account.Country__r.Code__c =:countryCode';
        
        return Database.getQueryLocator(queryString);                
    }
    
    public void execute(Database.BatchableContext bc, list<Contract> contractList){
        Set<Id> inactiveContractIdSet = new Set<Id>();
        List<Contract> updateContractList = new List<Contract>();
        List<Outlet_Contract__c> otContractInactiveList = new List<Outlet_Contract__c>();
        String frequency;
        try{
            if(contractList != null && contractList.size() > 0){
                // Finding the Contract Extension Frequency for the country
                List<Market_Setting__c> marketSettingsList = [select A_P_Contract_Extension_Frequency__c, Geography__r.Code__c from Market_Setting__c where Geography__r.Code__c =:countryCode];
                if(marketSettingsList != null && marketSettingsList.size()>0 ){
                    frequency = marketSettingsList[0].A_P_Contract_Extension_Frequency__c;  
                }
                
                for(Contract contractUpdate : contractList){
                    if((contractUpdate.UOS_Earnt__c == null || contractUpdate.UOS_Earnt__c < contractUpdate.UOS_Target__c )  && frequency != null){  
                        //If the frequency is not blank in market settings and update the contract status as Active, Extended as true and Update Contract End Date and Original End Date
                        contractUpdate.Extended__c = true;
                        if(contractUpdate.Original_End_Date__c == null){
                            contractUpdate.Original_End_Date__c = contractUpdate.Contract_End_Date__c;
                        }
                        
                        if(frequency == 'Weekly'){
                            contractUpdate.Contract_End_Date__c = contractUpdate.Contract_End_Date__c.addDays(7);  
                        }else if(frequency == 'Monthly'){
                            contractUpdate.Contract_End_Date__c = contractUpdate.Contract_End_Date__c.addDays(30);
                        }
                        updateContractList.add(contractUpdate);
                    }
                }
                
                if(updateContractList != null && updateContractList.size()>0){
                    system.debug('@@updateContractList' +updateContractList);
                    database.update(updateContractList,false);   
                }
            }
        }
        catch(Exception ex){
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ContractStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', responseMsg);
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
    }   
}