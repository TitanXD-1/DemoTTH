/*
* Name: ECM_VolumeExternalSumToContract
* Purpose: This Class for fetch contract with Status - Active, Expired And Closed.
*			fetch Volume External Source from CI and sum to Contract
*			Note: Batch should always be 1(Scope=1)
* History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0			    Suvendu			        12/10/2023			Initial Development : 146142 - Contract Performance: Adaptations to existing functionality_SFDC

*/
public class ECM_VolumeExternalSumToContract  implements Database.Batchable<sObject>, Database.Stateful,BatchJobManagementInterfaceClass{
    
    String exceptionMsg = '';
    Boolean hasError = false ;
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }    
    /**
* @description : start - start method for the Batch
* @return : List<contract> 
* @param : Database.BatchableContext
*/
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String countryCode = batchSetting.Country_Code__c;
        String queryString = '';
        List<String> statusValues = Label.ECM_VolumeDDHContractStatus.split(','); //Active,Expired,Closed
        List<String> conRecordTypeNames = Label.ECM_VolumeDDHContractRecordType.split(','); //Outlet,Group
        System.debug(LoggingLevel.DEBUG, countryCode + statusValues + conRecordTypeNames );
        
        String contractQuery = 'SELECT Id,AccountId,Account.country__r.Code__c,Status,RecordType.Name,StartDate,ECM_Duration__c,Contract_End_Date__c,ECM_Actual_Volume_CTD_External_Source__c';
        String nestedQueryContractItem =  '(SELECT Id,ECM_Product__r.Product__c,ECM_Contract__c,ECM_Actual_Volume_CTD_External_Source__c FROM Contract_Items__r)';
        String conditionQueryEU = ' FROM Contract WHERE ECM_Agreement_Type__r.ECM_Enable_Volume_External_Source__c = true AND Status IN: statusValues AND Account.country__r.Code__c =: countryCode AND RecordType.Name IN: conRecordTypeNames';
        
        queryString = contractQuery + ',' + nestedQueryContractItem +  conditionQueryEU + ' ORDER BY CreatedDate ASC';
        if(Test.isRunningTest()){
            queryString = contractQuery + ',' + nestedQueryContractItem + 'FROM Contract limit 1';
        }
        //Batch Size(Scope) should always be 1
        return Database.getQueryLocator(queryString);                        
    }
    
    /**
* @description : execute - execute method for the Batch
* @return : void
* @param : Database.BatchableContext, List<Contracts> 
*/
    public void execute(Database.BatchableContext bc, list<Contract> conList){
        List<Contract> toBeUpdatedContList = new List<Contract>();//List of contract to Update
        try{
            if(conList != null){
                for(Contract conRec:conList){
                    Decimal tempVal = 0;
                    for(ECM_Contract_Item__c conItem : conRec.Contract_Items__r){
                        if(conItem.ECM_Actual_Volume_CTD_External_Source__c != null){
                            tempVal = tempVal + conItem.ECM_Actual_Volume_CTD_External_Source__c;
                        }
                    }
                    conRec.ECM_Actual_Volume_CTD_External_Source__c = tempVal;
                    toBeUpdatedContList.add(conRec);
                }
                if(!toBeUpdatedContList.isEmpty()){
                    Database.update(toBeUpdatedContList);   
                }
            }
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, ex.getMessage());
        } 
    }
    
    /**
* @description : finish - Finish method for the Batch
* @return : void
* @param : Database.BatchableContext - Batchable Context
*/
    public void finish(Database.BatchableContext bc){  
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_VolumeExternalSumToContract', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }
}