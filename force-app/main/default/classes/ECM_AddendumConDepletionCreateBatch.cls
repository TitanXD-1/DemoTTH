/*
@Name: ECM_AddendumConDepletionCreateBatch
@Purpose: This batch is to send email notification to the owner of a contract when the expiry period for the contract starts

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Suvendu Roy       25/10/2022        Initial Development (ECM-6220) Scope of this batch is 1 as there can be huge depletion data per contract

*/
public class ECM_AddendumConDepletionCreateBatch implements Database.Batchable<sObject>, Database.Stateful,BatchJobManagementInterfaceClass{
    String exceptionMsg = '';
    Boolean hasError = false ;
    String countryCode = '';
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    
    /*
* @description : get the batch detail for corresponding market 
* @return : void
* @param : Market_Batch_Setting Metadata
*/
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        Id outletRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id groupRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        String contractQuery = 'SELECT Id,RecordTypeId,ECM_Parent_Contract__c,Account.Country__r.code__c';
        String conditionQuery = ' FROM Contract WHERE ECM_Amended__c = true AND Status = \'Active\' AND LastModifiedDate = TODAY ' 
            + 'AND ECM_Parent_Contract__c != null AND Account.Country__r.code__c =: countryCode '
            + 'AND (RecordTypeId=:outletRecTypeId OR RecordTypeId=:groupRecTypeId)';
        String query = contractQuery + conditionQuery;
        return Database.getQueryLocator(query);
        
    }
    
    public void execute(Database.BatchableContext bc, List<Contract> contractList){
        if(contractList != null){
            Map<Id,Contract> reqConMap = new Map<Id,Contract>();
            Map<Id,Contract> contractMap = new Map<Id,Contract>(contractList);
            Map<Id,Depletions__c> depMap = new Map<Id,Depletions__c>();
            Map<Id,Id> parChilConMap = new Map<Id,Id>();
            for(Depletions__c depObj : [SELECT Contract__c,ECM_Product__c,Id 
                                        FROM Depletions__c 
                                        WHERE Contract__c IN: contractMap.keySet()]){ 
                                            depMap.put(depObj.Contract__c,depObj);
                                        }
            for(Id conObjId : contractMap.keySet()){
                if(!depMap.containsKey(conObjId)){
                    reqConMap.put(conObjId,contractMap.get(conObjId));
                    //Always only one child contract can be activated for one Parent Contract
                    //though the relationship one parent contract can be associated with Multiple Child Contarct
                    parChilConMap.put(contractMap.get(conObjId).ECM_Parent_Contract__c,conObjId);
                }
            }
            if(!parChilConMap.isEmpty()){
                ECM_AddendumConDepletionCreateHelper.addendumCreate(parChilConMap);
            }
        }
    }
    /*
* @description : finish method of batch
* @return : void
* @param : Database.BatchableContext
*/
    public void finish(database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_AddendumContractDepletionUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}