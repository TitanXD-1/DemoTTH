/********************************************************************************************
Class Name: EDGE_OperatorOutletCalcBatch

Author              Version       Date           Detail
Sandip Ghosh      	V1.0        10/09/2020     [ES20-8498]
*********************************************************************************************/
public class EDGE_OperatorOutletCalcBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    Date markCycleStartDate;
    Date markCycleEndDate;
    Map<String, Operator_KPI_Fields_Mapping__mdt> kpiFieldsMap = new Map<String, Operator_KPI_Fields_Mapping__mdt>(); 
	String queryFieldsString = '';
    Map<String, List<String>> kpiAchivementFieldsMap = new Map<String, List<String>>();
    Map<Id, Set<Account>> operatorIdToOutletsRetained = new Map<Id, Set<Account>>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(25);
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        
        //Iterating over Sales Area KPI Fields Mapping
        if(Schema.SObjectType.Operator_KPI_Fields_Mapping__mdt.isAccessible()){//Territory_Target_Fields__c, Territory_Cycle_Target_Field__c,
            for(Operator_KPI_Fields_Mapping__mdt kpiMap : [SELECT MasterLabel, Account_KPI_Field__c, Operation_Type__c, Calculation_Type__c, Relationship__c, Market_Settings_Reference__c, Check_for_Null__c, KPI_Achievement_Type__c, Dependent_Field__c, Fraction_Variant__c, Contains_Operator_KPI_Fields__c,Operator_KPI_Numerator_Field__c,Operator_KPI_Denominator_Field__c,Operator_KPI_Field__c FROM Operator_KPI_Fields_Mapping__mdt WHERE KPI_Achievement_Type__c != null AND Active__c = True]){
                //Mapping Account KPI fields with KPI Mapping instance
                kpiFieldsMap.put(kpiMap.Account_KPI_Field__c, kpiMap);
                queryFieldsString += kpiMap.Account_KPI_Field__c + ' ,';
            }
        }
        
        String queryString = 'SELECT Id, Name, Operator__c, '+ queryFieldsString.removeEnd(',') + 
                             ' FROM Account WHERE Country__r.Code__c =:countryCode and Operator__c != null AND '+
            				 ' Status__c = \'Active\'';

        System.debug('queryString = '+ queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> listOfOutlets){
        System.debug('listOfOutlets size = '+ listOfOutlets.size());
        //System.debug('listOfOutlets = '+ listOfOutlets);
        Set<Id> operatorIdSet = new Set<Id>();
        Map<Id, Set<Account>> operatorIdToOutletsMap = new Map<Id, Set<Account>>();
        Map<Id, Integer> operatorIdToOutletsCountMap = new Map<Id, Integer>();
        List<Account> outletsToBePassedToHelper = new List<Account>();
        
        for(Account outlet : listOfOutlets){
            Id operatorId = outlet.Operator__c;
            if(!operatorIdToOutletsMap.containsKey(operatorId)){
                operatorIdToOutletsMap.put(operatorId, new Set<Account>{outlet});
            }else{
                operatorIdToOutletsMap.get(operatorId).add(outlet);
            }               
        }

        if(operatorIdToOutletsMap.size() > 0){
            for(AggregateResult agResult : [Select Count(Id) noOfOutlets,Operator__r.Name operatorName,Operator__c 
                                            from Account where RecordType.Name = 'Outlet' and 
                                            Operator__c in :operatorIdToOutletsMap.keySet() 
                                            AND Status__c = 'Active' group by Operator__r.Name,Operator__c ])
            {
                operatorIdToOutletsCountMap.put((Id)agResult.get('Operator__c'), (Integer)agResult.get('noOfOutlets'));
            }
        }
        //System.debug('operatorIdToOutletsCountMap '+ operatorIdToOutletsCountMap);
        if(operatorIdToOutletsCountMap.size() > 0){
            for(Id operatorId : operatorIdToOutletsCountMap.keySet()){
                if(operatorIdToOutletsCountMap.get(operatorId) == operatorIdToOutletsMap.get(operatorId).size()){
                    outletsToBePassedToHelper.addAll(operatorIdToOutletsMap.get(operatorId));
                }else{
                    if(operatorIdToOutletsRetained.containsKey(operatorId)){
                        operatorIdToOutletsRetained.get(operatorId).addAll(operatorIdToOutletsMap.get(operatorId)); 
                    }else{
                        operatorIdToOutletsRetained.put(operatorId,operatorIdToOutletsMap.get(operatorId));
                    }
                    if(operatorIdToOutletsCountMap.get(operatorId) == operatorIdToOutletsRetained.get(operatorId).size()){
                        outletsToBePassedToHelper.addAll(operatorIdToOutletsRetained.get(operatorId));
                        operatorIdToOutletsRetained.remove(operatorId);
                    }
                }
            }
        }
            
        try{
            if(listOfOutlets!=null && listOfOutlets.size()>0){
				
                List<Account_KPI_Achievement__c> opAccKPIAchvListToUpdate = EDGE_OperatorKPIAchivementOperations.calculateKPIAchivements(operatorIdToOutletsMap.keySet(), outletsToBePassedToHelper, countryCode);

                //update operators
                if(opAccKPIAchvListToUpdate!=null && opAccKPIAchvListToUpdate.size()>0 && Schema.sObjectType.Account_KPI_Achievement__c.isUpdateable()){
                    system.debug('@@opAccKPIAchvListToUpdate' + opAccKPIAchvListToUpdate);
                    Database.upsert(opAccKPIAchvListToUpdate,true);
                }
            }
            
        }catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'with message '+ batchException.getLineNumber());
            System.debug('Exception stack trace '+ batchException.getStackTraceString());
            hasError = true;
        }
        
        
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(88);
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OperatorCBOpportunityDetailsBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError); 
        }
        
    }
    
}