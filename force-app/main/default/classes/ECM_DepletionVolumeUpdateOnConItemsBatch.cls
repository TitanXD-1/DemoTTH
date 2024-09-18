/*
* Name: ECM_DepletionVolumeUpdateOnConItemsBatch
* Purpose: This is Class for fetch required data for Depletion volume to update on contract item
* History                                                            
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	Anivesh Muppa        	14/05/2020        	Initial Development
1.1      	Anivesh Muppa        	22/12/2020       	Requirement per ECM-3615
1.2      	Anivesh Muppa        	07/06/2021        	Requirement per ECM-4447
1.3		 	Pratap and Subhrojit	25/03/2022			Requirement per ECM-5352 : Modify Calculation Logic of Actual Volume CTD at Contract Item
1.4         Pratap and Subhrojit    12/04/2022          Requirement per ECM-5314 : Logic for Actual Volume CTD field at Contract Item object_Australia & Code Re-structure
1.5         Pratap Sen              12/05/2022          Requirement per ECM-5527 : Updated logic for actualVolumeCTDEU() & the batch query
1.6         Pratik Somani           07/11/2022          Requirement per ECM-6315 : Migrating Actual Volume CTD KPI from Parent to child contract_SFDC_EU
1.7         Tanishq/Anshu           25/01/2023          Requirement per ECM-6709 : Fix the batch (ECM_DepletionVolumeUpdateOnConItemsBatch)_Tech Debt
1.8			Rajarshi/Mayukh			31/05/2023			ES20-14043
1.9         Mayukh                  30/06/2023          142290
*/

public with sharing class ECM_DepletionVolumeUpdateOnConItemsBatch implements Database.Batchable<SObject>,Database.RaisesPlatformEvents, Database.Stateful,BatchJobManagementInterfaceClass{
    String exceptionMsg = '';
    Boolean hasError = false ;
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }    
    
    /**
	* @description : start - start method for the Batch
	* @return : List<contract items> 
	* @param : Database.BatchableContext
	*/
    
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        String countryCode = batchSetting.Country_Code__c;
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        List<String> statusValuesAU = new List<String>();
        List<String> statusValuesEU = new List<String>();
        List<String> conRecordTypeNames = new List<String>();
        
        statusValuesAU = Label.ECM_Contract_Status.split(','); //Lost,Won,Cancelled
        statusValuesEU = Label.ECM_ContractStatusForActualVolumeYTDBatch.split(','); //Active,Expired,Closed
        conRecordTypeNames = Label.ECM_ActualVolumeYTDBatchConRecordType.split(','); //Outlet,Group
        String queryString = '';
        queryString = 'SELECT Id,ECM_Parent_Actual_Volume_CTD__c,ECM_Product__r.Product__c,ECM_Contract__c,ECM_Contract__r.ECM_Select_UoM__c,ECM_Contract__r.ECM_Amended__c,ECM_Contract__r.AccountId,'+
            			+'ECM_Actual_Volume_YTD__c,ECM_Contract__r.Account.country__r.Code__c,ECM_Contract__r.ECM_Payment_Frequency__c,ECM_Contract__r.StartDate,ECM_Contract__r.Original_End_Date__c '+
            			+'FROM ECM_Contract_Item__c WHERE ECM_Contract__r.Account.country__r.Code__c =: countryCode AND ECM_Contract__r.RecordType.Name IN: conRecordTypeNames AND ECM_Product__c != Null '+
            			+'AND ECM_Product__r.Product__c != Null';
        
        String conditionQueryAU = ' AND ECM_Contract__r.Status NOT IN: statusValuesAU Order By ECM_Contract__r.StartDate ASC';
        String conditionQueryEU = ' AND ECM_Contract__r.Status IN: statusValuesEU ORDER BY CreatedDate ASC';
		
        queryString = (Label.ECM_CountryCodeAU.contains(countryCode)) ? (queryString + conditionQueryAU):(queryString + conditionQueryEU);
        
        return Database.getQueryLocator(queryString);                        
    }
    
    /**
    * @description : execute - execute method for the Batch
    * @return : void
    * @param : Database.BatchableContext, List<ECM_Contract_Item__c> 
    */
    
    public void execute(Database.BatchableContext bc, List<ECM_Contract_Item__c> scope){
        try{
			 if(scope != null && scope[0].ECM_Contract__r.Account != Null){
                if(Label.ECM_CountryCodeAU.contains(scope[0].ECM_Contract__r.Account.country__r.Code__c)){
                    ECM_DepletionVolumeOnConItemsBatchHelper.actualVolumeCTDAUS(scope); 
                }
                else{
                    ECM_DepletionVolumeOnConItemsBatchHelper.actualVolumeCTDEU(scope);
                }
            }
        }
        catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_DepletionVolumeUpdateOnconitemBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }
}