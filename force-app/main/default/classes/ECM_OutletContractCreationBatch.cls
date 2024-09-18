/*
*@Name: ECM_OutletContractCreationBatch
*@Description: Create new Outlet Contract when there is new Outlet on Operator
* History                                                            
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	Ravi Kant        	   4/07/2022        	Initial Development
2.0			Saurav Paul				31/08/2022			Changes for ECM-5971
3.0			Sudipta Nandy		   26/10/2023			US-3408243 -- CHG0195284 Add filter criteria in Account query to fetch outlets ony
*/

global class ECM_OutletContractCreationBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';

    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<String> recordtyes = Label.ECM_OutletContractCreation_Recordtype.split(',');//Added for ECM-5971
        String query='SELECT Id,AccountId FROM Contract WHERE Status=\'Active\' AND ECM_Applicable_for_all_Outlets__c = true AND recordType.Name IN: recordtyes AND AccountId != null '+ 
        'AND Account.IsOperator__c = true AND Account.country__r.Code__c =: countryCode';
        System.debug('query::'+ query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Contract> contractRecords){
        try{
            List<Outlet_Contract__c> listNewOutletContracts = new List<Outlet_Contract__c>();
            Set<Id> operatorIds = new Set<Id>();
            Set<Id> contractIds = new Set<Id>();
            Map<Id,Set<Id>>mapContractIdWithOutletContractOutletIds = new Map<Id,Set<Id>>();
            Map<Id,set<Id>> mapAccountIdWithContractIds = new Map<Id,set<Id>>();

            for(Contract groupCont: contractRecords){
                contractIds.add(groupCont.Id);
                operatorIds.add(groupCont.AccountId);
                if(mapAccountIdWithContractIds.containsKey(groupCont.AccountId)){
                    mapAccountIdWithContractIds.get(groupCont.AccountId).add(groupCont.Id);
                }else{
                    mapAccountIdWithContractIds.put(groupCont.AccountId, new Set<Id>{groupCont.Id});
                }
            }
            system.debug('contractIds:: '+ contractIds);
            System.debug('operatorIds:: '+operatorIds);
            System.debug('mapAccountIdWithContractIds:: '+mapAccountIdWithContractIds);

            for(Outlet_Contract__c outletCon : [Select Id,Outlet__c,Contract__c from Outlet_Contract__c where Status__c='Active' and Contract__c In:contractIds]){
                if(mapContractIdWithOutletContractOutletIds.containsKey(outletCon.Contract__c)){
                    mapContractIdWithOutletContractOutletIds.get(outletCon.Contract__c).add(outletCon.Outlet__c);
                }else{
                    mapContractIdWithOutletContractOutletIds.put(outletCon.Contract__c, new Set<Id>{outletCon.Outlet__c});
                }
            }

            System.debug('mapContractIdWithOutletContractOutletIds:: '+mapContractIdWithOutletContractOutletIds);
			//US-3408243 -- Adding filter criteria to fetch Outlets only
            for(Account outlet : [Select Id, Operator__c FROM Account where Operator__c In:operatorIds and Record_Type_Name__c = 'Outlet']){
                System.debug('Inside outlet loop');
                if(mapAccountIdWithContractIds.containsKey(outlet.Operator__c)){
                    System.debug(LoggingLevel.DEBUG, 'Inside map check');
                    for (Id conIds : mapAccountIdWithContractIds.get(outlet.Operator__c)) {
                        System.debug(LoggingLevel.DEBUG, 'Inside contracts map');
                        System.debug(LoggingLevel.debug, mapContractIdWithOutletContractOutletIds.containsKey(conIds));
                        if(mapContractIdWithOutletContractOutletIds.containsKey(conIds)){
                            if(!mapContractIdWithOutletContractOutletIds.get(conIds).contains(outlet.Id)){
                                System.debug(LoggingLevel.DEBUG, 'Inside if condition for not having matching outletContract');
                                Outlet_Contract__c newOC = new Outlet_Contract__c();
                                newOC.Outlet__c = outlet.Id;
                                newOC.Contract__c = conIds;
                                newOC.Status__c = 'Active';
                                listNewOutletContracts.add(newOC);
                            }
                        }else{
                            System.debug(LoggingLevel.DEBUG, 'Inside if condition for not having any outletContract');
                                Outlet_Contract__c newOC = new Outlet_Contract__c();
                                newOC.Outlet__c = outlet.Id;
                                newOC.Contract__c = conIds;
                                newOC.Status__c = 'Active';
                                listNewOutletContracts.add(newOC);
                        }
                    }
                }
            }
            System.debug('listNewOutletContracts:: '+listNewOutletContracts);
            if(listNewOutletContracts.size()>0){
                Database.SaveResult[] srList= Database.insert(listNewOutletContracts);
            }
        }

        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }

    global void finish(Database.BatchableContext bc){
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_NewOutletContractCreationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class
        }
    }
}