/*
*@Name: ECM_AnP_PlanningCalcBatch
*@Test Class: ECM_AnP_PlanningCalcBatchTest
*@Description: This class is used to Upsert A&P Planning Object records with the following equal split calculations (considering Calendar Year Split)
*@History                                                            
*
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Saurav Prasad		24/07/2023			Initial Development - 143389 : Creation of A&P screen records for Active/Expired contract and equal split of A&P
*1.1			Shivam Chauhan		07/08/2023				143947
*/
public class ECM_AnP_PlanningCalcBatch  implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
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
    /**
	* @description : start - start method for the Batch
	* @return : List<contract items> 
	* @param : Database.BatchableContext
	*/
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<String> contractStatus = Label.ECM_AnP_PlanningContractStatus.split(',');
        List<String> conRecordTypeNames = Label.ECM_AnP_PlanningContractRecordTypes.split(',');
        System.debug(LoggingLevel.INFO,'contractStatus @'+contractStatus);
        System.debug(LoggingLevel.INFO,'conRecordTypeNames @'+conRecordTypeNames);
        String query=  	'SELECT Id,ContractNumber,Status,ECM_A_P_Records_Created__c,AccountId,ECM_Duration__c,Account.country__r.Code__c,'+
            +' StartDate, Contract_End_Date__c, ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c,RecordType.Name,'+
            +' (SELECT Id,ECM_Product__r.Product__c,ECM_Contract__c,ECM_Contract__r.AccountId,ECM_Contract__r.ECM_Duration__c,ECM_TotalAnP_incl_Indirect__c, '+
            +' ECM_Contract__r.Account.country__r.Code__c,ECM_Contract__r.StartDate,ECM_Contract__r.Contract_End_Date__c,ECM_Phasing_Forecast_Total__c, '+
            +' ECM_Paid_A_P_Total__c  FROM Contract_Items__r WHERE ECM_Product__c != Null AND ECM_Product__r.Product__c != Null ) FROM Contract'+ 
            +' WHERE Account.country__r.Code__c =: countryCode AND RecordType.Name IN: conRecordTypeNames AND ECM_Duration__c!=NULL AND'+
            +' Status IN: contractStatus AND ECM_A_P_Records_Created__c=false AND ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c=true';
        system.debug(LoggingLevel.DEBUG,'query--->'+query);
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description : execute - execute method for the Batch
    * @return : void
    * @param : Database.BatchableContext, List<ECM_Contract_Item__c> 
    */
    
    public void execute(Database.BatchableContext bc, List<Contract> scope){
        Map<Id,ECM_Contract_Item__c> mapOfCI = new Map<Id,ECM_Contract_Item__c>();
        Map<Id,Contract> contractMap = new Map<Id,Contract>();
        List<ECM_A_P_Planning__c> listOfAnPRecords = new List<ECM_A_P_Planning__c>();
        List<String> fieldSetAPINames = System.Label.ECM_AnP_PlanningFieldSets.split(';');//ECM_Forcast_Field_Set;ECM_Paid_Field_Set
        Schema.FieldSet fsForecast = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[0]);
        Schema.FieldSet fsPaid = Schema.SObjectType.ECM_A_P_Planning__c.fieldSets.getMap().get(fieldSetAPINames[1]);
        Map<Integer,Schema.FieldSetMember> forecastFieldSetMap = new Map<Integer,Schema.FieldSetMember>();
        Map<Integer,Schema.FieldSetMember> paidFieldSetMap = new Map<Integer,Schema.FieldSetMember>();
        
        set<Id> exclusionConIds = new set<Id>();
        
        try{
            //Controller initialization 
            ECM_AnP_PlanningCalcBatchCtrl controller = new ECM_AnP_PlanningCalcBatchCtrl();
            //Structuring Forecast Map
            controller.getSchemaFieldSet(fsForecast,forecastFieldSetMap);
            
            //Structuring Paid Map
            controller.getSchemaFieldSet(fsPaid,paidFieldSetMap);
            
            //Get All Contract Items
            controller.getContractAndCIMap(scope, contractMap, mapOfCI);
            
            //get list of AnP Records
            listOfAnPRecords.addAll(controller.getListofAnPRecords(mapOfCI,forecastFieldSetMap,paidFieldSetMap));
            
            Database.SaveResult[] srList = Database.insert(listOfAnPRecords, false);
            
            ECM_AnP_PlanningCalcBatchCtrl.ResultWrapper resultWrap =  controller.getResults(srList, listOfAnPRecords, mapOfCI);
            
            System.debug(LoggingLevel.DEBUG, 'resultWrap @'+resultWrap);
            String tempString = resultWrap.exceptionMsg;
            hasError = resultWrap.hasError;
            exclusionConIds.addAll(resultWrap.exclusionIds);
            
            if(hasError){
                exceptionMsg += 'Line# ' + '128' +' \n ' +tempString;
            }
            
            for(Id conId : contractMap.keySet()){
                if(!exclusionConIds.contains(conId)){
                    contractMap.get(conId).ECM_A_P_Records_Created__c = true;
                }
            }
            if(!contractMap.isEmpty()){
                Database.update(contractMap.values());
            }
            if(!mapOfCI.isEmpty()){//143947
                Database.update(mapOfCI.values());
            }
            
            
        }catch(Exception ex) {
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
        String reducedExceptionMsg = '';
        
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            reducedExceptionMsg = (exceptionMsg != null  && exceptionMsg.length() >= 32768)? exceptionMsg.substring(0, 32768): exceptionMsg; 
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_AnP_PlanningCalcBatch', reducedExceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }

}